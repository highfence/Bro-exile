---
title: "feat: P8 무기 정체성 검증 루프"
type: feat
status: complete
date: 2026-06-04
origin: docs/superpowers/specs/2026-06-04-p8-weapon-identity-design.md
related_origins:
  - docs/brainstorms/2026-06-03-p7-threat-economy-and-p8-weapon-identity-brainstorm.md
  - docs/plans/2026-06-03-feat-p7-ten-round-threat-economy-plan.md
  - todos/018-pending-p2-upgrade-item-relic-review.md
---

# feat: P8 무기 정체성 검증 루프

## Overview

P8은 P7에서 만든 10라운드 위협/계약/상점 루프 위에 `곡괭이`, `네일건`, `랜턴` 3종 스타터 무기를 추가해, 플레이어 무기 선택이 실제 플레이 감각을 바꾸는지 검증하는 마일스톤이다. P7은 10라운드 압박과 상점 rarity/계약 경제를 검증했고, P8은 그 위에서 “같은 위협을 서로 다른 무기로 다르게 푸는가?”를 검증한다. (see design: `docs/superpowers/specs/2026-06-04-p8-weapon-identity-design.md`)

P8은 장기적으로 런 도중 장비를 습득하는 구조로 확장될 전 단계다. 하지만 이번 범위에서는 비교 검증을 선명하게 하기 위해 새 런 시작 직후 스타터 무기 하나를 선택하고, 그 무기 하나만 들고 10라운드 루프를 플레이한다. 기존 `드릴촉`은 일반 플레이 스타터에서 제외한다. (see design)

## Origin Decisions

- P8의 첫 검증 축은 `무기 타입별 플레이 감각 차이`다. (see design: `docs/superpowers/specs/2026-06-04-p8-weapon-identity-design.md`)
- 스타터 3종은 `곡괭이`, `네일건`, `랜턴`이다. (see design)
- 새 런 시작 직후, R1 타이머와 몹 스폰이 시작되기 전에 무기 선택 UI를 띄운다. 선택 전에는 게임이 진행되지 않고, 선택 후 R1이 시작된다. (see design)
- 게임오버 후 다시 시작할 때도 무기 선택 UI를 다시 띄운다. (see design)
- 기존 `드릴촉`은 P8 일반 플레이 스타터에서 제외하고, 선택한 스타터 무기 하나만 들고 시작한다. (see design)
- 조작은 기존처럼 자동 공격을 유지한다. 곡괭이와 네일건 모두 가장 가까운 적을 기준으로 조준한다. (see design)
- 곡괭이는 가장 가까운 적 방향의 짧은 전방 부채꼴 휘두르기다. (see design)
- 네일건은 가장 가까운 적을 향한 빠른 직선 투사체다. 방패 좀비에게 벽처럼 막히는 약점을 유지한다. (see design)
- 랜턴은 상시 오라가 아니라 1초 안팎의 쿨다운마다 플레이어 주변에 번지는 짧은 빛/불꽃 펄스다. (see design)
- 상점은 선택 무기 전용 강화와 플레이어 공용 스탯 아이템을 함께 제공한다. 무기 강화는 같은 효과 풀을 유지하되 선택 무기에 맞춰 표시명과 설명을 바꾼다. (see design)
- 전설 효과인 `쌍열 드릴 챔버` 계열은 `공격 레인/타격 횟수 +1` 역할로 해석한다. 네일건은 못 한 발 추가, 곡괭이는 보조 휘두름, 랜턴은 두 번째 펄스 또는 추가 빛 고리다. (see design)
- `곡괭이`, `네일건`, `랜턴`은 간단한 도트 아이콘을 새로 만든다. (see design)
- 세 무기는 모두 10라운드 클리어 가능성을 갖되, 난이도 체감은 달라도 된다. 특정 무기가 명백한 정답 또는 실패 전용이 되면 안 된다. (see design)
- 강화 목록, 아이템 목록, 유물 목록의 전면 재검토는 P8 구현 범위가 아니라 `todos/018-pending-p2-upgrade-item-relic-review.md`로 분리한다. (see todo: `todos/018-pending-p2-upgrade-item-relic-review.md`)

## Local Research Findings

### Repository Research Summary

