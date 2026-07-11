---
status: pending
priority: p1
issue_id: "021"
tags: [prototype, m1, d9, characters, archetypes, synergy, trigger-economy, design, ui]
dependencies: ["019", "020"]
milestone: M1
delivery: D9
chain: buildcraft
quest_title: "M1-D9 캐릭터 3종과 빌드 아키타입 매트릭스"
pipeline_slice: true
queue_order: 3
owner_lane: planning
validator_verdict: not-run
user_gate: not-requested
active_thread:
worktree:
blocked_questions: []
artifacts:
  - "docs/brainstorms/2026-06-07-m1-d9-character-archetype-matrix-brainstorm.md"
  - "docs/operations/agent-pipeline-current-state.md"
  - "docs/quality/2026-06-30-pixel-perfect-quality-gates.md"
last_handoff: "2026-07-12 - Producer Queue Rebaseline Handoff"
routing_reason: ""
---

# 021. M1-D9 캐릭터 3종과 빌드 아키타입 매트릭스

## Quest Card

- 목표: 최종 게임의 빌드 제작 방향을 캐릭터 3종, 캐릭터별 아키타입, 트리거 기반 시너지 구조로 정리한다.
- 플레이어 감정: “이 캐릭터는 이런 빌드를 잘 만들지만, 런 중 선택과 운에 따라 다른 길도 탈 수 있다.”
- 완료 보상: 아이템/유물/장비/화폐를 늘리기 전에, 무엇이 시너지이고 무엇이 기회비용인지 판단하는 기준이 생긴다.
- 실패 신호: 캐릭터가 단순 스킨이 되거나, 반대로 한 캐릭터가 정해진 아키타입 하나만 강요한다.

## Problem Statement

현재 M1-D8은 무기 정체성을 검증하고 있고, M1-D10 후보였던 다중 화폐 경제는 상점/강화 구조를 더 세분화하려는 방향이다. 하지만 화폐, 아이템, 유물, 장비를 늘리기 전에 “어떤 캐릭터가 어떤 빌드 아키타입을 선호하는가”를 먼저 정리해야 한다.

사용자는 최종 게임을 `빌드 제작 70% + 전투 검증 30%`에 가까운 roguelike로 보고 있다. 런 밖에서는 방향성을 조금 열어주되, 한 판의 재미는 런 중 나온 선택지로 시너지를 만드는 데 있어야 한다. Slay the Spire처럼 각 캐릭터는 컨셉과 대표 아키타입을 가지지만, 덱/빌드는 순수 아키타입 카드만으로 구성되지 않는다. 초반에는 깡 성능이 좋은 선택을 집어야 할 수 있고, 운이 나쁘면 한 아키타입만으로는 극복하기 어렵다.

## Findings

- 빌드 제작의 중심은 런 안 선택이다. 런 밖 요소는 방향성을 넓히는 보조축이다.
- 시너지는 플레이어에게 태그 묶음으로 보이기보다 자연어 효과 설명으로 읽혀야 한다.
- 내부적으로는 트리거/페이로드/빈도/대가를 관리하는 문법이 필요하다.
- 자주 발생하는 트리거는 약하게 시작하고, 희소한 트리거는 더 강한 효과를 가질 수 있다.
- 좋은 빌드는 트리거 빈도와 효과 강도의 균형을 깨는 과정에서 생긴다.
- 코어 아이템이나 캐릭터 특성은 빌드가 “켜지는” 큰 도약을 만들어야 한다.
- 강한 코어에는 공격 속도 감소, 직접 피해 감소, 생존 약화, 자원 소모 같은 대가가 있어야 한다.
- 캐릭터마다 정답 아키타입 하나가 아니라 2-3개의 대표 아키타입과 교차 시너지가 있어야 한다.

## Design Notes

### 빌드 레이어

| 레이어 | 역할 |
| --- | --- |
| 캐릭터 | 어떤 빌드 문법을 선호하는지 정한다. |
| 무기/장비 템플릿 | 공격 방식의 뼈대다. 근접, 투사체, 펄스, 장판, 소환 등이 될 수 있다. |
| 스탯 선택 | 공격 속도, 범위, 피해, 방어, 회복 같은 기초 체급을 만든다. |
| 특이 아이템 | 특정 조건을 변형하거나 시너지를 여는 부품이다. |
| 전설/코어 아이템 | 빌드 방향을 크게 꺾는 고유 규칙과 대가를 제공한다. |
| 유물/계약 | 위험과 보상, 적 구성을 바꿔 빌드가 풀어야 하는 문제를 바꾼다. |
| 화폐/제작 | 어떤 선택을 반복하거나 강화할지 결정하는 장기 경제 문법이다. |

