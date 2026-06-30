---
date: 2026-06-30
topic: pixel-perfect-quality-gates
kind: quality
status: active-reference
---

# Bro-exile Pixel-Perfect 품질 게이트

## 목적

Bro-exile의 픽셀 테스트는 “빌드가 된다”가 아니라 “작은 화면에서 실제로 읽힌다”를 검증한다. 에셋, UI, 애니메이션, 캡처 작업은 headless 성공만으로 완료하지 않고, 48-64px preview와 실제 Godot 렌더 캡처를 증거로 남긴다.

## 기본 계약

- 캐릭터/아이콘/몬스터 후보는 `256x256` 셀 또는 문서화된 고정 셀 계약을 가진다.
- 투명 에셋은 RGBA PNG이며 alpha bbox가 비어 있지 않아야 한다.
- 후보마다 64px preview를 만든다.
- 플레이어/적/아이콘은 실제 게임 배경 위 캡처에서 구분되어야 한다.
- 생성 후보는 승인 전 `assets/candidates/...`에 머물고, 실사용 `assets/sprites/...`를 바로 덮어쓰지 않는다.
- 검증 결과는 todo `Work Log`, `docs/reports/...`, 또는 후보 metadata에 남긴다.

## 에셋 게이트

다음을 확인하지 못하면 실사용 에셋으로 승격하지 않는다.

- `metadata.json` 또는 report에 source, candidate, prompt, preview, capture path가 있다.
- alpha bbox가 비어 있지 않다.
- cell size와 기준선이 의도와 맞는다.
- 64px preview에서 역할이 읽힌다.
- 크로마키 잔여물, halo, 배경 찌꺼기가 눈에 띄지 않는다.
- 애니메이션은 adjacent duplicate frame이 없어야 한다.
- loop 검증에서 `loop_alpha_mismatch_pixels`가 0이거나, 다른 값이면 이유가 기록되어 있다.

## UI 게이트

UI 변경은 실제 렌더 캡처가 필요하다.

- 시작 화면, HUD, 선택 overlay, 상점/보상 화면 중 변경된 상태를 캡처한다.
- 텍스트가 실제로 보이는지 확인한다.
- 버튼/카드/동적 수치가 겹치지 않아야 한다.
- Godot font renderer가 의심되면 `scripts/pixel_ui.gd` 경로의 pixel text fallback을 확인한다.

기본 캡처 예시:

```bash
/Users/highfence/Dev/Sweep/engine/godot/bin/godot.macos.editor.arm64 \
  --log-file /private/tmp/bro-exile-ui-capture.log \
  --path /Users/highfence/Documents/Bro-exile \
  -- --capture-ui
```

## 하네스 게이트

Player harness:

```bash
/Users/highfence/Dev/Sweep/engine/godot/bin/godot.macos.editor.arm64 \
  --log-file /private/tmp/bro-exile-player-harness.log \
  --path /Users/highfence/Documents/Bro-exile \
  --scene res://scenes/tools/player_asset_harness.tscn \
  --quit-after 360 \
  -- \
  --asset-output=/private/tmp/bro-exile-asset-harness \
  --frame-count=8
```

Zombie/enemy harness:

```bash
/Users/highfence/Dev/Sweep/engine/godot/bin/godot.macos.editor.arm64 \
  --log-file /private/tmp/bro-exile-zombie-harness.log \
  --path /Users/highfence/Documents/Bro-exile \
  --scene res://scenes/tools/zombie_asset_harness.tscn \
  --quit-after 360 \
  -- \
  --asset-output=/private/tmp/bro-exile-zombie-harness \
  --source-frame=res://assets/sprites/characters/miner_zombie_v1/zombie_idle.png \
  --motion-profile=shamble \
  --frame-count=8
```

Stage capture:

```bash
/Users/highfence/Dev/Sweep/engine/godot/bin/godot.macos.editor.arm64 \
  --log-file /private/tmp/bro-exile-stage1.log \
  --path /Users/highfence/Documents/Bro-exile \
  -- --capture-stage1
```

## Validator 판정

Validator는 다음 중 하나로 판정한다.

- `passed`: preview, metadata, capture가 모두 있고 acceptance criteria를 통과한다.
- `conditional-pass`: 게임 진행에는 충분하지만 시각 리스크나 후속 보정 항목이 남아 있다.
- `rejected`: 작은 preview나 실제 캡처에서 역할이 읽히지 않거나, metadata/capture 증거가 부족하다.

## Handoff에 반드시 남길 것

- 실행한 명령.
- 생성된 preview/capture/metadata 경로.
- 통과/실패한 gate.
- 사람이 판단해야 하는 취향/아트 방향 질문.
- 다음 owner lane.
