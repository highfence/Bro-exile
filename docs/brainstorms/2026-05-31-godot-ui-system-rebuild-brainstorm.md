---
date: 2026-05-31
topic: godot-ui-system-rebuild
---

# Godot UI 시스템 재설계 브레인스토밍

## What We're Building

Godot 버전의 UI 시스템을 한 번 정리해서, 한글 텍스트와 패널/버튼/카드의 시각 언어가 같은 체계 안에서 보이도록 만든다. 목표는 “일단 글자가 보인다”가 아니라, 시작 화면, HUD, 능력 선택, 상점, 게임오버까지 같은 폰트·간격·색·컴포넌트 규칙으로 동작하는 기본 UI 골격을 세우는 것이다.

현재 문제의 핵심은 게임 로직보다 렌더링 책임이 갈라져 있다는 점이다. Godot `Control`은 패널과 버튼 배경을 그리고, 별도의 픽셀 오버레이가 글자를 그리면서 폰트와 UI 표면이 서로 다른 물건처럼 보인다. 이번 재설계는 텍스트와 UI 표면의 소유자를 하나로 통일하는 방향이어야 한다.

## Research Notes

- 새 worktree는 `main` 기준으로 만들었기 때문에 현재 추적된 브라우저 프로토타입만 포함한다. Godot 포트 파일들은 원래 워크스페이스에 아직 untracked 상태로 남아 있다.
- 브라우저 프로토타입은 DOM/CSS가 폰트, 레이아웃, 카드 상태를 한 번에 처리해서 UI가 비교적 일관된다.
- Godot 포트는 `scripts/main.gd`에서 `CanvasLayer`, `PanelContainer`, `ProgressBar`, `Button`, `Label`을 만들고, 별도 `scripts/pixel_ui.gd`가 텍스트를 그린다.
- 기존 해결 문서에 따르면 로컬 custom Godot 빌드에서 기본 `Label`, `Button`, `draw_string()`, `SystemFont`, `FontFile.load_dynamic_font()` 텍스트가 캡처에서 보이지 않았다.
- 최근 한글 픽셀 렌더러 실험은 글자가 보이게는 만들었지만, 한글 글꼴 품질과 Godot 컨트롤 스타일이 맞지 않아 사용자 기준을 통과하지 못했다.
- Godot 공식 문서는 `Theme` 리소스가 `Control`/`Window` 스타일을 공유 적용하는 방식이고, 프로젝트 전체 theme/custom font 및 Control tree 단위 theme가 가능하다고 설명한다.

## Approach A: Godot Control + Theme + Bundled Korean Font

추천 접근이다. 먼저 아주 작은 검증 씬에서 `res://`에 포함한 한글 폰트가 현재 Godot 실행 바이너리에서 실제 캡처로 렌더링되는지 증명한다. 통과하면 UI를 `Control` 컴포넌트와 프로젝트 공통 `Theme` 중심으로 재작성한다.

장점은 Godot의 버튼, 포커스, hover/disabled 상태, 컨테이너 레이아웃, 향후 접근성·해상도 대응을 그대로 쓸 수 있다는 점이다. 단점은 기존 custom Godot 빌드의 폰트 렌더링 문제가 아직 남아 있을 수 있어서, 첫 단계가 실패하면 구조 설계보다 엔진/폰트 문제를 먼저 해결해야 한다.

## Approach B: Canvas-First Custom UI Renderer

Godot `Control` 텍스트 렌더링을 믿지 않고, UI 전체를 하나의 custom `CanvasItem` 계층에서 그린다. 지금처럼 손으로 조합한 한글이 아니라, 생성된 한글 bitmap/SDF 폰트 아틀라스나 검증된 텍스처 기반 폰트만 사용한다.

장점은 현재 환경의 폰트 렌더링 버그를 우회할 수 있고, 게임 화면과 UI가 같은 드로잉 언어를 공유한다는 점이다. 단점은 버튼 상태, 카드 레이아웃, 클릭 hitbox, 키보드 포커스, 비활성 상태 같은 UI 기본기를 직접 구현해야 해서 프로토타입 속도가 떨어진다.

## Approach C: UI Schema + Renderer Split

게임 상태와 UI 화면 정의를 데이터로 분리하고, 이를 Godot Control 렌더러나 Canvas 렌더러가 받아 그리게 한다. 예를 들어 능력 선택, 상점, 게임오버 화면은 같은 옵션 데이터 구조를 공유하고, 렌더러만 갈아끼울 수 있게 한다.

장점은 브라우저 프로토타입과 Godot 포트 사이의 사고방식을 맞추기 좋고, 나중에 로컬라이제이션이나 UI 테스트를 붙이기 쉽다. 단점은 지금 규모에서는 추상화가 과할 수 있으며, 폰트 렌더링 문제가 해결되지 않으면 예쁜 구조만 있고 화면은 여전히 깨질 수 있다.

## Recommendation