### 아이템 역할

| 역할 | 의미 |
| --- | --- |
| 깡 성능 선택 | 시너지가 약한 초반에도 집을 수 있는 안정적인 강화다. |
| 아키타입 조각 | 특정 트리거나 페이로드를 조금씩 밀어준다. |
| 브릿지 아이템 | 두 아키타입을 연결해 운이 나쁠 때도 빌드가 막히지 않게 한다. |
| 코어 아이템 | 빌드가 켜지는 순간을 만든다. 강한 대신 분명한 대가가 있어야 한다. |

### 트리거 경제 원칙

자주 발생하는 트리거는 약하게 시작하고, 희소한 트리거는 강하게 시작한다. 빌드는 희소한 트리거를 더 자주 만들거나, 자주 발생하는 약한 트리거를 강하게 만드는 방향으로 성장한다.

예시:
- `처치 시 폭발`은 자주 발생하므로 기본 피해/반경이 약해야 한다.
- 이를 강화하는 코어 아이템이 `시체 폭발을 두 번 발생`시킨다면, 공격 속도 대폭 감소 같은 대가가 필요하다.
- 이 구조는 시체 폭발 빌드만의 문제가 아니라 모든 아키타입 설계의 기준이 된다.

## Proposed Solutions

### Option 1: 캐릭터별 2-3 아키타입 매트릭스

캐릭터 3종을 확정하고, 각 캐릭터가 선호하는 대표 아키타입 2-3개와 교차 시너지를 표로 정리한다.

- 장점: Slay the Spire식 캐릭터 정체성과 런 중 빌드 선택을 함께 살릴 수 있다.
- 단점: 캐릭터 컨셉을 너무 빨리 확정하면 이후 무기/장비 설계가 좁아질 수 있다.

### Option 2: 아키타입 문법 먼저, 캐릭터는 나중

처치, 명중, 관통, 폭발, 광석 획득, 장판 같은 트리거 문법을 먼저 정리하고, 나중에 캐릭터에 배분한다.

- 장점: 시스템 설계가 유연하다.
- 단점: 플레이어가 기억할 캐릭터 판타지가 늦게 생긴다.

### Option 3: 캐릭터 컨셉만 먼저, 아키타입은 느슨하게

캐릭터 3종의 직업/성향만 잡고, 대표 아키타입은 후보로만 둔다.

- 장점: 너무 이른 확정을 피한다.
- 단점: 아이템/유물/화폐 설계 기준으로는 부족할 수 있다.

## Recommended Action

D8 무기 정체성은 complete 상태이므로, D9는 `docs/brainstorms/2026-06-07-m1-d9-character-archetype-matrix-brainstorm.md`를 기준으로 진행한다.

Option 1을 목표로 하되 캐릭터 이름/직업 확정은 강요하지 않는다. 먼저 “캐릭터 3종이 어떤 빌드 문법을 선호해야 하는가”와 “각 캐릭터가 억지로 한 아키타입만 타지 않게 만드는 브릿지/깡 성능 선택은 무엇인가”를 정리한다.

Planner 권장 기본값은 캐릭터를 임시 코드명 `압축형`, `연쇄형`, `전환형`으로 두고, 각 캐릭터가 2-3개 아키타입을 선호하게 만드는 것이다. 이 3분할 방향은 2026-06-07 Producer/User 논의에서 승인됐다. 2026-07-01과 2026-07-02 Producer/User 논의에서 D9 첫 구현 scope와 UI/data/debug 세부 결정도 승인됐다.

