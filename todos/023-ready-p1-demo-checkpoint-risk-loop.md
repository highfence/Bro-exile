---
status: ready
priority: p1
issue_id: "023"
tags: [public-demo, checkpoint, risk, reward, vertical-slice]
dependencies: ["019"]
milestone: Public Demo
delivery: Checkpoint Risk Slice
chain: risk-reward
quest_title: "공개 데모 체크포인트 위험 선택 루프"
pipeline_slice: true
queue_order: 1
owner_lane: producer
validator_verdict: passed
user_gate: awaiting-user-approval
artifacts:
  - "docs/plans/2026-07-12-001-feat-public-demo-vertical-slice-pipeline-plan.md"
  - "scripts/game/run_rules.gd"
  - "scripts/game/demo_content.gd"
  - "scripts/main.gd"
  - "scripts/ui/game_ui.gd"
  - "scripts/tools/demo_validation_harness.gd"
  - "docs/reports/validation/2026-07-12-u3-checkpoint-risk-loop-validation.md"
last_handoff: "2026-07-12 - U3 R5 Progression Regression Validator Handoff"
routing_reason: ""
---

# 023. 공개 데모 체크포인트 위험 선택 루프

## Quest Card

- 목표: R3, R5, R7 뒤에 안전, 위험, 상점, 엘리트 중 하나를 능동적으로 고르는 플레이 가능한 한 조각을 만든다.
- 플레이어 감정: “현재 빌드로 어디까지 욕심낼지 내가 결정한다.”
- 완료 보상: 위험 선택이 같은 런의 보상을 키우고, 무리한 선택은 납득 가능한 폭사로 이어진다.
- 실패 신호: 선택이 고정 보상 화면처럼 느껴지거나, 안전 선택이 전투 외 회복과 중복되어 항상 정답이 된다.

## Scope

- 구현 기준은 `docs/plans/2026-07-12-001-feat-public-demo-vertical-slice-pipeline-plan.md`의 U2와 U3다.
- 체크포인트 선택은 기존 10라운드 전투를 보존하며 R3, R5, R7의 고정 보상 꼬리를 대체한다.
- 이 slice가 Validator 판정과 Product Owner 승인을 모두 받기 전에는 020 화폐 slice를 활성화하지 않는다.

## Acceptance Criteria

- [x] R3, R5, R7 뒤에 체크포인트 선택이 정확히 한 번 열린다.
- [x] 안전만 완전 회복을 제공하며, 위험/상점/엘리트는 고유한 비용과 이득을 가진다.
- [x] 선택한 위험과 보상이 다음 전투 및 런 종료 요약에서 추적된다.
- [ ] debug, smoke, 실제 플레이, UI capture 증거가 Work Log 또는 validation report에 남는다.
- [ ] 독립 Validator가 판정한 뒤 Product Owner가 실제 빌드를 승인해야 `complete`가 된다.

## Work Log

### 2026-07-12 - Producer Queue Rebaseline Handoff

<!-- pipeline-state
{"artifacts": ["docs/plans/2026-07-12-001-feat-public-demo-vertical-slice-pipeline-plan.md"], "owner_lane": "dev", "routing_reason": "", "status": "ready", "user_gate": "not-requested", "validator_verdict": "not-run"}
-->

**By:** Producer

**상태:**
- ready

**Actions:**
- 공개 데모의 첫 활성 slice로 체크포인트 위험 선택 루프를 지정했다.
- D9의 오래된 active dispatch를 닫고, 구현 순서를 체크포인트부터 시작하도록 재정렬했다.

**Verification:**
- `python3 scripts/tools/test_validate_agent_pipeline.py`
- `python3 scripts/tools/validate_agent_pipeline.py`

**Questions:**
- 없음. U2 characterization gate를 먼저 추가한 뒤 U3 구현으로 진행한다.

**Next Handoff:**
- Developer가 U2/U3 범위의 구현과 증거를 이 Work Log에 남긴다.
- Developer 완료 후 독립 Validator가 판정한다.

### 2026-07-12 - U3 Developer Handoff

<!-- pipeline-state
{"artifacts": ["docs/plans/2026-07-12-001-feat-public-demo-vertical-slice-pipeline-plan.md", "scripts/game/run_rules.gd", "scripts/game/demo_content.gd", "scripts/main.gd", "scripts/ui/game_ui.gd", "scripts/tools/demo_validation_harness.gd"], "owner_lane": "validation", "routing_reason": "", "status": "ready", "user_gate": "not-requested", "validator_verdict": "not-run"}
-->

**By:** Developer

**상태:**
- needs-review

