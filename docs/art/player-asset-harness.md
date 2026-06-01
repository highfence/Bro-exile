---
date: 2026-06-01
topic: player-asset-harness
kind: art-pipeline
status: active-reference
---

# 플레이어 에셋 하네스

## 목적

이 하네스는 지금까지 수동으로 진행하던 플레이어 에셋 제작 과정을 재실행 가능한 형태로 묶는다.

현재 자동화 범위는 다음이다.

- `core_body`, `left_glove`, `right_glove`, `left_boot`, `right_boot` 파츠 리그를 기준으로 사용한다.
- Godot에서 파츠 위치, 회전, 스케일을 움직여 `idle`과 `move` 프레임을 만든다.
- 좌/우 방향은 같은 리그를 미러링해서 만든다.
- 각 애니메이션의 PNG 프레임, 256px 스프라이트 시트, 64px 확인용 시트, `metadata.json`을 생성한다.
- 첫 프레임과 루프 프레임이 맞는지, 인접 프레임이 중복인지 검증 수치를 남긴다.

GIF는 하네스에서 직접 만들지 않는다. Godot에 기본 GIF 인코더가 없기 때문에, 움직이는 프리뷰가 필요하면 생성된 `frames/` 폴더를 외부 도구로 변환한다.

## 실행

기본 출력 위치는 `/private/tmp/bro-exile-asset-harness`다.

```bash
/Users/highfence/Dev/Sweep/engine/godot/bin/godot.macos.editor.arm64 \
  --log-file /private/tmp/bro-exile-asset-harness-godot.log \
  --path /Users/highfence/Documents/Bro-exile \
  --scene res://scenes/tools/player_asset_harness.tscn \
  --quit-after 360
```

출력 위치를 바꾸려면 `--asset-output`을 붙인다.

```bash
/Users/highfence/Dev/Sweep/engine/godot/bin/godot.macos.editor.arm64 \
  --log-file /private/tmp/bro-exile-asset-harness-godot.log \
  --path /Users/highfence/Documents/Bro-exile \
  --scene res://scenes/tools/player_asset_harness.tscn \
  --quit-after 360 \
  -- --asset-output=/private/tmp/bro-exile-asset-harness
```

특정 애니메이션만 뽑을 수도 있다.

```bash
/Users/highfence/Dev/Sweep/engine/godot/bin/godot.macos.editor.arm64 \
  --log-file /private/tmp/bro-exile-asset-harness-godot.log \
  --path /Users/highfence/Documents/Bro-exile \
  --scene res://scenes/tools/player_asset_harness.tscn \
  --quit-after 360 \
  -- --animations=idle_left,move_left
```

## 출력 구조

```text
/private/tmp/bro-exile-asset-harness/
  player_helmet_mascot_semilayered_gloves_v1/
    metadata.json
    idle_left/
      frames/
      idle_left_sheet_24x1_256.png
      idle_left_sheet_24x1_64_preview.png
      metadata.json
    idle_right/
    move_left/
    move_right/
```

## 옵션

- `--asset-name=...`: 출력 하위 폴더 이름.
- `--asset-output=...`: 출력 루트. `res://`와 절대 경로를 모두 사용할 수 있다.
- `--animations=idle_left,idle_right,move_left,move_right`: 생성할 애니메이션 목록.
- `--frame-count=24`: 애니메이션별 프레임 수.
- `--cell-size=256`: 게임용 시트 셀 크기.
- `--preview-cell-size=64`: 확인용 시트 셀 크기.

## 현재 하네스의 계약

하네스는 다음 레이어 순서를 게임용 계약으로 본다.

1. `shadow`
2. `back_gloves`
3. `boots`
4. `body`
5. `front_gloves`

플레이어 파츠는 현재 `assets/sprites/characters/player_helmet_mascot_semilayered_gloves_v1/parts`를 사용한다.

## 에셋 제작 흐름에서의 위치

1. AI 또는 수동 작업으로 기준 캐릭터와 파츠를 만든다.
2. 파츠를 `player_idle_rig.tscn`에 연결하고 위치를 조정한다.
3. 하네스를 실행해 `idle_left`, `idle_right`, `move_left`, `move_right`를 생성한다.
4. 64px preview와 `metadata.json` 검증 값을 본다.
5. 마음에 들면 출력물을 `assets/sprites/characters/...` 아래의 새 버전 폴더로 복사하고 게임 코드에서 참조한다.

이 하네스는 최종 아트 제작기라기보다, “현재 파츠 리그가 실제 게임용 시트로 bake될 수 있는가”를 빠르게 확인하는 검증 장치다.
