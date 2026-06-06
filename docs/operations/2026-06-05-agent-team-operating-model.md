---
date: 2026-06-05
topic: agent-team-operating-model
kind: operations
status: active-reference
---

# 반자동 에이전트 운영 팀

## 목적

Bro-exile의 장기 작업은 기획, 개발, 에셋이 서로 다른 속도로 움직인다. 한 스레드에서 모든 컨텍스트를 계속 들고 가면 작업이 빠르게 넓어지고, 반대로 역할별 에이전트를 아무 규칙 없이 늘리면 handoff가 사라진다.

이 운영 모델은 사용자가 메인 에이전트를 통해 전체 흐름을 관리하면서, 기획/개발/에셋/검증 역할 에이전트가 각자의 컨텍스트와 하네스를 유지하게 만드는 반자동 팀 방식이다. 첫 단계에서는 자동 queue watcher를 만들지 않는다. 메인 에이전트가 `todos/`와 문서를 읽고 필요한 역할 스레드에 작업을 배정한다.

## 팀 구성

### 메인 에이전트: Producer

역할:

- `todos/README.md`와 개별 todo를 읽고 현재 우선순위를 정리한다.
- 기획, 개발, 에셋, 검증 에이전트에 작업을 배정한다.
- 각 역할 에이전트의 결과를 하나로 합쳐 사용자에게 보고한다.
- 사용자가 결정해야 하는 질문만 추려서 묻는다.
- todo 상태, Work Log, handoff 문서가 최신인지 확인한다.

메인 에이전트가 직접 해도 되는 일:

- 큐 읽기, 상태 요약, 의존성 확인.
- 작은 문서 정리.
- 역할별 프롬프트 작성.
- 여러 에이전트 결과 통합.

메인 에이전트가 직접 하지 않는 편이 좋은 일:

- 큰 Godot 구현.
- 대량 에셋 후보 생성.
- 장시간 검증 하네스 실행.
- 이미 역할 에이전트에게 맡긴 같은 범위의 중복 작업.

### 기획 에이전트: Planner

역할:

- 애매한 아이디어를 검증 질문, acceptance criteria, todo, brainstorm, plan으로 바꾼다.
- 마일스톤 간 의존성을 정리한다.
- "무엇을 검증하는가?"를 책임진다.
- 구현자가 임의 판단하면 안 되는 디자인 질문을 `BLOCKED: DESIGN QUESTION`으로 남긴다.

주요 산출물:

- `docs/brainstorms/YYYY-MM-DD-...-brainstorm.md`
- `docs/plans/YYYY-MM-DD-...-plan.md`
- `todos/NNN-...md`
- todo의 `Acceptance Criteria`, `Recommended Action`, `Work Log`

### 개발 에이전트: Developer

역할:

- `ready` 상태의 todo와 plan을 받아 Godot 구현을 진행한다.
- 기능별 debug, smoke, capture 검증을 추가하거나 실행한다.
- 사용자/다른 worker 변경을 되돌리지 않고, 자기 작업 범위만 책임진다.
- 구현 중 디자인 판단이 필요하면 멈추고 질문을 남긴다.

주요 산출물:

- Godot 코드와 씬/리소스 변경.
- 검증 커맨드와 결과.
- 커밋 또는 변경 파일 목록.
- todo `Work Log`의 구현/검증 기록.

### 에셋 에이전트: Asset

역할:

- 게임 코드와 todo에서 필요한 에셋 gap을 찾는다.
- 프롬프트 팩, 후보 이미지, 정규화, Godot 캡처, 리포트를 만든다.
- 승인되지 않은 후보를 실사용 에셋에 바로 덮어쓰지 않는다.
- 48-64px 가독성, 투명 배경, 스타일 일관성, 실제 게임 배경 위 캡처를 확인한다.

주요 산출물:

- `docs/art/...`
- `docs/reports/assets/...`
- `assets/candidates/...`
- 에셋 후보 metadata와 캡처 이미지.

### 검증 에이전트: Validator

역할:

- Developer 또는 Asset의 완료 보고를 독립적으로 검증한다.
- todo acceptance criteria가 실제로 검증 가능한지 확인한다.
- 빠진 테스트 케이스, 회귀 위험, 플레이 감각 문제를 찾는다.
- debug, smoke, capture, headless load, 실제 플레이 확인을 실행한다.
- "통과 / 조건부 통과 / 반려"로 판정하고 Producer에게 넘긴다.

주요 산출물:

- todo `Work Log`의 검증 기록.
- `docs/reports/playtests/...` 또는 `docs/reports/validation/...` 리포트.
- 실행한 명령, 캡처 경로, 실패 로그, 재현 절차.
- 후속 Developer/Asset/Planner 작업으로 넘길 구체적인 이슈.

Validator가 직접 하지 않는 일:

