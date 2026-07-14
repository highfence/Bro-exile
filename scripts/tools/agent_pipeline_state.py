#!/usr/bin/env python3
"""Canonical, importable state model for the Bro-exile agent pipeline."""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime
import json
from pathlib import Path, PurePosixPath
import re
import subprocess
from typing import Any


STATUSES = {"pending", "ready", "complete"}
OWNER_LANES = {"planning", "dev", "asset", "validation", "producer"}
VERDICTS = {"not-run", "passed", "conditional-pass", "rejected"}
USER_GATES = {
    "not-requested",
    "awaiting-user-approval",
    "approved",
    "changes-requested",
}
STUDIO_PHASES = {
    "spec-locked",
    "running",
    "blocked",
    "demo-ready",
    "adjusting",
    "kept",
    "archived",
}
ACTIVE_PLAN_CONTRACT = {
    "artifact_contract": "ce-unified-plan/v1",
    "artifact_readiness": "implementation-ready",
    "execution": "code",
}
STATE_KEYS = (
    "status",
    "owner_lane",
    "validator_verdict",
    "user_gate",
    "artifacts",
    "routing_reason",
)
STUDIO_STATE_DEFAULTS: dict[str, Any] = {
    "studio_enabled": False,
    "studio_phase": "",
    "studio_spec_lock": "",
    "studio_stable_ref": "",
    "studio_stable_commit": "",
    "studio_candidate_ref": "",
    "studio_candidate_commit": "",
    "studio_review_due_at": "",
    "studio_repair_count": 0,
    "studio_blocker": "",
    "studio_demo_bundle": "",
}
STUDIO_STATE_KEYS = tuple(STUDIO_STATE_DEFAULTS)
PIPELINE_STATE_RE = re.compile(
    r"<!--\s*pipeline-state\s*\n(?P<payload>.*?)\n-->", re.DOTALL
)
PIPELINE_QUEUE_RE = re.compile(
    r"<!--\s*pipeline-queue\s*\n(?P<payload>.*?)\n-->", re.DOTALL
)
STUDIO_INBOX_RE = re.compile(
    r"<!--\s*studio-inbox\s*\n(?P<payload>.*?)\n-->", re.DOTALL
)
GITHUB_ISSUE_RE = re.compile(
    r"https://github\.com/highfence/Bro-exile/issues/[1-9]\d*\Z"
)
GIT_REF_RE = re.compile(r"refs/[A-Za-z0-9._/-]+\Z")
GIT_COMMIT_RE = re.compile(r"[0-9a-fA-F]{7,40}\Z")


class ValidationError(Exception):
    """A user-actionable pipeline consistency failure."""


@dataclass(frozen=True)
class SliceTodo:
    path: Path
    issue_id: str
    github_issue: str
    queue_order: int
    state: dict[str, Any]
    last_handoff: str


@dataclass(frozen=True)
class PipelineSnapshot:
    root: Path
    active: SliceTodo
    slices: tuple[SliceTodo, ...]
    next_transition: str


def scalar(value: str) -> Any:
    value = value.strip()
    if not value:
        return ""
    try:
        return json.loads(value)
    except json.JSONDecodeError:
        if value == "true":
            return True
        if value == "false":
            return False
        if value in {"null", "~"}:
            return None
        return value.strip('"\'')


def parse_frontmatter(text: str, path: Path) -> dict[str, Any]:
    if not text.startswith("---\n"):
        raise ValidationError(f"{path}: missing frontmatter")
    parts = text.split("---\n", 2)
    if len(parts) < 3:
        raise ValidationError(f"{path}: unterminated frontmatter")

    result: dict[str, Any] = {}
    active_list: str | None = None
    for line in parts[1].splitlines():
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        if line.startswith("  - ") and active_list:
            result[active_list].append(scalar(line[4:]))
            continue
        active_list = None
        if ":" not in line:
            raise ValidationError(f"{path}: unsupported frontmatter line: {line}")
        key, raw_value = line.split(":", 1)
        key = key.strip()
        raw_value = raw_value.strip()
        if raw_value == "":
            result[key] = [] if key in {"artifacts", "dependencies"} else ""
            if isinstance(result[key], list):
                active_list = key
        else:
            result[key] = scalar(raw_value)
    return result


def read_json_marker(
    text: str, pattern: re.Pattern[str], path: Path
) -> dict[str, Any]:
    matches = list(pattern.finditer(text))
    if not matches:
        marker_name = "pipeline-state" if pattern is PIPELINE_STATE_RE else "pipeline-queue"
        raise ValidationError(f"{path}: missing {marker_name} marker")
    try:
        value = json.loads(matches[-1].group("payload"))
    except json.JSONDecodeError as exc:
        raise ValidationError(f"{path}: invalid pipeline JSON: {exc}") from exc
    if not isinstance(value, dict):
        raise ValidationError(f"{path}: pipeline marker must contain a JSON object")
    return value


