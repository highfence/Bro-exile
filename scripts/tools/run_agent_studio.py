#!/usr/bin/env python3
"""Run the local, spec-locked Bro-exile asynchronous agent studio.

The repository is the product authority. Orca is used only as a replaceable
control plane, and every mutating command requires explicit confirmation.
"""

from __future__ import annotations

import argparse
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
import hashlib
import json
from pathlib import Path, PurePosixPath
import re
import shutil
import subprocess
import sys
from typing import Any

from agent_pipeline_state import (
    ACTIVE_PLAN_CONTRACT,
    PIPELINE_QUEUE_RE,
    PIPELINE_STATE_RE,
    STATE_KEYS,
    STUDIO_STATE_DEFAULTS,
    ValidationError,
    parse_frontmatter,
    validate_pipeline,
)


STABLE_REF = "refs/bro-exile-studio/approved"
REQUIRED_HEADINGS = (
    "Demo Promise",
    "Player Outcome",
    "Must / May / Must Not",
    "Acceptance Examples",
    "Defaults and Variants",
    "Rejected Alternatives",
    "Stop Conditions",
    "Play Lens",
)
REQUIRED_LIST_FIELDS = (
    "must",
    "may",
    "must_not",
    "acceptance_examples",
    "defaults",
    "variants",
    "rejected_alternatives",
    "stop_conditions",
    "unresolved_product_decisions",
    "writer_lanes",
    "allowed_paths",
)


class StudioError(Exception):
    """A fail-closed, user-actionable studio preflight failure."""


@dataclass(frozen=True)
class CommandResult:
    returncode: int
    stdout: str
    stderr: str


class SubprocessRunner:
    """Run fixed argv vectors without a shell or inherited prompt interpolation."""

    def run(self, argv: list[str], *, cwd: Path | None = None) -> CommandResult:
        try:
            result = subprocess.run(
                argv,
                cwd=cwd,
                text=True,
                capture_output=True,
                check=False,
                timeout=120,
            )
        except subprocess.TimeoutExpired as exc:
            stdout = exc.stdout if isinstance(exc.stdout, str) else ""
            stderr = exc.stderr if isinstance(exc.stderr, str) else ""
            return CommandResult(124, stdout, stderr or "command timed out after 120 seconds")
        return CommandResult(result.returncode, result.stdout, result.stderr)


@dataclass(frozen=True)
class SpecLock:
    path: Path
    relative_path: str
    slice_id: str
    todo_path: str
    plan_path: str
    demo_promise: str
    player_outcome: str
    must: tuple[str, ...]
    may: tuple[str, ...]
    must_not: tuple[str, ...]
    acceptance_examples: tuple[str, ...]
    defaults: tuple[str, ...]
    variants: tuple[str, ...]
    rejected_alternatives: tuple[str, ...]
    stop_conditions: tuple[str, ...]
    repair_budget: int
    review_due_at: datetime
    review_deadline_override: str
    play_lens: str
    writer_lanes: tuple[str, ...]
    allowed_paths: tuple[str, ...]
    next_owner: str


@dataclass(frozen=True)
class RoleCompletion:
    task_id: str
    dispatch_id: str
    role: str
    terminal: str
    commit: str
    handoff_path: str
    artifacts: tuple[str, ...]


@dataclass(frozen=True)
class DemoBundle:
    path: Path
    relative_path: str
    slice_id: str
    spec_lock: str
    stable_commit: str
    candidate_commit: str
    validation_status: str
    change_summary: str
    validation_evidence: tuple[str, ...]
    deviations: tuple[str, ...]
    variants: tuple[str, ...]
    play_lens: str
    blocker_question: str
    visual_change: bool
    visual_evidence: tuple[str, ...]
    launch_scene: str


def _inside(root: Path, path: Path) -> bool:
    try:
        path.relative_to(root)
    except ValueError:
        return False
    return True


def _repo_path(root: Path, value: Any, *, field: str) -> tuple[str, Path]:
    if not isinstance(value, str) or not value:
        raise StudioError(f"{field} must be a non-empty repository-relative path")
    pure = PurePosixPath(value)
    if pure.is_absolute() or ".." in pure.parts or pure.parts[0] in {".git", ".studio"}:
        raise StudioError(f"{field} escapes the allowed repository surface: {value}")
    resolved = (root / value).resolve()
    if not _inside(root, resolved):
        raise StudioError(f"{field} escapes the repository: {value}")
    return value, resolved


def _string_list(data: dict[str, Any], key: str, *, allow_empty: bool = False) -> tuple[str, ...]:
    value = data.get(key)
    if not isinstance(value, list) or not all(isinstance(item, str) and item.strip() for item in value):
        raise StudioError(f"{key} must be a list of non-empty strings")
    if not value and not allow_empty:
        raise StudioError(f"{key} must contain at least one item")
    return tuple(item.strip() for item in value)


def _one_line(data: dict[str, Any], key: str) -> str:
    value = data.get(key)
    if not isinstance(value, str) or not value.strip() or "\n" in value.strip():
        raise StudioError(f"{key} must be one non-empty line")
    return value.strip()


def _redact(text: str) -> str:
    redacted = re.sub(
        r"(?i)(token|password|secret|authorization)([=: ]+)([^\s,}]+)",
        r"\1\2[REDACTED]",
        text,
    )
    return redacted[-2000:]


def _read_json_object(text: str, *, label: str) -> dict[str, Any]:
    try:
        value = json.loads(text)
    except json.JSONDecodeError as exc:
        raise StudioError(f"{label} returned invalid JSON") from exc
    if not isinstance(value, dict):
        raise StudioError(f"{label} must return a JSON object")
    return value


def _command(
    runner: Any,
    argv: list[str],
    *,
    cwd: Path | None = None,
    label: str,
) -> CommandResult:
    result = runner.run(argv, cwd=cwd)
    if result.returncode:
        detail = _redact(result.stderr or result.stdout or "no output")
        raise StudioError(f"{label} failed: {detail}")
    return result


def _git(
    root: Path,
    *args: str,
    runner: Any | None = None,
    label: str = "git",
    strip: bool = True,
) -> str:
    active_runner = runner or SubprocessRunner()
    result = _command(
        active_runner,
        ["git", "-C", str(root), *args],
        label=label,
    )
    return result.stdout.strip() if strip else result.stdout


def _parse_due(data: dict[str, Any], now: datetime) -> tuple[datetime, str]:
    raw = data.get("review_due_at")
    if not isinstance(raw, str):
        raise StudioError("review_due_at must be an ISO 8601 timestamp")
    try:
        due = datetime.fromisoformat(raw)
    except ValueError as exc:
        raise StudioError("review_due_at must be an ISO 8601 timestamp") from exc
    if due.tzinfo is None:
        raise StudioError("review_due_at must include a timezone")
    if now.tzinfo is None:
        raise StudioError("preflight now must include a timezone")
    override = data.get("review_deadline_override", "")
    if not isinstance(override, str):
        raise StudioError("review_deadline_override must be a string")
    delta = due.astimezone(timezone.utc) - now.astimezone(timezone.utc)
    if not timedelta(days=1) <= delta <= timedelta(days=3) and not override.strip():
        raise StudioError("review_due_at must be 1 to 3 days away or include an override reason")
    if delta <= timedelta(0):
        raise StudioError("review_due_at must be in the future")
    return due, override.strip()