- DECIDED: DESIGN QUESTION - 캐릭터 3종은 지금 단계에서 “압축형/연쇄형/전환형” 같은 빌드 문법 코드명으로 확정한다.
- DECIDED: DESIGN QUESTION - D9 첫 구현은 캐릭터 선택 UI까지 포함한다. 데이터/디버그/상점 편향도 같은 plan 범위에 포함하되, UI는 실제 렌더 캡처로 검증한다.
- DECIDED: DESIGN QUESTION - 각 캐릭터는 모든 D8 무기와 조합 가능하게 둔다. 특정 무기 hard lock 또는 1-2개 강한 무기 선호를 요구하지 않는다.
- DECIDED: DESIGN QUESTION - 런 시작 흐름은 `캐릭터 선택 -> 무기 선택 -> R1 시작` 순서로 진행한다.
- DECIDED: DESIGN QUESTION - D9 UI는 최종 이름/직업 없이 `압축형`, `연쇄형`, `전환형` 코드명을 그대로 표시한다.
- DECIDED: DESIGN QUESTION - 세 캐릭터는 D9 첫 구현에서 같은 광부 외형을 공유한다. 캐릭터별 실사용 에셋은 계속 hold다.
- DECIDED: DESIGN QUESTION - 캐릭터 선택 카드는 코드명, 한 줄 빌드 문법, 대표 아키타입 tag 2-3개, 약점/대가 1줄만 표시한다.
- DECIDED: DESIGN QUESTION - D9 첫 구현에는 캐릭터별 고유 스탯 보정을 넣지 않는다.
- DECIDED: DESIGN QUESTION - 새 아이템/유물은 D9 첫 구현에 추가하지 않고, 기존 상점/보상 풀에 metadata와 soft bias만 붙인다. 새 아이템/유물 추가는 018 목록 재검토로 넘긴다.
- DECIDED: DESIGN QUESTION - 캐릭터 편향은 상점과 보상 둘 다 대상으로 하되, 구현 우선순위는 상점 먼저, 보상은 metadata/debug 기준까지 잡는다.
- DECIDED: DESIGN QUESTION - 대표 아키타입 tag는 brainstorm의 3개씩 그대로 사용한다.

## Acceptance Criteria

### Design-Only

- [ ] 캐릭터 3종은 최종 이름/직업이 아니라 빌드 문법 선호 코드명으로 정의되어 있다.
- [ ] 각 캐릭터가 선호하는 대표 아키타입 2-3개가 정리되어 있다.
- [ ] 각 캐릭터는 모든 D8 무기와 조합 가능하며, 캐릭터 정체성은 무기 잠금이 아니라 아키타입/상점/보상 편향으로 드러난다.
- [ ] D9 첫 구현은 캐릭터별 고유 스탯 보정, 신규 아이템, 신규 유물, 신규 실사용 캐릭터 에셋을 포함하지 않는다.
- [ ] 캐릭터 선택 UI 카드에는 코드명, 한 줄 빌드 문법, 대표 아키타입 tag 2-3개, 약점/대가 1줄만 들어간다.
- [ ] 각 아키타입의 핵심 trigger, payload, frequency, cost가 정리되어 있다.
- [ ] 초반 깡 성능 선택, 아키타입 조각, 브릿지 아이템, 코어 아이템의 차이가 정리되어 있다.
- [ ] 이후 강화/아이템/유물 재검토와 다중 화폐 경제 설계에 넘길 기준이 생긴다.

### Validator-Verifiable

- [ ] debug: 캐릭터/아키타입/아이템 metadata를 구현할 때 각 항목은 `character_bias`, `archetype_tags`, `trigger`, `payload`, `frequency`, `cost` 중 필요한 필드를 출력할 수 있다.
- [ ] debug: 최소 3개 캐릭터 코드명, 캐릭터별 대표 아키타입 tag, 적용 가능한 D8 무기 3종, 상점/보상 bias 샘플이 데이터 검사 명령에서 누락 없이 출력된다.
- [ ] debug: 기존 상점/보상 후보에는 D9 metadata와 soft bias가 붙지만, D9 첫 구현에서 신규 아이템/유물은 추가되지 않는다.
- [ ] smoke: 각 캐릭터 코드명은 모든 D8 무기 선택지와 함께 1라운드 시작이 가능하고, 기존 D8 무기 선택 흐름을 깨지 않는다.
- [ ] smoke: 런 시작 흐름은 `캐릭터 선택 -> 무기 선택 -> R1 시작` 순서로 진행된다.
- [ ] smoke: 각 캐릭터는 soft bias가 적용된 상점/보상 후보를 받을 수 있고, 중립 또는 브릿지 선택지도 함께 유지된다.
- [ ] capture: 캐릭터 선택 UI에서 코드명/선호 문법/대표 tag가 한 화면에서 겹치지 않고 읽히며, `--capture-ui` 또는 동등한 실제 렌더 캡처 경로가 handoff에 남는다.
- [ ] playtest: 같은 무기라도 캐릭터 코드명에 따라 상점에서 고르고 싶은 카드가 달라졌는지 기록한다.
- [ ] playtest: 한 캐릭터가 하나의 정답 아키타입만 강요하거나, 반대로 캐릭터 차이가 스킨처럼 느껴지면 조정 대상으로 기록한다.

