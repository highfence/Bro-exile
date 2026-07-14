---
status: complete
priority: p2
issue_id: "020"
github_issue: "https://github.com/highfence/Bro-exile/issues/1"
tags: [prototype, m1, d11, economy, currency, shop, design]
dependencies: ["019", "023"]
milestone: M1
delivery: D11
chain: economy
quest_title: "M1-D11 다중 화폐 경제"
pipeline_slice: true
queue_order: 2
owner_lane: producer
validator_verdict: passed
user_gate: approved
artifacts:
  - "docs/plans/2026-07-13-001-feat-multi-currency-playable-slice-plan.md"
  - "docs/plans/2026-07-12-001-feat-public-demo-vertical-slice-pipeline-plan.md"
  - "todos/011-pending-p2-shop-and-reward-choice-pass.md"
  - "todos/018-pending-p2-upgrade-item-relic-review.md"
  - "scripts/game/demo_content.gd"
  - "scripts/game/economy_rules.gd"
  - "scripts/game/run_rules.gd"
  - "scripts/main.gd"
  - "scripts/tools/demo_validation_harness.gd"
  - "scripts/tools/measure_currency_distribution.py"
  - "scripts/ui/game_ui.gd"
  - "docs/reports/validation/2026-07-14-multi-currency-playable-slice-validation.md"
last_handoff: "2026-07-14 - Product Owner Approval"
routing_reason: ""
---

# 020. M1-D11 다중 화폐 경제

## Quest Card

- 목표: 하나의 광석 경제를 여러 목적별 화폐로 나누는 방향을 검토한다.
- 플레이어 감정: “이번 런에서 어떤 자원을 노릴지에 따라 상점과 성장이 달라진다.”
- 완료 보상: 리롤, 능력 획득, 장비 강화가 같은 통화 경쟁을 하지 않게 된다.
- 실패 신호: 화폐가 늘었지만 선택이 깊어지지 않고 관리 부담만 커진다.

## Problem Statement

현재 경제는 광석 중심으로 통합되어 있어 상점 리롤, 능력 구매, 장비 강화가 모두 같은 자원을 사용하게 될 가능성이 높다. 사용자는 POE처럼 화폐가 쓰임에 따라 나뉘고, 각 화폐가 유물/콘텐츠/위험 보상과 연결되는 구조를 원한다.

## Findings

- 공개 데모 첫 세분화는 023 체크포인트 slice 승인 뒤 진행하고, 011 상점/보상 선택과 018 강화 sink를 같은 playable slice에 흡수한다.
- 첫 설계에서는 너무 많은 화폐보다 3종 안팎의 목적 분리가 적절하다.
- 후보 역할은 상점 리롤, 능력/부품 획득, 장비 강화다.
- 계약 보상은 직접 능력치 상승보다 위험한 몹을 잡았을 때의 보상 품질 상승과 연결되는 쪽이 더 적절하다.

## Proposed Solutions

### Option 1: 3화폐 첫 검증

리롤 화폐, 능력 화폐, 강화 화폐만 먼저 도입한다.

- 장점: 목적이 선명하고 구현 범위가 낮다.
- 단점: POE식 변환/제작 깊이는 아직 약하다.

### Option 2: 3화폐 + 희귀 변환 재료

기본 3화폐에 상점 선택지를 바꾸거나 등급을 조정하는 희귀 재료를 추가한다.

- 장점: 장기 경제 방향이 조금 더 보인다.
- 단점: D11 첫 검증치고 변수가 늘어난다.

## Recommended Action

023 체크포인트 slice 승인 뒤 3화폐의 source와 sink를 한 판에서 함께 검증한다. 이 playable slice가 승인된 뒤 D9 캐릭터, D10 시뮬레이션으로 넘어간다.

## Acceptance Criteria

- [ ] D8 무기 체계와 충돌하지 않는 화폐 역할을 정한다.
- [ ] 상점 리롤, 능력 획득, 장비 강화의 지불 자원이 분리되어 있다.
- [ ] 계약/위험 보상이 어떤 화폐 품질을 올리는지 정리되어 있다.
- [ ] 첫 구현 범위와 보류할 장기 경제 요소가 분리되어 있다.