def load_spec_lock(root: Path, spec_path: Path, *, now: datetime | None = None) -> SpecLock:
    """Validate a spec lock without mutating files, refs, worktrees, or Orca."""

    root = root.resolve()
    path = spec_path if spec_path.is_absolute() else root / spec_path
    path = path.resolve()
    if not _inside(root, path):
        raise StudioError(f"spec lock must be inside the repository: {spec_path}")
    if not path.is_file():
        raise StudioError(f"spec lock not found: {path}")
    relative_path = path.relative_to(root).as_posix()
    if not relative_path.startswith("docs/spec-locks/"):
        raise StudioError("spec lock must live under docs/spec-locks/")

    text = path.read_text(encoding="utf-8")
    try:
        data = parse_frontmatter(text, path)
    except ValidationError as exc:
        raise StudioError(str(exc)) from exc
    if data.get("studio_spec_lock") is not True:
        raise StudioError("studio_spec_lock must be true")
    missing_headings = [heading for heading in REQUIRED_HEADINGS if f"## {heading}" not in text]
    if missing_headings:
        raise StudioError(f"spec lock is missing sections: {', '.join(missing_headings)}")
    for key in REQUIRED_LIST_FIELDS:
        if key not in data:
            raise StudioError(f"spec lock is missing field: {key}")

    slice_id = _one_line(data, "slice_id")
    if not re.fullmatch(r"[0-9]{3}", slice_id):
        raise StudioError("slice_id must be exactly three digits")
    todo_value, todo_path = _repo_path(root, data.get("todo"), field="todo")
    plan_value, plan_path = _repo_path(root, data.get("plan"), field="plan")
    if not todo_path.is_file() or not plan_path.is_file():
        raise StudioError("spec lock todo and plan must exist")
    todo_data = parse_frontmatter(todo_path.read_text(encoding="utf-8"), todo_path)
    if str(todo_data.get("issue_id", "")) != slice_id:
        raise StudioError("spec lock slice_id does not match linked todo")
    if todo_data.get("pipeline_slice") is not True or todo_data.get("status") != "ready":
        raise StudioError("linked todo must be the ready pipeline_slice")
    next_owner = str(todo_data.get("owner_lane", ""))
    if next_owner not in {"planning", "dev", "asset", "validation", "producer"}:
        raise StudioError("linked todo has no valid owner lane")

    plan_data = parse_frontmatter(plan_path.read_text(encoding="utf-8"), plan_path)
    actual_plan = {key: plan_data.get(key) for key in ACTIVE_PLAN_CONTRACT}
    if actual_plan != ACTIVE_PLAN_CONTRACT:
        raise StudioError(
            f"linked plan must be implementation-ready code: expected={ACTIVE_PLAN_CONTRACT!r} "
            f"actual={actual_plan!r}"
        )

    demo_promise = _one_line(data, "demo_promise")
    player_outcome = _one_line(data, "player_outcome")
    play_lens = _one_line(data, "play_lens")
    must = _string_list(data, "must")
    may = _string_list(data, "may", allow_empty=True)
    must_not = _string_list(data, "must_not")
    normalized_must = {item.casefold() for item in must}
    conflict = normalized_must & {item.casefold() for item in must_not}
    if conflict:
        raise StudioError(f"must and must_not conflict: {', '.join(sorted(conflict))}")
    acceptance_examples = _string_list(data, "acceptance_examples")
    categories = {item.split(":", 1)[0].strip().casefold() for item in acceptance_examples if ":" in item}
    if not {"happy", "edge", "failure"}.issubset(categories):
        raise StudioError("acceptance_examples must include happy, edge, and failure cases")
    defaults = _string_list(data, "defaults")
    variants = _string_list(data, "variants")
    if len(variants) > 2:
        raise StudioError("spec lock allows at most two variants")
    rejected = _string_list(data, "rejected_alternatives")
    stop_conditions = _string_list(data, "stop_conditions")
    unresolved = _string_list(data, "unresolved_product_decisions", allow_empty=True)
    if unresolved:
        raise StudioError(f"unresolved product decision: {unresolved[0]}")
    writer_lanes = _string_list(data, "writer_lanes")
    if len(writer_lanes) > 2 or len(set(writer_lanes)) != len(writer_lanes):
        raise StudioError("writer_lanes must contain one or two unique lanes")
    if not set(writer_lanes).issubset({"dev", "asset"}):
        raise StudioError("writer_lanes may contain only dev and asset")
    allowed_paths = _string_list(data, "allowed_paths")
    for allowed in allowed_paths:
        _repo_path(root, allowed, field="allowed_paths")

    repair_budget = data.get("repair_budget")
    if repair_budget != 2:
        raise StudioError("v1 repair_budget must be 2")
    due, override = _parse_due(data, now or datetime.now().astimezone())
    return SpecLock(
        path=path,
        relative_path=relative_path,
        slice_id=slice_id,
        todo_path=todo_value,
        plan_path=plan_value,
        demo_promise=demo_promise,
        player_outcome=player_outcome,
        must=must,
        may=may,
        must_not=must_not,
        acceptance_examples=acceptance_examples,
        defaults=defaults,
        variants=variants,
        rejected_alternatives=rejected,
        stop_conditions=stop_conditions,
        repair_budget=repair_budget,
        review_due_at=due,
        review_deadline_override=override,
        play_lens=play_lens,
        writer_lanes=writer_lanes,
        allowed_paths=allowed_paths,
        next_owner=next_owner,
    )


def build_start_preview(root: Path, spec: SpecLock) -> dict[str, Any]:
    """Return the exact local mutations a confirmed start would attempt."""

    spec_hash = hashlib.sha256(spec.path.read_bytes()).hexdigest()[:10]
    candidate_name = f"studio-{spec.slice_id}-{spec_hash}"
    return {
        "ready": True,
        "mutates_state": False,
        "slice_id": spec.slice_id,
        "demo_promise": spec.demo_promise,
        "stable_ref": STABLE_REF,
        "candidate_ref": f"refs/heads/{candidate_name}",
        "candidate_name": candidate_name,
        "next_owner": spec.next_owner,
        "writer_lanes": list(spec.writer_lanes),
        "max_concurrency": 1,
        "review_due_at": spec.review_due_at.isoformat(),
        "checkpoint_allowlist": [
            spec.relative_path,
            spec.todo_path,
            "todos/README.md",
            "docs/operations/agent-pipeline-current-state.md",
        ],
        "orca": {
            "required": True,
            "worktree_base": STABLE_REF,
            "coordinator": "manual-loop",
        },
        "forbidden_side_effects": [
            "remote push",
            "main update",
            "force ref update",
            "runtime asset promotion",
            "public release",
        ],
    }


def bootstrap_stable_ref(
    root: Path,
    commit: str,
    *,
    confirmed: bool,
    runner: Any | None = None,
) -> str:
    """Create the approved local ref once; never move an existing ref implicitly."""

    if not confirmed:
        raise StudioError("bootstrap requires explicit --yes confirmation")
    root = root.resolve()
    active_runner = runner or SubprocessRunner()
    resolved = _git(root, "rev-parse", "--verify", f"{commit}^{{commit}}", runner=active_runner)
    probe = active_runner.run(
        ["git", "-C", str(root), "rev-parse", "--verify", f"{STABLE_REF}^{{commit}}"],
        cwd=None,
    )
    if probe.returncode == 0:
        existing = probe.stdout.strip()
        if existing != resolved:
            raise StudioError(
                f"{STABLE_REF} already points to {existing}; use an explicit keep decision to move it"
            )
        return existing
    zero = "0" * 40
    _git(
        root,
        "update-ref",
        STABLE_REF,
        resolved,
        zero,
        runner=active_runner,
        label="stable ref bootstrap",
    )
    return resolved


def _dirty_paths(root: Path, runner: Any) -> tuple[str, ...]:
    raw = _git(
        root,
        "status",
        "--porcelain=v1",
        "-z",
        "--untracked-files=all",
        runner=runner,
        label="dirty workspace check",
        strip=False,
    )
    if not raw:
        return ()
    entries = raw.split("\0")
    paths: list[str] = []
    index = 0
    while index < len(entries):
        entry = entries[index]
        index += 1
        if not entry:
            continue
        if len(entry) < 4:
            raise StudioError(f"unable to parse dirty workspace entry: {entry!r}")
        status = entry[:2]
        path = entry[3:]
        if "R" in status or "C" in status:
            if index < len(entries) and entries[index]:
                path = entries[index]
                index += 1
        paths.append(PurePosixPath(path).as_posix())
    return tuple(paths)


def _path_overlaps(path: str, allowed: str) -> bool:
    clean_path = PurePosixPath(path).as_posix().rstrip("/")
    clean_allowed = PurePosixPath(allowed).as_posix().rstrip("/")
    return clean_path == clean_allowed or clean_path.startswith(clean_allowed + "/")


def _check_dirty_overlap(root: Path, spec: SpecLock, runner: Any) -> tuple[str, ...]:
    dirty = _dirty_paths(root, runner)
    copied = {
        spec.relative_path,
        spec.todo_path,
        "todos/README.md",
        "docs/operations/agent-pipeline-current-state.md",
    }
    overlap = [
        path
        for path in dirty
        if path not in copied and any(_path_overlaps(path, allowed) for allowed in spec.allowed_paths)
    ]
    if overlap:
        raise StudioError(
            "dirty files overlap the candidate write scope: " + ", ".join(sorted(overlap))
        )
    return dirty