- 프로젝트는 Godot 프로젝트이며 메인 씬은 `res://scenes/main.tscn`이다. 실행 파일은 `/Users/highfence/Dev/Sweep/engine/godot/bin/godot.macos.editor.arm64`다. (see `AGENTS.md`)
- 기획/계획/리뷰 문서는 기본 한글로 작성한다. (see `AGENTS.md`)
- `scripts/main.gd`가 게임 상태, 라운드, 무기, 상점, 보상, 계약, 적 행동, debug/capture 커맨드를 대부분 소유한다.
- `scripts/ui/game_ui.gd`는 HUD, 무기 표시, 선택/상점/종료 overlay, 일시정지 UI를 소유한다. `scripts/ui/ore_ui_theme.gd`는 theme/style helper를 소유한다.
- 현재 `_reset_run(start_playing)`은 새 런에서 `weapons.clear()` 후 `_add_weapon("drill_tip")`를 호출한다. P8에서는 이 흐름을 `무기 선택 전 대기 -> 선택 -> 선택 무기 장착 -> R1 시작`으로 바꿔야 한다.
- 현재 `weapon_catalog`에는 `drill_tip`, `spitter`, `flintlock`, `drill`, `coil`, `cleaver`, `launcher`가 있고, `fire_type`은 `bullet`, `arc`, `slash`, `explosive`가 있다. P8은 기존 타입을 재사용하되 `pickaxe`, `nailgun`, `lantern` 스타터 중심으로 재정리한다.
- 현재 `_fire_weapon()`은 `bullet`, `arc`, `slash`, `explosive`를 분기한다. 곡괭이는 기존 `slash`를 “거리 내 가까운 적 전체”가 아니라 “가장 가까운 적 방향의 전방 부채꼴”로 조정해야 한다.
- 현재 `hazard_zones`는 플레이어에게 피해를 주는 독/보스 장판이다. 랜턴은 적에게 피해를 주는 펄스이므로 같은 배열에 섞지 않는 편이 안전하다.
- 현재 상점 `part` 구매는 `_apply_weapon_part_stats()`에서 `weapons[0]`에 직접 붙는다. P8의 “선택 무기 하나만 장착” 범위에서는 유지 가능하지만, 표시명/설명은 선택 무기에 맞게 decorate해야 한다.
- `GameUI.render_weapons()`는 현재 무기 이름과 단계/피해 텍스트만 표시한다. P8에서는 선택 무기 아이콘과 계열을 상태 UI에서 읽히게 해야 한다.
- P7 이후 debug/capture 관례가 강하다. `--debug-p7-*`, `--capture-p7-*`, `--smoke-playtest` 패턴을 P8에도 이어간다.

### Institutional Learnings

- `docs/architecture/2026-05-31-godot-ui-system.md`는 게임 상태와 선택 처리를 `main.gd`, HUD/overlay 렌더링을 `GameUI`에 두는 책임 분리를 권장한다.
- `docs/solutions/ui-bugs/invisible-godot-ui-text-GodotPort-20260522.md`는 UI 변경이 headless 통과만으로 충분하지 않고 실제 캡처로 텍스트/레이아웃을 확인해야 한다고 기록한다.
- P7 plan과 todo는 큰 기능 구현에서 phase별 debug/capture를 만들고, 사용자 플레이 테스트 전 자체 회귀를 돌리는 패턴을 세웠다.

### External Research Decision

외부 리서치는 생략한다. P8은 보안, 결제, 외부 API, 새 프레임워크가 아니라 기존 Godot 프로토타입의 전투/상점/UI 내부 확장이다. 코드베이스에 이미 자동 공격, 선택 overlay, 상점 rarity, debug/capture 패턴이 있고, P8 디자인 문서가 충분히 구체적이다.

## Problem Statement

P7 이후 게임은 10라운드 위협/경제 루프를 갖췄지만, 플레이어 무기는 여전히 드릴촉 중심이다. 현재 구조에서는 플레이어가 “어떤 무기를 골랐기 때문에 같은 위험을 다르게 풀었다”는 감각을 검증하기 어렵다. 상점 부품도 드릴촉 중심 이름과 설명을 갖고 있어, P8의 `곡괭이`, `네일건`, `랜턴` 체계와 그대로 연결하면 판타지와 기능이 어긋날 수 있다.

P8은 무기 다양화의 첫 검증이다. 무기 수를 많이 늘리거나 런 중 장비 드랍을 바로 구현하면 변수가 커져, 기본 무기 감각이 실제로 다른지 판단하기 어렵다. 따라서 P8에서는 시작 무기 3종 선택과 선택 무기 전용 강화 해석에 집중한다.

## Proposed Solution

새 런 시작 직후 스타터 선택 overlay를 띄우고, `곡괭이`, `네일건`, `랜턴` 중 하나를 고르면 선택 무기 하나만 장착한 상태로 R1을 시작한다. 게임오버 후 다시 시작해도 같은 선택 overlay로 돌아간다.

무기별 기본 공격은 기존 자동 공격 흐름을 유지한다.

- 곡괭이: 가장 가까운 적 방향의 전방 부채꼴 근접 휘두르기.
- 네일건: 가장 가까운 적을 향한 빠른 직선 투사체.
- 랜턴: 플레이어 주변에 주기적으로 번지는 적 피해용 빛/불꽃 펄스.

상점은 선택 무기 전용 강화와 플레이어 공용 스탯 아이템을 함께 보여준다. 무기 강화 효과 풀은 P8에서 완전히 분리하지 않고, 표시명/설명/아이콘만 선택 무기에 맞춰 decorate한다. 전설 `projectiles_add` 계열은 무기별로 “못 한 발 추가”, “보조 휘두름”, “두 번째 펄스”처럼 해석한다.