## Work Log

### 2026-06-05 - Initial Capture

**By:** Codex

**Actions:**
- 사용자와 논의한 최종 방향성을 M1-D9 기획 todo로 캡처했다.
- 다중 화폐 경제보다 먼저 캐릭터/아키타입/트리거 경제를 정리해야 한다는 결정을 반영했다.
- 캐릭터 자체는 아직 확정하지 않고, D9에서 정리할 주제로만 큐에 넣었다.

**Learnings:**
- 최종 게임의 핵심은 단일 빌드가 아니라, 여러 강화 레이어가 맞물려 시너지를 일으키는 빌드 제작이다.
- Slay the Spire식 캐릭터 구조를 차용하되, 각 캐릭터가 하나의 정답 아키타입만 강요하지 않게 해야 한다.

### 2026-06-07 - Planner Handoff

**By:** Planner

**상태:**
- needs-review

**Actions:**
- D9 scope를 캐릭터 최종 이름/직업 확정이 아니라 캐릭터별 빌드 문법 선호 매트릭스 작성으로 좁혔다.
- `docs/brainstorms/2026-06-07-m1-d9-character-archetype-matrix-brainstorm.md` 초안을 작성했다.
- 임시 캐릭터 코드명 `압축형`, `연쇄형`, `전환형`과 각 2-3개 아키타입 후보를 정리했다.
- 각 아키타입을 `trigger`, `payload`, `frequency`, `cost`로 설명했다.
- `Acceptance Criteria`를 design-only와 Validator-verifiable 항목으로 분리했다.

**Verification:**
- 문서 작업만 수행했다. 구현, 에셋 생성, Godot 검증은 수행하지 않았다.
- Validator가 이후 확인할 수 있도록 debug/smoke/capture/playtest 검증 방식을 acceptance criteria에 명시했다.

**Questions:**
- BLOCKED: DESIGN QUESTION - 캐릭터 3종은 지금 단계에서 “압축형/연쇄형/전환형” 같은 빌드 문법 코드명으로 확정해도 되는가?
- BLOCKED: DESIGN QUESTION - D9 첫 구현은 캐릭터 선택 UI까지 포함해야 하는가, 아니면 데이터/디버그/상점 편향만 먼저 넣고 UI는 다음 단계로 미룰 것인가?
- BLOCKED: DESIGN QUESTION - 각 캐릭터는 모든 D8 무기와 조합 가능해야 하는가, 아니면 특정 무기 1-2개와 강한 선호를 가져도 되는가?

**Next Handoff:**
- Producer는 1번 승인 결정을 기준으로 남은 2번을 사용자에게 확인하고, 필요하면 3번 기본값도 확정한다.
- Developer는 사용자 결정 후 `data/debug first` 또는 `selection UI included` 범위로 D9 plan을 받아 구현한다.
- Asset은 캐릭터 이름/직업 확정 전에는 실사용 캐릭터 에셋을 만들지 말고, 필요 시 mood/reference만 제안한다.
- Validator는 design-only 기준과 debug/smoke/capture/playtest 기준을 분리해 완료 판정을 준비한다.

### 2026-06-07 - Producer Decision

**By:** Producer

**Decision:**
- 사용자와 논의한 결과, D9의 캐릭터 아키타입을 `압축형`, `연쇄형`, `전환형` 3종 빌드 문법으로 구분하는 방향을 승인했다.
- 이 결정은 최종 캐릭터 이름, 직업, 외형 확정이 아니라 D9 plan과 D10 simulation profile이 참조할 임시 설계 축이다.

**Remaining Questions:**
- BLOCKED: DESIGN QUESTION - D9 첫 구현은 캐릭터 선택 UI까지 포함해야 하는가, 아니면 데이터/디버그/상점 편향만 먼저 넣고 UI는 다음 단계로 미룰 것인가?
- BLOCKED: DESIGN QUESTION - 각 캐릭터는 모든 D8 무기와 조합 가능해야 하는가, 아니면 특정 무기 1-2개와 강한 선호를 가져도 되는가?