## Work Log

### 2026-06-05 - Todo Capture

**By:** Codex

**Actions:**
- 다중 화폐 경제 방향을 M1-D9 pending todo로 기록했다.
- 이후 캐릭터/아키타입 매트릭스를 먼저 정리하기로 하면서 이 todo를 M1-D10으로 이동했다.
- 숙련도별 자동 시뮬레이션을 먼저 만들기로 하면서 이 todo를 M1-D11로 한 번 더 이동했다.
- D11 세분화는 D8, D9, D10, 018 완료 이후 진행하도록 의존성을 걸었다.

**Learnings:**
- 경제 시스템은 무기/아이템 체계가 흔들리는 동안 먼저 세분화하면 다시 바뀔 가능성이 크다.

### 2026-07-12 - Producer Queue Rebaseline Handoff

<!-- pipeline-state
{"artifacts": ["docs/plans/2026-07-12-001-feat-public-demo-vertical-slice-pipeline-plan.md", "todos/011-pending-p2-shop-and-reward-choice-pass.md", "todos/018-pending-p2-upgrade-item-relic-review.md"], "owner_lane": "planning", "routing_reason": "", "status": "pending", "user_gate": "not-requested", "validator_verdict": "not-run"}
-->

**By:** Producer

**상태:**
- pending

**Actions:**
- 기존 020, 011, 018을 하나의 플레이 가능한 화폐 source/sink slice로 묶었다.
- 공개 데모 큐에서 023 체크포인트 slice 다음, D9 캐릭터 slice 이전으로 이동했다.
- 과거 D11 명칭과 Work Log는 역사로 보존하고, 첫 구현은 3화폐의 획득과 소비가 한 판 안에서 닫히는 범위로 제한한다.

**Verification:**
- 큐/상태 계약만 검증한다. 경제 구현 검증은 이 slice 활성화 뒤 수행한다.

**Questions:**
- 023 Product Owner 승인 뒤 Planner가 화폐 이름과 수치를 구현 시점에 확정한다.

**Next Handoff:**
- 023이 `complete/approved`가 되면 이 todo를 `ready`로 바꾸고 Planner에 넘긴다.

### 2026-07-13 - Producer Activation Handoff

<!-- pipeline-state
{"artifacts": ["docs/plans/2026-07-12-001-feat-public-demo-vertical-slice-pipeline-plan.md", "todos/011-pending-p2-shop-and-reward-choice-pass.md", "todos/018-pending-p2-upgrade-item-relic-review.md"], "owner_lane": "planning", "routing_reason": "", "status": "ready", "user_gate": "not-requested", "validator_verdict": "not-run"}
-->

**By:** Producer

**상태:**
- ready

**Actions:**
- 선행 023이 Product Owner 승인으로 닫혀 다음 공개 데모 slice로 활성화했다.
- 현재 저장 지점에서는 Planner dispatch나 경제 구현을 시작하지 않는다.

**Verification:**
- pipeline consistency validator로 023 완료와 020 단일 ready 상태를 확인한다.

**Next Handoff:**
- 다음 작업 재개 시 Planner가 3화폐 source/sink 계약과 discovery-first 획득 구조를 구체화한다.

### 2026-07-13 - Planner Implementation Handoff

<!-- pipeline-state
{"artifacts": ["docs/plans/2026-07-13-001-feat-multi-currency-playable-slice-plan.md", "docs/plans/2026-07-12-001-feat-public-demo-vertical-slice-pipeline-plan.md", "todos/011-pending-p2-shop-and-reward-choice-pass.md", "todos/018-pending-p2-upgrade-item-relic-review.md"], "owner_lane": "dev", "routing_reason": "", "status": "ready", "user_gate": "not-requested", "validator_verdict": "not-run"}
-->

**By:** Planner

**상태:**
- ready

