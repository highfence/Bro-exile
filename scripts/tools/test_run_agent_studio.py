#!/usr/bin/env python3
"""Behavior tests for the spec-locked Bro-exile agent studio runner."""

from __future__ import annotations

from datetime import datetime, timedelta, timezone
import json
from pathlib import Path
import subprocess
import sys
import tempfile
from types import SimpleNamespace
import unittest


REPO_ROOT = Path(__file__).resolve().parents[2]
TOOLS_DIR = REPO_ROOT / "scripts" / "tools"
if str(TOOLS_DIR) not in sys.path:
    sys.path.insert(0, str(TOOLS_DIR))

from run_agent_studio import (
    CommandResult,
    RoleCompletion,
    StudioError,
    apply_demo_decision,
    bootstrap_stable_ref,
    build_coordinator_request,
    build_start_preview,
    launch_coordinator,
    load_demo_bundle,
    load_spec_lock,
    plan_recovery,
    resume_run,
    start_run,
    validate_role_completion,
)


NOW = datetime(2026, 7, 14, 21, 0, tzinfo=timezone(timedelta(hours=9)))


def _frontmatter(data: dict[str, object]) -> str:
    return "\n".join(
        ["---"]
        + [f"{key}: {json.dumps(value, ensure_ascii=False)}" for key, value in data.items()]
        + ["---"]
    )


def _write_plan(root: Path, readiness: str = "implementation-ready") -> str:
    relative = "docs/plans/studio-fixture-plan.md"
    path = root / relative
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        "---\n"
        "artifact_contract: ce-unified-plan/v1\n"
        f"artifact_readiness: {readiness}\n"
        "execution: code\n"
        "---\n\n# Fixture Plan\n",
        encoding="utf-8",
    )
    return relative


def _write_todo(root: Path, issue_id: str = "020") -> str:
    relative = f"todos/{issue_id}-studio-fixture.md"
    path = root / relative
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        _frontmatter(
            {
                "issue_id": issue_id,
                "status": "ready",
                "pipeline_slice": True,
                "owner_lane": "planning",
            }
        )
        + f"\n\n# {issue_id}. Fixture\n",
        encoding="utf-8",
    )
    return relative


def _write_spec(
    root: Path,
    *,
    overrides: dict[str, object] | None = None,
    readiness: str = "implementation-ready",
) -> Path:
    plan = _write_plan(root, readiness)
    todo = _write_todo(root)
    data: dict[str, object] = {
        "studio_spec_lock": True,
        "slice_id": "020",
        "todo": todo,
        "plan": plan,
        "demo_promise": "적 family에 따라 광석과 촉매 획득 경향이 읽힌다.",
        "player_outcome": "플레이어가 다음 적을 노릴 이유를 말할 수 있다.",
        "must": ["weighted family drop"],
        "may": ["drop feedback timing"],
        "must_not": ["exact probability UI"],
        "acceptance_examples": [
            "happy: family 성향이 한 런에서 관찰된다",
            "edge: 희귀 편차가 있어도 자원 획득은 지속된다",
            "failure: 확률 UI가 필요하면 제품 blocker로 멈춘다",
        ],
        "defaults": ["확률 수치는 숨기고 획득 피드백만 표시한다"],
        "variants": ["candidate"],
        "rejected_alternatives": ["모든 적이 동일한 비율로 드롭"],
        "stop_conditions": ["새 경제 방향", "runtime asset promotion", "public release"],
        "repair_budget": 2,
        "review_due_at": (NOW + timedelta(days=2)).isoformat(),
        "review_deadline_override": "",
        "play_lens": "family별로 다른 적을 노릴 이유가 생겼는가?",
        "unresolved_product_decisions": [],
        "writer_lanes": ["dev"],
        "allowed_paths": ["scripts/game", "scripts/ui", todo],
    }
    if overrides:
        data.update(overrides)
    path = root / "docs/spec-locks/020-fixture.md"
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        _frontmatter(data)
        + "\n\n"
        "# 020 Spec Lock\n\n"
        "## Demo Promise\n\n적 family에 따라 광석과 촉매 획득 경향이 읽힌다.\n\n"
        "## Player Outcome\n\n플레이어가 다음 적을 노릴 이유를 말할 수 있다.\n\n"
        "## Must / May / Must Not\n\nfrontmatter projection을 따른다.\n\n"
        "## Acceptance Examples\n\n정상, 경계, 실패 사례는 frontmatter projection을 따른다.\n\n"
        "## Defaults and Variants\n\nfrontmatter projection을 따른다.\n\n"
        "## Rejected Alternatives\n\nfrontmatter projection을 따른다.\n\n"
        "## Stop Conditions\n\nfrontmatter projection을 따른다.\n\n"
        "## Play Lens\n\nfamily별로 다른 적을 노릴 이유가 생겼는가?\n",
        encoding="utf-8",
    )
    return path