- 큰 기능 구현.
- 디자인 방향 임의 확정.
- Developer와 같은 파일을 동시에 수정.
- 취향 문제를 버그처럼 단정.

## todo-queue 라우팅 규칙

기본 큐는 `todos/README.md`다. 개별 작업의 source of truth는 `todos/NNN-...md`다.

라우팅 기준:

| 신호 | 기본 담당 |
| --- | --- |
| `status: pending`, 검증 질문이 흐림 | Planner |
| `status: ready`, 구현 acceptance criteria가 명확함 | Developer |
| `tags`에 `asset`, `art`, `sprite`, `icon`, `harness` 포함 | Asset |
| 구현/에셋 완료 보고 이후, 완료 판정 전 | Validator |
| `tags`에 `validation`, `playtest`, `simulation`, `readability` 포함 | Validator |
| UI/전투/경제 구현과 에셋이 모두 필요한 작업 | Producer가 Planner/Developer/Asset으로 분할 |
| 여러 todo 의존성 조정, 마일스톤 순서 변경 | Producer + Planner |

권장 frontmatter 확장:

```yaml
owner_lane: planning | dev | asset | validation | producer
active_thread:
worktree:
blocked_questions: []
artifacts: []
last_handoff:
```

처음부터 모든 todo에 필드를 추가하지 않는다. 새 작업이나 현재 활성 작업부터 점진적으로 추가한다.

## Handoff 형식

역할 에이전트는 작업을 끝낼 때 스레드 안에서만 요약하지 않고, todo 또는 관련 문서에 handoff를 남긴다.

```markdown
### YYYY-MM-DD - <역할> Handoff

**By:** Planner / Developer / Asset / Validator

**상태:**
- done / blocked / needs-review / passed / conditional-pass / rejected 중 하나

**Actions:**
- 수행한 일
- 변경한 파일 또는 생성한 산출물

**Verification:**
- 실행한 검증
- 실패한 검증과 이유

**Questions:**
- 사용자 결정이 필요한 질문

**Next Handoff:**
- 다음 역할 에이전트가 읽어야 할 문서
- 다음에 맡길 작업
```

## 운영 흐름

1. 사용자가 메인 에이전트에게 아이디어, 작업, 또는 "D8 상태" 같은 질문을 던진다.
2. 메인 에이전트가 `todos/README.md`와 관련 todo/plan/report를 읽는다.
3. 메인 에이전트가 필요한 역할을 판정한다.
4. 역할 에이전트에게 명확한 범위, 읽을 문서, 쓰기 범위, 멈춰야 할 질문 조건을 전달한다.
5. 역할 에이전트는 자기 스레드와 필요 시 worktree에서 작업한다.
6. Developer 또는 Asset 작업이 끝나면 Validator가 완료 판정 전 독립 검증을 수행한다.
7. 결과는 todo `Work Log`, docs, reports, artifacts에 남긴다.
8. 메인 에이전트가 결과를 합쳐 사용자에게 현재 상태, 질문, 다음 결정을 보고한다.

## D8 첫 적용

현재 큐의 첫 운영 대상은 `M1-D8 무기 정체성 루프`다.

관련 문서:

- `todos/019-ready-p1-m1-d8-weapon-identity.md`
- `docs/plans/2026-06-04-feat-p8-weapon-identity-loop-plan.md`
- `docs/brainstorms/2026-06-03-p7-threat-economy-and-p8-weapon-identity-brainstorm.md`
- `docs/reports/assets/`

D8 라우팅:

- Planner: D8의 남은 디자인 질문, D9/D10/D11 의존성, D8 완료 판정 기준을 정리한다.
- Developer: 무기 선택 UI, 세 스타터 무기 공격, 상점 decoration, debug/capture/smoke 검증을 구현한다.
- Asset: 곡괭이/네일건/랜턴 아이콘, 무기 선택 UI/HUD/상점에서 읽히는 프리뷰, 필요한 후보 리포트를 만든다.
- Validator: D8 구현과 에셋이 acceptance criteria를 통과하는지 독립 검증하고, 실제 캡처/플레이 감각에서 이상한 부분을 찾는다.
- Producer: 네 결과를 합쳐 "D8을 계속 진행할 수 있는가, 사용자 결정이 필요한가, 다음 todo가 무엇인가"를 보고한다.

## 자동화로 승격하는 조건

다음 조건이 2-3개 마일스톤 동안 안정적으로 반복되면 자동 queue watcher를 검토한다.

- todo의 owner lane이 일관되게 맞는다.
- 역할 에이전트가 handoff를 빠뜨리지 않는다.
- Validator가 완료 전 검증 로그를 안정적으로 남긴다.
- 사용자 질문이 줄고, 질문 품질이 올라간다.
- worktree/branch 충돌이 관리된다.
- 에셋 후보가 실사용 에셋에 자동으로 섞이지 않는다.

그 전에는 자동 배정보다 반자동 Producer 운영을 우선한다.
