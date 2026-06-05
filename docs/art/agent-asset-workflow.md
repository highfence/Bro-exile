---
date: 2026-06-05
topic: agent-asset-workflow
kind: art-pipeline
status: active-reference
skill: .codex/skills/bro-exile-asset-workflow/SKILL.md
---

# 에이전트 에셋 제작 워크플로우

## 목적

이 문서는 Bro-exile의 에셋 제작 맥락을 다른 에이전트가 이어받을 수 있도록 정리한 handoff 문서다. 목표는 대화 안에만 있던 판단을 repo 안에 남겨서, 새 에이전트가 플레이어, 좀비, P1 몬스터, prompt pack, Godot harness, 후보 검증, 실사용 promotion 흐름을 같은 방식으로 반복할 수 있게 하는 것이다.

에셋 작업을 시작하는 에이전트는 먼저 `.codex/skills/bro-exile-asset-workflow/SKILL.md`를 열고, 다음 명령으로 현재 경로와 참조 상태를 확인한다.

```bash
python3 scripts/tools/asset_workflow_context.py --format markdown
```

## 지금까지 확정한 방향

Bro-exile의 시각 방향은 **귀엽고 약간 기괴한 광산 생존 액션 장난감**이다. Brotato는 구조 참고용이다. 실제 형태, 실루엣, 캐릭터, 아이콘, 장식은 직접 복제하지 않는다.

핵심 제작 결정은 다음이다.

- 플레이어는 둥근 차콜 몸, 큰 노란 안전모, 헤드램프, 작은 얼굴을 가진 광부 마스코트다.
- 플레이어 본체는 헬멧, 램프, 벨트, 가방을 유지하고, 장갑과 부츠만 별도 파츠로 움직인다.
- 일반 적은 한 장의 full-frame PNG를 만들고, Godot에서 flip, bob, squash, lean, shadow로 움직임을 만든다.
- 보스나 특수 적만 상태별 프레임을 추가한다.
- AI 생성 결과는 곧바로 실사용 파일이 아니라 candidate다.
- 후보는 normalize, 64px preview, metadata, Godot harness, stage capture를 거친 뒤 사용자가 승인해야 promotion한다.

## 작업 시작 체크리스트

1. `git status --short --branch`로 현재 브랜치와 열려 있는 변경을 확인한다.
2. 관련 없는 변경은 되돌리거나 수정하지 않는다.
3. `scripts/tools/asset_workflow_context.py --format markdown`를 실행한다.
4. `docs/art/asset-generation-principles.md`를 읽는다.
5. 작업 유형에 맞는 prompt pack과 harness 문서를 연다.
6. 새 에셋은 먼저 후보 경로나 `/private/tmp`에 만든다.
7. 사용자가 승인하기 전에는 실사용 asset path를 덮어쓰지 않는다.

## 파일 지도

중요한 문서:

- `docs/art/asset-generation-principles.md`
- `docs/art/player-asset-harness.md`
- `docs/art/prompt-packs/README.md`
- `docs/art/prompt-packs/enemy-single-image.md`
- `docs/plans/2026-06-04-feat-automated-asset-quality-harness-plan.md`
- `docs/reports/assets/2026-06-04-asset-automation-dry-run-report.md`
- `docs/reports/assets/2026-06-05-enemy-motion-profile-comparison-report.md`

중요한 도구:

- `scripts/tools/asset_workflow_context.py`
- `scripts/tools/asset_candidate_harness.py`
- `scripts/tools/player_asset_harness.gd`
- `scripts/tools/zombie_asset_harness.gd`
- `scenes/tools/player_asset_harness.tscn`
- `scenes/tools/zombie_asset_harness.tscn`

중요한 에셋:

- `assets/sprites/characters/player_helmet_mascot_semilayered_gloves_v1/parts`
- `assets/sprites/characters/miner_zombie_v1/zombie_idle.png`
- `assets/sprites/characters/p1_monsters_runtime_v1`
- `assets/sprites/characters/p1_monsters_runtime_v2`

## 플레이어 워크플로우

플레이어는 완성 시트를 직접 생성하는 방식보다 semi-layered part rig를 우선한다.

현재 기본 계약:

- `core_body`: 몸, 헬멧, 램프, 얼굴, 벨트, 가방.
- `left_glove`, `right_glove`: 손 역할.
- `left_boot`, `right_boot`: 발 역할.
- 팔과 다리 전체는 그리지 않고, 코드에서 장갑/부츠 위치를 움직여 모션을 만든다.

제작 순서:

1. 기준 캐릭터 원본을 확정한다.
2. 자동 분해만 믿지 말고 의미 레이어가 깨지지 않았는지 확인한다.
3. 장갑과 부츠 위치를 리그에서 조정한다.
4. `player_asset_harness`로 `idle_left`, `idle_right`, `move_left`, `move_right`를 bake한다.
5. 64px preview에서 얼굴, 헬멧, 램프, 손발 위치를 본다.
6. 왼쪽/오른쪽 전환에서 front/back glove layering이 자연스러운지 확인한다.
7. 승인된 결과만 새 asset version으로 promotion한다.

Player harness 예시:

```bash
/Users/highfence/Dev/Sweep/engine/godot/bin/godot.macos.editor.arm64 \
  --log-file /private/tmp/bro-exile-player-harness.log \
  --path /Users/highfence/Documents/Bro-exile \
  --scene res://scenes/tools/player_asset_harness.tscn \
  --quit-after 360 \
  -- \
  --asset-output=/private/tmp/bro-exile-asset-harness \
  --asset-name=player_review \
  --frame-count=8
```

