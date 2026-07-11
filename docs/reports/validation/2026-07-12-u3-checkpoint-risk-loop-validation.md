---
date: 2026-07-12
topic: u3-checkpoint-risk-loop-validation
kind: validation
status: passed
---

# U3 체크포인트 위험 선택 루프 검증

## Verdict

- Validator 판정: `passed`.
- 다음 게이트: Product Owner 실제 플레이 승인.
- 발견된 구현/시각 결함: 없음.
- 수동 입력 플레이: 수행하지 않음. Godot 게임 창이 macOS accessibility에 노출되지 않아 자동 입력을 수동 플레이로 간주하지 않았다.

## Execution Evidence

- 프로젝트 headless load: exit 0.
- 순수 규칙 하네스 `--rule=all`: `DEMO_RULE_HARNESS_PASS`.
- `--debug-u3-checkpoint-contract`: `failures=0`; R3/R5/R7 cadence, 재진입 불변성, 지속 위험, 엘리트 success/missed 및 피드백 통과.
- `--smoke-checkpoint-route=safe|risk|shop|elite`: 모두 exit 0. safe만 `37/100 -> 100/100`, 나머지는 `37/100` 유지. 상점 무료 exit 확인.
- missing/unknown/disabled/unchanged route: 각각 즉시 exit 1과 state/options dump. timeout 없음.
- P7 reward/shop/contract/boss/pause/legendary, P8 weapon routes, U2 rule seams: 모두 exit 0.
- pipeline validator unit tests: 9 tests 통과.
- actual Metal renderer elite-marker 회귀: exit 0, `body_ring_pixels=0 expected=0`.

## Pixel-Perfect Evidence

- 체크포인트 overlay: `/private/tmp/orebound-godot-checkpoint-ui.png` (`1280x720`).
- 지속 위험/엘리트 HUD: `/private/tmp/orebound-godot-checkpoint-hud.png` (`1280x720`).
- 실제 Metal renderer에서 두 캡처를 새로 생성했다.
- overlay의 한글 텍스트 픽셀이 실제로 보이고 2x2 카드가 겹치지 않는다.
- 네 카드 모두 구간 범위, 질적 위험, 결과 유형을 읽을 수 있다.
- HUD에서 `런 지속` 위험과 `R6-R7` 엘리트 목표 범위를 동시에 읽을 수 있다.

## Code Review Findings

- R3/R5/R7 reward chain에는 기존 contract/shop tail 중복이 없다.
- 공통 round/shop/next-round transition의 완전 회복은 제거됐고 safe만 완전 회복을 소유한다.
- 선택 후 checkpoint 재진입은 route를 변경하지 않으며 현재 진행을 보존한다.
- persistent risk는 이후 safe 선택 뒤에도 유지되고 elite 목표는 성공 또는 구간 종료 missed로 닫힌다.
- checkpoint elite는 한 번 예약되며 처치 시 45 광석 보너스와 run accounting을 함께 기록한다.
- retry reset은 checkpoint state와 pending risk를 초기화한다.

## Product Owner Question

실제 입력으로 safe/risk/shop/elite를 플레이한 뒤, 위험을 스스로 고른 느낌과 다음 구간 보상 기대가 충분하면 023을 승인한다.

## Post-Simplification Revalidation

- canonical route/segment API, shared `MAX_ROUNDS`, dedicated risk callback, HUD feedback cache, ore accounting helper, enemy-derived kill type로 단순화된 뒤 전체 fast gate를 다시 실행했다.
- 첫 재실행에서 risk smoke가 일반 relic callback을 호출해 persistent risk 없이도 통과하는 false positive를 발견했다. 현재 트리는 `_choose_checkpoint_risk_relic()`을 호출하고 persistent risk가 비어 있으면 실패한다.
- 수정 후 risk smoke는 exit 0과 함께 `persistent_risks=[{"id":"sharpened_throwing","since_round":3}]`를 출력했다.
- project load, pure harness, U3 debug, 네 positive route, 네 fail-fast negative route, P7 reward/contracts/shop/boss/pause, P8, U2, pipeline tests가 모두 기대한 결과로 통과했다.
- 모든 실제 state transition은 cache-invalidating setter를 사용하고, 모든 collected ore 경로는 wallet/round/run totals를 한 helper에서 갱신한다.
- 2026-07-12 03:13:31 Metal 캡처 두 장에서 기존 실제 텍스트 픽셀과 레이아웃 가독성이 유지됐다.
- 최종 판정은 `passed`; 남은 게이트는 Product Owner 실제 플레이 승인이다.