def _repository_path(value: Any, *, field: str, allow_empty: bool = False) -> str:
    if value == "" and allow_empty:
        return ""
    if not isinstance(value, str) or not value:
        raise ValidationError(f"{field} must be a non-empty repository-relative path")
    path = PurePosixPath(value)
    if path.is_absolute() or ".." in path.parts or path.parts[0] in {".git", ".studio"}:
        raise ValidationError(f"{field} must stay inside the durable repository surface: {value}")
    return value


def _load_slice(path: Path) -> SliceTodo | None:
    text = path.read_text(encoding="utf-8")
    frontmatter = parse_frontmatter(text, path)
    if frontmatter.get("pipeline_slice") is not True:
        return None

    missing = [
        key
        for key in (
            "status",
            "issue_id",
            "queue_order",
            "owner_lane",
            "validator_verdict",
            "user_gate",
            "artifacts",
            "last_handoff",
        )
        if key not in frontmatter
    ]
    if missing:
        raise ValidationError(f"{path}: missing canonical fields: {', '.join(missing)}")

    evidence = read_json_marker(text, PIPELINE_STATE_RE, path)
    state = {
        key: frontmatter.get(key, "" if key == "routing_reason" else None)
        for key in STATE_KEYS
    }
    evidence_state = {
        key: evidence.get(key, "" if key == "routing_reason" else None)
        for key in STATE_KEYS
    }
    if state != evidence_state:
        raise ValidationError(
            f"{path}: frontmatter/work-log mismatch: "
            f"frontmatter={state!r} work_log={evidence_state!r}"
        )

    studio_present = any(key in frontmatter or key in evidence for key in STUDIO_STATE_KEYS)
    if studio_present:
        studio_state = {
            key: frontmatter.get(key, default)
            for key, default in STUDIO_STATE_DEFAULTS.items()
        }
        studio_evidence = {
            key: evidence.get(key, default)
            for key, default in STUDIO_STATE_DEFAULTS.items()
        }
        if studio_state != studio_evidence:
            raise ValidationError(
                f"{path}: frontmatter/work-log mismatch: "
                f"frontmatter={studio_state!r} work_log={studio_evidence!r}"
            )
        state.update(studio_state)

    last_handoff = str(frontmatter["last_handoff"])
    handoff_heading = f"### {last_handoff}"
    if handoff_heading not in text:
        raise ValidationError(f"{path}: last_handoff heading not found: {last_handoff}")
    headings = list(re.finditer(r"^### (?P<title>.+)$", text, re.MULTILINE))
    if not headings or headings[-1].group("title") != last_handoff:
        latest = headings[-1].group("title") if headings else "none"
        raise ValidationError(
            f"{path}: last_handoff is not the latest appended Work Log heading: {latest}"
        )
    latest_marker = list(PIPELINE_STATE_RE.finditer(text))[-1]
    if latest_marker.start() < headings[-1].end():
        raise ValidationError(f"{path}: latest pipeline-state must follow last_handoff")

    try:
        queue_order = int(frontmatter["queue_order"])
    except (TypeError, ValueError) as exc:
        raise ValidationError(f"{path}: queue_order must be an integer") from exc
    return SliceTodo(
        path=path,
        issue_id=str(frontmatter["issue_id"]),
        github_issue=str(frontmatter.get("github_issue", "")),
        queue_order=queue_order,
        state=state,
        last_handoff=last_handoff,
    )


def _validate_github_issue_links(todo_dir: Path) -> None:
    linked: dict[str, Path] = {}
    for path in sorted(todo_dir.glob("*.md")):
        if path.name == "README.md":
            continue
        frontmatter = parse_frontmatter(path.read_text(encoding="utf-8"), path)
        if frontmatter.get("status") not in {"pending", "ready"}:
            continue
        github_issue = frontmatter.get("github_issue")
        if not isinstance(github_issue, str) or not GITHUB_ISSUE_RE.fullmatch(github_issue):
            raise ValidationError(
                f"{path}: pending/ready todo requires github_issue URL for highfence/Bro-exile"
            )
        if github_issue in linked:
            raise ValidationError(
                f"{path}: duplicate github_issue also used by {linked[github_issue]}: {github_issue}"
            )
        linked[github_issue] = path


