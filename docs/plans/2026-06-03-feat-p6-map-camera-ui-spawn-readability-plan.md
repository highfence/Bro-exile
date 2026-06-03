---
title: "feat: P6 맵/카메라/UI/스폰 가독성 개선"
type: feat
status: complete
date: 2026-06-03
origin: todos/016-complete-p6-map-camera-ui-spawn-readability.md
related_origins:
  - docs/plans/2026-06-03-feat-p4-p5-prototype-validation-plan.md
  - docs/architecture/2026-05-31-godot-ui-system.md
---

# feat: P6 맵/카메라/UI/스폰 가독성 개선

## Overview

P6는 전투 콘텐츠를 더 늘리기 전에, 게임을 읽는 기본 환경을 정리하는 마일스톤이다. 현재 프로젝트는 Godot viewport와 월드 크기가 모두 `1280x720`이라, 보이는 화면이 곧 전체 맵이다. Switch 2 휴대 화면과 TV 출력도 16:9 계열이고 프로젝트 viewport도 `1280x720` 16:9이므로, 답답함의 핵심은 화면비가 아니라 월드 크기와 카메라 부재다.

P6에서는 viewport를 유지하되 월드를 `2048x2048` 정사각형으로 확장하고, 플레이어를 따라가는 카메라를 붙인다. 동시에 전투 중 UI가 몹을 가리는 문제를 줄이기 위해 하단 HUD를 제거하거나 숨기고, 상세 상태는 유물 선택/상점/일시정지 overlay에서 확인하게 한다. 마지막으로 적은 화면 밖에서 갑자기 들어오는 대신, 화면 안에서 흙이 들썩이는 스폰 예고를 보여준 뒤 땅 아래에서 위로 등장한다.

## Origin Decisions

- P6 목표 카드에서 월드 크기를 `2048x2048`, viewport를 `1280x720`으로 유지하기로 결정했다. (see origin: `todos/016-complete-p6-map-camera-ui-spawn-readability.md`)
- 전투 UI는 계속 많은 정보를 띄우기보다 몹 가림을 줄이고, 선택/상점/일시정지 화면에서 상세 상태를 보여주기로 했다. (see origin: `todos/016-complete-p6-map-camera-ui-spawn-readability.md`)
- 스폰은 화면 밖 즉시 등장 대신 화면 안 예고 후 등장으로 바꾼다. 이 예고는 흙 들썩임/균열/먼지 느낌의 애니메이션이어야 한다. (see origin: `todos/016-complete-p6-map-camera-ui-spawn-readability.md`)

## Local Research Findings

### Repository Research Summary

- `project.godot`는 viewport를 `1280x720`, stretch mode를 `canvas_items`, aspect를 `expand`로 설정한다.
- `scripts/main.gd`는 `WORLD_SIZE := Vector2(1280, 720)`를 화면 크기와 월드 크기 양쪽 의미로 사용한다.
- 플레이어 이동, 적 스폰, 투사체 생존 범위, 적 clamp, 배경 그리기, pause dim rect가 모두 `WORLD_SIZE`에 직접 의존한다.
- 현재 `_draw()`는 `Node2D` 커스텀 드로잉으로 게임 월드를 그리고, `GameUI`는 `CanvasLayer` 위에서 HUD/overlay를 그린다.
- `scripts/ui/game_ui.gd`는 상단 HUD, 하단 무기 HUD, 하단 유물 HUD, choice/end overlay, pause banner를 소유한다.
- P4/P5 이후 검증 커맨드는 `--smoke-playtest`, `--debug-spider-relic-wave2`, `--debug-boss-pierce-splash`, `--capture-run-report-ui`, `--capture-combat-feedback`가 있다.
- P6 목표 카드 파일은 `todos/016-complete-p6-map-camera-ui-spawn-readability.md`다.

### Institutional Learnings