def _orca_available(root: Path, runner: Any) -> dict[str, Any]:
    result = _command(
        runner,
        ["orca", "status", "--json"],
        cwd=root,
        label="Orca status",
    )
    payload = _read_json_object(result.stdout, label="Orca status")
    try:
        runtime = payload["result"]["runtime"]
        graph = payload["result"]["graph"]
    except (KeyError, TypeError) as exc:
        raise StudioError("Orca status returned an invalid JSON contract") from exc
    if runtime.get("reachable") is not True or runtime.get("state") != "running":
        raise StudioError(
            "Orca runtime is unavailable; start Orca and enable orchestration before retrying"
        )
    if graph.get("state") != "running":
        raise StudioError("Orca orchestration graph is not running")
    return payload


def _find_worktree(payload: Any) -> dict[str, Any] | None:
    if isinstance(payload, dict):
        if isinstance(payload.get("path"), str) and (
            "worktree" in payload or "branch" in payload or "id" in payload
        ):
            return payload
        preferred = payload.get("worktree")
        if isinstance(preferred, dict) and isinstance(preferred.get("path"), str):
            return preferred
        for value in payload.values():
            found = _find_worktree(value)
            if found:
                return found
    if isinstance(payload, list):
        for value in payload:
            found = _find_worktree(value)
            if found:
                return found
    return None


def _validated_candidate_branch(root: Path, candidate: Path, runner: Any) -> str:
    if candidate == root:
        raise StudioError("candidate path must be distinct from the Product Owner workspace")
    if not candidate.is_dir():
        raise StudioError(f"candidate path does not exist: {candidate}")
    top_level = _git(candidate, "rev-parse", "--show-toplevel", runner=runner)
    if Path(top_level).resolve() != candidate:
        raise StudioError("candidate path is not the worktree root")
    root_common = Path(_git(root, "rev-parse", "--git-common-dir", runner=runner))
    candidate_common = Path(
        _git(candidate, "rev-parse", "--git-common-dir", runner=runner)
    )
    if not root_common.is_absolute():
        root_common = (root / root_common).resolve()
    if not candidate_common.is_absolute():
        candidate_common = (candidate / candidate_common).resolve()
    if root_common.resolve() != candidate_common.resolve():
        raise StudioError("candidate belongs to a different Git repository")
    branch = _git(
        candidate,
        "symbolic-ref",
        "--quiet",
        "HEAD",
        runner=runner,
        label="candidate branch lookup",
    )
    return branch


def _require_studio_branch(branch: str) -> None:
    if branch in {"refs/heads/main", "refs/heads/master"}:
        raise StudioError("candidate may not use the repository default branch")
    if not (
        branch.startswith("refs/heads/studio-")
        or branch.startswith("refs/heads/studio/")
    ):
        raise StudioError(f"candidate uses an invalid studio branch: {branch}")


def _copy_checkpoint_files(root: Path, candidate: Path, spec: SpecLock) -> list[str]:
    relative_paths = [
        spec.relative_path,
        spec.todo_path,
        "todos/README.md",
        "docs/operations/agent-pipeline-current-state.md",
    ]
    copied: list[str] = []
    for relative in relative_paths:
        source = root / relative
        if not source.is_file():
            raise StudioError(f"checkpoint source is missing: {relative}")
        target = candidate / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, target)
        copied.append(relative)
    return copied


def _update_frontmatter(path: Path, updates: dict[str, Any]) -> dict[str, Any]:
    text = path.read_text(encoding="utf-8")
    parts = text.split("---\n", 2)
    if len(parts) < 3:
        raise StudioError(f"cannot update frontmatter in {path}")
    raw_lines = parts[1].splitlines()
    rendered_updates = {
        key: json.dumps(value, ensure_ascii=False) for key, value in updates.items()
    }
    seen: set[str] = set()
    output: list[str] = []
    for line in raw_lines:
        if ":" not in line or line.startswith(" "):
            output.append(line)
            continue
        key = line.split(":", 1)[0].strip()
        if key in rendered_updates:
            output.append(f"{key}: {rendered_updates[key]}")
            seen.add(key)
        else:
            output.append(line)
    for key, value in rendered_updates.items():
        if key not in seen:
            output.append(f"{key}: {value}")
    path.write_text(
        "---\n" + "\n".join(output) + "\n---\n" + parts[2],
        encoding="utf-8",
    )
    return parse_frontmatter(path.read_text(encoding="utf-8"), path)


def _replace_latest_marker(path: Path, pattern: re.Pattern[str], name: str, payload: dict[str, Any]) -> None:
    text = path.read_text(encoding="utf-8")
    matches = list(pattern.finditer(text))
    marker = f"<!-- {name}\n{json.dumps(payload, ensure_ascii=False, sort_keys=True)}\n-->"
    if matches:
        latest = matches[-1]
        text = text[: latest.start()] + marker + text[latest.end() :]
    else:
        text = text.rstrip() + "\n\n" + marker + "\n"
    path.write_text(text, encoding="utf-8")


def _seed_candidate_state(
    candidate: Path,
    spec: SpecLock,
    *,
    stable_commit: str,
    candidate_ref: str,
    snapshot: Any,
) -> list[str]:
    """Commit the initial repository authority only when the source is a real pipeline todo."""

    todo_path = candidate / spec.todo_path
    text = todo_path.read_text(encoding="utf-8")
    if not PIPELINE_STATE_RE.search(text):
        return []
    heading = f"{datetime.now().astimezone().date().isoformat()} - Producer Async Studio Start"
    studio = {
        "studio_enabled": True,
        "studio_phase": "running",
        "studio_spec_lock": spec.relative_path,
        "studio_stable_ref": STABLE_REF,
        "studio_stable_commit": stable_commit,
        "studio_candidate_ref": candidate_ref,
        "studio_candidate_commit": "",
        "studio_review_due_at": spec.review_due_at.isoformat(),
        "studio_repair_count": 0,
        "studio_blocker": "",
        "studio_demo_bundle": "",
    }
    frontmatter = _update_frontmatter(
        todo_path,
        {
            "owner_lane": "planning",
            "validator_verdict": "not-run",
            "user_gate": "not-requested",
            "routing_reason": "",
            "last_handoff": heading,
            **studio,
        },
    )
    state_marker = {
        key: frontmatter.get(key, "" if key == "routing_reason" else None)
        for key in STATE_KEYS
    }
    state_marker.update(studio)
    appendix = (
        "\n\n"
        + ("## Work Log\n\n" if "## Work Log" not in text else "")
        + f"### {heading}\n\n"
        + "**By:** Producer\n\n"
        + "**상태:** done\n\n"
        + f"- spec lock `{spec.relative_path}`를 잠갔다.\n"
        + f"- stable `{stable_commit}`에서 candidate `{candidate_ref}`를 시작했다.\n"
        + "- 다음 owner lane은 planning audit이다.\n\n"
        + "<!-- pipeline-state\n"
        + json.dumps(state_marker, ensure_ascii=False, sort_keys=True)
        + "\n-->\n"
    )
    todo_path.write_text(todo_path.read_text(encoding="utf-8").rstrip() + appendix, encoding="utf-8")
    queue = {
        "active_slice": spec.slice_id,
        "owner_lane": "planning",
        "last_handoff": heading,
        "artifacts": frontmatter.get("artifacts", []),
        "order": [todo.issue_id for todo in snapshot.slices],
    }
    projection_paths = [
        candidate / "todos/README.md",
        candidate / "docs/operations/agent-pipeline-current-state.md",
    ]
    for projection in projection_paths:
        _replace_latest_marker(projection, PIPELINE_QUEUE_RE, "pipeline-queue", queue)
    inbox_path = candidate / "docs/operations/agent-studio-inbox.md"
    inbox_path.parent.mkdir(parents=True, exist_ok=True)
    inbox_payload = {
        "active_slice": spec.slice_id,
        "studio_phase": "running",
        "studio_blocker": "",
        "studio_demo_bundle": "",
        "studio_stable_ref": STABLE_REF,
        "studio_candidate_ref": candidate_ref,
        "studio_review_due_at": spec.review_due_at.isoformat(),
        "studio_repair_count": 0,
    }
    inbox_path.write_text(
        "# Agent Studio Inbox\n\n"
        "<!-- studio-inbox\n"
        + json.dumps(inbox_payload, ensure_ascii=False, sort_keys=True)
        + "\n-->\n\n"
        "상태: running. stable fallback을 유지하고 현재 planning audit을 기다린다.\n",
        encoding="utf-8",
    )
    return [spec.todo_path, "todos/README.md", "docs/operations/agent-pipeline-current-state.md", "docs/operations/agent-studio-inbox.md"]