def _validate_studio_state(todo: SliceTodo, root: Path) -> None:
    state = todo.state
    if not state.get("studio_enabled"):
        return
    required = (
        "studio_phase",
        "studio_spec_lock",
        "studio_stable_ref",
        "studio_review_due_at",
        "studio_repair_count",
    )
    missing = [key for key in required if state.get(key, "") == ""]
    if missing:
        raise ValidationError(
            f"{todo.path}: missing async studio fields: {', '.join(missing)}"
        )
    phase = state["studio_phase"]
    if phase not in STUDIO_PHASES:
        raise ValidationError(f"{todo.path}: invalid studio_phase={phase!r}")
    _repository_path(state["studio_spec_lock"], field="studio_spec_lock")
    _repository_path(state.get("studio_demo_bundle", ""), field="studio_demo_bundle", allow_empty=True)

    stable_ref = state["studio_stable_ref"]
    candidate_ref = state.get("studio_candidate_ref", "")
    if stable_ref != "refs/bro-exile-studio/approved":
        raise ValidationError(
            f"{todo.path}: studio_stable_ref must be refs/bro-exile-studio/approved"
        )
    if candidate_ref:
        if candidate_ref == stable_ref:
            raise ValidationError(f"{todo.path}: stable and candidate refs must be distinct")
        if not GIT_REF_RE.fullmatch(candidate_ref) or not (
            candidate_ref.startswith("refs/heads/studio/")
            or candidate_ref.startswith("refs/heads/studio-")
        ):
            raise ValidationError(f"{todo.path}: invalid local studio candidate ref: {candidate_ref}")

    stable_commit = state["studio_stable_commit"]
    candidate_commit = state.get("studio_candidate_commit", "")
    if stable_commit and not GIT_COMMIT_RE.fullmatch(stable_commit):
        raise ValidationError(f"{todo.path}: invalid studio_stable_commit")
    if candidate_commit and not GIT_COMMIT_RE.fullmatch(candidate_commit):
        raise ValidationError(f"{todo.path}: invalid studio_candidate_commit")
    if phase in {"running", "blocked", "demo-ready", "adjusting", "kept", "archived"}:
        if not candidate_ref:
            raise ValidationError(
                f"{todo.path}: phase {phase} requires a candidate ref"
            )
    if stable_commit == candidate_commit and candidate_commit:
        raise ValidationError(f"{todo.path}: stable and candidate commits must be distinct")

    try:
        due = datetime.fromisoformat(str(state["studio_review_due_at"]))
    except ValueError as exc:
        raise ValidationError(f"{todo.path}: studio_review_due_at must be ISO 8601") from exc
    if due.tzinfo is None:
        raise ValidationError(f"{todo.path}: studio_review_due_at must include timezone")
    repair_count = state["studio_repair_count"]
    if not isinstance(repair_count, int) or isinstance(repair_count, bool) or not 0 <= repair_count <= 2:
        raise ValidationError(f"{todo.path}: studio_repair_count must be an integer from 0 to 2")
    blocker = state.get("studio_blocker", "")
    if phase == "blocked" and (not isinstance(blocker, str) or not blocker.strip()):
        raise ValidationError(f"{todo.path}: blocked studio run requires one blocker question")
    if isinstance(blocker, str) and "\n" in blocker.strip():
        raise ValidationError(f"{todo.path}: studio_blocker must be one question")
    if phase == "demo-ready" and not state.get("studio_demo_bundle"):
        raise ValidationError(f"{todo.path}: demo-ready studio run requires studio_demo_bundle")

    git_dir = root / ".git"
    if git_dir.exists():
        resolved_stable = subprocess.run(
            ["git", "-C", str(root), "rev-parse", "--verify", f"{stable_ref}^{{commit}}"],
            capture_output=True,
            text=True,
            check=False,
        )
        if resolved_stable.returncode:
            raise ValidationError(f"{todo.path}: stable ref does not exist locally: {stable_ref}")
        stable_tip = resolved_stable.stdout.strip()
        if stable_commit and stable_tip != stable_commit:
            raise ValidationError(f"{todo.path}: recorded stable commit does not match stable ref")
    if git_dir.exists() and candidate_ref:
        resolved_candidate = subprocess.run(
            ["git", "-C", str(root), "rev-parse", "--verify", f"{candidate_ref}^{{commit}}"],
            capture_output=True,
            text=True,
            check=False,
        )
        if resolved_candidate.returncode:
            raise ValidationError(f"{todo.path}: candidate ref does not exist locally: {candidate_ref}")
        candidate_tip = resolved_candidate.stdout.strip()
        if candidate_commit and candidate_tip != candidate_commit:
            raise ValidationError(
                f"{todo.path}: recorded candidate commit does not match candidate ref tip"
            )
        for commit, label in ((stable_tip, "stable"), (candidate_tip, "candidate")):
            probe = subprocess.run(
                ["git", "-C", str(root), "cat-file", "-e", f"{commit}^{{commit}}"],
                capture_output=True,
                text=True,
                check=False,
            )
            if probe.returncode:
                raise ValidationError(f"{todo.path}: {label} commit does not exist locally: {commit}")
        ancestry = subprocess.run(
            ["git", "-C", str(root), "merge-base", "--is-ancestor", stable_tip, candidate_tip],
            capture_output=True,
            text=True,
            check=False,
        )
        if ancestry.returncode:
            raise ValidationError(f"{todo.path}: candidate lost stable ancestry")