- `docs/solutions/ui-bugs/invisible-godot-ui-text-GodotPort-20260522.md`는 UI 변경이 headless 통과만으로 충분하지 않고 실제 캡처로 텍스트/레이아웃을 확인해야 한다고 기록한다.
- `docs/architecture/2026-05-31-godot-ui-system.md`는 `main.gd`가 게임 상태와 선택 처리를 담당하고, `GameUI`가 HUD/overlay 표시를 담당하는 구조를 권장한다.
- P4/P5 계획은 UI와 전투 피드백 변경 시 캡처 커맨드로 실제 화면을 확인하는 검증 습관을 이미 세웠다.

### External Research Decision

외부 조사는 Switch 2 화면 스펙과 Godot 공식 API 확인으로 제한한다. 보안/결제/외부 API가 아니라 기존 Godot 프로토타입 구조 개편이므로 폭넓은 외부 리서치는 불필요하다.

- Nintendo 공식 스펙은 Switch 2 화면이 `1920x1080`, 7.9인치이며 TV 출력도 최대 4K 16:9 계열임을 보여준다.
- Godot 공식 문서에 따르면 `Camera2D`는 viewport를 제어하며, `limit_left/right/top/bottom`, position smoothing, drag margins 같은 2D 카메라 옵션을 제공한다.
- Godot 공식 문서의 `CanvasItem._draw()` 패턴은 현재 `main.gd`의 커스텀 드로잉 방식과 맞는다.

## Proposed Solution

### 1. `VIEW_SIZE`와 `WORLD_SIZE` 분리

`WORLD_SIZE`를 더 이상 화면 크기로 쓰지 않는다.

```gdscript
const VIEW_SIZE := Vector2(1280, 720)
const WORLD_SIZE := Vector2(2048, 2048)
```

`VIEW_SIZE`는 카메라 화면, capture 기준, 화면 안 스폰 후보 계산, pause dim 등 viewport성 계산에 사용한다. `WORLD_SIZE`는 플레이어 이동 clamp, 적/픽업/탄 월드 위치, 배경 그리드, 카메라 제한에 사용한다.

### 2. 플레이어 추적 카메라

P6의 첫 구현은 수동 카메라 오프셋 방식이 더 작고 안전하다. 현재 게임은 하나의 `Node2D`에서 직접 `_draw()`를 호출하고 있기 때문에, `Camera2D` 노드를 도입하기 전에 다음 방식으로 월드 드로잉에만 카메라 오프셋을 적용한다.

```gdscript
var camera_pos := Vector2.ZERO

func _camera_origin() -> Vector2:
    return camera_pos - VIEW_SIZE * 0.5
```

월드 드로잉 전에는 `draw_set_transform(-_camera_origin() + shake, 0, Vector2.ONE)`를 적용하고, UI/overlay는 `CanvasLayer`에 그대로 둔다. 이 방식은 기존 `GameUI`와 충돌이 적고, 스크린 좌표가 필요한 스폰 예고 계산도 명시적으로 처리할 수 있다.

추후 카메라 기능이 커지면 `Camera2D`로 옮길 수 있다. Godot 공식 문서는 `Camera2D`가 limit/smoothing/drag margin을 제공한다고 설명하므로, P6 이후 카메라 감도 조정이 필요해지면 그때 전환한다.

### 3. 전투 HUD 정리

전투 중 하단 무기 HUD와 하단 유물 HUD는 제거하거나 숨긴다. P6 목표는 “항상 많은 상태를 보여주기”가 아니라 “몹과 탄을 가리지 않기”다.

상단 HUD는 다음만 유지한다.

- 체력
- 공세
- 광석
- 시간

상단 HUD는 더 투명한 패널로 바꾸고, 전투 중에는 화면 위쪽을 덜 차지하게 한다. 상세 정보는 다음 overlay에서 확인한다.

- 유물 선택 overlay
- 상점 overlay
- ESC 일시정지 overlay
- 승리/패배 런 리포트

### 4. 상태 패널 확장

`GameUI.show_choice()`는 현재 유물 strip을 보여줄 수 있다. P6에서는 선택/상점/일시정지 overlay에 “현재 상태” 요약을 추가한다.

상태 요약의 최소 내용:

- 체력과 최대 체력
- 광석
- 현재 공세
- 현재 무기 이름
- 무기 부품 목록
- 선택 유물 목록
- 리롤/구매/처치 등 P4 런 리포트 핵심 수치 일부

