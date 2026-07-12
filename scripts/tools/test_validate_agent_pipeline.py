#!/usr/bin/env python3
"""Fixture tests for the public-demo agent pipeline validator."""

from __future__ import annotations

import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


REPO_ROOT = Path(__file__).resolve().parents[2]
VALIDATOR = REPO_ROOT / "scripts" / "tools" / "validate_agent_pipeline.py"
QUEUE = ["023", "020", "021", "022", "024"]


def _frontmatter(data: dict[str, object]) -> str:
    lines = ["---"]
    for key, value in data.items():
        if isinstance(value, bool):
            rendered = "true" if value else "false"
        elif isinstance(value, list):
            rendered = json.dumps(value, ensure_ascii=False)
        else:
            rendered = json.dumps(value, ensure_ascii=False)
        lines.append(f"{key}: {rendered}")
    return "\n".join(lines + ["---"])


def _todo_state(
    issue_id: str,
    *,
    status: str,
    owner_lane: str,
    validator_verdict: str = "not-run",
    user_gate: str = "not-requested",
    artifacts: list[str] | None = None,
    routing_reason: str = "",
) -> dict[str, object]:
    return {
        "status": status,
        "priority": "p1",
        "issue_id": issue_id,
        "pipeline_slice": True,
        "queue_order": QUEUE.index(issue_id) + 1,
        "owner_lane": owner_lane,
        "validator_verdict": validator_verdict,
        "user_gate": user_gate,
        "artifacts": artifacts or [],
        "last_handoff": "2026-07-12 - Fixture Handoff",
        "routing_reason": routing_reason,
    }


def _write_todo(root: Path, state: dict[str, object]) -> None:
    issue_id = str(state["issue_id"])
    state_evidence = {
        key: state[key]
        for key in (
            "status",
            "owner_lane",
            "validator_verdict",
            "user_gate",
            "artifacts",
            "routing_reason",
        )
    }
    body = (
        f"{_frontmatter(state)}\n\n"
        f"# {issue_id}. Fixture\n\n"
        "## Work Log\n\n"
        "### 2026-07-12 - Fixture Handoff\n\n"
        "<!-- pipeline-state\n"
        f"{json.dumps(state_evidence, ensure_ascii=False, sort_keys=True)}\n"
        "-->\n"
    )
    (root / "todos" / f"{issue_id}-fixture.md").write_text(body, encoding="utf-8")


def _write_projection(
    root: Path, active_slice: str, active_state: dict[str, object]
) -> None:
    payload = json.dumps(
        {
            "active_slice": active_slice,
            "owner_lane": active_state["owner_lane"],
            "last_handoff": active_state["last_handoff"],
            "artifacts": active_state["artifacts"],
            "order": QUEUE,
        },
        ensure_ascii=False,
        sort_keys=True,
    )
    (root / "todos" / "README.md").write_text(
        f"# Queue\n\n<!-- pipeline-queue\n{payload}\n-->\n", encoding="utf-8"
    )
    state_path = root / "docs" / "operations" / "agent-pipeline-current-state.md"
    state_path.parent.mkdir(parents=True, exist_ok=True)
    state_path.write_text(
        f"# Current\n\n<!-- pipeline-queue\n{payload}\n-->\n", encoding="utf-8"
    )


def _make_fixture(
    root: Path,
    states: dict[str, dict[str, object]],
    *,
    active_slice: str,
) -> None:
    (root / "todos").mkdir(parents=True)
    _write_projection(root, active_slice, states[active_slice])
    for issue_id in QUEUE:
        _write_todo(root, states[issue_id])


def _base_states() -> dict[str, dict[str, object]]:
    return {
        "023": _todo_state("023", status="ready", owner_lane="dev"),
        "020": _todo_state("020", status="pending", owner_lane="planning"),
        "021": _todo_state("021", status="pending", owner_lane="planning"),
        "022": _todo_state("022", status="pending", owner_lane="planning"),
        "024": _todo_state("024", status="pending", owner_lane="planning"),
    }


def _write_plan(root: Path, path: str, *, readiness: str = "implementation-ready") -> None:
    plan = root / path
    plan.parent.mkdir(parents=True, exist_ok=True)
    plan.write_text(
        "---\n"
        "artifact_contract: ce-unified-plan/v1\n"
        f"artifact_readiness: {readiness}\n"
        "execution: code\n"
        "---\n\n"
        "# Plan\n",
        encoding="utf-8",
    )