## Technical Approach

### Architecture

- `scripts/main.gd`
  - P8 스타터 선택 상태와 선택 무기 id를 관리한다.
  - `_reset_run()`에서 무기를 바로 장착하지 않고, 일반 플레이에서는 스타터 선택 overlay를 먼저 연다.
  - `drill_tip`은 일반 스타터에서 제외하되 legacy/debug 용도는 남긴다.
  - `weapon_catalog`에 P8 스타터 3종을 추가하거나 기존 후보를 P8 id로 재정리한다.
  - `fire_type`에 필요한 경우 `pulse` 또는 `lantern_pulse`를 추가한다.
  - `slash`는 전방 부채꼴 판정으로 바꾸거나 `pickaxe_slash` 별도 타입으로 분리한다.
  - 상점 옵션 표시 전 `_decorate_shop_option_for_weapon()` 같은 helper로 선택 무기별 표시명/설명을 만든다.
  - `--debug-p8-weapon-routes`와 P8 capture/debug 커맨드를 추가한다.
- `scripts/ui/game_ui.gd`
  - 스타터 선택 카드에서 아이콘, 계열, 공격 감각, 강점, 약점을 표시한다.
  - 무기 HUD와 상태 summary에 선택 무기 아이콘/계열이 읽히게 한다.
  - 상점/일시정지 화면에서도 현재 선택 무기를 확인할 수 있게 한다.
- `scripts/ui/ore_ui_theme.gd`
  - 필요하면 무기 계열별 색상 helper를 추가한다.
- `assets/sprites/items/` 또는 적절한 `assets/sprites/weapons/`
  - `곡괭이`, `네일건`, `랜턴` 간단 도트 아이콘을 추가한다.
- `todos/`
  - P8 quest card를 추가하고 dashboard에 반영한다.
- `docs/plans/`
  - 구현 완료 후 이 plan의 status와 verification 기록을 갱신한다.

### Data Shape Suggestions

스타터 무기는 `weapon_catalog`에 다음 성격의 metadata를 둔다.

```gdscript
"pickaxe": {
  "name": "곡괭이",
  "family": "근접",
  "fire_type": "pickaxe_slash",
  "strength": "보스 딜타임",
  "weakness": "거미떼/투척 좀비",
  "icon": "res://assets/sprites/weapons/weapon_pickaxe.png",
}
```

상점 표시 치환은 기존 `shop_catalog` 원본을 직접 훼손하지 말고, overlay에 넘기기 전 duplicate/decorate한다.

```gdscript
func _decorate_shop_item_for_weapon(item: Dictionary) -> Dictionary:
  var option := item.duplicate(true)
  if str(option.get("kind", "")) == "part":
    # selected_weapon_id에 따라 name/desc/icon/meta만 치환
  return option
```

## SpecFlow Analysis

### User Flow Overview

1. 새 게임 시작
   - 시작 overlay에서 “시작”을 누른다.
   - 런 상태를 초기화한다.
   - R1 타이머/스폰 시작 전에 무기 선택 overlay를 띄운다.
   - 무기를 선택하면 해당 무기 하나만 장착하고 R1을 시작한다.

2. 전투 중 플레이
   - 선택 무기에 따라 자동 공격 형태가 달라진다.
   - 무기 HUD/상태 summary에서 현재 무기를 확인한다.
   - R1-R10 P7 루프는 유지된다.

3. 라운드 클리어 후 상점
   - 상점은 선택 무기 전용 강화와 플레이어 공용 스탯 아이템을 보여준다.
   - 리롤/구매/다음 라운드 흐름은 P7과 동일하게 동작한다.

4. 일시정지
   - ESC로 pause overlay를 열고 현재 무기/스탯/계약을 확인한다.
   - 계속/다시 시작이 정상 동작한다.

5. 게임오버/승리 후 재시작
   - 다시 시작 버튼을 누르면 새 런으로 초기화된다.
   - 다시 무기 선택 overlay가 뜬다.

### Missing Elements & Plan Defaults

- 선택 UI에서 “선택 전 mode”가 무엇인지 명확해야 한다. 기본값: `MODE_CHOICE` 또는 별도 `MODE_WEAPON_SELECT`를 사용하되, 선택 전에는 `_process` 전투 업데이트가 진행되지 않게 한다.
- smoke playtest가 무기 선택을 어떻게 처리할지 정해야 한다. 기본값: smoke는 기본 무기 인자 또는 deterministic 선택을 사용하고, 별도 인자로 특정 무기를 선택할 수 있게 한다.
- 랜턴 펄스가 보스에게 여러 번 중첩 타격되는지 정해야 한다. 기본값: 펄스 1회당 적 1회 피해.
- 곡괭이 부채꼴 판정이 방패 좀비 정면/측면과 어떻게 상호작용하는지 정해야 한다. 기본값: 기존 방패 정면 피해 감소는 유지하고, 곡괭이는 측면/뒤 히트 보상을 플레이테스트 후 조정한다.
- 기존 `weapon` kind 상점 아이템이 있다면 P8 범위에서 숨기거나 무시해야 한다. 기본값: P8에서는 상점에서 새 무기 구매를 제외한다.