구현 방식은 `main.gd`가 `_player_state_summary()` 같은 Dictionary/Array를 만들고, `GameUI`가 이를 읽어 작은 상태 패널로 렌더링하는 구조를 권장한다.

### 5. ESC 일시정지창

현재 pause는 `pause_banner`만 표시한다. P6에서는 `pause` 입력 시 `mode`를 바꾸지 않고 `paused = true` 상태에서 pause overlay를 연다.

Pause overlay 요구:

- 타이틀: 일시정지
- 상태 요약 패널
- 현재 유물 strip
- 버튼: 계속하기
- 버튼: 다시 시작

입력/클릭 흐름:

- `ESC` 또는 pause action: pause overlay 표시/숨김
- 계속하기: `paused = false`, overlay 닫기
- 다시 시작: `_start_run()`

### 6. 화면 안 스폰 예고

현재 `_spawn_enemies()`는 즉시 `_spawn_enemy_pack()`을 호출하고, `_spawn_position()`은 화면/월드 바깥 edge를 반환한다. P6에서는 즉시 적을 만들지 않고 `spawn_warnings` 배열을 먼저 만든다.

```gdscript
var spawn_warnings: Array = []

{
    "kind": "spider",
    "pack_size": 4,
    "pos": Vector2(...),
    "timer": 0.8,
    "duration": 0.8,
}
```

`_update_spawn_warnings(delta)`가 timer를 줄이고, 시간이 끝나면 `_spawn_enemy_pack_at(kind, pack_size, pos, emerging=true)`를 호출한다. 등장한 적은 `emerge_timer`와 `emerge_duration`을 가지고 땅 아래에서 위로 올라오는 offset을 그릴 때 적용한다.

스폰 위치 선택:

- 현재 카메라 viewport 안
- 플레이어와 최소 거리 확보
- 화면 가장자리 너무 가까운 위치 회피
- 이미 있는 적과 너무 가까운 위치 회피
- 실패 시 몇 번 재시도 후 가장 덜 나쁜 위치 사용

스폰 예고 표현:

- 바닥 균열/먼지 원형 ring
- 작은 흙 입자
- 0.6초 이상 들썩이는 scale/alpha 애니메이션
- 예고가 끝나면 적 스프라이트가 `y + 22px` 정도 아래에서 위로 올라옴

## Alternative Approaches Considered

### A. `Camera2D` 즉시 도입

장점은 Godot의 limit/smoothing 기능을 바로 쓸 수 있다는 점이다. 단점은 현재 `main.gd`의 `_draw()` 기반 월드 그리기, screen shake, capture/debug 코드와 좌표계 영향 범위가 커질 수 있다는 점이다.

P6 첫 패스에서는 수동 카메라 오프셋을 추천한다.

### B. 수동 카메라 오프셋

현재 코드와 가장 잘 맞는다. `Node2D` 커스텀 드로잉 전 transform을 적용하고, UI는 CanvasLayer에 그대로 남겨 좌표계 충돌을 줄인다. 단점은 smoothing/drag margin을 직접 관리해야 한다는 점이지만, P6의 목표에는 충분하다.

### C. 맵 확장만 하고 카메라 없이 줌아웃

월드가 넓어졌다는 감각은 약하고, 전투 가독성도 떨어진다. Switch 2 16:9와 프로젝트 16:9가 이미 맞기 때문에 줌아웃은 답답함의 원인에 직접 대응하지 않는다.

## Technical Approach

### Architecture

- `scripts/main.gd`
  - 월드/카메라 좌표계
  - 플레이어 이동 clamp
  - 스폰 예고 상태
  - 적 등장 애니메이션 상태
  - P6 capture/debug 커맨드
- `scripts/ui/game_ui.gd`
  - 전투 HUD 최소화
  - 하단 HUD 제거/숨김
  - 선택/상점/일시정지 상태 패널
  - pause overlay 버튼
- `project.godot`
  - viewport는 유지한다. 변경이 필요 없다면 손대지 않는다.

### Implementation Phases