**Actions:**
- `광석/ore`는 part·item 구매, `촉매/catalyst`는 상점 리롤, `강화핵/forge_core`는 스타터 무기 단련에만 쓰는 3-wallet 계약을 고정했다.
- 일반 좀비·거미·방패는 광석, 빠른·투척·독·자폭 위협은 촉매, 엘리트와 중간 보스는 강화핵을 주 source로 두고 정확한 표와 확률은 player UI에서 숨긴다.
- U4 source/accounting과 U5 세 sink를 내부 단계로 구현하되 런타임에서는 함께 활성화해 sinkless currency가 플레이어에게 드롭되지 않게 했다.
- 강화핵 첫 sink는 별도 3축 강화 트리 대신 무기별 고정 단련 recipe와 `upgrade_rank III`로 제한했다.
- 10라운드는 마지막 상점 뒤이므로 spend currency drop을 막고, 첫 런의 발견을 두 번째 런의 목표 파밍으로 사용하는 수동 검증을 acceptance gate에 추가했다.
- 현재 choice handler의 stale callback과 중복 결제를 막기 위해 stable option ID와 `choice_generation` 검증을 구현 계약에 포함했다.

**Verification:**
- `ce-doc-review`의 coherence, feasibility, product, design, scope, adversarial 관점으로 plan을 검토하고 구현 범위·검증 명령·중복 거래·기대값 fixture·다음 런 discovery 누락을 반영했다.
- `env HOME=/private/tmp/bro-exile-godot-home /Users/highfence/Dev/.tools/bin/godot --headless --path /Users/highfence/Dev/Bro-exile --quit` exit 0.
- economy harness가 `DEMO_RULE_HARNESS_PASS`, main seam이 `DEBUG_DEMO_RULE_SEAMS failures=0`을 출력했다.

**Questions:**
- 없음. 표시명과 밸런스 seed는 capture와 대표 플레이에서 조정할 수 있지만 `ore/catalyst/forge_core` 역할과 source/sink 동시 활성화 범위는 Developer 입력으로 고정한다.

**Next Handoff:**
- Developer가 `docs/plans/2026-07-13-001-feat-multi-currency-playable-slice-plan.md`의 Phase 1–5를 구현하고 자동 결과, capture 경로, 실제 플레이 메모를 이 todo에 append한 뒤 `owner_lane: validation`으로 넘긴다.
- 사용자 미커밋 변경인 `docs/README.md`와 `docs/brainstorms/2026-06-07-m1-d9-character-archetype-matrix-brainstorm.md`는 수정하거나 commit scope에 포함하지 않는다.

### 2026-07-14 - Developer Implementation Handoff

<!-- pipeline-state
{"artifacts": ["docs/plans/2026-07-13-001-feat-multi-currency-playable-slice-plan.md", "docs/plans/2026-07-12-001-feat-public-demo-vertical-slice-pipeline-plan.md", "todos/011-pending-p2-shop-and-reward-choice-pass.md", "todos/018-pending-p2-upgrade-item-relic-review.md", "scripts/game/demo_content.gd", "scripts/game/economy_rules.gd", "scripts/game/run_rules.gd", "scripts/main.gd", "scripts/tools/demo_validation_harness.gd", "scripts/ui/game_ui.gd"], "owner_lane": "validation", "routing_reason": "", "status": "ready", "user_gate": "not-requested", "validator_verdict": "not-run"}
-->

**By:** Developer

**상태:**
- needs-review

**Actions:**
- `ore`, `catalyst`, `forge_core`를 registry 기반 typed wallet으로 도입하고 enemy primary drop, pickup, leftover 회수, reset, report까지 하나의 ledger로 연결했다.
- 광석 part/item 구매, 촉매 리롤, 강화핵 스타터 무기 단련을 같은 runtime에 열고 단련은 무기별 고정 recipe와 rank III cap으로 제한했다.
- `choice_generation`과 stable ID를 도입하고 handler가 전달된 option이 아니라 현재 active option을 canonical source로 사용하게 해 stale, duplicate, 변조 가격을 효과·차감 전에 거부했다.
- 라운드 고정 광석은 R1 6, R2 6으로만 제한하고 좀비·거미 drop을 각각 확정 2개로 조정해 적 사냥이 주 수입원이 되게 했다.
- HUD의 세 wallet pill, 화폐별 pickup shape, 상점 3열 비용 카드, 승리·패배 ledger report를 1280×720에서 확인했다.