## Implementation Phases

### Phase 1: Quest, Branch, Starter Selection Skeleton

- `todos/019-complete-p1-m1-d8-weapon-identity.md`와 `todos/README.md`를 D8 기준으로 갱신한다.
- `todos/README.md`에 P8 메인 퀘스트와 dashboard row를 추가한다.
- 새 worker branch/worktree에서 작업한다.
- `_reset_run()`의 자동 `drill_tip` 장착을 일반 플레이 경로에서 제거한다.
- 새 런 시작 후 무기 선택 overlay를 띄우고, 선택 전에는 R1 타이머와 스폰이 진행되지 않게 한다.
- 선택 후 선택 무기 하나를 장착하고 R1을 시작한다.
- 게임오버/승리 후 다시 시작도 무기 선택 overlay로 돌아가게 한다.

Success:

- 일반 시작/재시작에서 무기 선택이 먼저 뜬다.
- 선택 전 enemies/bullets/spawn timer가 진행되지 않는다.
- 선택 후 `weapons.size() == 1`이고 선택 id가 장착된다.

### Phase 2: P8 Weapon Catalog and Icons

- `pickaxe`, `nailgun`, `lantern` 무기 데이터를 추가한다.
- 기존 `drill_tip`은 debug/legacy 용도로 남기되 스타터 후보에서 제외한다.
- 간단한 도트 아이콘 3개를 추가한다.
- 선택 UI, HUD, 상점/일시정지 상태 summary에서 같은 아이콘을 재사용한다.
- 선택 UI 카드에는 계열, 공격 감각, 강점, 약점을 명확히 표시한다.

Success:

- 세 무기가 시각적으로 구분된다.
- starter 선택 카드가 “검증 의도”를 숨기지 않는다.
- 선택 무기 정보가 pause/shop 상태 확인에서도 보인다.

### Phase 3: Weapon Attack Signatures

- 곡괭이:
  - 가장 가까운 적 방향으로 전방 부채꼴 판정을 만든다.
  - 짧은 사거리, 강한 넉백, 보스 딜타임 보상을 갖게 한다.
  - 기존 `slash`를 바꾸거나 `pickaxe_slash` 별도 fire type으로 분리한다.
- 네일건:
  - 가장 가까운 적을 향한 빠른 직선 투사체다.
  - `bullet` 타입을 재사용하되 `shape`를 `nail` 등으로 분리해 그리기 쉽게 한다.
  - 방패 좀비 정면에 막히는 약점을 유지한다.
- 랜턴:
  - 상시 오라가 아닌 주기적 펄스다.
  - 적 피해용 펄스 효과 배열 또는 별도 fire type을 추가한다.
  - 기존 `hazard_zones`와 섞지 않는다.
  - 펄스 1회당 각 적 1회 피해를 기본값으로 둔다.

Success:

- 세 무기 공격 모양이 화면에서 구분된다.
- 곡괭이는 가까이 붙어야 강하고, 네일건은 직선으로 빠르게 쏘며, 랜턴은 타이밍 있는 원형 펄스로 무리를 처리한다.
- 특정 무기가 명백한 정답/실패 전용으로 보이지 않도록 1차 수치를 잡는다.

### Phase 4: Shop Decoration for Selected Weapon

- P7 상점 rarity/가격/리롤/next round 흐름은 유지한다.
- 플레이어 공용 스탯 아이템은 모든 무기에서 계속 등장한다.
- `part` 아이템은 선택 무기에 맞춰 표시명/설명/icon/meta를 치환한다.
- 같은 효과 풀을 유지하되, 특정 무기에 말이 안 되는 효과는 숨기거나 같은 역할의 표현으로 치환한다.
- `projectiles_add` 전설은 `공격 레인/타격 횟수 +1`로 해석한다.
  - 네일건: 못 한 발 추가
  - 곡괭이: 보조 휘두름 또는 두 번 휘두르기
  - 랜턴: 두 번째 펄스 또는 추가 빛 고리

Success:

- 상점에 드릴촉 전용 문구가 그대로 노출되지 않는다.
- 선택한 무기와 강화 이름/설명이 충돌하지 않는다.
- 리롤/구매/중복/unique 로직이 P7 회귀를 일으키지 않는다.

### Phase 5: Debug, Capture, Smoke

- `--debug-p8-weapon-routes`를 추가한다.
  - 세 스타터를 각각 선택한다.
  - 장착 id/name/fire type을 확인한다.
  - 공격 1회를 발생시키고 expected effect가 생겼는지 확인한다.
  - 상점 overlay option decoration이 선택 무기별로 달라지는지 확인한다.