1차 목표는 Approach A로 잡는 것이 가장 낫다. 단, 바로 전체 UI를 갈아엎지 말고 “한글 폰트 렌더링 검증”을 통과 조건으로 둔다. 이 검증을 통과하면 Godot의 정식 UI 시스템 위에 다시 짓고, 실패하면 Approach B로 전환하거나 custom Godot 빌드/폰트 파이프라인을 먼저 고친다.

현재 픽셀 한글 렌더러를 확장하는 방식은 추천하지 않는다. 당장의 글자 표시에는 도움이 됐지만, 선택 카드처럼 정보량이 많은 화면에서는 읽기 품질과 UI 밀도가 곧 한계에 부딪힌다.

## Key Decisions

- Godot을 주 실행 환경으로 본다.
- 1차 계획의 기본 노선은 Approach A, 즉 Godot `Control` + 공통 `Theme` + 번들 한글 폰트로 잡는다.
- UI 텍스트와 UI 표면은 하나의 렌더링 체계가 책임진다.
- 한글은 임시 영문 폰트 fallback이나 손코딩 픽셀 글자가 아니라, 번들 폰트 또는 생성된 폰트 아틀라스로 다룬다.
- 시작 화면, 능력 선택, 상점, 게임오버는 같은 컴포넌트 규칙을 공유한다.
- 시각 검증은 실제 Godot 캡처 기준으로 한다. 로딩 성공이나 코드상 text 값만으로는 통과로 보지 않는다.

## Engine Finding

현재 custom Godot editor는 `TextServerDummy`만 포함하고 있으며, 엔진 빌드 설정에서도 `module_text_server_fb_enabled=false`, `module_text_server_adv_enabled=false`가 확인됐다. 따라서 이 바이너리로는 Approach A의 UI 구조가 있어도 `Label`, `Button`, `draw_string()`, 번들 `.ttf`가 렌더링되지 않는다.

Approach A를 계속 진행하려면 최소한 fallback text server를 켠 Godot editor 빌드가 필요하다.

2026-05-31 추가 확인: `module_text_server_fb_enabled=yes`로 엔진을 다시 빌드한 뒤 `TextServerFallback`이 등록됐고, `scripts/tools/font_probe.gd`가 `FONT_PROBE ok=true`로 통과했다. `ResourceLoader.exists()`는 커스텀 빌드에서 `.ttf`에 대해 false를 반환할 수 있어, 최종 UI 시스템은 `FontFile.load_dynamic_font()` 직접 로딩 경로를 함께 둔다.

## Outcome

Approach A로 진행했다. UI 표면과 텍스트를 Godot `Control` + `Theme` 체계로 통일하고, 기존 픽셀 텍스트 우회는 제거했다.

초기 테스트 폰트였던 D2Coding은 UI 박스와 글자 인상이 잘 맞지 않아 제거했다. 현재는 한글/영문 UI용으로 Pretendard variable font를 번들해 사용한다.

구조상 `GameUI`는 HUD/overlay/card/button 렌더링만 담당하고, `main.gd`는 게임 상태와 선택 처리만 담당한다. 선택 버튼 signal도 `option`만 반환하며, 어떤 처리기를 부를지는 `main.gd`가 보관한 `active_choice_method`가 결정한다.

선택 카드는 `Button`에 자식 label을 얹는 방식에서 `PanelContainer` 기반 카드 컴포넌트로 바꿨다. 카드 내부에는 title/body/meta 슬롯이 있고, 카드 표면과 텍스트 레이아웃이 같은 컴포넌트 안에서 계산된다.

검증 결과:

- `font_probe`: 통과.
- 시작 화면 캡처: 한글 렌더링 확인.
- 선택 화면 캡처: 한글 카드 렌더링과 슬롯 정렬 확인.
- `--smoke-playtest`: 통과.

## Open Questions

- 다음 단계에서 원하는 시각 방향을 더 정해야 한다. 현재는 읽기 좋은 현대적 한글 게임 UI 쪽으로 기본값을 잡았다.
- 상점/보상/게임오버별로 카드 밀도와 버튼 hierarchy를 더 세밀하게 나눌지 정해야 한다.

## Sources

- Godot 4.6 GUI skinning/theme guide: https://docs.godotengine.org/en/4.6/tutorials/ui/gui_skinning.html
- Godot 4.6 Theme class: https://docs.godotengine.org/en/4.6/classes/class_theme.html
- Godot 4.6 FontFile class: https://docs.godotengine.org/en/4.6/classes/class_fontfile.html
- Godot 4.6 internationalizing games: https://docs.godotengine.org/en/4.6/tutorials/i18n/internationalizing_games.html
- Pretendard GitHub release v1.3.9: https://github.com/orioncactus/pretendard/releases/tag/v1.3.9
- Local note: `/Users/highfence/Documents/Bro-exile/docs/solutions/ui-bugs/invisible-godot-ui-text-GodotPort-20260522.md`

## Next Steps

새 UI 구조를 기준으로 실제 플레이 중 보상 선택, 상점, 게임오버 화면을 한 화면씩 플레이테스트하며 밀도와 상태 표현을 다듬는다.