**Actions:**
- R3/R5/R7의 고정 계약-상점 꼬리를 `safe`, `risk`, `shop`, `elite` 체크포인트 라우트로 교체했다. R5/R7의 stat 보상은 체크포인트보다 먼저 유지한다.
- 공통 라운드 종료, 상점 진입, 다음 라운드 시작의 자동 완전 회복을 제거하고 `safe`만 한 번 완전 회복하도록 했다.
- `risk` 계약은 이후 safe를 골라도 런 전체에 남고, `elite` 목표는 지정 구간에 강적을 예약해 처치 시 보너스를 지급하거나 구간 종료 시 missed로 닫힌다.
- 지속 위험과 엘리트 active/success/missed 상태를 HUD와 런 요약에 질적 설명으로 노출했다. 내부 드롭 확률 공식은 UI에 노출하지 않았다.
- 1280x720 체크포인트 카드를 2x2로 배치하고 scope, danger, outcome을 각 카드에 표시했다.

**Changed Files:**
- `scripts/game/run_rules.gd`
- `scripts/game/demo_content.gd`
- `scripts/main.gd`
- `scripts/ui/game_ui.gd`
- `scripts/tools/demo_validation_harness.gd`
- `todos/023-ready-p1-demo-checkpoint-risk-loop.md`
- projection only: `todos/README.md`, `docs/operations/agent-pipeline-current-state.md`

**Verification:**
- Red first: 순수 하네스가 `checkpoint_route_ids`, `open_checkpoint`, `select_checkpoint_route`, `advance_checkpoint_state` 부재 Parse Error로 실패하는 것을 확인했다.
- `HOME=/private/tmp/codex-godot-home /Users/highfence/Dev/.tools/bin/godot --headless --path . res://scenes/tools/demo_validation_harness.tscn -- --rule=all` -> `DEMO_RULE_HARNESS_PASS`.
- `--smoke-checkpoint-route=safe|risk|shop|elite` 각 route -> exit 0, `SMOKE_CHECKPOINT_ROUTE result=PASS`; safe만 37/100에서 100/100으로 회복하고 나머지는 37/100을 유지했다.
- missing, unknown, disabled, unchanged route -> 각각 즉시 exit 1과 state/options dump. timeout 없음.
- `--debug-u3-checkpoint-contract` -> failures=0; R3/R5/R7 route, risk 지속, elite success/missed 및 HUD feedback 확인.
- re-entry proof first: 실제 `_open_checkpoint_choice()` 재호출 계약을 추가한 직후 `failures=2 reopen_nonblocking=false current_reopen_nonblocking=false`로 exit 1을 확인했다.
- re-entry fix 후 같은 명령 -> exit 0, `reopen_nonblocking=true current_reopen_nonblocking=true paused_reopen_immutable=true resumed_reopen_immutable=true`. locked route는 바뀌지 않고 같은 라운드는 기존 진행을 이어가며, 이미 다음 라운드면 현재 전투 상태를 보존한다.
- `--debug-p7-reward-routes`, `--debug-p7-shop-rarity`, `--debug-p7-relic-contracts`, `--debug-p7-boss-patterns`, `--debug-p7-pause-cycle`, `--debug-p7-legendary-aim`, `--debug-p8-weapon-routes`, `--debug-demo-rule-seams` -> exit 0.
- actual renderer `--debug-p7-elite-marker` -> exit 0, `body_ring_pixels=0 expected=0`.
- `HOME=/private/tmp/codex-godot-home /Users/highfence/Dev/.tools/bin/godot --path . -- --capture-checkpoint-ui` -> exit 0, Metal actual renderer, 1280x720.
- 실제 캡처 검사: 카드 4장 텍스트 겹침 없음; scope/danger/outcome 가독; 전투 HUD에서 지속 위험 효과/범위와 엘리트 목표 범위 가독.

**Capture Evidence:**
- checkpoint overlay: `/private/tmp/orebound-godot-checkpoint-ui.png`
- active risk/elite HUD: `/private/tmp/orebound-godot-checkpoint-hud.png`

**Questions:**
- 없음. Product Owner 수동 플레이와 독립 Validator 판정은 수행하지 않았다.

**Next Handoff:**
- Validator가 체크포인트 4개 route, 실패 route, elite 실제 스폰/처치, 캡처 가독성을 독립 검증한다.
- Validator verdict 전에는 status를 `ready`, user gate를 `not-requested`로 유지한다.

### 2026-07-12 - U3 Validator Handoff

<!-- pipeline-state
{"artifacts": ["docs/plans/2026-07-12-001-feat-public-demo-vertical-slice-pipeline-plan.md", "scripts/game/run_rules.gd", "scripts/game/demo_content.gd", "scripts/main.gd", "scripts/ui/game_ui.gd", "scripts/tools/demo_validation_harness.gd", "docs/reports/validation/2026-07-12-u3-checkpoint-risk-loop-validation.md"], "owner_lane": "producer", "routing_reason": "", "status": "ready", "user_gate": "awaiting-user-approval", "validator_verdict": "passed"}
-->