### 2026-07-01 - Producer Restart

**By:** Producer

**상태:**
- blocked

**Actions:**
- 에이전트 파이프라인 재시동을 위해 `docs/operations/agent-pipeline-current-state.md`를 추가했다.
- `docs/operations/agent-pipeline-quickstart.md`와 `.codex/skills/bro-exile-agent-pipeline/references/role-prompts.md`를 현재 상태판과 역할별 handoff 템플릿에 맞게 보강했다.
- 이 todo frontmatter에 `owner_lane`, `blocked_questions`, `artifacts`, `last_handoff`를 추가해 다음 Producer/Planner가 채팅 맥락 없이 이어받을 수 있게 했다.

**Verification:**
- 문서/운영 설정 작업만 수행했다.
- Godot 구현, 에셋 생성, UI capture, headless load는 실행하지 않았다.

**Questions:**
- BLOCKED: DESIGN QUESTION - D9 첫 구현은 캐릭터 선택 UI까지 포함할 것인가, 아니면 데이터/디버그/상점 편향만 먼저 넣고 UI는 다음 단계로 미룰 것인가?
- BLOCKED: DESIGN QUESTION - 각 캐릭터는 모든 D8 무기와 조합 가능하게 둘 것인가, 아니면 특정 무기 1-2개와 강한 선호를 갖게 할 것인가?

**Next Handoff:**
- Producer는 사용자에게 남은 결정 2개를 확인한다.
- 결정이 나면 Planner가 `docs/plans/2026-07-01-feat-m1-d9-character-archetype-matrix-plan.md`를 작성한다.
- Developer는 D9 plan이 `ready`가 된 뒤 데이터/디버그/상점 편향 구현을 맡는다.

### 2026-07-01 - Producer Decision Handoff

**By:** Producer

**상태:**
- done

**Actions:**
- 사용자 결정에 따라 D9 첫 구현 범위에 캐릭터 선택 UI를 포함하기로 확정했다.
- 각 캐릭터는 모든 D8 무기와 조합 가능하게 두고, 특정 무기 hard lock 또는 1-2개 강한 무기 선호는 요구하지 않기로 확정했다.
- 이 todo frontmatter의 `owner_lane`을 `planning`으로 넘기고 `blocked_questions`를 비웠다.
- UI 범위가 들어왔으므로 pixel-perfect UI capture 기준을 `Acceptance Criteria`와 artifacts에 반영했다.

**Verification:**
- 문서/운영 handoff 작업만 수행했다.
- Godot 구현, 에셋 생성, UI capture, headless load는 실행하지 않았다.

**Questions:**
- 없음. D9 Producer blocking decision은 해소됐다.

**Next Handoff:**
- Planner는 `docs/plans/2026-07-01-feat-m1-d9-character-archetype-matrix-plan.md`를 작성한다.
- Plan에는 캐릭터 코드명 3종, 캐릭터별 2개 이상 아키타입 tag, 모든 D8 무기 조합 허용 조건, metadata 필드, debug 출력, 상점/보상 편향, 캐릭터 선택 UI, `--capture-ui` 검증을 포함한다.
- Developer는 D9 plan이 `ready`가 된 뒤에만 데이터/디버그/상점 편향/캐릭터 선택 UI 구현을 맡는다.
- Asset은 최종 이름/직업/외형 확정 전까지 실사용 캐릭터 에셋을 만들지 않는다.
- Validator는 Developer handoff 이후 debug/smoke/playtest와 함께 실제 UI capture 증거를 확인한다.

**Planner Handoff Prompt:**