class SpecLockTests(unittest.TestCase):
    def test_valid_spec_lock_builds_mutation_free_preview(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            spec_path = _write_spec(root)
            before = sorted(str(path.relative_to(root)) for path in root.rglob("*"))

            spec = load_spec_lock(root, spec_path, now=NOW)
            preview = build_start_preview(root, spec)

            after = sorted(str(path.relative_to(root)) for path in root.rglob("*"))
            self.assertEqual(before, after)
            self.assertEqual(preview["slice_id"], "020")
            self.assertEqual(preview["next_owner"], "planning")
            self.assertEqual(preview["max_concurrency"], 1)
            self.assertFalse(preview["mutates_state"])

    def test_unresolved_product_decision_rejects_lock(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            path = _write_spec(
                root,
                overrides={"unresolved_product_decisions": ["정확한 확률을 공개할까?"]},
            )
            with self.assertRaisesRegex(StudioError, "unresolved product decision"):
                load_spec_lock(root, path, now=NOW)

    def test_more_than_two_variants_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            path = _write_spec(root, overrides={"variants": ["A", "B", "C"]})
            with self.assertRaisesRegex(StudioError, "at most two variants"):
                load_spec_lock(root, path, now=NOW)

    def test_must_and_must_not_contradiction_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            path = _write_spec(
                root,
                overrides={"must": ["exact probability UI"], "must_not": ["exact probability UI"]},
            )
            with self.assertRaisesRegex(StudioError, "must and must_not conflict"):
                load_spec_lock(root, path, now=NOW)

    def test_deadline_outside_one_to_three_days_requires_override(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            path = _write_spec(
                root,
                overrides={"review_due_at": (NOW + timedelta(hours=8)).isoformat()},
            )
            with self.assertRaisesRegex(StudioError, "1 to 3 days"):
                load_spec_lock(root, path, now=NOW)

    def test_requirements_only_plan_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            path = _write_spec(root, readiness="requirements-only")
            with self.assertRaisesRegex(StudioError, "implementation-ready"):
                load_spec_lock(root, path, now=NOW)


def _git(root: Path, *args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["git", "-C", str(root), *args],
        text=True,
        capture_output=True,
        check=True,
    )


def _init_repo(root: Path) -> Path:
    _write_spec(root)
    (root / "todos" / "README.md").write_text("# Queue\n", encoding="utf-8")
    current = root / "docs/operations/agent-pipeline-current-state.md"
    current.parent.mkdir(parents=True, exist_ok=True)
    current.write_text("# Current\n", encoding="utf-8")
    (root / "scripts/game").mkdir(parents=True)
    (root / "scripts/game/economy_rules.gd").write_text("extends RefCounted\n", encoding="utf-8")
    (root / "scenes").mkdir(parents=True)
    (root / "scenes/main.tscn").write_text(
        "[gd_scene format=3]\n\n[node name=\"Main\" type=\"Node\"]\n",
        encoding="utf-8",
    )
    _git(root, "init")
    _git(root, "config", "user.email", "studio@example.invalid")
    _git(root, "config", "user.name", "Studio Fixture")
    _git(root, "add", "docs", "todos", "scripts", "scenes")
    _git(root, "commit", "-m", "fixture")
    return root / "docs/spec-locks/020-fixture.md"


class FakeOrcaRunner:
    def __init__(self, root: Path) -> None:
        self.root = root
        self.commands: list[list[str]] = []
        self.created_path: Path | None = None

    def run(self, argv: list[str], *, cwd: Path | None = None) -> CommandResult:
        self.commands.append(list(argv))
        if argv and argv[0] == "git":
            result = subprocess.run(
                argv,
                cwd=cwd,
                text=True,
                capture_output=True,
                check=False,
            )
            return CommandResult(result.returncode, result.stdout, result.stderr)
        if argv[:2] == ["orca", "status"]:
            return CommandResult(
                0,
                json.dumps(
                    {
                        "ok": True,
                        "result": {
                            "runtime": {"state": "running", "reachable": True},
                            "graph": {"state": "running"},
                        },
                    }
                ),
                "",
            )
        if argv[:3] == ["orca", "worktree", "create"]:
            name = argv[argv.index("--name") + 1]
            base = argv[argv.index("--base-branch") + 1]
            path = self.root.parent / f"{self.root.name}-{name}"
            _git(self.root, "worktree", "add", "-b", name, str(path), base)
            self.created_path = path
            return CommandResult(
                0,
                json.dumps(
                    {
                        "ok": True,
                        "result": {
                            "worktree": {
                                "id": f"fixture::{path}",
                                "path": str(path),
                                "branch": name,
                            }
                        },
                    }
                ),
                "",
            )
        if argv[:3] == ["orca", "worktree", "rm"]:
            if self.created_path and self.created_path.exists():
                _git(self.root, "worktree", "remove", "--force", str(self.created_path))
            return CommandResult(0, json.dumps({"ok": True}), "")
        if argv[:3] == ["orca", "orchestration", "run"]:
            return CommandResult(
                0,
                json.dumps({"ok": True, "result": {"runId": "run-fixture-1"}}),
                "",
            )
        raise AssertionError(f"unexpected command: {argv}")


class CandidateLifecycleTests(unittest.TestCase):
    def test_explicit_start_creates_descendant_without_touching_unrelated_dirty_file(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp) / "repo"
            root.mkdir()
            spec_path = _init_repo(root)
            stable = _git(root, "rev-parse", "HEAD").stdout.strip()
            bootstrap_stable_ref(root, stable, confirmed=True)
            unrelated = root / "notes.txt"
            unrelated.write_text("keep me\n", encoding="utf-8")
            runner = FakeOrcaRunner(root)
            spec = load_spec_lock(root, spec_path, now=NOW)

            result = start_run(root, spec, confirmed=True, runner=runner, launch_orchestration=False)

            self.assertEqual(unrelated.read_text(encoding="utf-8"), "keep me\n")
            self.assertIn("?? notes.txt", _git(root, "status", "--short").stdout)
            self.assertTrue(runner.created_path)
            self.assertEqual(
                _git(root, "merge-base", "--is-ancestor", stable, result["candidate_commit"]).returncode,
                0,
            )
            self.assertTrue((runner.created_path / result["checkpoint_report"]).is_file())
            self.assertFalse(any("push" in command for command in runner.commands))

    def test_default_start_launches_coordinator_after_checkpoint(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp) / "repo"
            root.mkdir()
            spec_path = _init_repo(root)
            stable = _git(root, "rev-parse", "HEAD").stdout.strip()
            bootstrap_stable_ref(root, stable, confirmed=True)
            runner = FakeOrcaRunner(root)
            spec = load_spec_lock(root, spec_path, now=NOW)

            result = start_run(root, spec, confirmed=True, runner=runner)

            self.assertEqual(result["coordinator"], "running")
            self.assertEqual(result["orca_run_id"], "run-fixture-1")

    def test_checkpoint_failure_removes_candidate_worktree_and_ref(self) -> None:
        class FailingCheckpointRunner(FakeOrcaRunner):
            def run(self, argv: list[str], *, cwd: Path | None = None) -> CommandResult:
                if (
                    argv and argv[0] == "git" and "commit" in argv
                    and self.created_path is not None
                ):
                    self.commands.append(list(argv))
                    return CommandResult(1, "", "checkpoint commit failed")
                return super().run(argv, cwd=cwd)

        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp) / "repo"
            root.mkdir()
            spec_path = _init_repo(root)
            stable = _git(root, "rev-parse", "HEAD").stdout.strip()
            bootstrap_stable_ref(root, stable, confirmed=True)
            runner = FailingCheckpointRunner(root)
            spec = load_spec_lock(root, spec_path, now=NOW)
            candidate_ref = build_start_preview(root, spec)["candidate_ref"]

            with self.assertRaisesRegex(StudioError, "checkpoint commit failed"):
                start_run(
                    root,
                    spec,
                    confirmed=True,
                    runner=runner,
                    launch_orchestration=False,
                )

            self.assertIsNotNone(runner.created_path)
            self.assertFalse(runner.created_path.exists())
            self.assertNotEqual(
                subprocess.run(
                    ["git", "-C", str(root), "show-ref", "--verify", candidate_ref],
                    text=True,
                    capture_output=True,
                    check=False,
                ).returncode,
                0,
            )
            self.assertEqual(
                _git(root, "rev-parse", "refs/bro-exile-studio/approved").stdout.strip(),
                stable,
            )

    def test_dirty_gameplay_overlap_stops_before_orca_mutation(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp) / "repo"
            root.mkdir()
            spec_path = _init_repo(root)
            stable = _git(root, "rev-parse", "HEAD").stdout.strip()
            bootstrap_stable_ref(root, stable, confirmed=True)
            gameplay = root / "scripts/game/economy_rules.gd"
            gameplay.write_text("extends RefCounted\n# dirty\n", encoding="utf-8")
            runner = FakeOrcaRunner(root)
            spec = load_spec_lock(root, spec_path, now=NOW)

            with self.assertRaisesRegex(StudioError, "dirty files overlap"):
                start_run(root, spec, confirmed=True, runner=runner, launch_orchestration=False)

            self.assertFalse(any(command[0] == "orca" for command in runner.commands))

    def test_start_requires_explicit_confirmation(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp) / "repo"
            root.mkdir()
            spec_path = _init_repo(root)
            spec = load_spec_lock(root, spec_path, now=NOW)
            with self.assertRaisesRegex(StudioError, "explicit --yes"):
                start_run(root, spec, confirmed=False, runner=FakeOrcaRunner(root))

    def test_orca_unavailable_leaves_refs_unchanged(self) -> None:
        class OfflineRunner(FakeOrcaRunner):
            def run(self, argv: list[str], *, cwd: Path | None = None) -> CommandResult:
                self.commands.append(list(argv))
                return CommandResult(
                    0,
                    json.dumps(
                        {
                            "ok": True,
                            "result": {
                                "runtime": {"state": "stale_bootstrap", "reachable": False},
                                "graph": {"state": "not_running"},
                            },
                        }
                    ),
                    "",
                )

        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp) / "repo"
            root.mkdir()
            spec_path = _init_repo(root)
            stable = _git(root, "rev-parse", "HEAD").stdout.strip()
            bootstrap_stable_ref(root, stable, confirmed=True)
            refs_before = _git(root, "show-ref").stdout
            spec = load_spec_lock(root, spec_path, now=NOW)

            with self.assertRaisesRegex(StudioError, "Orca runtime is unavailable"):
                start_run(root, spec, confirmed=True, runner=OfflineRunner(root))

            self.assertEqual(_git(root, "show-ref").stdout, refs_before)

    def test_real_pipeline_candidate_seeds_canonical_studio_state_and_inbox(self) -> None:
        from test_validate_agent_pipeline import (
            _base_states as pipeline_states,
            _make_fixture as make_pipeline_fixture,
            _write_plan as write_pipeline_plan,
        )

        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp) / "repo"
            root.mkdir()
            states = pipeline_states()
            states["023"].update(
                status="complete",
                owner_lane="producer",
                validator_verdict="passed",
                user_gate="approved",
            )
            states["020"].update(status="ready", owner_lane="planning")
            write_pipeline_plan(root, "docs/plans/020-plan.md")
            states["020"]["artifacts"] = ["docs/plans/020-plan.md"]
            make_pipeline_fixture(root, states, active_slice="020")
            spec_path = _write_spec(
                root,
                overrides={
                    "todo": "todos/020-fixture.md",
                    "plan": "docs/plans/020-plan.md",
                    "allowed_paths": ["scripts/game", "todos/020-fixture.md"],
                },
            )
            (root / "todos/020-studio-fixture.md").unlink()
            _git(root, "init")
            _git(root, "config", "user.email", "studio@example.invalid")
            _git(root, "config", "user.name", "Studio Fixture")
            _git(root, "add", "docs", "todos")
            _git(root, "commit", "-m", "fixture")
            stable = _git(root, "rev-parse", "HEAD").stdout.strip()
            bootstrap_stable_ref(root, stable, confirmed=True)
            runner = FakeOrcaRunner(root)
            spec = load_spec_lock(root, spec_path, now=NOW)

            started = start_run(
                root,
                spec,
                confirmed=True,
                runner=runner,
                launch_orchestration=False,
            )

            candidate = Path(started["candidate_path"])
            todo_text = (candidate / "todos/020-fixture.md").read_text(encoding="utf-8")
            self.assertIn("studio_enabled: true", todo_text)
            self.assertIn("Producer Async Studio Start", todo_text)
            self.assertTrue((candidate / "docs/operations/agent-studio-inbox.md").is_file())

    def test_keep_commits_canonical_decision_and_activates_next_slice(self) -> None:
        from agent_pipeline_state import PIPELINE_QUEUE_RE, parse_frontmatter, validate_pipeline
        from run_agent_studio import _append_pipeline_handoff, _replace_latest_marker
        import re

        from test_validate_agent_pipeline import (
            QUEUE,
            _base_states as pipeline_states,
            _make_fixture as make_pipeline_fixture,
            _write_plan as write_pipeline_plan,
        )

        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp) / "repo"
            root.mkdir()
            states = pipeline_states()
            states["023"].update(
                status="complete",
                owner_lane="producer",
                validator_verdict="passed",
                user_gate="approved",
            )
            states["020"].update(status="ready", owner_lane="planning")
            write_pipeline_plan(root, "docs/plans/020-plan.md")
            states["020"]["artifacts"] = ["docs/plans/020-plan.md"]
            make_pipeline_fixture(root, states, active_slice="020")
            spec_path = _write_spec(
                root,
                overrides={
                    "todo": "todos/020-fixture.md",
                    "plan": "docs/plans/020-plan.md",
                    "allowed_paths": ["scripts/game", "todos/020-fixture.md"],
                },
            )
            (root / "todos/020-studio-fixture.md").unlink()
            (root / "scenes").mkdir(parents=True)
            (root / "scenes/main.tscn").write_text(
                "[gd_scene format=3]\n\n[node name=\"Main\" type=\"Node\"]\n",
                encoding="utf-8",
            )
            _git(root, "init")
            _git(root, "config", "user.email", "studio@example.invalid")
            _git(root, "config", "user.name", "Studio Fixture")
            _git(root, "add", "docs", "todos", "scenes")
            _git(root, "commit", "-m", "fixture")
            stable = _git(root, "rev-parse", "HEAD").stdout.strip()
            bootstrap_stable_ref(root, stable, confirmed=True)
            runner = FakeOrcaRunner(root)
            spec = load_spec_lock(root, spec_path, now=NOW)
            started = start_run(
                root,
                spec,
                confirmed=True,
                runner=runner,
                launch_orchestration=False,
            )
            candidate = Path(started["candidate_path"])
            bundle_path = _write_bundle(candidate, spec, started)
            todo = candidate / "todos/020-fixture.md"
            heading = "2026-07-14 - Producer Demo Bundle"
            fm = _append_pipeline_handoff(
                todo,
                heading=heading,
                updates={
                    "owner_lane": "producer",
                    "validator_verdict": "passed",
                    "user_gate": "awaiting-user-approval",
                    "studio_phase": "demo-ready",
                    "studio_demo_bundle": "docs/reports/studio/demo-bundle.md",
                },
                actions=("Validator passed 뒤 demo bundle을 만들었다.",),
            )
            queue = {
                "active_slice": "020",
                "owner_lane": "producer",
                "last_handoff": heading,
                "artifacts": fm["artifacts"],
                "order": QUEUE,
            }
            for relative in (
                "todos/README.md",
                "docs/operations/agent-pipeline-current-state.md",
            ):
                _replace_latest_marker(candidate / relative, PIPELINE_QUEUE_RE, "pipeline-queue", queue)
            inbox_payload = {
                "active_slice": "020",
                "studio_phase": "demo-ready",
                "studio_blocker": "",
                "studio_demo_bundle": "docs/reports/studio/demo-bundle.md",
                "studio_stable_ref": "refs/bro-exile-studio/approved",
                "studio_candidate_ref": started["candidate_ref"],
                "studio_review_due_at": spec.review_due_at.isoformat(),
                "studio_repair_count": 0,
            }
            _replace_latest_marker(
                candidate / "docs/operations/agent-studio-inbox.md",
                re.compile(r"<!--\s*studio-inbox\s*\n(?P<payload>.*?)\n-->", re.DOTALL),
                "studio-inbox",
                inbox_payload,
            )
            _git(candidate, "add", "todos", "docs/operations", "docs/reports/studio")
            _git(candidate, "commit", "-m", "test: record demo ready")
            bundle = load_demo_bundle(candidate, bundle_path, spec)

            result = apply_demo_decision(
                root,
                bundle,
                decision="keep",
                confirmed=True,
                runner=runner,
                candidate_path=candidate,
            )

            snapshot = validate_pipeline(candidate)
            self.assertEqual(snapshot.active.issue_id, "021")
            self.assertEqual(result["stable_after"], _git(candidate, "rev-parse", "HEAD").stdout.strip())