def _validate_state(todo: SliceTodo, root: Path) -> None:
    state = todo.state
    for key, allowed in (
        ("status", STATUSES),
        ("owner_lane", OWNER_LANES),
        ("validator_verdict", VERDICTS),
        ("user_gate", USER_GATES),
    ):
        if state[key] not in allowed:
            raise ValidationError(
                f"{todo.path}: invalid {key}={state[key]!r}; expected one of {sorted(allowed)}"
            )
    if not isinstance(state["artifacts"], list) or not all(
        isinstance(item, str) for item in state["artifacts"]
    ):
        raise ValidationError(f"{todo.path}: artifacts must be a list of repository paths")
    for artifact in state["artifacts"]:
        _repository_path(artifact, field="artifact")

    status = state["status"]
    verdict = state["validator_verdict"]
    gate = state["user_gate"]
    owner = state["owner_lane"]
    routing_reason = state["routing_reason"]
    if verdict == "passed" and status != "complete":
        awaiting_approval = gate == "awaiting-user-approval" and owner == "producer"
        revising_after_feedback = gate == "changes-requested" and owner == "planning"
        if not (awaiting_approval or revising_after_feedback):
            raise ValidationError(
                f"{todo.path}: passed requires either owner_lane=producer with "
                "user_gate=awaiting-user-approval or owner_lane=planning with "
                "user_gate=changes-requested"
            )
    if status == "complete" and not (verdict == "passed" and gate == "approved"):
        raise ValidationError(
            f"{todo.path}: complete requires validator_verdict=passed and user_gate=approved"
        )
    if gate == "approved" and status != "complete":
        raise ValidationError(f"{todo.path}: approved requires status=complete")
    if gate == "changes-requested" and owner != "planning":
        raise ValidationError(f"{todo.path}: changes-requested must route to owner_lane=planning")
    if verdict == "rejected":
        expected = {"code": "dev", "asset": "asset", "design": "planning"}.get(routing_reason)
        if expected is None:
            raise ValidationError(f"{todo.path}: rejected requires routing_reason=code|asset|design")
        if owner != expected:
            raise ValidationError(
                f"{todo.path}: rejected routing_reason={routing_reason} requires owner_lane={expected}"
            )
    elif routing_reason:
        raise ValidationError(f"{todo.path}: routing_reason is only valid for rejected verdicts")
    _validate_studio_state(todo, root)


def next_transition(active: SliceTodo) -> str:
    state = active.state
    if state.get("studio_enabled"):
        phase = state.get("studio_phase")
        if phase == "spec-locked":
            return "product-owner-start"
        if phase == "blocked":
            return "product-owner-decision"
        if phase == "demo-ready":
            return "product-owner-demo-decision"
    if state["user_gate"] == "changes-requested":
        return "planner-handoff"
    if state["validator_verdict"] == "passed":
        return "product-owner-approval"
    if state["validator_verdict"] in {"rejected", "conditional-pass"}:
        return f"{state['owner_lane']}-handoff"
    return {
        "planning": "planner-handoff",
        "dev": "validator-handoff",
        "asset": "validator-handoff",
        "validation": "validator-verdict",
        "producer": "producer-decision",
    }[state["owner_lane"]]