## 적 워크플로우

일반 적은 single-image runtime enemy asset으로 만든다. AI에게 8프레임 스프라이트 시트를 바로 요청하지 않는다. 먼저 한 장의 정체성 있는 full-frame PNG를 만들고, 움직임은 Godot runtime transform으로 만든다.

제작 순서:

1. `docs/art/prompt-packs/enemy-single-image.md`의 common prompt와 variant prompt를 조합한다.
2. flat chroma-key background 또는 transparent PNG로 후보를 만든다.
3. `asset_candidate_harness.py normalize-single-image`로 alpha 제거와 packing을 한다.
4. 64px preview에서 역할이 읽히는지 확인한다.
5. `zombie_asset_harness`로 motion preview를 만든다.
6. 실제 stage capture에서 배경 위 가독성을 확인한다.
7. 승인 후에만 `assets/sprites/characters/...` 아래 새 version으로 promotion한다.

Enemy motion profile 기준:

- `shamble`: 기본 좀비.
- `sprint`: 빠른 좀비.
- `brace`: 방패/탱커.
- `heavy`: 보스/엘리트.
- `skitter`: 거미/작은 군집.
- `throw`: 투척 적.

Zombie harness 예시:

```bash
/Users/highfence/Dev/Sweep/engine/godot/bin/godot.macos.editor.arm64 \
  --log-file /private/tmp/bro-exile-zombie-harness.log \
  --path /Users/highfence/Documents/Bro-exile \
  --scene res://scenes/tools/zombie_asset_harness.tscn \
  --quit-after 360 \
  -- \
  --asset-output=/private/tmp/bro-exile-zombie-harness \
  --asset-name=thrower_review \
  --source-frame=res://assets/sprites/characters/p1_monsters_runtime_v1/thrower_zombie.png \
  --motion-profile=throw \
  --frame-count=8
```

## 후보 정규화 워크플로우

`asset_candidate_harness.py`는 후보를 실사용 직전 형태로 정리하는 deterministic 단계다. 생성 결과가 chroma-key 배경이면 다음처럼 실행한다.

```bash
python3 scripts/tools/asset_candidate_harness.py normalize-single-image \
  --asset-id enemy_thrower_zombie \
  --candidate-id 2026-06-05-enemy_thrower_zombie-c01 \
  --input /path/to/generated.png \
  --out-dir assets/candidates/2026-06-05/enemy_thrower_zombie/c01 \
  --prompt-pack docs/art/prompt-packs/enemy-single-image.md \
  --source-ref assets/sprites/characters/miner_zombie_v1/zombie_idle.png \
  --chroma-key '#ff00ff'
```

정규화 결과에서 확인할 파일:

- `original_chromakey.png`
- `alpha.png`
- `normalized_256.png`
- `preview_64.png`
- `metadata.json`

## 실제 게임 검증

Godot 명령에는 항상 `--log-file /private/tmp/...`를 붙인다. headless load는 빠른 확인용이고, harness나 capture는 실제 renderer가 필요할 수 있다. headless exit code 0만으로 output 생성 성공을 판단하지 않는다.

Headless load:

```bash
/Users/highfence/Dev/Sweep/engine/godot/bin/godot.macos.editor.arm64 \
  --headless \
  --log-file /private/tmp/bro-exile-headless.log \
  --path /Users/highfence/Documents/Bro-exile \
  --quit
```

Stage capture:

```bash
/Users/highfence/Dev/Sweep/engine/godot/bin/godot.macos.editor.arm64 \
  --log-file /private/tmp/bro-exile-stage1.log \
  --path /Users/highfence/Documents/Bro-exile \
  -- \
  --capture-stage1
```

Monster roster capture:

```bash
/Users/highfence/Dev/Sweep/engine/godot/bin/godot.macos.editor.arm64 \
  --log-file /private/tmp/bro-exile-roster.log \
  --path /Users/highfence/Documents/Bro-exile \
  -- \
  --capture-monster-roster
```

## Promotion 규칙

후보를 실사용 에셋으로 승격할 때는 다음을 남긴다.

- 새 asset version folder.
- 원본 후보 경로.
- prompt pack과 full prompt.
- provider, model, revised prompt.
- normalization metadata.
- 64px preview.
- Godot harness output.
- stage capture.
- 사용자의 승인 또는 피드백 요약.

승격 후에는 `scripts/main.gd`나 관련 resource 파일의 `res://assets/...` 참조를 바꾸고, `python3 scripts/tools/asset_candidate_harness.py scan --script scripts/main.gd`로 asset reference 상태를 다시 본다.

## 금지 사항

- Brotato 원본 asset을 복사하지 않는다.
- 완성 sprite sheet 한 번 생성으로 최종 애니메이션을 대체하지 않는다.
- 자동 분해 결과를 그대로 의미 파츠라고 믿지 않는다.
- 생성 후보를 사용자 확인 없이 `main` 실사용 asset으로 교체하지 않는다.
- preview만 보고 끝내지 않는다. 실제 Godot capture를 확인한다.

## 마무리 체크리스트

작업 종료 시 다음을 요약한다.

- 무엇을 만들었는지.
- 어떤 파일을 추가/수정했는지.
- 어떤 prompt와 source ref를 썼는지.
- 어떤 harness와 capture를 실행했는지.
- 검증 결과와 남은 리스크.
- 다음 에이전트가 이어받을 피드백.