class CoordinatorTests(unittest.TestCase):
    def _started(self, root: Path) -> tuple[object, dict[str, object], FakeOrcaRunner]:
        spec_path = _init_repo(root)
        stable = _git(root, "rev-parse", "HEAD").stdout.strip()
        bootstrap_stable_ref(root, stable, confirmed=True)
        runner = FakeOrcaRunner(root)
        spec = load_spec_lock(root, spec_path, now=NOW)
        started = start_run(
            root,
            spec,
            confirmed=True,
            runner=runner,
            launch_orchestration=False,
        )
        return spec, started, runner

    def test_coordinator_request_is_serial_and_bound_to_candidate(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp) / "repo"
            root.mkdir()
            spec, started, _ = self._started(root)

            request = build_coordinator_request(spec, started)

            self.assertEqual(request["max_concurrent"], 1)
            self.assertEqual(request["next_role"], "planning")
            self.assertEqual(request["worktree"], f"path:{started['candidate_path']}")
            self.assertIn(str(started["candidate_ref"]), request["spec"])
            self.assertIn(str(spec.relative_path), request["spec"])

    def test_launch_uses_orca_run_with_max_concurrent_one(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp) / "repo"
            root.mkdir()
            spec, started, runner = self._started(root)

            result = launch_coordinator(root, spec, started, runner=runner)

            self.assertEqual(result["orca_run_id"], "run-fixture-1")
            command = runner.commands[-1]
            self.assertEqual(command[:3], ["orca", "orchestration", "run"])
            self.assertEqual(command[command.index("--max-concurrent") + 1], "1")

    def test_request_resumes_from_repository_authoritative_next_role(self) -> None:
        from test_validate_agent_pipeline import (
            _base_states as pipeline_states,
            _make_fixture as make_pipeline_fixture,
            _write_plan as write_pipeline_plan,
        )

        with tempfile.TemporaryDirectory() as tmp:
            candidate = Path(tmp)
            states = pipeline_states()
            write_pipeline_plan(candidate, "docs/plans/checkpoint.md")
            states["023"]["artifacts"] = ["docs/plans/checkpoint.md"]
            make_pipeline_fixture(candidate, states, active_slice="023")
            spec = SimpleNamespace(
                slice_id="023",
                relative_path="docs/spec-locks/023.md",
                demo_promise="검증 가능한 다음 플레이",
                play_lens="다음 행동이 읽히는가?",
            )

            request = build_coordinator_request(
                spec,
                {
                    "candidate_path": str(candidate),
                    "candidate_ref": "refs/heads/studio-023-fixture",
                },
            )

            self.assertEqual(request["next_role"], "validation")
            self.assertIn("Repository-authoritative next role: validation", request["spec"])
            self.assertNotIn("Start with Planner audit", request["spec"])

    def test_resume_relaunches_one_coordinator_from_latest_checkpoint(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp) / "repo"
            root.mkdir()
            spec, started, runner = self._started(root)
            record = root / ".studio" / "runs" / str(started["run_id"]) / "run.json"

            result = resume_run(
                root,
                record,
                spec,
                confirmed=True,
                now=NOW,
                runner=runner,
            )

            self.assertEqual(result["status"], "resumed")
            self.assertEqual(result["next_role"], "planning")
            launches = [
                command
                for command in runner.commands
                if command[:3] == ["orca", "orchestration", "run"]
            ]
            self.assertEqual(len(launches), 1)

    def test_stale_completion_provenance_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp) / "repo"
            root.mkdir()
            _, started, runner = self._started(root)
            run_state = {
                **started,
                "active_task_id": "task-current",
                "active_dispatch_id": "dispatch-current",
                "active_role": "dev",
                "active_terminal": "terminal-dev",
            }
            completion = RoleCompletion(
                task_id="task-stale",
                dispatch_id="dispatch-current",
                role="dev",
                terminal="terminal-dev",
                commit=str(started["candidate_commit"]),
                handoff_path=str(started["checkpoint_report"]),
                artifacts=(str(started["checkpoint_report"]),),
            )
            with self.assertRaisesRegex(StudioError, "stale completion provenance"):
                validate_role_completion(root, run_state, completion, runner=runner)

    def test_fresh_validator_may_not_reuse_writer_terminal(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp) / "repo"
            root.mkdir()
            _, started, runner = self._started(root)
            run_state = {
                **started,
                "active_task_id": "task-validator",
                "active_dispatch_id": "dispatch-validator",
                "active_role": "validation",
                "active_terminal": "terminal-writer",
                "writer_terminal": "terminal-writer",
            }
            completion = RoleCompletion(
                task_id="task-validator",
                dispatch_id="dispatch-validator",
                role="validation",
                terminal="terminal-writer",
                commit=str(started["candidate_commit"]),
                handoff_path=str(started["checkpoint_report"]),
                artifacts=(str(started["checkpoint_report"]),),
            )
            with self.assertRaisesRegex(StudioError, "fresh terminal"):
                validate_role_completion(root, run_state, completion, runner=runner)