**By:** Validator

**상태:**
- passed

**Actions:**
- U3 코드를 독립 검토해 reward 중복, 회복 소유권, checkpoint 재진입 불변성, elite 만료/보너스, 무료 상점 exit, retry reset 누수를 확인했다.
- actual Metal renderer로 1280x720 checkpoint overlay와 위험/엘리트 HUD를 새로 캡처하고 실제 텍스트 픽셀과 레이아웃을 눈으로 검사했다.
- 상세 증거를 `docs/reports/validation/2026-07-12-u3-checkpoint-risk-loop-validation.md`에 남겼다.

**Verification:**
- `HOME=/private/tmp/codex-u3-load /Users/highfence/Dev/.tools/bin/godot --headless --path . --quit` -> exit 0.
- `HOME=/private/tmp/codex-u3-harness /Users/highfence/Dev/.tools/bin/godot --headless --path . res://scenes/tools/demo_validation_harness.tscn -- --rule=all` -> exit 0, `DEMO_RULE_HARNESS_PASS`.
- `--debug-u3-checkpoint-contract` -> exit 0, `failures=0`; R3/R5/R7, 재진입, persistent risk, elite success/missed 통과.
- `--smoke-checkpoint-route=safe|risk|shop|elite` -> 모두 exit 0. safe만 37/100에서 100/100으로 회복하고 나머지는 37/100을 유지했다. shop은 비용 0 exit로 다음 구간에 도달했다.
- missing/unknown/disabled/unchanged route -> 각각 즉시 exit 1과 state/options dump. timeout 없음.
- P7 reward/shop/contract/boss/pause/legendary, P8 weapon routes, U2 rule seams -> 모두 exit 0.
- `python3 scripts/tools/test_validate_agent_pipeline.py` -> 9 tests 통과.
- actual renderer `--debug-p7-elite-marker` -> Metal, exit 0, `body_ring_pixels=0 expected=0`.
- actual renderer `--capture-checkpoint-ui` -> Metal, exit 0; `/private/tmp/orebound-godot-checkpoint-ui.png`, `/private/tmp/orebound-godot-checkpoint-hud.png`, 두 파일 모두 1280x720.
- 캡처 판정: 실제 한글 텍스트 픽셀이 보이고 2x2 카드가 겹치지 않는다. scope/danger/outcome, `런 지속` 위험, `R6-R7` elite 목표가 읽힌다.

**Questions:**
- Product Owner가 실제 입력으로 네 route를 플레이했을 때 위험 선택이 능동적으로 느껴지고 다음 구간을 이어가고 싶은지 승인해 달라.
- macOS accessibility에서 Godot 게임 창을 찾지 못해 수동 입력 플레이를 수행했다고 주장하지 않는다. 현재 `passed`는 actual renderer와 실제 handler smoke에 대한 Validator 판정이며, 사람 플레이는 별도 user gate다.

**Next Handoff:**
- Producer가 Product Owner에게 023 실제 플레이 단위를 제공한다.
- 승인 전에는 020을 활성화하지 않고 `status: ready`, `owner_lane: producer`, `validator_verdict: passed`, `user_gate: awaiting-user-approval`을 유지한다.

### 2026-07-12 - U3 Post-Simplification Validator Handoff

<!-- pipeline-state
{"artifacts": ["docs/plans/2026-07-12-001-feat-public-demo-vertical-slice-pipeline-plan.md", "scripts/game/run_rules.gd", "scripts/game/demo_content.gd", "scripts/main.gd", "scripts/ui/game_ui.gd", "scripts/tools/demo_validation_harness.gd", "docs/reports/validation/2026-07-12-u3-checkpoint-risk-loop-validation.md"], "owner_lane": "producer", "routing_reason": "", "status": "ready", "user_gate": "awaiting-user-approval", "validator_verdict": "passed"}
-->

**By:** Validator

**상태:**
- passed

**Actions:**
- canonical checkpoint route/segment API, `MAX_ROUNDS` alias, 전용 risk relic callback, state 기반 HUD cache invalidation, 광석 accounting helper, enemy dictionary 기반 처치 기록을 독립 재검토했다.
- 첫 재실행에서 risk smoke가 전용 callback을 검사만 하고 일반 relic callback을 호출해 persistent risk 없이도 통과하는 false positive를 발견했다. 현재 트리는 전용 callback을 호출하고 persistent risk가 비어 있으면 실패하도록 수정됐으며, 수정 후 전체 gate를 다시 실행했다.
- 03:13:31에 생성된 1280x720 Metal 캡처 두 장을 다시 눈으로 검사했다.

