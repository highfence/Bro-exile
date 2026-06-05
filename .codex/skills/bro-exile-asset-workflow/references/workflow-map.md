# Bro-exile Asset Workflow Map

## 핵심 문서

- `docs/art/agent-asset-workflow.md`: 에이전트용 전체 asset workflow handoff 문서.
- `docs/art/asset-generation-principles.md`: 스타일, 파츠, 생성, 검증 원칙.
- `docs/art/player-asset-harness.md`: 플레이어 Godot harness 사용법.
- `docs/art/prompt-packs/README.md`: prompt pack 공통 규칙.
- `docs/art/prompt-packs/enemy-single-image.md`: single-image enemy prompt pack.
- `docs/plans/2026-06-04-feat-automated-asset-quality-harness-plan.md`: 후보 생성/품질 게이트 계획.
- `docs/reports/assets/2026-06-04-asset-automation-dry-run-report.md`: Godot harness dry-run 결과.
- `docs/reports/assets/2026-06-05-enemy-motion-profile-comparison-report.md`: enemy motion profile 비교 결과.

## 핵심 하네스

- `scripts/tools/asset_workflow_context.py`: 에이전트 handoff context 출력과 기본 asset reference 점검.
- `scripts/tools/asset_candidate_harness.py`: asset reference scan과 single-image candidate normalization.
- `scenes/tools/player_asset_harness.tscn`: 플레이어 파츠 리그를 idle/move sheet로 bake.
- `scenes/tools/zombie_asset_harness.tscn`: single-image enemy를 runtime motion sheet로 preview.

## 핵심 asset paths

- 플레이어 기준 파츠: `assets/sprites/characters/player_helmet_mascot_semilayered_gloves_v1/parts`
- 기본 좀비 기준 이미지: `assets/sprites/characters/miner_zombie_v1/zombie_idle.png`
- P1 runtime enemies v1: `assets/sprites/characters/p1_monsters_runtime_v1`
- P1 runtime enemies v2: `assets/sprites/characters/p1_monsters_runtime_v2`

## 기억할 결정

- 플레이어는 팔/다리 전체가 아니라 장갑/부츠를 별도 파츠로 움직인다.
- 헬멧, 램프, 벨트, 가방은 body/core 쪽에 남겨 identity drift를 줄인다.
- 일반 적은 single image + runtime transform을 기본으로 한다.
- 적 motion은 역할별 profile로 분리한다.
- 후보 생성 자동화는 promotion 자동화가 아니다.
