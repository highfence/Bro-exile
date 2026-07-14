---
name: bro-exile-asset-workflow
description: This skill should be used when creating, reviewing, normalizing, animating, documenting, or promoting Bro-exile game assets, especially player/enemy sprites, single-image runtime enemies, Godot asset harness outputs, prompt packs, and cross-agent asset workflow handoffs.
---

# Bro-exile Asset Workflow

## 목적

Bro-exile의 에셋 제작 맥락을 잃지 않고 이어받기 위해 사용한다. 플레이어, 좀비, P1 몬스터, 무기/아이템 아이콘, prompt pack, Godot harness, candidate review, promotion 작업을 할 때 이 skill을 먼저 적용한다.

핵심 원칙은 다음이다.

- Brotato는 리소스 구조와 운영 방식만 참고하고 형태, 실루엣, 캐릭터, 아이콘, 장식을 복제하지 않는다.
- 게임의 얼굴은 귀엽고 약간 기괴한 광산 생존 장난감 톤이다.
- 플레이어는 승인된 semi-layered 파츠 리그를 우선한다.
- 일반 적은 완성 스프라이트 시트보다 single-image sprite plus runtime motion을 우선한다.
- 자동화는 후보를 만들고 검증 리포트를 남기는 도구이며, 사람이 승인하기 전에는 실사용 에셋을 교체하지 않는다.

## 시작 절차

1. `scripts/tools/asset_workflow_context.py --format markdown`를 실행해 현재 asset workflow 진입점을 확인한다.
2. `docs/art/agent-asset-workflow.md`를 읽어 전체 제작 흐름과 handoff 계약을 확인한다.
3. `docs/art/asset-generation-principles.md`를 읽어 스타일, 파츠, 검증 원칙을 확인한다.
4. `docs/quality/2026-06-30-pixel-perfect-quality-gates.md`를 읽어 preview, alpha bbox, capture gate를 확인한다.
5. 작업 유형에 맞춰 다음 문서만 추가로 연다.
   - 플레이어 파츠/애니메이션: `docs/art/player-asset-harness.md`
   - 적 single-image 후보: `docs/art/prompt-packs/enemy-single-image.md`
   - 자동 후보/품질 게이트: `docs/plans/2026-06-04-feat-automated-asset-quality-harness-plan.md`
   - enemy motion profile 조정: `docs/reports/assets/2026-06-05-enemy-motion-profile-comparison-report.md`
5. `git status --short --branch`로 사용자의 기존 변경을 확인하고, 관련 없는 변경은 건드리지 않는다.

## 작업 선택

플레이어 캐릭터나 플레이어 애니메이션이면 다음 흐름을 따른다.

1. 승인된 기준 파츠 경로 `assets/sprites/characters/player_helmet_mascot_semilayered_gloves_v1/parts`를 확인한다.
2. 장갑과 부츠를 코드/리그에서 움직이고, 본체에는 헬멧, 램프, 벨트, 가방을 유지한다.
3. `scenes/tools/player_asset_harness.tscn`을 실행해 `idle_left`, `idle_right`, `move_left`, `move_right` 프레임과 preview를 생성한다.
4. 64px preview, loop metadata, adjacent duplicate metadata를 확인한다.
5. 마음에 드는 결과만 새 버전 폴더로 승격하고 게임 코드 참조를 바꾼다.

일반 적이나 P1 몬스터면 다음 흐름을 따른다.

1. 한 장의 readable full-frame enemy PNG를 만든다.
2. `scripts/tools/asset_candidate_harness.py normalize-single-image`로 chroma-key 제거, RGBA 변환, 256px packing, 64px preview, metadata를 만든다.
3. `scenes/tools/zombie_asset_harness.tscn`으로 runtime motion preview를 만든다.
4. 적 역할에 맞는 motion profile을 선택한다: `shamble`, `sprint`, `brace`, `heavy`, `skitter`, `throw`.
5. `--capture-stage1` 또는 `--capture-monster-roster`로 실제 게임 배경 위 가독성을 확인한다.

무기, 아이템, 이펙트면 다음 흐름을 따른다.

1. 캐릭터 본체와 분리된 독립 에셋으로 만든다.
2. 48-64px에서 역할이 읽히는지 먼저 확인한다.
3. `assets/candidates/...`와 `docs/reports/assets/...`에 후보와 리포트를 남긴다.
4. 승인 전에는 `assets/sprites/...` 실사용 경로를 덮어쓰지 않는다.

## 필수 명령

항상 `--log-file /private/tmp/...`를 붙여 Godot 로그 경로 문제를 피한다.

```bash
python3 scripts/tools/asset_workflow_context.py --format markdown
python3 scripts/tools/asset_candidate_harness.py scan --script scripts/main.gd
```

```bash
/Users/highfence/Dev/Sweep/engine/godot/bin/godot.macos.editor.arm64 \
  --headless \
  --log-file /private/tmp/bro-exile-headless.log \
  --path /Users/highfence/Documents/Bro-exile \
  --quit
```

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

```bash
/Users/highfence/Dev/Sweep/engine/godot/bin/godot.macos.editor.arm64 \
  --log-file /private/tmp/bro-exile-stage1.log \
  --path /Users/highfence/Documents/Bro-exile \
  -- \
  --capture-stage1
```

## 검증 기준

다음 조건을 통과하지 못하면 실사용 에셋으로 승격하지 않는다.

- 투명 RGBA PNG 또는 정상 alpha 제거된 chroma-key 결과여야 한다.
- 256px cell과 64px preview가 있어야 한다.
- alpha bbox가 비어 있지 않고, 실루엣이 cell에 너무 작거나 크게 들어가지 않아야 한다.
- preview에서 역할이 읽혀야 한다.
- 애니메이션은 loop frame과 first frame이 맞고 adjacent duplicate pair가 없어야 한다.
- Godot renderer에서 실제 harness output이 생성되어야 한다. headless exit code 0만으로 성공 처리하지 않는다.
- 실제 stage capture에서 플레이어, 적, 배경, 투사체가 서로 읽혀야 한다.
- Pixel-perfect gate 결과를 todo Work Log 또는 report에 남겨야 한다.

## 금지

- Brotato 원본 에셋을 복사하거나, 형태/실루엣/장식을 직접 따라 하지 않는다.
- "Brotato 스타일로 만들어줘" 같은 모호한 prompt를 최종 prompt로 쓰지 않는다.
- AI가 만든 완성 스프라이트 시트를 검증 없이 바로 실사용 경로에 넣지 않는다.
- 자동 색상 분해 결과만으로 플레이어 파츠가 production-ready라고 판단하지 않는다.
- 사용자가 승인하지 않은 후보를 `main` asset으로 자동 promotion하지 않는다.

## Handoff

작업이 끝나면 다음을 남긴다.

- 생성/편집한 asset path
- 사용한 prompt pack과 full prompt
- provider, model, action, revised prompt가 있으면 그 값
- source refs
- normalization metadata path
- 64px preview path
- Godot harness output path
- stage capture path
- 사용자가 준 피드백과 다음 조정 포인트
