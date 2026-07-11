#!/usr/bin/env python3
"""Validate the resumable Bro-exile public-demo agent pipeline.

The canonical state lives in slice todo frontmatter.  The latest structured
``pipeline-state`` marker in each todo's append-only Work Log is evidence of
the handoff that produced that state.  Queue/current-state documents are
projections and may never override or drift from the canonical records.
"""

from __future__ import annotations

import argparse
from dataclasses import dataclass
import json
from pathlib import Path
import re
import sys
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
PIPELINE_STATE_RE = re.compile(
    r"<!--\s*pipeline-state\s*\n(?P<payload>.*?)\n-->", re.DOTALL
)
PIPELINE_QUEUE_RE = re.compile(
    r"<!--\s*pipeline-queue\s*\n(?P<payload>.*?)\n-->", re.DOTALL
)


class ValidationError(Exception):
    """A user-actionable pipeline consistency failure."""


@dataclass(frozen=True)
class SliceTodo:
    path: Path
    issue_id: str
    queue_order: int
    state: dict[str, Any]
    last_handoff: str


def _scalar(value: str) -> Any:
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


def _parse_frontmatter(text: str, path: Path) -> dict[str, Any]:
    if not text.startswith("---\n"):
        raise ValidationError(f"{path}: missing frontmatter")
    try:
        raw = text.split("---\n", 2)[1]
    except IndexError as exc:
        raise ValidationError(f"{path}: unterminated frontmatter") from exc

    result: dict[str, Any] = {}
    active_list: str | None = None
    for line in raw.splitlines():
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        if line.startswith("  - ") and active_list:
            result[active_list].append(_scalar(line[4:]))
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
            result[key] = _scalar(raw_value)
    return result


def _read_json_marker(text: str, pattern: re.Pattern[str], path: Path) -> dict[str, Any]:
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


def _load_slice(path: Path) -> SliceTodo | None:
    text = path.read_text(encoding="utf-8")
    frontmatter = _parse_frontmatter(text, path)
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

    evidence = _read_json_marker(text, PIPELINE_STATE_RE, path)
    state = {key: frontmatter.get(key, "" if key == "routing_reason" else None) for key in STATE_KEYS}
    evidence_state = {key: evidence.get(key, "" if key == "routing_reason" else None) for key in STATE_KEYS}
    if state != evidence_state:
        raise ValidationError(
            f"{path}: frontmatter/work-log mismatch: frontmatter={state!r} work_log={evidence_state!r}"
        )

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
        queue_order=queue_order,
        state=state,
        last_handoff=last_handoff,
    )


def _validate_state(todo: SliceTodo) -> None:
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

    status = state["status"]
    verdict = state["validator_verdict"]
    gate = state["user_gate"]
    owner = state["owner_lane"]
    routing_reason = state["routing_reason"]

    if verdict == "passed" and status != "complete":
        if gate != "awaiting-user-approval" or owner != "producer":
            raise ValidationError(
                f"{todo.path}: passed requires owner_lane=producer and "
                "user_gate=awaiting-user-approval until approval"
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
            raise ValidationError(
                f"{todo.path}: rejected requires routing_reason=code|asset|design"
            )
        if owner != expected:
            raise ValidationError(
                f"{todo.path}: rejected routing_reason={routing_reason} requires owner_lane={expected}"
            )
    elif routing_reason:
        raise ValidationError(f"{todo.path}: routing_reason is only valid for rejected verdicts")


def _next_transition(active: SliceTodo) -> str:
    state = active.state
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


def validate(root: Path) -> tuple[SliceTodo, str]:
    todo_dir = root / "todos"
    if not todo_dir.is_dir():
        raise ValidationError(f"{todo_dir}: todo directory not found")

    slices = [
        todo
        for path in sorted(todo_dir.glob("*.md"))
        if path.name != "README.md" and (todo := _load_slice(path)) is not None
    ]
    if not slices:
        raise ValidationError("no pipeline_slice todos found")
    for todo in slices:
        _validate_state(todo)

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
        artifact_parts = Path(artifact).parts
        if artifact_parts[:2] == ("docs", "plans"):
            plan_frontmatter = _parse_frontmatter(
                artifact_path.read_text(encoding="utf-8"), artifact_path
            )
            actual = {
                key: plan_frontmatter.get(key) for key in ACTIVE_PLAN_CONTRACT
            }
            if actual != ACTIVE_PLAN_CONTRACT:
                raise ValidationError(
                    f"{current.path}: active plan is not implementation-ready code: "
                    f"{artifact}; expected={ACTIVE_PLAN_CONTRACT!r} actual={actual!r}"
                )

    readme = _read_json_marker(
        (todo_dir / "README.md").read_text(encoding="utf-8"),
        PIPELINE_QUEUE_RE,
        todo_dir / "README.md",
    )
    current_state_path = root / "docs" / "operations" / "agent-pipeline-current-state.md"
    current_projection = _read_json_marker(
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
        raise ValidationError(f"{todo_dir / 'README.md'}: queue projection drift: {readme!r} != {expected!r}")
    if current_projection != expected:
        raise ValidationError(
            f"{current_state_path}: current-state projection drift: "
            f"{current_projection!r} != {expected!r}"
        )

    return current, _next_transition(current)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--root",
        type=Path,
        default=Path(__file__).resolve().parents[2],
        help="Repository or fixture root (defaults to the repository root).",
    )
    args = parser.parse_args()
    try:
        active, transition = validate(args.root.resolve())
    except (OSError, ValidationError) as exc:
        print(f"PIPELINE INVALID: {exc}", file=sys.stderr)
        return 1

    artifacts = ",".join(active.state["artifacts"]) or "none"
    print("PIPELINE VALID")
    print(f"active_slice={active.issue_id}")
    print(f"owner_lane={active.state['owner_lane']}")
    print(f"last_handoff={active.last_handoff}")
    print(f"artifacts={artifacts}")
    print(f"validator_verdict={active.state['validator_verdict']}")
    print(f"user_gate={active.state['user_gate']}")
    print(f"next_allowed_transition={transition}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