```markdown
역할: Bro-exile Planner

읽을 문서:
- `AGENTS.md`
- `.codex/skills/bro-exile-agent-pipeline/SKILL.md`
- `.codex/skills/bro-exile-pixel-perfect/SKILL.md`
- `docs/operations/agent-pipeline-current-state.md`
- `todos/021-pending-p1-m1-d9-character-archetype-matrix.md`
- `docs/brainstorms/2026-06-07-m1-d9-character-archetype-matrix-brainstorm.md`
- `docs/quality/2026-06-30-pixel-perfect-quality-gates.md`

목표:
- `docs/plans/2026-07-01-feat-m1-d9-character-archetype-matrix-plan.md`를 작성한다.
- D9 첫 구현 scope는 `selection UI included`다.
- 캐릭터 코드명은 `압축형`, `연쇄형`, `전환형`을 사용한다.
- 모든 캐릭터는 모든 D8 무기와 조합 가능해야 한다.
- 캐릭터 정체성은 무기 잠금이 아니라 아키타입 tag, 상점/보상 편향, debug metadata로 드러나야 한다.

Plan에 포함할 것:
- 캐릭터별 2개 이상 아키타입 tag.
- `character_bias`, `archetype_tags`, `trigger`, `payload`, `frequency`, `cost` metadata 필드.
- 캐릭터 선택 UI 요구사항과 `--capture-ui` 검증 기준.
- debug/smoke/playtest/Validator acceptance criteria.

쓰기 범위:
- `docs/plans/2026-07-01-feat-m1-d9-character-archetype-matrix-plan.md`
- 이 todo의 Work Log/frontmatter

멈춤 조건:
- 최종 캐릭터 이름/직업/외형을 확정해야 하는 경우.
- 실사용 캐릭터 에셋 생성 또는 promotion이 필요한 경우.

handoff:
- plan 작성 뒤 이 todo Work Log에 `needs-review` 또는 `ready-for-dev` 상태로 남긴다.
```

### 2026-07-02 - Producer Scope Handoff

**By:** Producer

**상태:**
- done

**Actions:**
- 사용자와 D9 첫 구현의 세부 scope를 단계별로 확정했다.
- 런 시작 흐름은 `캐릭터 선택 -> 무기 선택 -> R1 시작` 순서로 확정했다.
- 캐릭터 선택 UI는 최종 이름/직업 없이 `압축형`, `연쇄형`, `전환형` 코드명을 그대로 보여준다.
- 세 캐릭터는 D9 첫 구현에서 같은 광부 외형을 공유하며, 실사용 캐릭터 에셋은 계속 hold한다.
- 캐릭터 선택 카드는 코드명, 한 줄 빌드 문법, 대표 아키타입 tag 2-3개, 약점/대가 1줄만 표시한다.
- 캐릭터별 고유 스탯 보정은 D9 첫 구현에 넣지 않는다.
- 새 아이템/유물은 추가하지 않고, 기존 상점/보상 풀에 metadata와 soft bias만 붙인다.
- 캐릭터 편향은 상점과 보상 둘 다 대상으로 하되, 구현 우선순위는 상점 먼저, 보상은 metadata/debug 기준까지 잡는다.
- 대표 아키타입 tag는 brainstorm의 3개씩 그대로 사용한다.
- D9 debug 출력은 캐릭터별 코드명, 대표 tag, 적용 가능한 D8 무기 3종, 상점/보상 bias 샘플을 한 번에 보여준다.
- D9 첫 구현 완료 기준을 캐릭터 선택 UI, 모든 D8 무기 연결, metadata/bias debug, 실제 UI capture 가독성으로 확정했다.

**Verification:**
- 문서/운영 handoff 작업만 수행했다.
- Godot 구현, 에셋 생성, UI capture, headless load는 실행하지 않았다.

**Questions:**
- 없음. D9 Planner가 plan을 작성하기 위해 사용자에게 먼저 물어야 할 blocking design question은 현재 없다.

**Next Handoff:**
- Planner는 `docs/plans/2026-07-02-feat-m1-d9-character-archetype-matrix-plan.md` 또는 기존 목표 경로 `docs/plans/2026-07-01-feat-m1-d9-character-archetype-matrix-plan.md` 중 하나를 선택해 D9 plan을 작성한다. 새 파일을 만들 때는 현재 날짜인 2026-07-02 경로를 선호한다.
- Developer는 D9 plan이 `ready`가 된 뒤에만 캐릭터 선택 UI, 무기 선택 연결, metadata/debug, 상점/보상 soft bias를 구현한다.
- Asset은 최종 이름/직업/외형 확정 전까지 실사용 캐릭터 에셋을 만들지 않는다.
- Validator는 Developer handoff 이후 debug/smoke/playtest와 실제 UI capture 증거를 확인한다.

**Planner Handoff Prompt:**