#### Phase 1: Plan/Quest Hygiene

- `docs/plans/2026-06-03-feat-p6-map-camera-ui-spawn-readability-plan.md` 작성
- `todos/016-complete-p6-map-camera-ui-spawn-readability.md`와 `todos/README.md`를 plan과 맞춘다.

Success:

- P6 작업자가 plan과 quest card만 보고 목표와 범위를 이해한다.

#### Phase 2: World/Camera Separation

- `VIEW_SIZE` 추가
- `WORLD_SIZE`를 `2048x2048`로 변경
- `camera_pos`, `_update_camera`, `_camera_origin`, `_visible_world_rect` 추가
- `_draw()`에서 월드 드로잉과 pause dim/UI 좌표계를 분리
- 플레이어 시작 위치는 `WORLD_SIZE * 0.5` 유지
- smoke boss 추적과 capture 장면 좌표를 넓은 월드 기준으로 조정

Success:

- 플레이어가 월드 중앙에서 시작하고, 이동하면 카메라가 따라간다.
- 카메라는 월드 바깥을 보여주지 않는다.
- 기존 전투가 카메라 좌표에서 정상 렌더링된다.

#### Phase 3: Combat HUD Declutter

- 전투 중 weapon HUD와 relic HUD를 숨기거나 제거
- 상단 HUD 패널 alpha를 낮추고 높이를 줄인다.
- `GameUI`에 `set_combat_details_visible(false)` 또는 유사 구조를 둔다.
- overlay 상태에서는 상세 상태 패널을 보여준다.

Success:

- 전투 중 하단 UI에 몹이 가려지지 않는다.
- 상점/유물 선택에서는 현재 빌드와 유물을 확인할 수 있다.

#### Phase 4: Pause Overlay

- `GameUI.show_pause(summary, relics)` 추가
- `GameUI.hide_pause()` 추가
- `resume_requested`, `restart_requested` signal 추가
- `main.gd`가 pause action을 받아 overlay를 열고 닫는다.

Success:

- `ESC`를 누르면 일시정지창이 뜬다.
- 일시정지창에서 현재 상태를 확인하고 계속하기/다시 시작이 가능하다.

#### Phase 5: Spawn Telegraph

- `spawn_warnings` 상태 추가
- `_spawn_enemies()`가 즉시 적 생성 대신 `_queue_spawn_warning(kind, pack_size)`를 호출
- `_pick_spawn_warning_position()`이 현재 camera viewport 안의 안전 위치를 고른다.
- `_update_spawn_warnings(delta)`로 timer를 관리하고, 종료 시 실제 적 생성
- `_draw_spawn_warnings()`로 흙 들썩임 애니메이션 렌더
- `_make_enemy()` 또는 spawn 함수에 `emerge_timer` 상태 추가
- 적 렌더 시 emerge offset 적용

Success:

- 적이 화면 밖에서 갑자기 들어오지 않는다.
- 화면 안의 흙 들썩임을 보고 스폰 위치를 미리 알 수 있다.
- 등장 애니메이션이 전투 읽기에 방해되지 않는다.

#### Phase 6: Verification Captures

- `--capture-p6-map-camera`: 넓은 맵과 카메라 위치/경계 확인
- `--capture-spawn-telegraph`: 화면 안 스폰 예고와 등장 직전/직후 확인
- `--capture-pause-ui`: 일시정지 상태 패널과 버튼 확인
- 기존 `--capture-combat-feedback`가 카메라 좌표계에서도 정상 동작하는지 확인

Success:

- 실제 캡처에서 UI가 전투를 덜 가리고, 스폰 예고가 보인다.

## System-Wide Impact

### Interaction Graph

- `_process` -> `_update_game` -> `_move_player` -> `_update_camera` -> `_spawn_enemies`/`_update_spawn_warnings` -> `_update_enemies`
- `_draw` -> camera transform 적용 -> world draw calls -> transform reset -> screen-space pause dim
- `GameUI.update_hud`는 계속 CanvasLayer screen-space에 남는다.
- pause action -> `main.gd` toggles `paused` -> `GameUI.show_pause`/`hide_pause`
- choice/shop overlay -> `main.gd` passes status summary -> `GameUI.show_choice`