class RecoveryTests(unittest.TestCase):
    def test_first_code_rejection_routes_to_dev_and_increments_repair(self) -> None:
        recovery = plan_recovery(
            routing_reason="code",
            repair_count=0,
            review_due_at=NOW + timedelta(days=1),
            now=NOW,
        )
        self.assertEqual(recovery["next_role"], "dev")
        self.assertEqual(recovery["repair_count"], 1)
        self.assertEqual(recovery["status"], "repair")

    def test_third_gameplay_rejection_stops_with_one_question(self) -> None:
        recovery = plan_recovery(
            routing_reason="asset",
            repair_count=2,
            review_due_at=NOW + timedelta(days=1),
            now=NOW,
        )
        self.assertEqual(recovery["status"], "blocked")
        self.assertEqual(recovery["reason"], "repair-budget-exhausted")
        self.assertEqual(len(recovery["questions"]), 1)

    def test_design_gap_stops_without_spending_repair_budget(self) -> None:
        recovery = plan_recovery(
            routing_reason="design",
            repair_count=1,
            review_due_at=NOW + timedelta(days=1),
            now=NOW,
        )
        self.assertEqual(recovery["status"], "blocked")
        self.assertEqual(recovery["repair_count"], 1)
        self.assertEqual(len(recovery["questions"]), 1)

    def test_deadline_stops_new_dispatch(self) -> None:
        recovery = plan_recovery(
            routing_reason="code",
            repair_count=0,
            review_due_at=NOW - timedelta(minutes=1),
            now=NOW,
        )
        self.assertEqual(recovery["status"], "blocked")
        self.assertEqual(recovery["reason"], "review-deadline-expired")
        self.assertFalse(recovery["dispatch_allowed"])