- 가능하면 smoke playtest에 무기 선택 인자를 추가한다.
  - 예: `--smoke-playtest --weapon=pickaxe`
  - 인자가 없으면 deterministic 기본값을 사용한다.
- UI capture 후보를 추가한다.
  - `--capture-p8-weapon-select-ui`
  - `--capture-p8-weapon-hud`
  - `--capture-p8-shop-weapon-parts`
- 기존 회귀를 유지한다.
  - P7 reward routes, shop rarity, relic contracts, pause cycle, legendary aim, boss pierce splash 등.

Success:

- worker가 사용자 테스트 전 세 무기 루트를 자체 검증할 수 있다.
- UI 변경은 실제 캡처로 확인한다.

### Phase 6: Playtest Handoff

- `todos/019...`의 Work Log를 갱신한다.
- plan status는 구현 완료 후 `complete`로 갱신한다.
- 최종 커밋은 worker branch에 남긴다.
- main 병합/원격 push는 사용자 플레이 테스트 후 현재 기획 스레드에서 진행한다.

Success:

- 사용자가 세 무기를 직접 고르고 테스트할 수 있다.
- worker는 검증 결과와 남은 밸런스 질문을 짧게 보고한다.

## Alternative Approaches Considered

### 상점에서 새 무기 구매까지 구현

최종 목표와 가깝지만 P8의 “스타터별 10라운드 감각 비교” 원인을 흐린다. 이번 범위에서는 제외한다. (see design)

### 무기별 완전 별도 강화 목록 작성

장기적으로 필요하지만, P8에서 기본 무기 감각과 강화 목록 차이가 동시에 변하면 검증이 어려워진다. `todos/018...`로 분리한다. (see todo)

### 랜턴 상시 오라

쉽게 이해되지만 너무 안전한 정답 무기가 될 수 있다. P8에서는 주기적 펄스로 확정했다. (see design)

### 곡괭이 수동 방향 조작

근접 손맛은 좋아질 수 있지만 자동 공격 게임의 조작 문법이 바뀐다. P8에서는 가장 가까운 적 방향 자동 조준으로 확정했다. (see design)

## System-Wide Impact

### Interaction Graph

- `GameUI.start_requested` -> `main.gd._start_run()` -> `_reset_run(false or selection state)` -> `_open_weapon_select()` -> `GameUI.show_choice(...)`
- 무기 선택 카드 click -> `GameUI.option_selected` -> `_choose_starter_weapon(option)` -> `_equip_starter_weapon(id)` -> `_start_selected_run()` -> `mode = MODE_PLAY`
- 라운드 클리어 -> 기존 P7 reward chain -> `_open_shop()` -> `_roll_shop_stock()` -> `_show_shop_overlay()` -> 선택 무기별 option decoration
- ESC -> `_set_paused(true)` -> `game_ui.show_pause(_current_state_summary(), _active_relic_summary())` -> 현재 무기 정보 표시
- Game over restart -> `GameUI.start_requested` 또는 restart signal -> 새 런 초기화 -> 무기 선택 overlay

### Error & Failure Propagation

- 선택 무기 id가 `weapon_catalog`에 없으면 장착 실패와 빈 무기 상태가 생긴다. debug에서 unknown id를 실패로 처리한다.
- 선택 전 `MODE_PLAY`가 되면 스폰/타이머가 먼저 진행될 수 있다. debug에서 선택 전 elapsed/wave_timer/enemies가 변하지 않는지 확인한다.
- 상점 decoration이 원본 `shop_catalog`를 mutate하면 다음 리롤/다음 무기 테스트에 오염된다. duplicate를 사용한다.
- 랜턴 펄스를 `hazard_zones`에 섞으면 플레이어가 자기 무기 효과에 맞거나 독 장판 렌더와 충돌할 수 있다. 별도 배열/효과로 분리한다.

### State Lifecycle Risks

- `_reset_run()`에서 `selected_weapon_id`, weapon effects, pending pulses, shop seen counts를 모두 초기화해야 한다.
- 게임오버 후 재시작에서 이전 무기 icon/mods가 HUD에 남지 않아야 한다.
- 선택 무기 없는 상태에서 상점/debug가 열리지 않도록 guard가 필요하다.
- `weapons[0]` 적용 구조는 P8에서는 허용되지만, `weapons`가 비어 있을 때 part 구매가 조용히 실패하지 않도록 debug에서 확인한다.

### API Surface Parity

- 시작 overlay, 선택 overlay, 상점 overlay, pause overlay, end overlay에서 현재 무기 정보 표시가 일관되어야 한다.
- smoke/debug/capture는 일반 플레이의 무기 선택 흐름과 같은 장착 함수를 써야 한다.
- 기존 P7 debug/capture는 P8 변경 후에도 통과해야 한다.

### Integration Test Scenarios

