---
date: 2026-07-14
topic: spec-locked-async-studio
kind: operations
status: active-reference
---

# 명세 잠금형 비동기 AI 제작 스튜디오 Runbook

## 목적

Product Owner는 PD 세션에서 하나의 demo promise와 제품 판단 경계를 잠근다. 그 뒤 Orca가 Planner audit, 한 writer lane, fresh Validator, Producer bundle을 직렬로 이어간다. 저장소가 제품 상태의 권위이고 Orca는 재생성 가능한 control plane이다.

## 첫 사용

1. `.codex/skills/bro-exile-agent-pipeline/references/spec-lock-template.md`를 `docs/spec-locks/` 아래로 복사해 active slice에 맞게 작성한다.
2. 다음 두 명령은 읽기 전용이다.

```bash
python3 scripts/tools/run_agent_studio.py --json spec-check --spec docs/spec-locks/<slice>.md
python3 scripts/tools/run_agent_studio.py --json preview --spec docs/spec-locks/<slice>.md
```

3. Product Owner가 선택한 마지막 승인 commit으로 local stable ref를 한 번만 만든다.

```bash
python3 scripts/tools/run_agent_studio.py --json bootstrap --commit <approved-commit> --yes
```

4. Orca app/runtime과 orchestration graph가 실행 중인지 확인한다. runtime이 꺼져 있으면 `start`는 Git ref나 todo를 바꾸기 전에 실패한다.
5. preview의 slice, promise, deadline, writer 순서, allowed paths와 금지 동작을 확인한 뒤 명시적으로 시작한다.

```bash
python3 scripts/tools/run_agent_studio.py --json start --spec docs/spec-locks/<slice>.md --yes
```

`start`는 `refs/bro-exile-studio/approved`에서 Orca candidate worktree를 만들고 allowlisted spec/pipeline snapshot만 첫 checkpoint로 commit한다. unrelated dirty file, remote, main과 runtime asset은 건드리지 않는다.

## Resume

Orca나 coordinator가 중단되면 candidate의 `.studio/runs/.../run.json`이 아니라 원본 workspace의 machine-local run record와 candidate latest commit을 사용한다.

```bash
python3 scripts/tools/run_agent_studio.py --json resume \
  --run-record .studio/runs/<run-id>/run.json \
  --spec docs/spec-locks/<slice>.md \
  --yes
```

deadline이 지났거나 infrastructure failure가 연속 3회면 새 dispatch를 만들지 않는다. code/asset Validator 반려는 최대 두 번까지 같은 candidate writer로 돌아가며 gameplay repair count와 infrastructure count를 섞지 않는다.

## Demo Inbox 정보 순서

`docs/operations/agent-studio-inbox.md`는 다음 순서로 읽힌다.

1. **실행:** candidate가 첫 버튼/명령이고 stable fallback이 두 번째다.
2. **변경과 검증:** 이전 승인본 대비 플레이 차이, validation, deviation, capture를 보여준다.
3. **Play lens:** Product Owner가 답할 질문 하나만 보여준다.
4. **판정:** `keep`, `adjust`, `cut`을 보여준다.

상태별 표시는 다음과 같다.

| 상태 | 첫 행동 | 판정 |
| --- | --- | --- |
| inactive / spec-draft | spec lock 작성 또는 preview | 없음 |
| running | stable fallback만 제공하고 현재 lane 표시 | 없음 |
| demo-ready | candidate 실행, 실패 시 stable | keep / adjust / cut |
| blocked | stable 실행, 근거와 제품 질문 하나 | 질문 해결 뒤 resume 또는 cut |
| expired | stable 실행, candidate evidence 보존 | deadline 재잠금 또는 cut |
| missing-bundle | stable 실행, 누락 evidence 표시 | 없음 |

## Bundle과 판정

Producer는 `demo-bundle-template.md` 형식으로 durable report를 만들고 검증한다.

```bash
python3 scripts/tools/run_agent_studio.py --json bundle-check \
  --candidate-path <candidate-path> \
  --spec docs/spec-locks/<slice>.md \
  --bundle docs/reports/studio/<bundle>.md
```

판정은 명시적 `--yes`만 받는다. `keep`은 passed bundle의 clean candidate tip으로 local stable ref를 compare-and-swap한다. `adjust`와 `cut`은 stable ref와 candidate evidence를 그대로 둔다. 어느 판정도 push, main merge, asset promotion 또는 public upload를 수행하지 않는다.

```bash
python3 scripts/tools/run_agent_studio.py --json decision \
  --candidate-path <candidate-path> \
  --spec docs/spec-locks/<slice>.md \
  --bundle docs/reports/studio/<bundle>.md \
  --decision keep \
  --yes
```

## Security boundary

- Git과 Orca는 `subprocess.run(argv, shell=False)` 형태로만 실행한다.
- slice ID, repository path, Git ref, scene path는 실행 전에 형식과 repository containment를 검증한다.
- arbitrary launch command를 spec이나 bundle에 저장하지 않는다.
- error output의 token, password, secret, authorization 값은 report 전에 가린다.
- `.studio/`는 machine-local이고 Git에 포함하지 않는다. durable handoff에는 credential, environment dump와 raw agent transcript를 넣지 않는다.

## Shadow와 live opt-in

다음 명령은 todo, ref, worktree와 Orca task를 만들지 않는다.

```bash
python3 scripts/tools/run_agent_studio.py --json shadow \
  --history todos/020-pending-p2-m1-d11-multi-currency-economy.md
```

shadow가 통과해도 실제 gameplay slice는 자동으로 시작하지 않는다. Product Owner가 spec lock을 검토하고 `start --yes`를 실행한 첫 slice만 live pilot이다. 기존 반자동 Producer 운영은 그때까지 fallback이다.