def _write_bundle(
    root: Path,
    spec: object,
    started: dict[str, object],
    *,
    overrides: dict[str, object] | None = None,
) -> Path:
    data: dict[str, object] = {
        "studio_demo_bundle": True,
        "slice_id": "020",
        "spec_lock": spec.relative_path,
        "stable_commit": started["stable_commit"],
        "candidate_commit": started["candidate_commit"],
        "validation_status": "passed",
        "change_summary": "family weighted drop과 피드백을 검증했다.",
        "validation_evidence": [started["checkpoint_report"]],
        "deviations": [],
        "variants": ["candidate"],
        "play_lens": spec.play_lens,
        "blocker_question": "",
        "visual_change": False,
        "visual_evidence": [],
        "launch_scene": "scenes/main.tscn",
    }
    if overrides:
        data.update(overrides)
    path = root / "docs/reports/studio/demo-bundle.md"
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        _frontmatter(data)
        + "\n\n# Demo Bundle\n\n"
        "## Launch\n\nCandidate와 stable을 같은 scene으로 실행한다.\n\n"
        "## Change Summary\n\nfamily weighted drop과 피드백을 검증했다.\n\n"
        "## Validation\n\nfrontmatter evidence를 따른다.\n\n"
        "## Play Lens\n\nfamily별로 다른 적을 노릴 이유가 생겼는가?\n",
        encoding="utf-8",
    )
    return path