- 새 런 시작 후 무기 선택 전 3초를 시뮬레이션해도 wave timer/enemies가 진행되지 않는다.
- `pickaxe`, `nailgun`, `lantern`을 각각 선택하면 weapon id/fire type/icon이 기대값이다.
- 각 무기가 공격 1회를 수행하고 bullets/slash/pulse effect 중 기대 효과를 만든다.
- 각 무기 선택 후 상점 stock이 선택 무기에 맞는 표시명/설명을 보여준다.
- 게임오버 restart 후 이전 선택 무기가 유지되지 않고 선택 UI가 다시 열린다.

## Acceptance Criteria

### Functional Requirements

- [ ] `곡괭이`, `네일건`, `랜턴` 스타터 선택 UI가 새 런 시작 직후 열린다.
- [ ] 선택 전에는 R1 타이머, 스폰, 전투 업데이트가 진행되지 않는다.
- [ ] 선택 후 해당 무기 하나만 장착되고 R1이 시작된다.
- [ ] 기존 `드릴촉`은 일반 플레이 스타터에서 제외된다.
- [ ] 게임오버/승리 후 다시 시작하면 무기 선택 UI가 다시 열린다.
- [ ] 곡괭이는 가장 가까운 적 방향의 전방 부채꼴 근접 공격이다.
- [ ] 네일건은 가장 가까운 적 방향의 빠른 직선 투사체다.
- [ ] 랜턴은 상시 오라가 아니라 주기적 적 피해 펄스다.
- [ ] 선택 UI는 각 무기의 계열, 공격 감각, 강점, 약점을 표시한다.
- [ ] 세 무기의 도트 아이콘이 선택 UI/HUD/상태 summary에서 구분된다.
- [ ] 상점은 선택 무기 전용 강화와 플레이어 공용 스탯 아이템을 함께 보여준다.
- [ ] 무기 강화 option은 선택 무기에 맞는 표시명/설명으로 치환된다.
- [ ] `projectiles_add` 전설은 선택 무기별 공격 레인/타격 횟수 증가로 해석된다.

### Non-Functional Requirements

- [ ] P7 계약/상점/reward chain/pause/game-over 루프가 깨지지 않는다.
- [ ] 상점 option decoration은 원본 `shop_catalog`를 오염시키지 않는다.
- [ ] 랜턴 적 피해 펄스는 플레이어 피해 hazard와 분리된다.
- [ ] UI 텍스트와 카드 레이아웃은 실제 capture로 확인된다.
- [ ] 세 무기는 난이도 체감이 달라도 되지만 명백한 정답/실패 전용이 되지 않는다.

### Quality Gates

- [ ] Godot headless load 통과
- [ ] `--debug-p8-weapon-routes` 통과
- [ ] P8 UI capture 1개 이상 확인
- [ ] `--smoke-playtest` 통과
- [ ] 가능하면 `--smoke-playtest --weapon=pickaxe`, `--weapon=nailgun`, `--weapon=lantern` 통과
- [ ] P7 debug 회귀 통과
- [ ] `git diff --check` 통과

## Success Metrics

- 플레이어가 시작 화면에서 세 무기의 의도를 즉시 이해한다.
- 같은 10라운드 루프에서 세 무기의 강한 구간과 약한 구간이 다르게 느껴진다.
- 상점 선택이 “선택한 무기를 어떻게 보강할까?”로 읽힌다.
- P7의 10라운드 위협/경제/계약 루프는 유지된다.
- 다음 브레인스토밍에서 강화 목록/아이템/유물을 재설계할 충분한 플레이 감각 데이터가 생긴다.

## Dependencies & Risks

### Dependencies

- P7 10라운드 위협/경제 루프 완료: `todos/017-complete-p1-m1-d7-ten-round-threat-economy.md`
- P8 디자인 확정: `docs/superpowers/specs/2026-06-04-p8-weapon-identity-design.md`
- UI 책임 분리: `docs/architecture/2026-05-31-godot-ui-system.md`

### Risks

- `main.gd`가 이미 많은 책임을 갖고 있어 무기/상점 helper를 추가하면 복잡해질 수 있다.
- 상점 표시명 치환이 원본 catalog를 mutate하면 리롤/방문/seen-count 로직이 깨질 수 있다.
- 랜턴 펄스가 너무 안전하면 정답 무기가 될 수 있다.
- 곡괭이 부채꼴이 너무 넓거나 강하면 근접 리스크가 사라진다.
- 무기 선택 overlay가 reward chain/pause/end overlay와 active choice state를 공유하므로 handler 꼬임이 생길 수 있다.

### Mitigation

- 선택/장착/상점 decoration helper를 작게 분리한다.
- 모든 overlay option은 duplicate 후 decorate한다.
- P8 전용 debug로 세 무기 route를 한 번에 검증한다.
- UI는 headless만 보지 말고 capture로 확인한다.
- 밸런스는 1차값으로 두고 사용자 플레이테스트 후 조정한다.

## Worker Sub Thread Protocol

P8 구현은 별도 worker thread/worktree에서 진행한다. 현재 대화는 기획실로 유지한다.