**Verification:**
- project headless load, pure `--rule=all` harness, `--debug-u3-checkpoint-contract` -> 모두 exit 0; U3 debug `failures=0`.
- safe/risk/shop/elite route -> 모두 exit 0. risk 결과에 `persistent_risks=[{"id":"sharpened_throwing","since_round":3}]`가 기록됐다.
- missing/unknown/disabled/unchanged route -> 각각 즉시 exit 1과 state/options dump.
- P7 reward/contracts/shop/boss/pause, P8 weapon routes, U2 rule seams -> 모두 exit 0.
- `python3 scripts/tools/test_validate_agent_pipeline.py` -> 9 tests 통과.
- code review: 실제 `run_rule_state` transition은 `_set_run_rule_state()`를 거쳐 HUD cache를 dirty로 만들며, debug reset probe를 제외한 직접 대입이 없다.
- code review: ore pickup, leftover, round clear, checkpoint elite bonus가 `_credit_collected_ore()`로 wallet/round/run totals를 함께 갱신한다.
- code review: `_record_enemy_defeat(enemy)`가 전달된 enemy의 `type`과 `checkpoint_elite`를 함께 사용해 kill type과 elite bonus를 기록한다.
- `/private/tmp/orebound-godot-checkpoint-ui.png`, `/private/tmp/orebound-godot-checkpoint-hud.png` -> 각 1280x720. 실제 한글 픽셀, 2x2 비중첩, scope/danger/outcome, 지속 위험과 elite 범위 가독성 통과.

**Questions:**
- 남은 질문은 Product Owner 실제 입력 플레이 승인뿐이다. Validator는 수동 플레이를 수행했다고 주장하지 않는다.

**Next Handoff:**
- Producer가 Product Owner 승인 또는 변경 요청을 받는다.
- 승인 전에는 020을 활성화하지 않는다.

### 2026-07-12 - U3 R5 Progression Regression Validator Handoff

<!-- pipeline-state
{"artifacts": ["docs/plans/2026-07-12-001-feat-public-demo-vertical-slice-pipeline-plan.md", "scripts/game/run_rules.gd", "scripts/game/demo_content.gd", "scripts/main.gd", "scripts/ui/game_ui.gd", "scripts/tools/demo_validation_harness.gd", "docs/reports/validation/2026-07-12-u3-checkpoint-risk-loop-validation.md"], "owner_lane": "producer", "routing_reason": "", "status": "ready", "user_gate": "awaiting-user-approval", "validator_verdict": "passed"}
-->

**By:** Validator

**상태:**
- passed

**Actions:**
- R3에서 선택한 route가 남아 있는 상태로 R5 보상 체인에 진입하면 체크포인트가 사라지던 회귀 수정을 독립 검증했다.
- 재진입 잠금이 현재 `wave`와 같은 checkpoint에만 적용되어 같은 라운드 선택은 불변으로 유지되고, 과거 R3 선택은 R5의 새 선택을 막지 않는지 확인했다.
- checkpoint reward가 열리기 전에 한 번만 소비되고, R5 선택 시 route history가 한 번만 추가되어 보상이 중복되지 않는 경로를 코드로 검토했다.

**Verification:**
- project headless load와 pure `--rule=all` harness -> exit 0, `DEMO_RULE_HARNESS_PASS`.
- `--debug-u3-checkpoint-contract` -> exit 0, `failures=0`, `later_checkpoint_opens=true`, `reopen_nonblocking=true`, `current_reopen_nonblocking=true`.
- historical R3 risk 뒤 R5 open에서 `checkpoint_round=5`, `selected_route=""`, route options 4개가 새로 열리고 persistent risk는 유지됐다.
- `--smoke-checkpoint-route=safe|risk|shop|elite` -> 모두 exit 0이며 각 route 선택 후 다음 라운드 `mode=play`, `wave=4`에 도달했다. 동일 handler와 비어 있는 R5 pending chain을 사용하는 R5 선택도 `_start_next_round()`로 R6에 진행함을 검토했다.
- P7 reward/shop/contract/boss/pause/legendary, P8 weapon routes, U2 rule seams -> 모두 exit 0.
- reward flow 검토: R5 `stat -> checkpoint`에서 checkpoint step은 `_open_checkpoint_choice()` 호출 전에 `pop_front()`되고, route 선택 경로는 checkpoint step을 다시 추가하지 않는다.

**Questions:**
- Product Owner가 수정 빌드로 R5 이후 진행을 다시 확인해 승인 또는 추가 변경을 요청한다.

**Next Handoff:**
- Producer가 수정 빌드를 다시 실행해 Product Owner 승인 게이트를 재개한다.
- 승인 전에는 `status: ready`, `owner_lane: producer`, `validator_verdict: passed`, `user_gate: awaiting-user-approval`을 유지하고 020을 활성화하지 않는다.
