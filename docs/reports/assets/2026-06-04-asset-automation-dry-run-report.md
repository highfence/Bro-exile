---
date: 2026-06-04
kind: asset-automation-dry-run
status: complete
origin: docs/plans/2026-06-04-feat-automated-asset-quality-harness-plan.md
---

# 에셋 자동화 Dry Run 리포트

## Summary

자동 에셋 품질 하네스 계획을 구현하기 전, 현재 저장소에서 수동 dry-run을 돌렸다. 이번 실행은 OpenAI 이미지 생성/API 호출 없이 다음만 확인했다.

- `scripts/main.gd`의 `res://assets/...` 참조 스캔
- 기존 player asset harness 실행
- 기존 zombie asset harness 실행
- `--capture-stage1` 실제 게임 캡처 실행
- headless Godot 실행의 실패/무산출 동작 확인

결론: 현재 player/zombie 하네스와 stage1 캡처는 실제 렌더러에서는 정상 동작한다. 다만 headless에서는 성공 코드로 끝나도 하네스 산출물이 비어 있을 수 있으므로, 자동화 구현 시 exit code만 믿으면 안 된다.

## Commands

### Asset Reference Scan

```bash
rg -o 'res://assets/[^" ]+' scripts/main.gd | sort | uniq -c | sort -nr
```

결과:

- 전체 asset 참조: 30
- 고유 asset 참조: 24
- `assets/sprites/**/metadata.json`: 11

반복 참조된 icon/asset:

```text
3 res://assets/sprites/items/p2_parts/part_carbide_tip.png
2 res://assets/sprites/items/p2_parts/part_piercing_bit.png
2 res://assets/sprites/items/p2_parts/part_rapid_trigger.png
2 res://assets/sprites/items/p2_parts/part_rations.png
2 res://assets/sprites/items/p3_relics/relic_unstable_blast_crystal.png
```

이 반복 참조는 꼭 버그는 아니지만, 자동화 gap detector의 첫 placeholder 후보 신호로 쓰기 좋다. 특히 P7 상점/계약 아이템이 늘어난 상태에서 같은 icon이 여러 디자인 역할에 재사용되고 있다.

### Godot Headless Load

첫 실행:

```bash
/Users/highfence/Dev/Sweep/engine/godot/bin/godot.macos.editor.arm64 \
  --headless \
  --path /Users/highfence/Documents/Bro-exile \
  --quit
```

결과:

- 실패.
- 기본 `user://logs` 로그 파일 생성 실패 후 Godot crash.

두 번째 실행:

```bash
/Users/highfence/Dev/Sweep/engine/godot/bin/godot.macos.editor.arm64 \
  --headless \
  --log-file /private/tmp/bro-exile-headless.log \
  --path /Users/highfence/Documents/Bro-exile \
  --quit
```

결과:

- exit code 0.
- `get_system_ca_certificates` 경고만 출력.
- 자동화에서는 항상 `--log-file /private/tmp/...`를 명시하는 편이 안전하다.

### Headless Harness Attempt

headless로 player/zombie harness를 실행하면 exit code 0으로 끝나지만, metadata와 preview 파일이 생성되지 않았다. 빈 output directory만 만들어졌다.

자동화 hard gate:

- harness command exit code 0만으로 통과 처리하지 않는다.
- expected `metadata.json` 존재를 확인한다.
- expected preview PNG 존재와 파일 크기를 확인한다.
- preview image dimension을 확인한다.
- metadata의 `animations[].verification` 값을 확인한다.

### Player Harness

```bash
/Users/highfence/Dev/Sweep/engine/godot/bin/godot.macos.editor.arm64 \
  --log-file /private/tmp/bro-exile-player-harness-gui.log \
  --path /Users/highfence/Documents/Bro-exile \
  --scene res://scenes/tools/player_asset_harness.tscn \
  --quit-after 360 \
  -- \
  --asset-output=/private/tmp/bro-exile-asset-dry-run \
  --asset-name=player_dry_run \
  --frame-count=8
```

결과:

- `PLAYER_ASSET_HARNESS_DONE`
- output: `/private/tmp/bro-exile-asset-dry-run/player_dry_run`
- variants: `idle_left`, `idle_right`, `move_left`, `move_right`
- frame count: 8
- all variants:
  - `loop_matches_first_frame: true`
  - `loop_alpha_mismatch_pixels: 0`
  - `loop_mean_abs_diff_rgba: 0.0`
  - `adjacent_duplicate_pairs: 0`

Preview:

![player idle preview](/private/tmp/bro-exile-asset-dry-run/player_dry_run/idle_left/idle_left_sheet_8x1_64_preview.png)

## Zombie Harness

```bash
/Users/highfence/Dev/Sweep/engine/godot/bin/godot.macos.editor.arm64 \
  --log-file /private/tmp/bro-exile-zombie-harness-gui.log \
  --path /Users/highfence/Documents/Bro-exile \
  --scene res://scenes/tools/zombie_asset_harness.tscn \
  --quit-after 360 \
  -- \
  --asset-output=/private/tmp/bro-exile-asset-dry-run \
  --asset-name=zombie_dry_run \
  --frame-count=8
```

결과:

- `ZOMBIE_ASSET_HARNESS_DONE`
- output: `/private/tmp/bro-exile-asset-dry-run/zombie_dry_run`
- variants: `idle_left`, `idle_right`, `move_left`, `move_right`
- frame count: 8
- all variants:
  - `loop_matches_first_frame: true`
  - `loop_alpha_mismatch_pixels: 0`
  - `loop_mean_abs_diff_rgba: 0.0`
  - `adjacent_duplicate_pairs: 0`

Preview:

![zombie move preview](/private/tmp/bro-exile-asset-dry-run/zombie_dry_run/move_left/move_left_sheet_8x1_64_preview.png)

## Stage1 Capture

```bash
/Users/highfence/Dev/Sweep/engine/godot/bin/godot.macos.editor.arm64 \
  --log-file /private/tmp/bro-exile-stage1-capture.log \
  --path /Users/highfence/Documents/Bro-exile \
  -- \
  --capture-stage1
```

결과:

- capture: `/private/tmp/orebound-godot-stage1.png`
- image: `1280 x 720`, RGB PNG
- player와 zombie enemy sprites가 실제 게임 배경 위에서 확인된다.

Capture:

![stage1 capture](/private/tmp/orebound-godot-stage1.png)

## Findings

- 현재 자동화 MVP는 image generation 없이도 유의미한 dry-run을 만들 수 있다.
- `scripts/main.gd` asset reference scan만으로도 반복 icon/placeholder 후보를 일부 찾을 수 있다.
- player/zombie harness metadata는 자동 리포트에 바로 쓰기 좋은 형태다.
- Godot harness는 실제 renderer가 필요하다. headless는 exit code 0이어도 산출물이 비어 있을 수 있다.
- 자동화의 첫 hard gate는 command success가 아니라 expected artifact 존재와 metadata 내용이어야 한다.

## Recommended Next Step

다음 구현은 full image generation이 아니라 다음 순서가 좋다.

1. `assets/asset_manifest.json` 초안 작성.
2. asset reference scan dry-run script 작성.
3. harness runner가 expected artifact를 검증하도록 만들기.
4. 이 리포트 형식으로 no-generation report를 자동 작성하기.
5. 그 다음 한 asset 타입에만 candidate generation을 붙이기.