```markdown
역할: Bro-exile Planner

읽을 문서:
- `AGENTS.md`
- `.codex/skills/bro-exile-agent-pipeline/SKILL.md`
- `.codex/skills/bro-exile-pixel-perfect/SKILL.md`
- `docs/operations/agent-pipeline-current-state.md`
- `todos/021-pending-p1-m1-d9-character-archetype-matrix.md`
- `docs/brainstorms/2026-06-07-m1-d9-character-archetype-matrix-brainstorm.md`
- `docs/quality/2026-06-30-pixel-perfect-quality-gates.md`

목표:
- D9 구현 plan을 작성한다.
- D9 첫 구현 scope는 캐릭터 선택 UI, 무기 선택 연결, metadata/debug, 상점/보상 soft bias다.
- 런 시작 흐름은 `캐릭터 선택 -> 무기 선택 -> R1 시작`이다.
- 캐릭터 코드명은 `압축형`, `연쇄형`, `전환형`을 그대로 UI에 표시한다.
- 세 캐릭터는 같은 광부 외형을 공유한다.
- 모든 캐릭터는 모든 D8 무기와 조합 가능해야 한다.
- 캐릭터별 고유 스탯 보정, 신규 아이템, 신규 유물, 신규 실사용 캐릭터 에셋은 D9 첫 구현에 포함하지 않는다.

Plan에 포함할 것:
- 캐릭터 선택 카드 필드: 코드명, 한 줄 빌드 문법, 대표 아키타입 tag 2-3개, 약점/대가 1줄.
- 캐릭터별 대표 tag: `압축형` = 처치 폭발/큰 한 방/과충전, `연쇄형` = 연속 명중/관통-전파/상태 누적, `전환형` = 위험 전환/위치-장판/방어 반격.
- `character_bias`, `archetype_tags`, `trigger`, `payload`, `frequency`, `cost` metadata 필드.
- 기존 상점/보상 풀에 metadata와 soft bias를 붙이는 방식. 중립 또는 브릿지 선택지는 유지한다.
- debug 출력 형식: `캐릭터 코드명 -> 대표 tag -> 적용 가능한 무기 3종 -> 상점/보상 bias 샘플`.
- smoke: 각 캐릭터 코드명으로 모든 D8 무기 선택 후 R1 시작 가능.
- capture: 캐릭터 선택 카드 텍스트가 실제 렌더 캡처에서 겹치지 않고 읽히는지 확인.
- playtest: 같은 무기라도 캐릭터에 따라 상점에서 고르고 싶은 카드가 달라졌는지 기록.

쓰기 범위:
- `docs/plans/...m1-d9-character-archetype-matrix-plan.md`
- 이 todo의 Work Log/frontmatter

멈춤 조건:
- 최종 캐릭터 이름/직업/외형을 확정해야 하는 경우.
- 실사용 캐릭터 에셋 생성 또는 promotion이 필요한 경우.
- 신규 아이템/유물 추가가 필요해지는 경우. 이 경우 018 목록 재검토로 넘긴다.

handoff:
- plan 작성 뒤 이 todo Work Log에 `needs-review` 또는 `ready-for-dev` 상태로 남긴다.
```

### 2026-07-12 - Producer Queue Rebaseline Handoff

<!-- pipeline-state
{"artifacts": ["docs/brainstorms/2026-06-07-m1-d9-character-archetype-matrix-brainstorm.md", "docs/operations/agent-pipeline-current-state.md", "docs/quality/2026-06-30-pixel-perfect-quality-gates.md"], "owner_lane": "planning", "routing_reason": "", "status": "pending", "user_gate": "not-requested", "validator_verdict": "not-run"}
-->

**By:** Producer

**상태:**
- pending

**Actions:**
- 기존 D9 scope 결정과 모든 Work Log를 보존한 채 active dispatch를 해제했다.
- 공개 데모의 체크포인트와 화폐 slice가 플레이 가능하게 승인된 뒤 D9를 시작하도록 dependency를 020으로 연결했다.
- 캐릭터 UI/data-first scope 자체는 변경하지 않았다.

**Verification:**
- 큐/상태 계약만 검증한다. D9 Godot/UI 검증은 이 slice 활성화 뒤 수행한다.

**Questions:**
- 없음. 기존 D9 제품 결정은 유효하며 다시 묻지 않는다.

**Next Handoff:**
- 020이 `complete/approved`가 되면 이 todo를 `ready`로 전환하고 기존 D9 결정을 기반으로 Planner에 넘긴다.
