---
date: 2026-05-31
topic: godot-ui-system
---

# Godot UI 시스템 구조

## 방향

앞으로 UI는 Godot `Control` 계층과 공통 `Theme`를 기본 구조로 사용한다. 게임 로직은 `scripts/main.gd`에 남기고, HUD/overlay/버튼/카드의 생성과 스타일은 `scripts/ui/` 아래로 분리한다.

이번 구조의 목표는 임시 픽셀 텍스트 우회가 아니라, 한글 폰트·패널·버튼·카드가 같은 체계로 렌더링되는 기반을 만드는 것이다.

## 파일 구조

- `assets/fonts/PretendardVariable.ttf`: 현재 프로젝트에 포함한 한글/영문 UI 폰트.
- `assets/fonts/Pretendard-OFL.txt`: Pretendard 폰트 라이선스.
- `scripts/ui/ore_ui_theme.gd`: 색상 토큰, 폰트 로딩, `Theme`, `StyleBoxFlat` 생성 책임.
- `scripts/ui/game_ui.gd`: HUD, 무기 표시, 시작/선택/상점/종료 overlay, 일시정지 배너 책임.
- `scripts/main.gd`: 게임 상태, 보상/상점 선택 처리, `GameUI`와의 signal 연결 책임.
- `scripts/tools/font_probe.gd`: 현재 Godot 바이너리의 폰트 로더와 TextServer 상태를 확인하는 진단 스크립트.

## 책임 분리

`main.gd`는 UI 노드를 직접 조립하지 않는다. 대신 `GameUI`를 만들고, 다음 메서드만 호출한다.

- `show_start(...)`
- `show_choice(...)`
- `show_end(...)`
- `hide_overlay()`
- `update_hud(data)`
- `render_weapons(weapons, damage_multiplier)`
- `set_paused(value)`

선택 버튼은 `GameUI.option_selected(option)` signal로 돌아온다. 실제 보상 적용, 상점 구매, 다음 라운드 시작은 계속 `main.gd`가 담당하며, 어떤 선택 처리기를 부를지는 `main.gd`의 `active_choice_method`가 결정한다.

`main.gd`가 보관하는 UI 관련 상태는 smoke playtest용 `active_choice_options`, `active_choice_method`뿐이다. 화면 문구, 카드 레이아웃, 버튼 스타일, pause banner 같은 표시 상태는 `GameUI`가 소유한다.

선택 카드는 `Button` 위에 텍스트를 얹지 않는다. `PanelContainer`가 카드 표면을 소유하고, 내부 `MarginContainer`와 `VBoxContainer`가 title/body/meta 슬롯을 소유한다. 클릭은 카드 위에 얹은 투명 `Button` hit layer의 `pressed` signal로 처리하고, hover/pressed 상태는 그 hit layer가 카드 표면 style을 바꾼다. 이 구조 덕분에 카드 박스와 텍스트 영역이 같은 컴포넌트 안에서 계산되면서도 클릭 판정은 Godot 기본 버튼 동작을 쓴다.

## 폰트 렌더링 게이트

`font_probe`는 실패 시 exit code 1을 반환한다. UI 작업 전 발견한 기존 엔진 상태는 다음처럼 실패했다.

- `FONT_PROBE file_exists=true`
- `FONT_PROBE resource_exists=false`
- `FONT_PROBE text_server_0=<TextServerDummy...>`
- `FONT_PROBE ok=false`

엔진 빌드 설정도 `module_text_server_fb_enabled=false`, `module_text_server_adv_enabled=false`로 되어 있었다. 이 상태에서는 `Label`, `Button`, `draw_string()`, 번들 `.ttf` 로딩이 모두 실패했다.

fallback text server를 켠 엔진 빌드 후에는 `TextServerFallback`이 등록된다. 단, `--script` 진단 경로에서는 primary text server가 `Dummy`로 남을 수 있어서 `OreUITheme.ensure_text_rendering_available()`가 시작 시 non-dummy text server를 primary로 선택한다.

현재 커스텀 빌드에서는 `ResourceLoader.exists()`가 `.ttf`에 대해 false를 반환할 수 있으므로, `OreUITheme.load_font()`는 `FontFile.load_dynamic_font(FONT_PATH)` 직접 로딩 경로도 가진다.

## 엔진 빌드

최소 요구사항은 fallback text server를 켠 Godot editor 빌드다. 이번 검증에서는 다음 명령으로 빌드했다.

```bash
/Users/highfence/Dev/Sweep/tools/build_godot_editor.sh macos -j8 module_text_server_fb_enabled=yes
```

빌드 후 다음 명령으로 확인한다.

```bash
/Users/highfence/Dev/Sweep/engine/godot/bin/godot.macos.editor.arm64 \
  --headless \
  --path /Users/highfence/Documents/Bro-exile/.worktrees/codex/ui-system-brainstorm \
  --script res://scripts/tools/font_probe.gd
```

통과 기준은 exit code 0과 `FONT_PROBE ok=true`다. 구체적으로는 `TextServerDummy`가 아닌 TextServer가 잡히고, `assets/fonts/...ttf`가 `Font`로 로드되며, 문자열 크기가 0보다 크게 나와야 한다.

## 현재 검증 상태

- 엔진 빌드: 통과. `module_text_server_fb_enabled=yes` 빌드에서 `TextServerFallback` 등록 확인.
- `font_probe`: 통과. `FONT_PROBE ok=true`, primary `TextServerFallback`, Pretendard `FontFile` 높이 29, 문자열 크기 `(211.0, 29.0)`.
- `--capture-ui`: 통과. 시작 overlay 한글 텍스트 렌더링 확인.
- `--capture-choice-ui`: 통과. 선택 카드 한글 텍스트와 카드 슬롯 정렬 확인.
- `--smoke-playtest`: 통과. `SMOKE_PLAYTEST result=OK mode=play wave=3 level=1 hp=68.0 ore=1 enemies=6 pickups=0 choices=3 elapsed=18.00`.

## 시각 검증 명령

```bash
/Users/highfence/Dev/Sweep/engine/godot/bin/godot.macos.editor.arm64 \
  --path /Users/highfence/Documents/Bro-exile/.worktrees/codex/ui-system-brainstorm \
  -- --capture-ui
```

```bash
/Users/highfence/Dev/Sweep/engine/godot/bin/godot.macos.editor.arm64 \
  --path /Users/highfence/Documents/Bro-exile/.worktrees/codex/ui-system-brainstorm \
  -- --capture-choice-ui
```

캡처 파일은 각각 `/private/tmp/orebound-godot-ui.png`, `/private/tmp/orebound-godot-choice-ui.png`에 저장된다.
