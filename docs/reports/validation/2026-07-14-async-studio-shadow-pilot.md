---
date: 2026-07-14
topic: async-studio-shadow-pilot
kind: validation
status: conditional-pass
---

# Async Studio Shadow Pilot 검증

## 판정

**conditional-pass.** 저장소 기반 state, spec preflight, dirty-workspace 보호, serial coordinator payload, completion provenance, repair/blocker, demo bundle과 local-only decision은 fixture와 shadow에서 통과했다. 실제 Orca runtime을 사용한 disposable worktree/dispatch smoke와 Product Owner opt-in live slice는 아직 실행하지 않았다.

## Shadow replay

대상은 `todos/020-pending-p2-m1-d11-multi-currency-economy.md`다. read-only replay는 9개의 historical marker에서 다음 핵심 전이를 재현했다.

- planning → dev → validation → `passed / awaiting-user-approval`
- Product Owner changes-requested → planning
- 재검증 → `passed / awaiting-user-approval`
- Product Owner approved

실행 뒤 현재 active slice는 021, next transition은 `planner-handoff`였다. shadow 결과는 `stable_ref_created=false`, `candidate_created=false`, `orca_task_created=false`를 보고했다.

## 자동 검증

```text
python3 scripts/tools/test_validate_agent_pipeline.py
16 tests passed

python3 scripts/tools/test_run_agent_studio.py
31 tests passed

python3 scripts/tools/validate_agent_pipeline.py
PIPELINE VALID

HOME=/private/tmp/bro-exile-godot /Users/highfence/Dev/.tools/bin/godot --headless --path /Users/highfence/Dev/Bro-exile --quit
exit 0 (macOS system CA warning only)
```

검증 범위:

- legacy validator output과 invalid fixture 호환성
- async frontmatter/Work Log/inbox drift fail-closed
- spec ambiguity, variant, contradiction, deadline, plan readiness
- mutation-free preview와 explicit confirmation
- dirty gameplay overlap, stable/candidate ancestry, Orca preflight-before-mutation, 실패 checkpoint cleanup
- max-concurrency 1 coordinator, repository-authoritative resume role, stale dispatch, fresh Validator
- code/asset repair budget, design/deadline one-question blocker
- bundle variant/visual evidence와 실제 launch scene, blocked keep 거부
- keep compare-and-swap crash recovery/idempotency, adjust/cut stable preservation
- 현재 Godot 프로젝트 headless load baseline

## Live adapter blocker

검증 시점의 `orca status --json`은 app이 실행되지 않았고 runtime `stale_bootstrap`, graph `not_running`을 보고했다. Runbook 계약에 따라 live `start`를 호출하지 않았으며 local approved ref도 bootstrap하지 않았다. 이는 구현 결함이 아니라 명시적 Product Owner start 전에 유지해야 할 안전 상태다.

## 다음 live pilot gate

1. Product Owner가 021용 spec lock을 검토한다.
2. Orca app/runtime과 orchestration graph를 실행한다.
3. 마지막 승인 commit을 `refs/bro-exile-studio/approved`로 명시적 bootstrap한다.
4. `preview`를 확인한 뒤 `start --yes`로 첫 live slice를 opt-in한다.
5. 1–3일 안에 demo-ready 또는 blocker 질문 하나가 남는지, 다음 PD 세션에서 5분 안에 candidate/stable을 실행하는지 기록한다.