**Verification:**
- `DEMO_RULE_HARNESS_PASS`: fixed ore share `0.25`, first shop budget `16`, source/sink/typed cost/reset/10라운드 계약 통과.
- `DEBUG_U4_CURRENCY_CONTRACT failures=0`: 세 source→pickup→wallet→sink, exact payment, stale·duplicate·변조 option, unknown pickup, death 미수거, 세 단련 recipe 통과.
- 곡괭이·네일건·랜턴 full smoke가 모두 10라운드 승리했다. 고정 광석 비중은 각각 `12/34`, `12/56`, `12/61`이었다.
- safe/risk/shop/elite checkpoint smoke, U3 checkpoint/balance, P7 reward/rarity/relic/boss/pause/legendary, P8 weapon route가 모두 exit 0 또는 `failures=0`이었다.
- 실제 capture: `/private/tmp/orebound-godot-shop-ui.png`, `/private/tmp/orebound-godot-combat-feedback.png`, `/private/tmp/orebound-godot-run-report-ui.png`, `/private/tmp/orebound-godot-p7-game-over-summary.png`, `/private/tmp/orebound-godot-checkpoint-hud.png`, `/private/tmp/orebound-godot-checkpoint-ui.png`.
- `git diff --check` 통과. 기존 사용자 변경 `docs/README.md`, D9 brainstorm은 수정하지 않았다.

**Questions:**
- 자동·시각 검증 뒤 남은 gate는 같은 플레이어가 두 런을 연속 플레이해 첫 런의 적→화폐 가설을 두 번째 런의 목표 파밍에 쓰는지 확인하는 것이다.

**Next Handoff:**
- Validator가 자동 명령과 capture를 독립 재검증하고 `passed`, `conditional-pass`, `rejected` 중 하나로 판정한다.

### 2026-07-14 - Validator Pass Handoff

<!-- pipeline-state
{"artifacts": ["docs/plans/2026-07-13-001-feat-multi-currency-playable-slice-plan.md", "docs/plans/2026-07-12-001-feat-public-demo-vertical-slice-pipeline-plan.md", "todos/011-pending-p2-shop-and-reward-choice-pass.md", "todos/018-pending-p2-upgrade-item-relic-review.md", "scripts/game/demo_content.gd", "scripts/game/economy_rules.gd", "scripts/game/run_rules.gd", "scripts/main.gd", "scripts/tools/demo_validation_harness.gd", "scripts/ui/game_ui.gd", "docs/reports/validation/2026-07-14-multi-currency-playable-slice-validation.md"], "owner_lane": "producer", "routing_reason": "", "status": "ready", "user_gate": "awaiting-user-approval", "validator_verdict": "passed"}
-->

**By:** Validator

**상태:**
- passed

**Actions:**
- Developer handoff의 typed wallet, source/sink, 단련, choice safety, balance 계약을 자동·시각 경로에서 별도 판정했다.
- correctness/adversarial review에서 발견된 가격·option canonicalization·고정 광석 과점·fractional ledger 문제의 수정과 회귀 테스트를 확인했다.
- 실제 Godot capture에서 HUD, 상점, 전투 pickup, 승리·패배 report의 1280×720 가독성을 확인했다.

**Verification:**
- 상세 결과는 `docs/reports/validation/2026-07-14-multi-currency-playable-slice-validation.md`에 기록했다.
- 자동 하네스, U4 contract, 스타터 세 full smoke, checkpoint 네 route, U3/P7/P8 회귀, pipeline validator가 모두 통과했다.

**Questions:**
- Product Owner는 같은 플레이어 두 런에서 첫 런의 적→화폐 가설을 두 번째 런의 목표 파밍에 사용했는지 확인해야 한다.

**Next Handoff:**
- Product Owner가 실제 두 런을 플레이하고 keep/adjust/cut 피드백을 남긴다. 승인 전에는 다음 021 slice를 활성화하지 않는다.

### 2026-07-14 - Product Owner Currency Distribution Feedback

