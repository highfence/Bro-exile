---
date: 2026-07-12
topic: agent-pipeline-current-state
kind: operations
status: active-reference
---

# 에이전트 파이프라인 현재 상태

<!-- pipeline-queue
{"active_slice": "021", "artifacts": ["docs/brainstorms/2026-06-07-m1-d9-character-archetype-matrix-brainstorm.md", "docs/operations/agent-pipeline-current-state.md", "docs/quality/2026-06-30-pixel-perfect-quality-gates.md"], "last_handoff": "2026-07-14 - Producer Activation Handoff", "order": ["023", "020", "021", "022", "024"], "owner_lane": "planning"}
-->

이 문서는 canonical todo를 새 세션에서 빠르게 읽기 위한 projection이다. 값이 충돌하면 개별 `pipeline_slice` todo frontmatter와 최신 Work Log 증거가 권위이며, projection을 고친 뒤에만 새 역할을 dispatch한다.

## Source of Truth

| 문서 | 용도 |
| --- | --- |
| `AGENTS.md` | 프로젝트 규칙, Godot 실행 경로, 에셋/픽셀 검증 규칙 |
| GitHub Issues | 작업 목록, 논의, 담당자, 의존성, 연결 PR과 종료 상태 |
| 개별 `pipeline_slice` todo | lifecycle, owner, verdict, user gate, artifacts의 canonical record |
| `todos/README.md` | Producer가 읽는 queue projection |
| 이 문서 | 현재 active dispatch projection |
| `docs/operations/2026-06-05-agent-team-operating-model.md` | 역할과 handoff 운영 계약 |
| `.codex/skills/bro-exile-agent-pipeline/references/role-prompts.md` | 역할별 bounded prompt template |

## Current Queue Snapshot

| 순서 | todo | GitHub | lifecycle | owner lane | Validator | user gate |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `todos/023-ready-p1-demo-checkpoint-risk-loop.md` | 과거 완료 기록 | complete | producer | passed | approved |
| 2 | `todos/020-pending-p2-m1-d11-multi-currency-economy.md` | [#1](https://github.com/highfence/Bro-exile/issues/1) | complete | producer | passed | approved |
| 3 | `todos/021-pending-p1-m1-d9-character-archetype-matrix.md` | [#2](https://github.com/highfence/Bro-exile/issues/2) | ready | planning | not-run | not-requested |
| 4 | `todos/022-pending-p1-m1-d10-skill-simulation-validation.md` | [#3](https://github.com/highfence/Bro-exile/issues/3) | pending | planning | not-run | not-requested |
| 5 | `todos/024-pending-p1-demo-windows-release.md` | [#4](https://github.com/highfence/Bro-exile/issues/4) | pending | planning | not-run | not-requested |

## Active Dispatch

- Active slice: `021` 캐릭터 3종과 빌드 아키타입 매트릭스.
- GitHub Issue: [#2](https://github.com/highfence/Bro-exile/issues/2).
- Owner lane: Planner.
- Canonical todo: `todos/021-pending-p1-m1-d9-character-archetype-matrix.md`.
- Brainstorm: `docs/brainstorms/2026-06-07-m1-d9-character-archetype-matrix-brainstorm.md`.
- 다음 허용 transition: Planner handoff.
- 기존 D9 제품 결정은 다시 묻지 않고 구현 plan으로 변환한다.

## State Contract

공개 데모 slice의 todo frontmatter가 lifecycle, owner, verdict, approval, artifact의 유일한 권위다.

| 축 | 허용 값 | 의미 |
| --- | --- | --- |
| `status` | `pending`, `ready`, `complete` | queue lifecycle. 정확히 하나의 slice만 `ready` |
| `owner_lane` | `planning`, `dev`, `asset`, `validation`, `producer` | 다음 handoff 책임자 |
| `validator_verdict` | `not-run`, `passed`, `conditional-pass`, `rejected` | 독립 검증 판정 |
| `user_gate` | `not-requested`, `awaiting-user-approval`, `approved`, `changes-requested` | Product Owner 결정 |
| `artifacts` | 저장소 상대 경로 목록 | 실제 존재하는 handoff 증거 |

각 handoff는 Work Log 끝에 새 항목을 append하고 다음 marker를 함께 남긴다.

```markdown
<!-- pipeline-state
{"artifacts": ["path/to/evidence"], "owner_lane": "validation", "routing_reason": "", "status": "ready", "user_gate": "not-requested", "validator_verdict": "not-run"}
-->
```

- frontmatter와 최신 marker가 다르면 hard failure다.
- `passed`는 `owner_lane: producer`, `user_gate: awaiting-user-approval`로만 이동한다.
- 사용자 승인 뒤에만 `status: complete`, `validator_verdict: passed`, `user_gate: approved`로 닫는다.
- `rejected`의 `routing_reason`이 `code`, `asset`, `design`이면 각각 `dev`, `asset`, `planning`으로 되돌린다.
- `todos/README.md`와 이 문서의 `pipeline-queue` marker는 projection이다.

## Restart Procedure

1. `python3 scripts/tools/validate_agent_pipeline.py`를 실행한다.
2. 실패하면 새 역할을 보내지 않고 보고된 canonical/projection mismatch를 먼저 고친다.
3. 출력된 `active_slice`, `owner_lane`, `last_handoff`, `artifacts`, `next_allowed_transition`을 읽는다.
4. active todo와 해당 plan만 추가로 읽고 한 owner lane에 bounded prompt를 보낸다.
5. 역할 결과는 todo Work Log 끝에 기록한 뒤 frontmatter를 같은 상태로 갱신한다.
6. Developer/Asset 결과는 독립 Validator가 판정한다.
7. Validator `passed` 뒤 Product Owner가 실제 플레이 단위를 승인할 때까지 다음 slice를 활성화하지 않는다.

## Preserved D9 Decisions

D9는 취소되지 않았고 공개 데모의 세 번째 slice로 이동했다. 다음 결정은 `todos/021-pending-p1-m1-d9-character-archetype-matrix.md`의 기존 Work Log에도 보존되어 있으며, D9를 활성화할 때 다시 묻지 않는다.

1. 캐릭터 선택 UI를 포함한다.
2. 모든 캐릭터는 모든 D8 무기와 조합 가능하다.
3. 런 시작은 `캐릭터 선택 -> 무기 선택 -> R1 시작` 순서다.
4. UI에는 `압축형`, `연쇄형`, `전환형` 코드명을 사용한다.
5. 세 캐릭터는 첫 구현에서 같은 광부 외형을 공유한다.
6. 선택 카드는 코드명, 빌드 문법, 대표 tag, 약점/대가만 표시한다.
7. 캐릭터별 고유 stat bonus를 추가하지 않는다.
8. 신규 아이템과 유물을 추가하지 않는다.
9. 기존 상점/보상 풀에 metadata와 soft bias를 붙이고 상점을 먼저 검증한다.
10. 대표 archetype tag는 기존 brainstorm의 3개씩을 사용한다.
11. 실제 UI capture 가독성을 완료 gate에 포함한다.

## Role Prompt Seed

021은 020 Product Owner 승인으로 활성화됐다. Planner는 기존 `압축형/연쇄형/전환형`, 모든 D8 무기 조합, `캐릭터 선택 -> 무기 선택 -> R1`, 신규 아이템·유물·실사용 에셋 제외 결정을 구현 plan으로 정리한다.