### Error & Failure Propagation

- 좌표계 혼용이 가장 큰 실패 지점이다. world 좌표와 screen 좌표 변환 helper를 명시해야 한다.
- 스폰 위치 후보가 없을 때 무한 루프가 나면 안 된다. 재시도 횟수를 제한하고 fallback 위치를 둔다.
- pause overlay가 choice/shop/end overlay와 충돌하면 입력이 막힐 수 있다. pause는 `MODE_PLAY`에서만 열리게 한다.

### State Lifecycle Risks

- `_reset_run`에서 `camera_pos`, `spawn_warnings`, enemy emergence state를 초기화해야 한다.
- 라운드 종료/상점 진입 시 pending spawn warning을 비워야 한다.
- smoke playtest는 스폰 예고 delay 때문에 이전보다 시간이 늘 수 있으므로 `SMOKE_PLAYTEST_DURATION` 또는 smoke tuning을 확인해야 한다.

### API Surface Parity

- 전투 HUD, choice overlay, shop overlay, end overlay, pause overlay가 모두 현재 상태 표시를 다루게 된다.
- `GameUI`는 “표시만”, `main.gd`는 “상태 생성과 선택 처리”라는 기존 경계를 유지한다.

### Integration Test Scenarios

1. 넓은 맵에서 플레이어가 네 방향 끝까지 이동해도 카메라가 월드 바깥을 보여주지 않는다.
2. 전투 중 하단 UI가 없어지고, 몹/탄이 하단까지 읽힌다.
3. 상점/유물 선택 화면에서 현재 무기/부품/유물/광석이 보인다.
4. `ESC` pause overlay에서 상태 확인 후 계속하기/다시 시작이 동작한다.
5. 스폰 예고가 화면 안에서 먼저 보이고, 예고 후 적이 등장한다.
6. `--smoke-playtest`가 P6 변경 후에도 라운드 5 승리까지 도달한다.

## Acceptance Criteria

### Functional Requirements

- [x] `VIEW_SIZE = Vector2(1280, 720)`와 `WORLD_SIZE = Vector2(2048, 2048)`가 분리된다.
- [x] 플레이어 추적 카메라가 작동한다.
- [x] 카메라는 월드 경계를 벗어나지 않는다.
- [x] 플레이어, 적, 탄, 픽업, 배경, 스폰이 월드 좌표로 동작한다.
- [x] 전투 중 하단 무기/유물 HUD가 사라지거나 몹을 가리지 않는다.
- [x] 상단 HUD는 투명/최소 형태로 조정된다.
- [x] 유물 선택과 상점 overlay에서 현재 상태를 확인할 수 있다.
- [x] `ESC` 일시정지창에서 현재 상태, 계속하기, 다시 시작을 확인할 수 있다.
- [x] 스폰 예고는 화면 안에서 먼저 나타난다.
- [x] 스폰 예고는 흙 들썩임/먼지/균열 애니메이션으로 보인다.
- [x] 적은 예고 후 땅 아래에서 위로 등장한다.

### Quality Gates

- [x] Godot headless load 통과
- [x] `--debug-spider-relic-wave2` 통과
- [x] `--debug-boss-pierce-splash` 통과
- [x] `--smoke-playtest` 통과
- [x] `--capture-p6-map-camera` 캡처 확인
- [x] `--capture-spawn-telegraph` 캡처 확인
- [x] `--capture-pause-ui` 캡처 확인
- [x] UI 텍스트/레이아웃은 실제 캡처로 확인
- [x] 변경사항은 새 브랜치에서 커밋한다.

## Success Metrics

- 플레이어가 한 화면짜리 경기장이 아니라 넓은 광산을 이동한다고 느낀다.
- 하단 UI 때문에 몹을 놓치는 순간이 줄어든다.
- 적 스폰을 보고 대응할 시간이 생긴다.
- smoke playtest의 P4 런 리포트가 P6 이후에도 정상 출력된다.
- P6 캡처에서 넓은 맵, 카메라, 스폰 예고가 한눈에 확인된다.