<!-- pipeline-state
{"artifacts": ["docs/plans/2026-07-13-001-feat-multi-currency-playable-slice-plan.md", "docs/plans/2026-07-12-001-feat-public-demo-vertical-slice-pipeline-plan.md", "todos/011-pending-p2-shop-and-reward-choice-pass.md", "todos/018-pending-p2-upgrade-item-relic-review.md", "scripts/game/demo_content.gd", "scripts/game/economy_rules.gd", "scripts/game/run_rules.gd", "scripts/main.gd", "scripts/tools/demo_validation_harness.gd", "scripts/ui/game_ui.gd", "docs/reports/validation/2026-07-14-multi-currency-playable-slice-validation.md"], "owner_lane": "planning", "routing_reason": "", "status": "ready", "user_gate": "changes-requested", "validator_verdict": "passed"}
-->

**By:** Product Owner / Producer

**상태:**
- needs-revision

**Actions:**
- 현재 플레이에서 촉매가 너무 많이, 광석이 너무 적게 떨어진다는 피드백을 기록했다.
- 일반 적이 광석 또는 촉매를 무조건 떨어뜨리는 확정 mapping 대신 enemy family별 가중치가 다른 경향성 distribution으로 바꾸는 방향을 고정했다.
- 희귀 수직 성장 재료인 강화핵의 보장성은 이번 피드백에서 변경하지 않고 일반 화폐인 광석·촉매 분포를 먼저 조정한다.

**Verification:**
- 기존 승인 대기 빌드의 full smoke 기준 획득량은 곡괭이 `광석 34 / 촉매 11`, 네일건 `56 / 25`, 랜턴 `61 / 35`였다.
- 자동 수치만으로 체감 목표를 확정하지 않고 Product Owner가 승인한 분포 목표를 새 fixture로 고정한다.

**Questions:**
- 권장 첫 목표는 일반 화폐 총량 중 광석 `70–80%`, 촉매 `20–30%`이며, 광석 성향 적은 `ore 75% / catalyst 10% / no drop 15%`, 촉매 성향 적은 `ore 35% / catalyst 45% / no drop 20%`로 시작하는 것이다.

**Next Handoff:**
- 현재 미커밋 multi-currency baseline을 저장한 뒤 Planner가 분포 목표와 측정 spec을 확정하고 Developer가 serial balance experiment를 실행한다.

### 2026-07-14 - Developer Currency Distribution Revision

<!-- pipeline-state
{"artifacts": ["docs/plans/2026-07-13-001-feat-multi-currency-playable-slice-plan.md", "docs/plans/2026-07-12-001-feat-public-demo-vertical-slice-pipeline-plan.md", "todos/011-pending-p2-shop-and-reward-choice-pass.md", "todos/018-pending-p2-upgrade-item-relic-review.md", "scripts/game/demo_content.gd", "scripts/game/economy_rules.gd", "scripts/game/run_rules.gd", "scripts/main.gd", "scripts/tools/demo_validation_harness.gd", "scripts/tools/measure_currency_distribution.py", "scripts/ui/game_ui.gd", "docs/reports/validation/2026-07-14-multi-currency-playable-slice-validation.md"], "owner_lane": "validation", "routing_reason": "", "status": "ready", "user_gate": "changes-requested", "validator_verdict": "not-run"}
-->

**By:** Developer

**상태:**
- needs-review

**Actions:**
- 일반 적의 확정 화폐 mapping을 처치당 하나의 weighted outcome으로 교체했다.
- 광석 성향 family는 `ore 75% / catalyst 10% / no drop 15%`, 촉매 성향 family는 `ore 30% / catalyst 50% / no drop 20%`를 사용한다.
- 위험 계약의 기존 currency multiplier는 해당 적의 선호 화폐 weight를 높여 목표 파밍 보상으로 연결했다.
- 강화핵의 엘리트·중간 보스 source와 단련 sink는 변경하지 않았다.

**Verification:**
- deterministic 측정에서 광석 `76.9%`, 촉매 `23.1%`, 무드롭 `17.4%`, 기대 리롤 `3.12회`, 첫 상점 기대 예산 `15`를 확인했다.
- 두 번의 serial experiment에서 `distribution_error`를 `0.109883 → 0.038803`으로 낮췄고 모든 balance gate를 통과했다.
- Godot headless load, `DEMO_RULE_HARNESS_PASS`, `DEBUG_U4_CURRENCY_CONTRACT failures=0`, `git diff --check`를 통과했다.