Worker에게 넘길 핵심 규칙:

- 이 plan, P8 design, origin brainstorm, P7 plan을 먼저 읽는다.
- 새 worktree/branch에서 작업한다.
- `main`/`origin/main`에 직접 푸시하지 않는다.
- 디자인이 이미 확정된 항목은 임의로 바꾸지 않는다.
- 무기 아이콘/공격 이펙트는 간단한 도트/primitive 수준으로 만든다. 고급 폴리시는 뒤로 미룬다.
- 강화 목록/아이템 목록/유물 목록 전면 재설계는 `todos/018...`로 분리되어 있으므로 P8 범위에 포함하지 않는다.
- 디자인 판단이 필요한 새 질문이 나오면 현재 기획 스레드에 질문한다.
- 내부 체크포인트마다 debug/capture를 만들고 결과를 보고한다.
- 최종적으로 worker branch에 커밋하되, main 병합/원격 push는 사용자 플레이 테스트 후 진행한다.

## Verification Commands

기본 검증:

```bash
/Users/highfence/Dev/Sweep/engine/godot/bin/godot.macos.editor.arm64 --headless --path /Users/highfence/Documents/Bro-exile --quit
```

```bash
/Users/highfence/Dev/Sweep/engine/godot/bin/godot.macos.editor.arm64 --headless --path /Users/highfence/Documents/Bro-exile -- --debug-p8-weapon-routes
```

```bash
/Users/highfence/Dev/Sweep/engine/godot/bin/godot.macos.editor.arm64 --headless --path /Users/highfence/Documents/Bro-exile -- --smoke-playtest
```

가능하면 무기별 smoke:

```bash
/Users/highfence/Dev/Sweep/engine/godot/bin/godot.macos.editor.arm64 --headless --path /Users/highfence/Documents/Bro-exile -- --smoke-playtest --weapon=pickaxe
```

```bash
/Users/highfence/Dev/Sweep/engine/godot/bin/godot.macos.editor.arm64 --headless --path /Users/highfence/Documents/Bro-exile -- --smoke-playtest --weapon=nailgun
```

```bash
/Users/highfence/Dev/Sweep/engine/godot/bin/godot.macos.editor.arm64 --headless --path /Users/highfence/Documents/Bro-exile -- --smoke-playtest --weapon=lantern
```

P7 회귀:

```bash
/Users/highfence/Dev/Sweep/engine/godot/bin/godot.macos.editor.arm64 --headless --path /Users/highfence/Documents/Bro-exile -- --debug-p7-reward-routes
```

```bash
/Users/highfence/Dev/Sweep/engine/godot/bin/godot.macos.editor.arm64 --headless --path /Users/highfence/Documents/Bro-exile -- --debug-p7-shop-rarity
```

```bash
/Users/highfence/Dev/Sweep/engine/godot/bin/godot.macos.editor.arm64 --headless --path /Users/highfence/Documents/Bro-exile -- --debug-p7-relic-contracts
```

```bash
/Users/highfence/Dev/Sweep/engine/godot/bin/godot.macos.editor.arm64 --headless --path /Users/highfence/Documents/Bro-exile -- --debug-p7-pause-cycle
```

기존 전투 회귀:

```bash
/Users/highfence/Dev/Sweep/engine/godot/bin/godot.macos.editor.arm64 --headless --path /Users/highfence/Documents/Bro-exile -- --debug-boss-pierce-splash
```

```bash
/Users/highfence/Dev/Sweep/engine/godot/bin/godot.macos.editor.arm64 --headless --path /Users/highfence/Documents/Bro-exile -- --debug-emerging-death-cleanup
```

UI capture 후보:

```bash
/Users/highfence/Dev/Sweep/engine/godot/bin/godot.macos.editor.arm64 --path /Users/highfence/Documents/Bro-exile -- --capture-p8-weapon-select-ui
```

```bash
/Users/highfence/Dev/Sweep/engine/godot/bin/godot.macos.editor.arm64 --path /Users/highfence/Documents/Bro-exile -- --capture-p8-shop-weapon-parts
```

## Future Considerations

- P8 이후 `todos/018...`에서 강화 목록, 아이템 목록, 유물 목록을 함께 재검토한다.
- 장기적으로 런 도중 상점/드랍/보상에서 장비를 습득하는 구조로 확장한다.
- P9에서는 다중 화폐 경제와 무기 강화/아이템/유물 목록을 연결한다.
- 유물은 장기적으로 광산에서 하나씩 발견하는 영구 성장/컬렉션 요소가 될 수 있다.

## Goal Prompt

아래 프롬프트를 `/goal` 또는 worker sub thread에 전달한다.