class DemoBundleTests(unittest.TestCase):
    def _started(self, root: Path) -> tuple[object, dict[str, object], FakeOrcaRunner]:
        spec_path = _init_repo(root)
        stable = _git(root, "rev-parse", "HEAD").stdout.strip()
        bootstrap_stable_ref(root, stable, confirmed=True)
        runner = FakeOrcaRunner(root)
        spec = load_spec_lock(root, spec_path, now=NOW)
        started = start_run(
            root,
            spec,
            confirmed=True,
            runner=runner,
            launch_orchestration=False,
        )
        return spec, started, runner

    def test_bundle_rejects_third_variant(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp) / "repo"
            root.mkdir()
            spec, started, _ = self._started(root)
            candidate = Path(started["candidate_path"])
            bundle_path = _write_bundle(
                candidate,
                spec,
                started,
                overrides={"variants": ["A", "B", "C"]},
            )
            with self.assertRaisesRegex(StudioError, "at most two variants"):
                load_demo_bundle(candidate, bundle_path, spec)

    def test_visual_bundle_requires_actual_capture_evidence(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp) / "repo"
            root.mkdir()
            spec, started, _ = self._started(root)
            candidate = Path(started["candidate_path"])
            bundle_path = _write_bundle(
                candidate,
                spec,
                started,
                overrides={"visual_change": True, "visual_evidence": []},
            )
            with self.assertRaisesRegex(StudioError, "visual evidence"):
                load_demo_bundle(candidate, bundle_path, spec)

    def test_bundle_requires_an_existing_launch_scene(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp) / "repo"
            root.mkdir()
            spec, started, _ = self._started(root)
            candidate = Path(started["candidate_path"])
            bundle_path = _write_bundle(
                candidate,
                spec,
                started,
                overrides={"launch_scene": "scenes/missing.tscn"},
            )

            with self.assertRaisesRegex(StudioError, "launch_scene is missing"):
                load_demo_bundle(candidate, bundle_path, spec)

    def test_keep_advances_only_local_stable_ref_and_is_idempotent(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp) / "repo"
            root.mkdir()
            spec, started, runner = self._started(root)
            candidate = Path(started["candidate_path"])
            bundle_path = _write_bundle(candidate, spec, started)
            _git(candidate, "add", "docs/reports/studio/demo-bundle.md")
            _git(candidate, "commit", "-m", "test: add demo bundle")
            bundle = load_demo_bundle(candidate, bundle_path, spec)

            first = apply_demo_decision(
                root,
                bundle,
                decision="keep",
                confirmed=True,
                runner=runner,
                candidate_path=candidate,
            )
            second = apply_demo_decision(
                root,
                bundle,
                decision="keep",
                confirmed=True,
                runner=runner,
                candidate_path=candidate,
            )

            stable_tip = _git(root, "rev-parse", "refs/bro-exile-studio/approved").stdout.strip()
            self.assertEqual(stable_tip, _git(candidate, "rev-parse", "HEAD").stdout.strip())
            self.assertEqual(first, second)
            self.assertFalse(any(command[:2] == ["git", "push"] for command in runner.commands))

    def test_keep_rejects_blocked_bundle_before_candidate_or_stable_mutation(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp) / "repo"
            root.mkdir()
            spec, started, runner = self._started(root)
            candidate = Path(started["candidate_path"])
            bundle_path = _write_bundle(
                candidate,
                spec,
                started,
                overrides={
                    "validation_status": "blocked",
                    "blocker_question": "제품 판단이 필요한가?",
                },
            )
            _git(candidate, "add", "docs/reports/studio/demo-bundle.md")
            _git(candidate, "commit", "-m", "test: add blocked demo bundle")
            bundle = load_demo_bundle(candidate, bundle_path, spec)
            candidate_before = _git(candidate, "rev-parse", "HEAD").stdout.strip()
            stable_before = _git(
                root, "rev-parse", "refs/bro-exile-studio/approved"
            ).stdout.strip()

            with self.assertRaisesRegex(StudioError, "requires a passed"):
                apply_demo_decision(
                    root,
                    bundle,
                    decision="keep",
                    confirmed=True,
                    runner=runner,
                    candidate_path=candidate,
                )

            self.assertEqual(_git(candidate, "rev-parse", "HEAD").stdout.strip(), candidate_before)
            self.assertEqual(
                _git(root, "rev-parse", "refs/bro-exile-studio/approved").stdout.strip(),
                stable_before,
            )
            self.assertFalse((root / ".studio/decisions").exists())

    def test_pending_keep_record_recovers_compare_and_swap_idempotently(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp) / "repo"
            root.mkdir()
            spec, started, runner = self._started(root)
            candidate = Path(started["candidate_path"])
            bundle_path = _write_bundle(candidate, spec, started)
            _git(candidate, "add", "docs/reports/studio/demo-bundle.md")
            _git(candidate, "commit", "-m", "test: add demo bundle")
            bundle = load_demo_bundle(candidate, bundle_path, spec)

            completed = apply_demo_decision(
                root,
                bundle,
                decision="keep",
                confirmed=True,
                runner=runner,
                candidate_path=candidate,
            )
            record = next((root / ".studio/decisions").glob("*.json"))
            pending = json.loads(record.read_text(encoding="utf-8"))
            pending["status"] = "pending-ref-update"
            pending["stable_after"] = pending["stable_before"]
            record.write_text(
                json.dumps(pending, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
                encoding="utf-8",
            )
            _git(
                root,
                "update-ref",
                "refs/bro-exile-studio/approved",
                str(pending["stable_before"]),
                str(completed["candidate_commit"]),
            )

            recovered = apply_demo_decision(
                root,
                bundle,
                decision="keep",
                confirmed=True,
                runner=runner,
                candidate_path=candidate,
            )

            self.assertEqual(recovered["status"], "complete")
            self.assertEqual(recovered["stable_after"], completed["candidate_commit"])
            self.assertEqual(
                _git(root, "rev-parse", "refs/bro-exile-studio/approved").stdout.strip(),
                completed["candidate_commit"],
            )

    def test_adjust_and_cut_preserve_stable_and_candidate(self) -> None:
        for decision in ("adjust", "cut"):
            with self.subTest(decision=decision):
                with tempfile.TemporaryDirectory() as tmp:
                    root = Path(tmp) / "repo"
                    root.mkdir()
                    spec, started, runner = self._started(root)
                    candidate = Path(started["candidate_path"])
                    bundle_path = _write_bundle(candidate, spec, started)
                    _git(candidate, "add", "docs/reports/studio/demo-bundle.md")
                    _git(candidate, "commit", "-m", "test: add demo bundle")
                    bundle = load_demo_bundle(candidate, bundle_path, spec)
                    stable_before = _git(root, "rev-parse", "refs/bro-exile-studio/approved").stdout

                    result = apply_demo_decision(
                        root,
                        bundle,
                        decision=decision,
                        confirmed=True,
                        runner=runner,
                        candidate_path=candidate,
                    )

                    self.assertEqual(
                        _git(root, "rev-parse", "refs/bro-exile-studio/approved").stdout,
                        stable_before,
                    )
                    self.assertTrue(candidate.is_dir())
                    self.assertEqual(result["decision"], decision)


if __name__ == "__main__":
    unittest.main()