**Next Handoff:**
- Validator가 실제 RNG를 포함한 스타터 3종 full smoke와 source/sink 회귀를 재검증한다.

### 2026-07-14 - Validator Currency Distribution Pass

<!-- pipeline-state
{"artifacts": ["docs/plans/2026-07-13-001-feat-multi-currency-playable-slice-plan.md", "docs/plans/2026-07-12-001-feat-public-demo-vertical-slice-pipeline-plan.md", "todos/011-pending-p2-shop-and-reward-choice-pass.md", "todos/018-pending-p2-upgrade-item-relic-review.md", "scripts/game/demo_content.gd", "scripts/game/economy_rules.gd", "scripts/game/run_rules.gd", "scripts/main.gd", "scripts/tools/demo_validation_harness.gd", "scripts/tools/measure_currency_distribution.py", "scripts/ui/game_ui.gd", "docs/reports/validation/2026-07-14-multi-currency-playable-slice-validation.md"], "owner_lane": "producer", "routing_reason": "", "status": "ready", "user_gate": "awaiting-user-approval", "validator_verdict": "passed"}
-->

**By:** Validator

**상태:**
- passed

**Actions:**
- weighted profile 계약, runtime outcome, typed wallet, 기존 sink, 강화핵 보장 source를 독립 재검증했다.
- 확률 변경으로 낡은 U4 확정 드롭 fixture를 weighted runtime probe로 보정하고 회귀 통과를 확인했다.

**Verification:**
- 곡괭이·네일건·랜턴 full smoke가 모두 10라운드 승리했다.
- 세 런 합계는 광석 `144`, 촉매 `38`로 일반 화폐 비중이 광석 `79.1%`, 촉매 `20.9%`였다.
- 곡괭이/네일건/랜턴은 각각 리롤 `1/1/2회`, 구매 `2/3/3회`, 단련 I을 완료했다.
- 자세한 결과는 `docs/reports/validation/2026-07-14-multi-currency-playable-slice-validation.md`에 갱신했다.

**Questions:**
- Product Owner가 실제 플레이에서 광석 부족과 촉매 과잉이 완화됐는지, 적 family의 경향성이 정확한 확률 공개 없이도 읽히는지 확인해야 한다.

**Next Handoff:**
- Product Owner가 한 런을 플레이하고 keep/adjust/cut으로 판정한다. 승인 전에는 021을 활성화하지 않는다.

### 2026-07-14 - Product Owner Approval

<!-- pipeline-state
{"artifacts": ["docs/plans/2026-07-13-001-feat-multi-currency-playable-slice-plan.md", "docs/plans/2026-07-12-001-feat-public-demo-vertical-slice-pipeline-plan.md", "todos/011-pending-p2-shop-and-reward-choice-pass.md", "todos/018-pending-p2-upgrade-item-relic-review.md", "scripts/game/demo_content.gd", "scripts/game/economy_rules.gd", "scripts/game/run_rules.gd", "scripts/main.gd", "scripts/tools/demo_validation_harness.gd", "scripts/tools/measure_currency_distribution.py", "scripts/ui/game_ui.gd", "docs/reports/validation/2026-07-14-multi-currency-playable-slice-validation.md"], "owner_lane": "producer", "routing_reason": "", "status": "complete", "user_gate": "approved", "validator_verdict": "passed"}
-->

**By:** Product Owner / Producer

**상태:**
- done

**Actions:**
- Product Owner가 weighted currency distribution 빌드를 직접 플레이하고 현재 상태가 나쁘지 않다고 승인했다.
- 추가 문제가 생기면 같은 분포 측정기와 플레이 리포트를 기준으로 재조정하기로 하고 020을 일단락했다.

**Verification:**
- 승인 직전 상태는 Validator `passed`, 실제 3무기 smoke 광석 `79.1%` / 촉매 `20.9%`, Product Owner 직접 플레이 완료다.

**Questions:**
- 없음. 이후 체감 문제가 재현되면 별도 revision으로 다시 연다.

**Next Handoff:**
- 021 캐릭터 3종과 빌드 아키타입 매트릭스를 다음 active slice로 전환한다.