## Dependencies & Risks

Dependencies:

- P5가 `main`에 반영되어 있어야 한다.
- Godot 실행 파일은 `/Users/highfence/Dev/Sweep/engine/godot/bin/godot.macos.editor.arm64`를 사용한다.
- 기존 `GameUI` 구조와 P4/P5 debug harness를 유지한다.

Risks:

- 좌표계 분리 중 draw/input/capture가 서로 다른 기준을 쓰면 화면이 어긋날 수 있다.
- 스폰 예고 delay가 난이도와 smoke timing을 바꿀 수 있다.
- 하단 HUD 제거 후 플레이어가 무기/유물 상태를 잊을 수 있으므로, overlay 상태 요약이 충분히 읽혀야 한다.
- Camera2D가 아닌 수동 카메라 방식은 장기적으로 기능이 늘면 재검토가 필요하다.

Mitigations:

- `_world_to_screen`, `_screen_to_world`, `_visible_world_rect` 같은 helper를 명시한다.
- capture command를 추가해 시각 회귀를 확인한다.
- P4 런 리포트와 pause overlay에 빌드 요약을 남긴다.

## Future Considerations

- P6 이후 카메라 smoothing/drag margin이 중요해지면 `Camera2D`로 전환한다.
- 더 큰 월드가 필요하면 `2048x2048`을 상수화해 P7 이후 맵 테마/타일 시스템으로 확장한다.
- 스폰 예고가 만족스러우면 적 타입별 예고 색/형태를 다르게 만든다.
- 하단 HUD 제거 후 상세 상태 접근성이 부족하면 짧은 hotkey overlay를 추가한다.

## Verification Commands

```bash
/Users/highfence/Dev/Sweep/engine/godot/bin/godot.macos.editor.arm64 --headless --path /Users/highfence/Documents/Bro-exile --quit
```

```bash
/Users/highfence/Dev/Sweep/engine/godot/bin/godot.macos.editor.arm64 --headless --path /Users/highfence/Documents/Bro-exile -- --debug-spider-relic-wave2
```

```bash
/Users/highfence/Dev/Sweep/engine/godot/bin/godot.macos.editor.arm64 --headless --path /Users/highfence/Documents/Bro-exile -- --debug-boss-pierce-splash
```

```bash
/Users/highfence/Dev/Sweep/engine/godot/bin/godot.macos.editor.arm64 --headless --path /Users/highfence/Documents/Bro-exile -- --smoke-playtest
```

```bash
/Users/highfence/Dev/Sweep/engine/godot/bin/godot.macos.editor.arm64 --path /Users/highfence/Documents/Bro-exile -- --capture-p6-map-camera
```

```bash
/Users/highfence/Dev/Sweep/engine/godot/bin/godot.macos.editor.arm64 --path /Users/highfence/Documents/Bro-exile -- --capture-spawn-telegraph
```

```bash
/Users/highfence/Dev/Sweep/engine/godot/bin/godot.macos.editor.arm64 --path /Users/highfence/Documents/Bro-exile -- --capture-pause-ui
```

## Sources & References

- Origin quest: `todos/016-complete-p6-map-camera-ui-spawn-readability.md`
- P4/P5 plan: `docs/plans/2026-06-03-feat-p4-p5-prototype-validation-plan.md`
- UI architecture: `docs/architecture/2026-05-31-godot-ui-system.md`
- UI rendering learning: `docs/solutions/ui-bugs/invisible-godot-ui-text-GodotPort-20260522.md`
- Main game loop: `scripts/main.gd`
- UI layer: `scripts/ui/game_ui.gd`
- Project viewport config: `project.godot`
- Nintendo official Switch 2 specs: `https://www.nintendo.com/us/gaming-systems/switch-2/tech-specs/`
- Nintendo UK Switch 2 specs: `https://www.nintendo.com/en-gb/Hardware/Nintendo-Switch-2/Nintendo-Switch-2-Specifications-2785627.html`
- Godot official docs: `Camera2D` and `CanvasItem` custom drawing via `/godotengine/godot-docs`