def _cleanup_candidate_checkpoint(
    root: Path,
    candidate_path: Path,
    candidate_ref: str,
    worktree: dict[str, Any],
    runner: Any,
) -> None:
    """Remove a safely identified candidate after checkpoint creation fails."""

    selector = f"path:{candidate_path}"
    remove_result = runner.run(
        [
            "orca",
            "worktree",
            "rm",
            "--worktree",
            selector,
            "--force",
            "--json",
        ],
        cwd=root,
    )
    if remove_result.returncode and candidate_path.exists():
        fallback = runner.run(
            [
                "git",
                "-C",
                str(root),
                "worktree",
                "remove",
                "--force",
                str(candidate_path),
            ],
            cwd=None,
        )
        if fallback.returncode and candidate_path.exists():
            detail = _redact(
                remove_result.stderr
                or fallback.stderr
                or "candidate worktree still exists"
            )
            raise StudioError(f"candidate cleanup failed: {detail}")
    delete_ref = runner.run(
        ["git", "-C", str(root), "update-ref", "-d", candidate_ref],
        cwd=None,
    )
    if delete_ref.returncode:
        raise StudioError(
            f"candidate ref cleanup failed: {_redact(delete_ref.stderr or delete_ref.stdout)}"
        )


def _prepare_candidate_checkpoint(
    root: Path,
    candidate_path: Path,
    spec: SpecLock,
    *,
    stable_commit: str,
    candidate_ref: str,
    snapshot: Any,
    dirty_before: tuple[str, ...],
    preview: dict[str, Any],
    worktree: dict[str, Any],
    runner: Any,
) -> dict[str, Any]:
    copied = _copy_checkpoint_files(root, candidate_path, spec)
    if snapshot is not None:
        copied.extend(
            _seed_candidate_state(
                candidate_path,
                spec,
                stable_commit=stable_commit,
                candidate_ref=candidate_ref,
                snapshot=snapshot,
            )
        )
    run_id = preview["candidate_name"]
    report_relative = f"docs/reports/studio/{run_id}-start.md"
    report = candidate_path / report_relative
    report.parent.mkdir(parents=True, exist_ok=True)
    report.write_text(
        "\n".join(
            [
                f"# {spec.slice_id} Async Studio Start Checkpoint",
                "",
                f"- spec lock: `{spec.relative_path}`",
                f"- stable ref: `{STABLE_REF}`",
                f"- stable commit: `{stable_commit}`",
                f"- demo promise: {spec.demo_promise}",
                f"- review due: `{spec.review_due_at.isoformat()}`",
                f"- next owner: `{spec.next_owner}`",
                f"- writer lanes: `{', '.join(spec.writer_lanes)}`",
                "- remote mutation: forbidden",
                "",
            ]
        ),
        encoding="utf-8",
    )
    checkpoint_paths = list(dict.fromkeys(copied + [report_relative]))
    _git(
        candidate_path,
        "add",
        "--",
        *checkpoint_paths,
        runner=runner,
        label="candidate checkpoint stage",
    )
    _git(
        candidate_path,
        "commit",
        "-m",
        f"chore(studio): lock slice {spec.slice_id} run",
        runner=runner,
        label="candidate checkpoint commit",
    )
    candidate_commit = _git(candidate_path, "rev-parse", "HEAD", runner=runner)
    _git(
        root,
        "merge-base",
        "--is-ancestor",
        stable_commit,
        candidate_commit,
        runner=runner,
        label="candidate ancestry check",
    )
    if snapshot is not None:
        validate_pipeline(candidate_path)
    return {
        "status": "candidate-checkpoint-ready",
        "run_id": run_id,
        "slice_id": spec.slice_id,
        "stable_ref": STABLE_REF,
        "stable_commit": stable_commit,
        "candidate_ref": candidate_ref,
        "candidate_commit": candidate_commit,
        "candidate_path": str(candidate_path),
        "worktree_id": worktree.get("id", ""),
        "checkpoint_report": report_relative,
        "dirty_root_paths_preserved": list(dirty_before),
        "coordinator": "pending",
    }