```text
P8 무기 정체성 검증 루프를 구현해줘.

작업 루트는 /Users/highfence/Documents/Bro-exile 이고, Godot 프로젝트다. 새 worktree/branch에서 작업하고 main/origin/main에 직접 푸시하지 마.

반드시 먼저 아래 문서를 읽고 그대로 따른다:
- docs/plans/2026-06-04-feat-p8-weapon-identity-loop-plan.md
- docs/superpowers/specs/2026-06-04-p8-weapon-identity-design.md
- docs/brainstorms/2026-06-03-p7-threat-economy-and-p8-weapon-identity-brainstorm.md
- docs/plans/2026-06-03-feat-p7-ten-round-threat-economy-plan.md

핵심 목표:
- 새 런 시작 직후 R1 타이머/스폰 전 무기 선택 UI를 띄운다.
- 스타터는 곡괭이, 네일건, 랜턴 3종이다.
- P8 일반 플레이에서는 기존 드릴촉을 스타터에서 제외하고, 선택 무기 하나만 들고 시작한다.
- 게임오버/승리 후 다시 시작하면 다시 무기 선택 UI로 돌아간다.
- 곡괭이는 가장 가까운 적 방향의 짧은 전방 부채꼴 근접 공격이다.
- 네일건은 가장 가까운 적 방향의 빠른 직선 투사체다.
- 랜턴은 상시 오라가 아니라 1초 안팎 쿨다운의 플레이어 주변 적 피해 펄스다.
- 상점은 선택 무기 전용 강화와 플레이어 공용 스탯 아이템을 함께 보여준다.
- 무기 강화는 기존 효과 풀을 유지하되 선택 무기에 맞는 표시명/설명으로 decorate한다.
- 쌍열 드릴 챔버 계열은 공격 레인/타격 횟수 +1로 해석한다.
- 곡괭이/네일건/랜턴 간단 도트 아이콘을 만들고 선택 UI/HUD/상점/일시정지에서 재사용한다.
- 강화 목록/아이템 목록/유물 목록 전면 재설계는 todos/018로 분리되어 있으니 P8 범위에 포함하지 않는다.

구현 단계:
1. todos/019-complete-p1-m1-d8-weapon-identity.md와 todos/README.md를 P8 quest 기준으로 갱신한다.
2. 무기 선택 UI와 선택 전 정지 상태를 구현한다.
3. P8 무기 catalog/icon/HUD 상태 표시를 구현한다.
4. 곡괭이/네일건/랜턴 공격 시그니처를 구현한다.
5. 선택 무기별 상점 강화 표시명/설명 decoration을 구현한다.
6. --debug-p8-weapon-routes와 필요한 capture를 추가한다.
7. 회귀 검증을 돌리고 결과를 보고한다.

필수 검증:
- git diff --check
- Godot headless load
- --debug-p8-weapon-routes
- --smoke-playtest
- 가능하면 --smoke-playtest --weapon=pickaxe, --weapon=nailgun, --weapon=lantern
- P7 회귀: --debug-p7-reward-routes, --debug-p7-shop-rarity, --debug-p7-relic-contracts, --debug-p7-pause-cycle
- 기존 전투 회귀: --debug-boss-pierce-splash, --debug-emerging-death-cleanup
- UI capture: --capture-p8-weapon-select-ui, --capture-p8-shop-weapon-parts

디자인 판단이 필요한 새 질문이 나오면 임의 확정하지 말고 현재 기획 스레드에 질문해. 최종적으로 worker branch에 커밋까지 남기고, main 병합/원격 push는 하지 마.
```

## Sources & References

### Origin

- **P8 design document:** `docs/superpowers/specs/2026-06-04-p8-weapon-identity-design.md`
  - 스타터 3종, 선택 시점, 드릴촉 제외, 자동 공격 유지, 랜턴 펄스, 선택 무기 전용 강화, 도트 아이콘, debug 요구를 carried forward했다.
- **Brainstorm document:** `docs/brainstorms/2026-06-03-p7-threat-economy-and-p8-weapon-identity-brainstorm.md`
  - P8은 무기 타입을 근접/원거리/마법/기묘한 광산 장비로 나누고, 무기마다 강한 몹 패턴과 약한 몹 패턴을 다르게 만든다는 방향을 carried forward했다.

### Internal References

- `AGENTS.md`: 한글 문서 작성과 Godot runbook.
- `scripts/main.gd`: 전투, 무기, 상점, 보상, debug/capture 중심 파일.
- `scripts/ui/game_ui.gd`: HUD, 무기 표시, 선택/상점/종료/pause overlay.
- `scripts/ui/ore_ui_theme.gd`: 공통 UI theme, rarity/card style helper.
- `docs/architecture/2026-05-31-godot-ui-system.md`: `main.gd`와 `GameUI` 책임 분리.
- `docs/solutions/ui-bugs/invisible-godot-ui-text-GodotPort-20260522.md`: UI capture 검증 필요성.
- `todos/017-complete-p1-m1-d7-ten-round-threat-economy.md`: P7 완료 기준과 debug/capture 관례.
- `todos/018-pending-p2-upgrade-item-relic-review.md`: P8 이후 아이템/유물/강화 목록 재검토 범위.