class AgentPipelineValidatorTests(unittest.TestCase):
    maxDiff = None

    def run_validator(self, root: Path) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [sys.executable, str(VALIDATOR), "--root", str(root)],
            text=True,
            capture_output=True,
            check=False,
        )

    def test_valid_queue_reports_active_owner_evidence_and_transition(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            states = _base_states()
            _write_plan(root, "docs/plans/checkpoint.md")
            states["023"]["artifacts"] = ["docs/plans/checkpoint.md"]
            _make_fixture(root, states, active_slice="023")

            result = self.run_validator(root)

            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertIn("active_slice=023", result.stdout)
            self.assertIn("owner_lane=dev", result.stdout)
            self.assertIn("last_handoff=2026-07-12 - Fixture Handoff", result.stdout)
            self.assertIn("artifacts=docs/plans/checkpoint.md", result.stdout)
            self.assertIn("next_allowed_transition=validator-handoff", result.stdout)

    def test_double_active_slice_fails(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            states = _base_states()
            states["020"]["status"] = "ready"
            _make_fixture(root, states, active_slice="023")

            result = self.run_validator(root)

            self.assertNotEqual(result.returncode, 0)
            self.assertIn("exactly one ready slice", result.stderr)

    def test_missing_plan_projection_fails_before_dispatch(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            states = _base_states()
            states["023"]["artifacts"] = ["docs/plans/missing-plan.md"]
            _make_fixture(root, states, active_slice="023")

            result = self.run_validator(root)

            self.assertNotEqual(result.returncode, 0)
            self.assertIn("missing active artifact", result.stderr)

    def test_requirements_only_active_plan_fails_before_dispatch(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            states = _base_states()
            _write_plan(
                root,
                "docs/plans/checkpoint.md",
                readiness="requirements-only",
            )
            states["023"]["artifacts"] = ["docs/plans/checkpoint.md"]
            _make_fixture(root, states, active_slice="023")

            result = self.run_validator(root)

            self.assertNotEqual(result.returncode, 0)
            self.assertIn("active plan is not implementation-ready code", result.stderr)

    def test_wrong_active_projection_fails_before_dispatch(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            states = _base_states()
            _make_fixture(root, states, active_slice="020")

            result = self.run_validator(root)

            self.assertNotEqual(result.returncode, 0)
            self.assertIn("queue projection drift", result.stderr)

    def test_passed_without_approval_locks_next_slice(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            states = _base_states()
            states["023"].update(
                owner_lane="producer",
                validator_verdict="passed",
                user_gate="awaiting-user-approval",
            )
            states["020"]["status"] = "ready"
            _make_fixture(root, states, active_slice="020")

            result = self.run_validator(root)

            self.assertNotEqual(result.returncode, 0)
            self.assertIn("awaiting Product Owner approval", result.stderr)

    def test_product_owner_changes_route_passed_slice_back_to_planning(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            states = _base_states()
            states["023"].update(
                owner_lane="planning",
                validator_verdict="passed",
                user_gate="changes-requested",
            )
            _make_fixture(root, states, active_slice="023")

            result = self.run_validator(root)

            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertIn("owner_lane=planning", result.stdout)
            self.assertIn("next_allowed_transition=planner-handoff", result.stdout)

    def test_rejection_routes_by_reason(self) -> None:
        cases = (("code", "dev"), ("asset", "asset"), ("design", "planning"))
        for routing_reason, expected_owner in cases:
            with self.subTest(routing_reason=routing_reason):
                with tempfile.TemporaryDirectory() as tmp:
                    root = Path(tmp)
                    states = _base_states()
                    states["023"].update(
                        owner_lane=expected_owner,
                        validator_verdict="rejected",
                        routing_reason=routing_reason,
                    )
                    _make_fixture(root, states, active_slice="023")

                    result = self.run_validator(root)

                    self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                    self.assertIn(f"owner_lane={expected_owner}", result.stdout)

    def test_approved_close_allows_next_activation(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            states = _base_states()
            states["023"].update(
                status="complete",
                owner_lane="producer",
                validator_verdict="passed",
                user_gate="approved",
            )
            states["020"]["status"] = "ready"
            _make_fixture(root, states, active_slice="020")

            result = self.run_validator(root)

            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertIn("active_slice=020", result.stdout)

    def test_work_log_mismatch_is_hard_failure(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            states = _base_states()
            _make_fixture(root, states, active_slice="023")
            todo = root / "todos" / "023-fixture.md"
            todo.write_text(
                todo.read_text(encoding="utf-8").replace(
                    '"owner_lane": "dev"', '"owner_lane": "planning"'
                ),
                encoding="utf-8",
            )

            result = self.run_validator(root)

            self.assertNotEqual(result.returncode, 0)
            self.assertIn("frontmatter/work-log mismatch", result.stderr)


if __name__ == "__main__":
    unittest.main()