def start_run(
    root: Path,
    spec: SpecLock,
    *,
    confirmed: bool,
    runner: Any | None = None,
    launch_orchestration: bool = True,
) -> dict[str, Any]:
    """Create a local candidate checkpoint after every fail-closed preflight."""

    if not confirmed:
        raise StudioError("start requires explicit --yes confirmation")
    root = root.resolve()
    active_runner = runner or SubprocessRunner()
    stable_commit = _git(
        root,
        "rev-parse",
        "--verify",
        f"{STABLE_REF}^{{commit}}",
        runner=active_runner,
        label="approved ref lookup",
    )
    dirty_before = _check_dirty_overlap(root, spec, active_runner)
    source_text = (root / spec.todo_path).read_text(encoding="utf-8")
    snapshot = None
    if PIPELINE_STATE_RE.search(source_text):
        snapshot = validate_pipeline(root)
        if snapshot.active.issue_id != spec.slice_id:
            raise StudioError("spec lock does not target the canonical active slice")
        if snapshot.next_transition in {
            "product-owner-approval",
            "product-owner-demo-decision",
        }:
            raise StudioError("the active slice still requires a Product Owner decision")
    _orca_available(root, active_runner)
    preview = build_start_preview(root, spec)
    candidate_ref = preview["candidate_ref"]
    ref_probe = active_runner.run(
        ["git", "-C", str(root), "show-ref", "--verify", candidate_ref],
        cwd=None,
    )
    if ref_probe.returncode == 0:
        raise StudioError(
            f"candidate ref already exists: {candidate_ref}; use resume instead of creating a new run"
        )

    create_result = _command(
        active_runner,
        [
            "orca",
            "worktree",
            "create",
            "--repo",
            f"path:{root}",
            "--name",
            preview["candidate_name"],
            "--base-branch",
            STABLE_REF,
            "--no-parent",
            "--setup",
            "skip",
            "--json",
        ],
        cwd=root,
        label="Orca candidate worktree creation",
    )
    create_payload = _read_json_object(
        create_result.stdout, label="Orca worktree creation"
    )
    worktree = _find_worktree(create_payload)
    if not worktree:
        raise StudioError("Orca worktree response did not include a candidate path")
    candidate_path = Path(worktree["path"]).resolve()
    if not candidate_path.is_dir() or candidate_path == root:
        raise StudioError("Orca candidate path is missing or unsafe")
    candidate_branch = _validated_candidate_branch(root, candidate_path, active_runner)
    try:
        _require_studio_branch(candidate_branch)
        if candidate_branch != candidate_ref:
            raise StudioError(
                f"Orca created unexpected candidate ref {candidate_branch}; expected {candidate_ref}"
            )
        result = _prepare_candidate_checkpoint(
            root,
            candidate_path,
            spec,
            stable_commit=stable_commit,
            candidate_ref=candidate_branch,
            snapshot=snapshot,
            dirty_before=dirty_before,
            preview=preview,
            worktree=worktree,
            runner=active_runner,
        )
    except Exception as exc:
        try:
            _cleanup_candidate_checkpoint(
                root,
                candidate_path,
                candidate_ref,
                worktree,
                active_runner,
            )
        except StudioError as cleanup_exc:
            raise StudioError(f"{exc}; {cleanup_exc}") from exc
        raise

    run_id = str(result["run_id"])
    local_record = root / ".studio" / "runs" / run_id / "run.json"
    local_record.parent.mkdir(parents=True, exist_ok=True)
    result["coordinator"] = "pending" if launch_orchestration else "not-launched"
    local_record.write_text(
        json.dumps(result, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    if launch_orchestration:
        try:
            coordinator = launch_coordinator(root, spec, result, runner=active_runner)
        except StudioError as exc:
            result.update(
                {
                    "status": "infrastructure-blocked",
                    "coordinator": "not-confirmed-running",
                    "infrastructure_failures": 1,
                    "last_error": _redact(str(exc)),
                }
            )
            local_record.write_text(
                json.dumps(result, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
                encoding="utf-8",
            )
            raise
        result.update(coordinator)
        result["coordinator"] = "running"
        local_record.write_text(
            json.dumps(result, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
            encoding="utf-8",
        )
    return result


def _candidate_next_role(candidate_path: Path) -> str:
    todo_paths = list((candidate_path / "todos").glob("*.md"))
    if not any(
        PIPELINE_STATE_RE.search(path.read_text(encoding="utf-8"))
        for path in todo_paths
        if path.is_file()
    ):
        return "planning"
    snapshot = validate_pipeline(candidate_path)
    transition_roles = {
        "planner-handoff": "planning",
        "dev-handoff": "dev",
        "asset-handoff": "asset",
        "validator-handoff": "validation",
        "validator-verdict": "validation",
        "producer-decision": "producer",
    }
    if snapshot.next_transition in {
        "product-owner-approval",
        "product-owner-demo-decision",
    }:
        raise StudioError("candidate is waiting for a Product Owner decision, not another worker")
    next_role = transition_roles.get(snapshot.next_transition)
    if not next_role:
        raise StudioError(
            f"candidate has no resumable role for transition {snapshot.next_transition}"
        )
    return next_role


def build_coordinator_request(spec: SpecLock, run_state: dict[str, Any]) -> dict[str, Any]:
    """Build one bounded serial coordinator request from repository authority."""

    candidate_path = str(run_state.get("candidate_path", ""))
    candidate_ref = str(run_state.get("candidate_ref", ""))
    if not candidate_path or not candidate_ref:
        raise StudioError("run state is missing candidate identity")
    candidate = Path(candidate_path).resolve()
    if not candidate.is_dir():
        raise StudioError("candidate worktree is missing")
    next_role = _candidate_next_role(candidate)
    sequence = {
        "planning": "Start with Planner audit, then the declared writer lanes, a fresh Validator, and Producer bundle.",
        "dev": "Resume with Developer, then a fresh Validator and Producer bundle.",
        "asset": "Resume with Asset, then a fresh Validator and Producer bundle.",
        "validation": "Resume with a fresh Validator, then Producer bundle if validation passes.",
        "producer": "Resume with Producer bundle assembly; do not reopen completed writer or Validator lanes.",
    }[next_role]
    coordinator_spec = "\n".join(
        [
            "Bro-exile spec-locked async studio coordinator.",
            f"Active slice: {spec.slice_id}.",
            f"Candidate ref: {candidate_ref}.",
            f"Spec lock: {spec.relative_path}.",
            f"Repository-authoritative next role: {next_role}.",
            f"Run roles serially with max concurrency 1. {sequence}",
            "On resume, do not replay any role whose committed handoff is already reflected in the "
            "latest pipeline-state marker.",
            "The repository todo and latest committed pipeline-state marker are authority. "
            "A terminal exit or Orca message alone never completes a lane.",
            "Each lane must commit its Work Log handoff and cited artifacts before worker_done. "
            "Stop on product decisions, spec contradictions, deadline, exhausted repair budget, "
            "runtime asset promotion, remote push, main merge, or public release.",
            f"Demo promise: {spec.demo_promise}",
            f"Play lens: {spec.play_lens}",
        ]
    )
    return {
        "spec": coordinator_spec,
        "worktree": f"path:{candidate_path}",
        "max_concurrent": 1,
        "next_role": next_role,
    }


def _find_value(payload: Any, keys: tuple[str, ...]) -> str | None:
    if isinstance(payload, dict):
        for key in keys:
            value = payload.get(key)
            if isinstance(value, str) and value:
                return value
        for value in payload.values():
            found = _find_value(value, keys)
            if found:
                return found
    if isinstance(payload, list):
        for value in payload:
            found = _find_value(value, keys)
            if found:
                return found
    return None


def launch_coordinator(
    root: Path,
    spec: SpecLock,
    run_state: dict[str, Any],
    *,
    runner: Any | None = None,
) -> dict[str, Any]:
    active_runner = runner or SubprocessRunner()
    _orca_available(root.resolve(), active_runner)
    request = build_coordinator_request(spec, run_state)
    result = _command(
        active_runner,
        [
            "orca",
            "orchestration",
            "run",
            "--spec",
            request["spec"],
            "--max-concurrent",
            "1",
            "--worktree",
            request["worktree"],
            "--json",
        ],
        cwd=root.resolve(),
        label="Orca serial coordinator launch",
    )
    payload = _read_json_object(result.stdout, label="Orca coordinator")
    run_id = _find_value(payload, ("runId", "run_id", "id"))
    if not run_id:
        raise StudioError("Orca coordinator response did not include a run id")
    return {
        "orca_run_id": run_id,
        "max_concurrency": 1,
        "next_role": request["next_role"],
    }


def validate_role_completion(
    root: Path,
    run_state: dict[str, Any],
    completion: RoleCompletion,
    *,
    runner: Any | None = None,
) -> dict[str, Any]:
    """Accept completion only from the active dispatch and a committed handoff."""

    if (
        completion.task_id != run_state.get("active_task_id")
        or completion.dispatch_id != run_state.get("active_dispatch_id")
    ):
        raise StudioError("stale completion provenance does not match the active task/dispatch")
    if completion.role != run_state.get("active_role"):
        raise StudioError("completion role does not match the active repository lane")
    if completion.terminal != run_state.get("active_terminal"):
        raise StudioError("completion terminal does not own the active dispatch")
    if completion.role == "validation" and completion.terminal == run_state.get("writer_terminal"):
        raise StudioError("Validator must use a fresh terminal instead of the writer terminal")
    if not completion.handoff_path or not completion.artifacts:
        raise StudioError("completion requires one handoff path and committed artifacts")

    active_runner = runner or SubprocessRunner()
    candidate = Path(str(run_state.get("candidate_path", ""))).resolve()
    if not candidate.is_dir():
        raise StudioError("candidate worktree is missing")
    head = _git(candidate, "rev-parse", "HEAD", runner=active_runner)
    if head != completion.commit:
        raise StudioError("completion commit is not the candidate branch tip")
    dirty = _git(
        candidate,
        "status",
        "--porcelain=v1",
        runner=active_runner,
        strip=False,
    )
    if dirty:
        raise StudioError("completion has uncommitted candidate changes")
    evidence_paths = (completion.handoff_path,) + completion.artifacts
    for path in dict.fromkeys(evidence_paths):
        _repo_path(candidate, path, field="completion evidence")
        _git(
            candidate,
            "cat-file",
            "-e",
            f"{completion.commit}:{path}",
            runner=active_runner,
            label="completion evidence lookup",
        )
    changed = set(
        _git(
            candidate,
            "diff-tree",
            "--root",
            "--no-commit-id",
            "--name-only",
            "-r",
            completion.commit,
            runner=active_runner,
        ).splitlines()
    )
    if completion.handoff_path not in changed:
        raise StudioError("completion commit does not contain the declared handoff change")
    return {
        "accepted": True,
        "role": completion.role,
        "commit": completion.commit,
        "artifacts": list(completion.artifacts),
    }


def plan_recovery(
    *,
    routing_reason: str,
    repair_count: int,
    review_due_at: datetime,
    now: datetime | None = None,
) -> dict[str, Any]:
    """Choose retry or one-question blocker without mutating repository state."""

    current = now or datetime.now().astimezone()
    if current.tzinfo is None or review_due_at.tzinfo is None:
        raise StudioError("recovery timestamps must include timezone")
    if not isinstance(repair_count, int) or isinstance(repair_count, bool) or repair_count < 0:
        raise StudioError("repair_count must be a non-negative integer")
    if current.astimezone(timezone.utc) >= review_due_at.astimezone(timezone.utc):
        return {
            "status": "blocked",
            "reason": "review-deadline-expired",
            "repair_count": repair_count,
            "dispatch_allowed": False,
            "questions": ["다음 PD 세션을 언제로 다시 잠글까요?"],
        }
    if routing_reason == "design":
        return {
            "status": "blocked",
            "reason": "product-decision-required",
            "repair_count": repair_count,
            "dispatch_allowed": False,
            "questions": ["현재 증거를 기준으로 어떤 제품 방향을 잠글까요?"],
        }
    if routing_reason not in {"code", "asset"}:
        raise StudioError("routing_reason must be code, asset, or design")
    if repair_count >= 2:
        return {
            "status": "blocked",
            "reason": "repair-budget-exhausted",
            "repair_count": repair_count,
            "dispatch_allowed": False,
            "questions": ["안정 빌드를 유지하고 이 candidate를 조정할까요, 중단할까요?"],
        }
    return {
        "status": "repair",
        "reason": routing_reason,
        "repair_count": repair_count + 1,
        "dispatch_allowed": True,
        "next_role": "dev" if routing_reason == "code" else "asset",
        "questions": [],
    }


def load_demo_bundle(root: Path, bundle_path: Path, spec: SpecLock) -> DemoBundle:
    """Validate a durable demo bundle and its local Git evidence."""

    root = root.resolve()
    path = bundle_path if bundle_path.is_absolute() else root / bundle_path
    path = path.resolve()
    if not _inside(root, path) or not path.is_file():
        raise StudioError("demo bundle must be a file inside the candidate worktree")
    relative = path.relative_to(root).as_posix()
    text = path.read_text(encoding="utf-8")
    try:
        data = parse_frontmatter(text, path)
    except ValidationError as exc:
        raise StudioError(str(exc)) from exc
    if data.get("studio_demo_bundle") is not True:
        raise StudioError("studio_demo_bundle must be true")
    for heading in ("Launch", "Change Summary", "Validation", "Play Lens"):
        if f"## {heading}" not in text:
            raise StudioError(f"demo bundle is missing section: {heading}")
    slice_id = _one_line(data, "slice_id")
    if slice_id != spec.slice_id:
        raise StudioError("demo bundle slice does not match spec lock")
    spec_lock = _one_line(data, "spec_lock")
    if spec_lock != spec.relative_path:
        raise StudioError("demo bundle references a different spec lock")
    stable_commit = _one_line(data, "stable_commit")
    candidate_commit = _one_line(data, "candidate_commit")
    if not re.fullmatch(r"[0-9a-fA-F]{7,40}", stable_commit) or not re.fullmatch(
        r"[0-9a-fA-F]{7,40}", candidate_commit
    ):
        raise StudioError("demo bundle commits must be immutable Git commit ids")
    validation_status = _one_line(data, "validation_status")
    if validation_status not in {"passed", "blocked"}:
        raise StudioError("validation_status must be passed or blocked")
    change_summary = _one_line(data, "change_summary")
    evidence = _string_list(data, "validation_evidence")
    deviations = _string_list(data, "deviations", allow_empty=True)
    variants = _string_list(data, "variants")
    if len(variants) > 2:
        raise StudioError("demo bundle allows at most two variants")
    play_lens = _one_line(data, "play_lens")
    if play_lens != spec.play_lens:
        raise StudioError("demo bundle play lens drifted from the spec lock")
    blocker_question = data.get("blocker_question", "")
    if not isinstance(blocker_question, str) or "\n" in blocker_question.strip():
        raise StudioError("blocker_question must be empty or one line")
    if validation_status == "blocked" and not blocker_question.strip():
        raise StudioError("blocked bundle requires one blocker question")
    visual_change = data.get("visual_change")
    if not isinstance(visual_change, bool):
        raise StudioError("visual_change must be true or false")
    visual_evidence = _string_list(data, "visual_evidence", allow_empty=True)
    if visual_change and not visual_evidence:
        raise StudioError("visual changes require actual capture and pixel-perfect visual evidence")
    launch_scene = _one_line(data, "launch_scene")
    if not launch_scene.endswith(".tscn"):
        raise StudioError("launch_scene must be a Godot .tscn repository path")
    _, launch_path = _repo_path(root, launch_scene, field="launch_scene")
    if not launch_path.is_file():
        raise StudioError(f"launch_scene is missing: {launch_scene}")

    for evidence_path in evidence + visual_evidence:
        _, resolved = _repo_path(root, evidence_path, field="bundle evidence")
        if not resolved.exists():
            raise StudioError(f"bundle evidence is missing: {evidence_path}")
    runner = SubprocessRunner()
    stable_tip = _git(root, "rev-parse", "--verify", f"{STABLE_REF}^{{commit}}", runner=runner)
    if stable_tip != stable_commit:
        raise StudioError("bundle stable commit no longer matches the approved ref")
    _git(
        root,
        "cat-file",
        "-e",
        f"{candidate_commit}^{{commit}}",
        runner=runner,
        label="bundle candidate lookup",
    )
    _git(
        root,
        "merge-base",
        "--is-ancestor",
        stable_commit,
        candidate_commit,
        runner=runner,
        label="bundle ancestry check",
    )
    return DemoBundle(
        path=path,
        relative_path=relative,
        slice_id=slice_id,
        spec_lock=spec_lock,
        stable_commit=stable_commit,
        candidate_commit=candidate_commit,
        validation_status=validation_status,
        change_summary=change_summary,
        validation_evidence=evidence,
        deviations=deviations,
        variants=variants,
        play_lens=play_lens,
        blocker_question=blocker_question.strip(),
        visual_change=visual_change,
        visual_evidence=visual_evidence,
        launch_scene=launch_scene,
    )


def _append_pipeline_handoff(
    todo_path: Path,
    *,
    heading: str,
    updates: dict[str, Any],
    actions: tuple[str, ...],
) -> dict[str, Any]:
    before = todo_path.read_text(encoding="utf-8")
    frontmatter = _update_frontmatter(todo_path, {**updates, "last_handoff": heading})
    marker = {
        key: frontmatter.get(key, "" if key == "routing_reason" else None)
        for key in STATE_KEYS
    }
    if frontmatter.get("studio_enabled") is True:
        marker.update(
            {
                key: frontmatter.get(key, default)
                for key, default in STUDIO_STATE_DEFAULTS.items()
            }
        )
    body = todo_path.read_text(encoding="utf-8").rstrip()
    if "## Work Log" not in before:
        body += "\n\n## Work Log"
    body += (
        f"\n\n### {heading}\n\n"
        "**By:** Producer\n\n"
        "**상태:** done\n\n"
        "**Actions:**\n\n"
        + "\n".join(f"- {action}" for action in actions)
        + "\n\n<!-- pipeline-state\n"
        + json.dumps(marker, ensure_ascii=False, sort_keys=True)
        + "\n-->\n"
    )
    todo_path.write_text(body, encoding="utf-8")
    return frontmatter


def _apply_repository_decision(
    candidate: Path,
    bundle: DemoBundle,
    decision: str,
    *,
    candidate_ref: str,
) -> tuple[list[str], str]:
    """Write canonical todo/projection state before a local ref decision."""

    snapshot = validate_pipeline(candidate)
    if snapshot.active.issue_id != bundle.slice_id:
        raise StudioError("demo decision does not target the canonical active slice")
    active = snapshot.active
    if active.state.get("studio_phase") != "demo-ready":
        raise StudioError("canonical studio state must be demo-ready before a decision")
    if active.state.get("studio_demo_bundle") != bundle.relative_path:
        raise StudioError("canonical studio state points to a different demo bundle")
    today = datetime.now().astimezone().date().isoformat()
    heading = f"{today} - Product Owner Studio {decision.title()}"
    common_studio = {
        "studio_enabled": True,
        "studio_spec_lock": bundle.spec_lock,
        "studio_stable_ref": STABLE_REF,
        "studio_stable_commit": "",
        "studio_candidate_ref": candidate_ref,
        "studio_candidate_commit": "",
        "studio_blocker": "",
        "studio_demo_bundle": bundle.relative_path,
    }
    changed = [active.path.relative_to(candidate).as_posix()]
    if decision == "keep":
        _append_pipeline_handoff(
            active.path,
            heading=heading,
            updates={
                "status": "complete",
                "owner_lane": "producer",
                "validator_verdict": "passed",
                "user_gate": "approved",
                "routing_reason": "",
                "studio_phase": "kept",
                **common_studio,
            },
            actions=(
                "검증된 candidate를 keep으로 승인했다.",
                "local approved ref 갱신은 이 checkpoint commit 뒤 compare-and-swap한다.",
            ),
        )
        later = [todo for todo in snapshot.slices if todo.queue_order > active.queue_order]
        if not later:
            raise StudioError("keep requires a queued next slice to preserve one-ready invariant")
        next_todo = later[0]
        next_heading = f"{today} - Producer Activation Handoff"
        next_frontmatter = _append_pipeline_handoff(
            next_todo.path,
            heading=next_heading,
            updates={
                "status": "ready",
                "owner_lane": "planning",
                "validator_verdict": "not-run",
                "user_gate": "not-requested",
                "routing_reason": "",
            },
            actions=(
                f"이전 slice {active.issue_id} keep 뒤 다음 queue slice를 활성화했다.",
                "다음 owner lane은 planning이다.",
            ),
        )
        changed.append(next_todo.path.relative_to(candidate).as_posix())
        projection_active = next_todo
        projection_frontmatter = next_frontmatter
        next_action = "lock-next-spec"
    else:
        phase = "adjusting" if decision == "adjust" else "archived"
        active_frontmatter = _append_pipeline_handoff(
            active.path,
            heading=heading,
            updates={
                "status": "ready",
                "owner_lane": "planning",
                "validator_verdict": "passed",
                "user_gate": "changes-requested",
                "routing_reason": "",
                "studio_phase": phase,
                **common_studio,
            },
            actions=(
                f"candidate를 {decision}으로 판정했다.",
                "stable ref와 candidate evidence는 보존한다.",
            ),
        )
        projection_active = active
        projection_frontmatter = active_frontmatter
        next_action = "relock-same-promise" if decision == "adjust" else "launch-stable"
    queue = {
        "active_slice": projection_active.issue_id,
        "owner_lane": projection_frontmatter["owner_lane"],
        "last_handoff": projection_frontmatter["last_handoff"],
        "artifacts": projection_frontmatter["artifacts"],
        "order": [todo.issue_id for todo in snapshot.slices],
    }
    for relative in (
        "todos/README.md",
        "docs/operations/agent-pipeline-current-state.md",
    ):
        _replace_latest_marker(candidate / relative, PIPELINE_QUEUE_RE, "pipeline-queue", queue)
        changed.append(relative)
    inbox_path = candidate / "docs/operations/agent-studio-inbox.md"
    inbox = {
        "active_slice": projection_active.issue_id,
        "studio_phase": "inactive" if decision == "keep" else phase,
        "studio_blocker": "",
        "studio_demo_bundle": bundle.relative_path,
        "studio_stable_ref": STABLE_REF,
        "studio_candidate_ref": candidate_ref,
        "studio_review_due_at": "" if decision == "keep" else active.state["studio_review_due_at"],
        "studio_repair_count": active.state.get("studio_repair_count", 0),
    }
    _replace_latest_marker(
        inbox_path,
        re.compile(r"<!--\s*studio-inbox\s*\n(?P<payload>.*?)\n-->", re.DOTALL),
        "studio-inbox",
        inbox,
    )
    changed.append("docs/operations/agent-studio-inbox.md")
    return list(dict.fromkeys(changed)), next_action


def apply_demo_decision(
    root: Path,
    bundle: DemoBundle,
    *,
    decision: str,
    confirmed: bool,
    candidate_path: Path,
    runner: Any | None = None,
) -> dict[str, Any]:
    """Apply a local-only, idempotent keep/adjust/cut decision."""

    if not confirmed:
        raise StudioError("demo decision requires explicit --yes confirmation")
    if decision not in {"keep", "adjust", "cut"}:
        raise StudioError("decision must be keep, adjust, or cut")
    if decision == "keep" and bundle.validation_status != "passed":
        raise StudioError("keep requires a passed validation bundle")
    root = root.resolve()
    candidate = candidate_path.resolve()
    active_runner = runner or SubprocessRunner()
    bundle_digest = hashlib.sha256(bundle.path.read_bytes()).hexdigest()[:12]
    record = root / ".studio" / "decisions" / f"{bundle.slice_id}-{bundle_digest}.json"
    if record.is_file():
        existing = _read_json_object(
            record.read_text(encoding="utf-8"), label="studio decision record"
        )
        if existing.get("decision") != decision:
            raise StudioError("this demo bundle already has a different Product Owner decision")
        if existing.get("status") == "pending-ref-update":
            if decision != "keep":
                raise StudioError("only keep may have a pending approved-ref update")
            if not candidate.is_dir():
                raise StudioError("candidate worktree is missing during keep recovery")
            _require_studio_branch(
                _validated_candidate_branch(root, candidate, active_runner)
            )
            candidate_tip = _git(candidate, "rev-parse", "HEAD", runner=active_runner)
            if candidate_tip != existing.get("candidate_commit"):
                raise StudioError("candidate changed during pending keep recovery")
            stable_tip = _git(root, "rev-parse", STABLE_REF, runner=active_runner)
            stable_before = str(existing.get("stable_before", ""))
            if stable_tip == stable_before:
                _git(
                    root,
                    "update-ref",
                    STABLE_REF,
                    candidate_tip,
                    stable_before,
                    runner=active_runner,
                    label="resume keep approved ref update",
                )
            elif stable_tip != candidate_tip:
                raise StudioError("approved ref diverged during pending keep recovery")
            existing["status"] = "complete"
            existing["stable_after"] = candidate_tip
            record.write_text(
                json.dumps(existing, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
                encoding="utf-8",
            )
        return existing
    if not candidate.is_dir():
        raise StudioError("candidate worktree is missing; stable fallback remains available")
    candidate_ref = _validated_candidate_branch(root, candidate, active_runner)
    _require_studio_branch(candidate_ref)
    dirty = _git(
        candidate,
        "status",
        "--porcelain=v1",
        runner=active_runner,
        strip=False,
    )
    if dirty:
        raise StudioError("candidate must be clean before a Product Owner decision")
    candidate_tip = _git(candidate, "rev-parse", "HEAD", runner=active_runner)
    stable_tip = _git(root, "rev-parse", STABLE_REF, runner=active_runner)
    if stable_tip != bundle.stable_commit:
        raise StudioError("approved ref changed after the bundle was produced")
    _git(
        candidate,
        "merge-base",
        "--is-ancestor",
        bundle.candidate_commit,
        candidate_tip,
        runner=active_runner,
        label="decision candidate ancestry check",
    )
    matching_todos = list((candidate / "todos").glob(f"{bundle.slice_id}-*.md"))
    has_pipeline_state = any(
        PIPELINE_STATE_RE.search(path.read_text(encoding="utf-8"))
        for path in matching_todos
    )
    next_action = "lock-next-spec" if decision == "keep" else (
        "relock-same-promise" if decision == "adjust" else "launch-stable"
    )
    decision_paths: list[str] = []
    if has_pipeline_state:
        decision_paths, next_action = _apply_repository_decision(
            candidate,
            bundle,
            decision,
            candidate_ref=candidate_ref,
        )
    decision_report = f"docs/reports/studio/{bundle.slice_id}-decision-{decision}.md"
    decision_report_path = candidate / decision_report
    decision_report_path.parent.mkdir(parents=True, exist_ok=True)
    decision_report_path.write_text(
        f"# {bundle.slice_id} Studio Decision: {decision}\n\n"
        f"- bundle: `{bundle.relative_path}`\n"
        f"- stable before: `{stable_tip}`\n"
        f"- candidate ref: `{candidate_ref}`\n"
        f"- remote mutation: `false`\n",
        encoding="utf-8",
    )
    decision_paths.append(decision_report)
    _git(
        candidate,
        "add",
        "--",
        *list(dict.fromkeys(decision_paths)),
        runner=active_runner,
        label="decision checkpoint stage",
    )
    _git(
        candidate,
        "commit",
        "-m",
        f"chore(studio): record {decision} decision for {bundle.slice_id}",
        runner=active_runner,
        label="decision checkpoint commit",
    )
    candidate_tip = _git(candidate, "rev-parse", "HEAD", runner=active_runner)
    if has_pipeline_state:
        validate_pipeline(candidate)
    result = {
        "status": "pending-ref-update" if decision == "keep" else "complete",
        "decision": decision,
        "slice_id": bundle.slice_id,
        "bundle": str(bundle.path),
        "stable_before": stable_tip,
        "stable_after": stable_tip,
        "candidate_ref_preserved": candidate_ref,
        "candidate_commit": candidate_tip,
        "next_action": next_action,
        "remote_mutation": False,
    }
    record.parent.mkdir(parents=True, exist_ok=True)
    record.write_text(
        json.dumps(result, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    if decision == "keep":
        _git(
            root,
            "update-ref",
            STABLE_REF,
            candidate_tip,
            stable_tip,
            runner=active_runner,
            label="keep approved ref update",
        )
        result["status"] = "complete"
        result["stable_after"] = candidate_tip
        record.write_text(
            json.dumps(result, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
            encoding="utf-8",
        )
    return result


def resume_run(
    root: Path,
    run_record: Path,
    spec: SpecLock,
    *,
    confirmed: bool,
    now: datetime | None = None,
    runner: Any | None = None,
) -> dict[str, Any]:
    """Resume only the latest incomplete candidate lane."""

    if not confirmed:
        raise StudioError("resume requires explicit --yes confirmation")
    root = root.resolve()
    record_path = run_record if run_record.is_absolute() else root / run_record
    record_path = record_path.resolve()
    if not _inside(root, record_path) or not record_path.is_file():
        raise StudioError("run record must exist under the repository .studio directory")
    if ".studio" not in record_path.relative_to(root).parts:
        raise StudioError("run record must live under .studio/")
    state = _read_json_object(
        record_path.read_text(encoding="utf-8"), label="studio run record"
    )
    if state.get("slice_id") != spec.slice_id:
        raise StudioError("run record and spec lock slice do not match")
    current = now or datetime.now().astimezone()
    if current.astimezone(timezone.utc) >= spec.review_due_at.astimezone(timezone.utc):
        return {
            **state,
            "status": "blocked",
            "blocker_reason": "review-deadline-expired",
            "blocker_question": "다음 PD 세션을 언제로 다시 잠글까요?",
            "coordinator": "stopped",
        }
    failures = state.get("infrastructure_failures", 0)
    if not isinstance(failures, int) or failures < 0:
        raise StudioError("invalid infrastructure failure count")
    if failures >= 3:
        return {
            **state,
            "status": "blocked",
            "blocker_reason": "infrastructure-circuit-breaker",
            "blocker_question": "Orca 실행 환경을 복구한 뒤 같은 candidate를 재개할까요?",
            "coordinator": "stopped",
        }
    candidate = Path(str(state.get("candidate_path", ""))).resolve()
    if not candidate.is_dir():
        raise StudioError("candidate worktree is missing; use the stable fallback")
    active_runner = runner or SubprocessRunner()
    head = _git(candidate, "rev-parse", "HEAD", runner=active_runner)
    previous = str(state.get("candidate_commit", ""))
    if previous:
        _git(
            candidate,
            "merge-base",
            "--is-ancestor",
            previous,
            head,
            runner=active_runner,
            label="resume checkpoint ancestry",
        )
    state["candidate_commit"] = head
    state.update(launch_coordinator(root, spec, state, runner=active_runner))
    state["coordinator"] = "running"
    state["status"] = "resumed"
    record_path.write_text(
        json.dumps(state, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    return state


def _marker_transition(state: dict[str, Any]) -> str:
    if state.get("user_gate") == "changes-requested":
        return "planner-handoff"
    if state.get("validator_verdict") == "passed":
        return "product-owner-approval"
    if state.get("validator_verdict") in {"rejected", "conditional-pass"}:
        return f"{state.get('owner_lane', '')}-handoff"
    return {
        "planning": "planner-handoff",
        "dev": "validator-handoff",
        "asset": "validator-handoff",
        "validation": "validator-verdict",
        "producer": "producer-decision",
    }.get(str(state.get("owner_lane", "")), "invalid")


def shadow_replay(root: Path, history_path: Path | None = None) -> dict[str, Any]:
    """Read-only replay of committed Work Log markers and current transition."""

    root = root.resolve()
    snapshot = validate_pipeline(root)
    target = snapshot.active.path
    if history_path is not None:
        target = history_path if history_path.is_absolute() else root / history_path
        target = target.resolve()
        if not _inside(root, target) or not target.is_file():
            raise StudioError("shadow history path must be a todo inside the repository")
    text = target.read_text(encoding="utf-8")
    target_data = parse_frontmatter(text, target)
    history: list[dict[str, Any]] = []
    for match in PIPELINE_STATE_RE.finditer(text):
        try:
            state = json.loads(match.group("payload"))
        except json.JSONDecodeError as exc:
            raise StudioError("active todo contains invalid historical pipeline marker") from exc
        if isinstance(state, dict):
            history.append(
                {
                    "owner_lane": state.get("owner_lane", ""),
                    "validator_verdict": state.get("validator_verdict", ""),
                    "user_gate": state.get("user_gate", ""),
                    "transition": _marker_transition(state),
                }
            )
    return {
        "mode": "shadow",
        "mutates_state": False,
        "active_slice": snapshot.active.issue_id,
        "replay_slice": str(target_data.get("issue_id", "")),
        "history_count": len(history),
        "history": history,
        "current_transition": snapshot.next_transition,
        "stable_ref_created": False,
        "candidate_created": False,
        "orca_task_created": False,
    }


def _parse_now(raw: str | None) -> datetime | None:
    if raw is None:
        return None
    try:
        value = datetime.fromisoformat(raw)
    except ValueError as exc:
        raise StudioError("--now must be an ISO 8601 timestamp") from exc
    if value.tzinfo is None:
        raise StudioError("--now must include a timezone")
    return value


def _print(payload: dict[str, Any], as_json: bool) -> None:
    if as_json:
        print(json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=True))
        return
    for key, value in payload.items():
        print(f"{key}={value}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--root",
        type=Path,
        default=Path(__file__).resolve().parents[2],
        help="Repository root.",
    )
    parser.add_argument("--json", action="store_true", help="Print machine-readable JSON.")
    subparsers = parser.add_subparsers(dest="command", required=True)
    for name in ("spec-check", "preview"):
        sub = subparsers.add_parser(name)
        sub.add_argument("--spec", type=Path, required=True)
        sub.add_argument("--now")
    subparsers.add_parser("status")
    bootstrap = subparsers.add_parser("bootstrap")
    bootstrap.add_argument("--commit", required=True)
    bootstrap.add_argument("--yes", action="store_true")
    start = subparsers.add_parser("start")
    start.add_argument("--spec", type=Path, required=True)
    start.add_argument("--now")
    start.add_argument("--yes", action="store_true")
    start.add_argument("--no-coordinator", action="store_true")
    resume = subparsers.add_parser("resume")
    resume.add_argument("--run-record", type=Path, required=True)
    resume.add_argument("--spec", type=Path, required=True)
    resume.add_argument("--now")
    resume.add_argument("--yes", action="store_true")
    bundle_check = subparsers.add_parser("bundle-check")
    bundle_check.add_argument("--candidate-path", type=Path, required=True)
    bundle_check.add_argument("--spec", type=Path, required=True)
    bundle_check.add_argument("--bundle", type=Path, required=True)
    decision = subparsers.add_parser("decision")
    decision.add_argument("--candidate-path", type=Path, required=True)
    decision.add_argument("--spec", type=Path, required=True)
    decision.add_argument("--bundle", type=Path, required=True)
    decision.add_argument("--decision", choices=("keep", "adjust", "cut"), required=True)
    decision.add_argument("--yes", action="store_true")
    shadow = subparsers.add_parser("shadow")
    shadow.add_argument("--history", type=Path)
    args = parser.parse_args()
    try:
        root = args.root.resolve()
        if args.command == "status":
            snapshot = validate_pipeline(root)
            payload = {
                "active_slice": snapshot.active.issue_id,
                "owner_lane": snapshot.active.state["owner_lane"],
                "next_transition": snapshot.next_transition,
                "studio_enabled": bool(snapshot.active.state.get("studio_enabled")),
            }
        elif args.command == "bootstrap":
            commit = bootstrap_stable_ref(root, args.commit, confirmed=args.yes)
            payload = {"bootstrapped": True, "stable_ref": STABLE_REF, "commit": commit}
        elif args.command == "shadow":
            payload = shadow_replay(root, args.history)
        elif args.command in {"bundle-check", "decision"}:
            candidate = args.candidate_path.resolve()
            candidate_spec = load_spec_lock(candidate, args.spec)
            bundle = load_demo_bundle(candidate, args.bundle, candidate_spec)
            if args.command == "bundle-check":
                payload = {
                    "valid": True,
                    "slice_id": bundle.slice_id,
                    "validation_status": bundle.validation_status,
                    "variants": list(bundle.variants),
                    "play_lens": bundle.play_lens,
                }
            else:
                payload = apply_demo_decision(
                    root,
                    bundle,
                    decision=args.decision,
                    confirmed=args.yes,
                    candidate_path=candidate,
                )
        elif args.command == "resume":
            record_path = args.run_record if args.run_record.is_absolute() else root / args.run_record
            state = _read_json_object(
                record_path.read_text(encoding="utf-8"), label="studio run record"
            )
            candidate = Path(str(state.get("candidate_path", "")))
            spec = load_spec_lock(candidate, args.spec, now=_parse_now(args.now))
            payload = resume_run(
                root,
                args.run_record,
                spec,
                confirmed=args.yes,
                now=_parse_now(args.now),
            )
        else:
            spec = load_spec_lock(root, args.spec, now=_parse_now(args.now))
            if args.command == "start":
                payload = start_run(
                    root,
                    spec,
                    confirmed=args.yes,
                    launch_orchestration=not args.no_coordinator,
                )
            else:
                payload = build_start_preview(root, spec)
            if args.command == "spec-check":
                payload = {
                    "valid": True,
                    "slice_id": spec.slice_id,
                    "demo_promise": spec.demo_promise,
                    "review_due_at": spec.review_due_at.isoformat(),
                    "play_lens": spec.play_lens,
                }
    except (OSError, StudioError, ValidationError) as exc:
        print(f"STUDIO INVALID: {exc}", file=sys.stderr)
        return 1
    _print(payload, args.json)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