def validate_pipeline(root: Path) -> PipelineSnapshot:
    root = root.resolve()
    todo_dir = root / "todos"
    if not todo_dir.is_dir():
        raise ValidationError(f"{todo_dir}: todo directory not found")
    _validate_github_issue_links(todo_dir)
    slices = [
        todo
        for path in sorted(todo_dir.glob("*.md"))
        if path.name != "README.md" and (todo := _load_slice(path)) is not None
    ]
    if not slices:
        raise ValidationError("no pipeline_slice todos found")
    for todo in slices:
        _validate_state(todo, root)
    slices.sort(key=lambda todo: todo.queue_order)
    ids = [todo.issue_id for todo in slices]
    if len(set(ids)) != len(ids) or [todo.queue_order for todo in slices] != list(
        range(1, len(slices) + 1)
    ):
        raise ValidationError("pipeline slice issue_id and queue_order must be unique and contiguous")

    awaiting = [
        todo
        for todo in slices
        if todo.state["validator_verdict"] == "passed"
        and todo.state["user_gate"] == "awaiting-user-approval"
    ]
    if awaiting:
        locked = awaiting[0]
        later_ready = [
            todo.issue_id
            for todo in slices
            if todo.queue_order > locked.queue_order and todo.state["status"] == "ready"
        ]
        if later_ready:
            raise ValidationError(
                f"slice {locked.issue_id} is awaiting Product Owner approval; "
                f"later slices cannot activate: {', '.join(later_ready)}"
            )

    active = [todo for todo in slices if todo.state["status"] == "ready"]
    if len(active) != 1:
        raise ValidationError(
            f"expected exactly one ready slice, found {len(active)}: "
            + ", ".join(todo.issue_id for todo in active)
        )
    current = active[0]
    for todo in slices:
        if todo.queue_order < current.queue_order and todo.state["status"] != "complete":
            raise ValidationError(
                f"slice {todo.issue_id} precedes active {current.issue_id} but is not complete"
            )
        if todo.queue_order > current.queue_order and todo.state["status"] != "pending":
            raise ValidationError(
                f"slice {todo.issue_id} follows active {current.issue_id} but is not pending"
            )

    for artifact in current.state["artifacts"]:
        artifact_path = root / artifact
        if not artifact_path.exists():
            raise ValidationError(
                f"{current.path}: missing active artifact before dispatch: {artifact}"
            )
        if PurePosixPath(artifact).parts[:2] == ("docs", "plans"):
            plan_frontmatter = parse_frontmatter(
                artifact_path.read_text(encoding="utf-8"), artifact_path
            )
            actual = {key: plan_frontmatter.get(key) for key in ACTIVE_PLAN_CONTRACT}
            if actual != ACTIVE_PLAN_CONTRACT:
                raise ValidationError(
                    f"{current.path}: active plan is not implementation-ready code: {artifact}; "
                    f"expected={ACTIVE_PLAN_CONTRACT!r} actual={actual!r}"
                )

    readme = read_json_marker(
        (todo_dir / "README.md").read_text(encoding="utf-8"),
        PIPELINE_QUEUE_RE,
        todo_dir / "README.md",
    )
    current_state_path = root / "docs" / "operations" / "agent-pipeline-current-state.md"
    current_projection = read_json_marker(
        current_state_path.read_text(encoding="utf-8"),
        PIPELINE_QUEUE_RE,
        current_state_path,
    )
    expected = {
        "active_slice": current.issue_id,
        "owner_lane": current.state["owner_lane"],
        "last_handoff": current.last_handoff,
        "artifacts": current.state["artifacts"],
        "order": ids,
    }
    if readme != expected:
        raise ValidationError(
            f"{todo_dir / 'README.md'}: queue projection drift: {readme!r} != {expected!r}"
        )
    if current_projection != expected:
        raise ValidationError(
            f"{current_state_path}: current-state projection drift: "
            f"{current_projection!r} != {expected!r}"
        )
    if current.state.get("studio_enabled"):
        inbox_path = root / "docs" / "operations" / "agent-studio-inbox.md"
        if not inbox_path.is_file():
            raise ValidationError(f"{inbox_path}: studio run requires inbox projection")
        inbox = read_json_marker(
            inbox_path.read_text(encoding="utf-8"),
            STUDIO_INBOX_RE,
            inbox_path,
        )
        expected_inbox = {
            "active_slice": current.issue_id,
            "studio_phase": current.state.get("studio_phase", ""),
            "studio_blocker": current.state.get("studio_blocker", ""),
            "studio_demo_bundle": current.state.get("studio_demo_bundle", ""),
            "studio_stable_ref": current.state.get("studio_stable_ref", ""),
            "studio_candidate_ref": current.state.get("studio_candidate_ref", ""),
            "studio_review_due_at": current.state.get("studio_review_due_at", ""),
            "studio_repair_count": current.state.get("studio_repair_count", 0),
        }
        if inbox != expected_inbox:
            raise ValidationError(
                f"{inbox_path}: studio inbox projection drift: {inbox!r} != {expected_inbox!r}"
            )
    return PipelineSnapshot(
        root=root,
        active=current,
        slices=tuple(slices),
        next_transition=next_transition(current),
    )
