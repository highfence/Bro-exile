---
title: "feat: P7 10라운드 위협/경제 재정비"
type: feat
status: complete
date: 2026-06-03
origin: docs/brainstorms/2026-06-03-p7-threat-economy-and-p8-weapon-identity-brainstorm.md
related_origins:
  - docs/plans/2026-06-03-feat-p6-map-camera-ui-spawn-readability-plan.md
  - docs/plans/2026-06-03-feat-p4-p5-prototype-validation-plan.md
  - docs/architecture/2026-05-31-godot-ui-system.md
---

# feat: P7 10라운드 위협/경제 재정비

## Overview

P7은 P6 이후 “클리어가 너무 쉽고 한 판이 너무 짧다”는 문제를 해결하기 위한 큰 프로토타입 마일스톤이다. 목표는 10라운드 한 사이클을 만들고, 플레이어가 첫 시도에 쉽게 완주하지 못하도록 난이도 곡선, 몹 패턴, 보스 패턴, 유물 계약, 상점 경제를 재정비하는 것이다. P7에서는 영구 성장 시스템을 아직 구현하지 않는다. 대신 죽음과 실패를 통해 “영구 성장이 필요하겠다”는 감각과 “다음에는 더 나아갈 수 있겠다”는 roguelike식 재도전 욕구를 검증한다. (see brainstorm: `docs/brainstorms/2026-06-03-p7-threat-economy-and-p8-weapon-identity-brainstorm.md`)

P8은 무기/장비 다양화, P9는 다중 화폐 경제로 분리한다. P7은 무기 판타지와 메타 경제를 크게 늘리지 않고, 현재 드릴촉 중심 빌드 안에서 난이도와 선택 압박이 작동하는지 먼저 본다. (see brainstorm: `docs/brainstorms/2026-06-03-p7-threat-economy-and-p8-weapon-identity-brainstorm.md`)

## Origin Decisions

- P7은 10라운드 한 사이클로 확장한다. (see brainstorm: `docs/brainstorms/2026-06-03-p7-threat-economy-and-p8-weapon-identity-brainstorm.md`)
- P7에서는 영구 성장 시스템을 구현하지 않고 난이도 곡선과 실패 경험을 먼저 검증한다. (see brainstorm)
- P7 난이도 검증의 성공 기준은 첫 블라인드 플레이에서 대부분 6-8R 사이에 실패하지만, 실패 원인이 억울한 숫자 압박이 아니라 “패턴 조합을 이해하면 다음에는 더 갈 수 있겠다”로 느껴지는 것이다.
- 큰 흐름은 1-3R 준비, 3R 후 계약 1, 4-5R 중간 보스 구간, 5R 후 계약 2, 6-7R 후반 진입, 7R 후 계약 3, 8-9R 후반 압박, 9R 최종 준비 상점, 10R 최종 보스다. (see brainstorm)
- 보상 배치는 1R 스탯, 2R 상점, 3R 계약+상점, 4R 상점, 5R 중간 보스 후 스탯+계약+상점, 6R 상점, 7R 스탯+계약+상점, 8R 상점, 9R 최종 준비 상점, 10R 최종 보스다.
- 라운드 길이는 R1 25초, R2 35초, R3 45초, R4 50초, R5 중간 보스 처치, R6 55초, R7 60초, R8 65초, R9 70초, R10 최종 보스 처치로 시작한다.
- 5R에는 중간 보스, 10R에는 최종 보스를 둔다. 중간 보스는 멈춤 후 돌진, 장판, 방패 좀비 1-2마리 소환으로 후반 패턴을 예고한다. 최종 보스는 체력 페이즈별로 돌진/장판/소환/탄막을 확장한다.
- 새 몹은 방패 좀비, 독/장판 거미, 자폭 광부 3종으로 확정한다. 방패 좀비는 5R 중간 보스 소환으로 먼저 보여주고 6R부터 일반 웨이브에 섞는다. 독/장판 거미는 7R, 자폭 광부는 8R부터 본격 등장한다.
- 유물은 라운드 보상 사이클과 분리하고, 3/5/7R 후 계약 이벤트에서 선택한다. 계약은 플레이어 스탯을 직접 올리지 않고, 몹 수를 늘리지 않으며, 기존 위험의 질을 올린다.
- 계약으로 강화된 위험 몹/엘리트/패턴은 처치 시 더 많은 광석 보상으로 이어진다. 보상 문구는 카드에 직접 수치로 쓰지 않고 “위험한 광맥일수록 더 많은 광석을 품는다.”처럼 짧게 암시한다.
- 계약은 중복 선택 가능하며 최대 III단계까지 누적된다. R5/R7 계약 선택지 중 하나는 가능하면 이전에 고른 계약의 다음 단계로 제안한다.
- 상점은 일반/레어/전설 등급 경제를 사용하고, 등급은 UI 카드 테두리/색상/라벨로 읽혀야 한다. (see brainstorm)
- 상점 아이템, 스탯 보상, 유물 계약 목록은 P7 기준으로 전면 재작성한다. 일반 아이템 7개, 레어 아이템 4개, 전설 대표 아이템 1개를 첫 기준으로 둔다.
- 라운드 클리어 후 보상/상점 UI는 다음 라운드 위험을 짧게 예고한다. 예: “다음 광맥: 방패를 든 무리”.
- 사망하면 게임오버 요약 화면에서 도달 라운드, 처치 수, 획득/사용 광석, 선택 계약과 단계, 구매한 희귀/전설 아이템을 보여준다.
- P7 구현은 하나의 큰 worker goal로 진행하되, 내부 체크포인트와 검증 커맨드를 강하게 둔다. 디자인 판단이 필요한 부분은 작업자가 이 기획 스레드에 질문을 남기고 사용자 확인 후 진행한다. (see brainstorm)

## Local Research Findings

### Repository Research Summary

- 프로젝트는 Godot 프로젝트이며 메인 씬은 `res://scenes/main.tscn`이다. 실행 파일은 `/Users/highfence/Dev/Sweep/engine/godot/bin/godot.macos.editor.arm64`다.
- `AGENTS.md`는 기획/계획/리뷰 문서를 기본 한글로 작성하라고 명시한다.
- `scripts/main.gd`가 핵심 전투 상태, 라운드 흐름, 상점/유물 선택, 몹 생성, 보스/적 행동, debug/capture 커맨드를 대부분 소유한다.
- `scripts/main.gd`의 현재 주요 진입점은 `MAX_ROUNDS`, `_finish_round`, `_open_relic_choice`, `_open_shop`, `_roll_shop_stock`, `_pick_enemy_kind`, `_enemy_cap`, `_make_enemy`, `_draw_enemies`, `_trigger_relic_death_hazard`, `_show_choice_overlay`다.
- 현재 `MAX_ROUNDS := 5`이며, `_finish_round()`은 라운드 종료 후 승리 또는 `_open_relic_choice()`로 바로 이동한다. P7에서는 이 단순 분기를 reward router로 바꿔야 한다.
- 현재 `stat_rewards`, `shop_catalog`, `relic_catalog`는 모두 `main.gd` 상단 배열로 정의되어 있다. P7에서는 이 목록을 전면 재작성하되, 파일 분리는 선택 사항이다. 큰 변경이므로 data helper를 추가해 가독성을 유지해야 한다.
- `GameUI`는 `CanvasLayer`이며 `show_choice`, `show_end`, `show_pause`, `update_hud`, `_make_option_card`를 통해 카드/오버레이를 렌더한다. 상점 등급 UI는 `scripts/ui/game_ui.gd`와 `scripts/ui/ore_ui_theme.gd`의 `option_card_style` 패턴을 확장하는 방식이 자연스럽다.
- P4-P6 이후 검증 커맨드는 `--smoke-playtest`, `--debug-spider-relic-wave2`, `--debug-boss-pierce-splash`, `--debug-emerging-death-cleanup`, `--capture-run-report-ui`, `--capture-combat-feedback`, `--capture-p6-map-camera`, `--capture-spawn-telegraph`, `--capture-pause-ui`가 있다.

### Institutional Learnings

- `docs/solutions/ui-bugs/invisible-godot-ui-text-GodotPort-20260522.md`는 UI 변경이 headless 통과만으로 충분하지 않고 실제 캡처로 텍스트/레이아웃을 확인해야 한다고 기록한다.
- `docs/architecture/2026-05-31-godot-ui-system.md`는 `main.gd`가 게임 상태와 선택 처리를 담당하고, `GameUI`가 HUD/overlay 표시를 담당하는 구조를 권장한다.
- P4/P5 계획은 런 결과와 debug 출력이 같은 summary를 공유해야 한다고 권장한다.
- P6 계획은 `_draw()` 월드 렌더와 CanvasLayer UI 좌표계를 분리한 뒤 실제 캡처로 확인하는 패턴을 세웠다.

### External Research Decision

외부 리서치는 생략한다. P7은 보안, 결제, 외부 API, 새 프레임워크가 아니라 기존 Godot 프로토타입의 내부 게임 규칙과 밸런스 구조 개편이다. 코드베이스에 이미 Godot 실행/검증/캡처 패턴이 있고, 사용자가 구체적인 게임 디자인 결정을 제공했다.

## Problem Statement

P6 이후 게임은 공간과 가독성은 좋아졌지만, 전체 플레이 루프는 여전히 5라운드 기준이며 클리어가 쉽다. 현재 라운드 구조는 roguelike식 “첫 실패 -> 학습/성장 필요 -> 더 나아감” 감각을 만들기에는 너무 짧고, 상점도 너무 적게 등장해 경제와 빌드 압박을 충분히 검증하기 어렵다.

또한 현재 유물은 “선택했다”는 존재감은 있지만, 플레이어에게 실제 위험 패턴을 강하게 요구하지 않는다. 상점도 관통/폭발/방어 관통 같은 강한 능력이 너무 쉽게 등장해 플레이어가 빠르게 완성 빌드에 도달한다.

## Proposed Solution

P7은 10라운드 한 사이클을 도입하고, 라운드별 보상 라우터를 만든다. 각 라운드 클리어 후 무엇을 열지 `_finish_round()`에서 직접 하드코딩하지 않고, 라운드 결과에 따라 스탯 보상, 큰 상점, 계약 이벤트, 중간 보스 후 보상, 최종 준비 상점을 명확히 라우팅한다.

P7은 다음 다섯 축을 동시에 조정한다.

1. **Stage/Threat**: 10라운드 계단식 난이도, 5R 중간 보스, 10R 최종 보스, 후반 새 몹 3종.
2. **Reward Rhythm**: 라운드별 스탯 보상/상점/계약 이벤트 배치.
3. **Economy**: 일반/레어/전설 등급 상점과 등급 UI.
4. **Contracts**: 3/5/7라운드 후 위험 품질을 높이고 광석 수익을 키우는 유물 계약.
5. **Run Report**: 실패 후 사망 요약으로 선택과 사망 지점을 복기하는 재도전 루프.

## Technical Approach

### Architecture

- `scripts/main.gd`
  - `MAX_ROUNDS`를 10으로 변경한다.
  - 라운드별 길이/보상/계약/보스 종류를 반환하는 helper를 추가한다.
  - `stat_rewards`, `shop_catalog`, `relic_catalog`를 P7 기준으로 재작성한다.
  - 다음 라운드 위험 예고, 계약 단계/광석 보상 modifier, elite 표시 상태, 게임오버 요약 데이터를 관리한다.
  - `enemy` kind와 boss behavior 상태를 확장한다.
  - 독/장판 hazard, 보스 돌진/탄막/소환 상태를 업데이트 루프에 추가한다.
  - P7 debug/capture 커맨드를 추가한다.
- `scripts/ui/game_ui.gd`
  - 상점 카드에 rarity 라벨/테두리/색상을 표시한다.
  - 스탯 보상/계약/상점 카드가 같은 `show_choice` 패턴을 공유하되, 카드 메타 텍스트와 rarity 표현이 명확해야 한다.
  - 계약 카드는 강화되는 위험을 본문으로 보여주고, 공통 보상 암시 문구만 하단에 표시한다.
  - 게임오버 요약 화면은 P7 런 요약 항목을 표시한다.
- `scripts/ui/ore_ui_theme.gd`
  - rarity별 카드 style helper를 추가하거나 `option_card_style`에 rarity 인자를 확장한다.
- `todos/`
  - P7 quest card를 추가하고 dashboard에 연결한다.
- `docs/plans/`
  - 이 plan을 구현 결과에 맞게 complete로 갱신한다.

### Design Checkpoints

아래 항목은 구현 중 디자인 판단이 필요하면 worker가 이 기획 스레드에 질문해야 한다. 임의로 확정하지 않는다.

- 방패 좀비, 독/장판 거미, 자폭 광부의 최종 이름, 실루엣, 색상, 아이콘/스프라이트 방향.
- 중간 보스와 최종 보스의 패턴 예고 시각 표현. 돌진 예고, 장판 경고, 탄막 발사 전조는 사용자가 볼 때 불공정하지 않아야 한다.
- 일반/레어/전설 상점 등급의 색상, 테두리, 라벨 명칭.
- P7 상점 아이템, 스탯 보상, 유물 계약 카드의 최종 아이콘 방향. 이름/기능은 이 문서의 확정안을 우선한다.
- 다음 라운드 위험 예고 문구의 최종 톤. 기능은 확정됐지만 문구는 플레이 테스트 후 조정 가능하다.
- 엘리트 몹 outline/aura/표식의 시각 방향.
- 전설 아이템 등장 시 특수 연출은 P7 범위 밖이다. 필요해 보이면 사용자와 논의하고 다음 마일스톤으로 미룬다.

## Implementation Phases

### Phase 1: Plan, Quest, Worker Setup

- `todos/017-complete-p1-m1-d7-ten-round-threat-economy.md` 생성.
- `todos/README.md`에 P7 메인 퀘스트와 dashboard row 추가.
- worker thread는 새 worktree/branch에서 진행한다.
- worker prompt는 이 plan을 origin으로 삼고, 디자인 체크포인트가 나오면 현재 기획 스레드에 질문하도록 지시한다.

Success:

- P7 목표, 범위, 라운드 흐름, 디자인 질문 규칙이 문서화된다.

### Phase 2: 10라운드 Reward Router

- `MAX_ROUNDS := 10`으로 변경.
- `_round_duration(round_index)`를 10라운드 기준으로 조정한다.
  - R1: 25초
  - R2: 35초
  - R3: 45초
  - R4: 50초
  - R5: 중간 보스 처치
  - R6: 55초
  - R7: 60초
  - R8: 65초
  - R9: 70초
  - R10: 최종 보스 처치
- `_finish_round()`의 `else: _open_relic_choice()` 흐름을 `_open_post_round_reward()` 같은 reward router로 교체한다.
- 라운드별 reward route:
  - 1R: 스탯 보상
  - 2R: 큰 상점
  - 3R: 계약 이벤트 -> 큰 상점
  - 4R: 큰 상점
  - 5R: 중간 보스 클리어 후 스탯 보상 -> 계약 이벤트 -> 큰 상점
  - 6R: 큰 상점
  - 7R: 스탯 보상 -> 계약 이벤트 -> 큰 상점
  - 8R: 큰 상점
  - 9R: 최종 준비 상점
  - 10R: 최종 보스 처치 후 승리
- 필요하면 `pending_reward_chain`을 둬서 “계약 후 상점”, “스탯 보상 후 계약 후 상점”처럼 연속 overlay를 처리한다.
- 보상/상점 UI 상단 또는 진입 직전에는 다음 라운드 위험 예고를 표시한다.
  - 예: “다음 광맥: 방패를 든 무리”
  - 예: “다음 광맥: 독 흔적”
  - 예: “다음 광맥: 불안정한 폭약 냄새”

Success:

- debug command로 각 라운드 클리어 후 다음 overlay route가 기대대로 출력된다.
- 기존 smoke playtest는 새 10라운드 루프를 따라 진행한다.
- R5/R7의 다단계 reward chain에서 overlay가 꼬이지 않는다.

### Phase 3: P7 Stat Rewards

- `stat_rewards` 목록을 전면 재작성한다.
- 스탯 보상은 상점 부품보다 작고 안정적인 성장이어야 한다.
- 스탯 보상은 무료 기본 체급 보정이며, 3개 중 1개를 고르는 구조로 시작한다.
- P7 스탯 보상 후보:
  - 공격 속도 아주 소폭 증가
  - 사거리 아주 소폭 증가
  - 이동 속도 아주 소폭 증가
  - 피해량 아주 소폭 증가
  - 최대 체력 아주 소폭 증가
  - 방어력 아주 소폭 증가
  - 라운드 중 미량 지속 회복 아주 소폭 증가
- 관통/폭발/투사체 추가 같은 레어/전설급 전투 능력은 스탯 보상에 넣지 않는다.
- 스탯 보상은 R1, R5 중간 보스 클리어 후, R7 클리어 후에 등장한다.

Success:

- 큰 상점이 없는 라운드에서도 “조금 대응해서 쉬워지는” 감각이 생긴다.
- 스탯 보상이 상점 등급 경제를 침식하지 않는다.

### Phase 4: P7 Shop Rarity Economy

- `shop_catalog`를 P7 기준으로 전면 재작성한다.
- 모든 상점 아이템에 `rarity` 필드를 추가한다.
  - `common`: 자주 등장, 저렴, 안정 성장.
  - `rare`: 드물게 등장, 비쌈, 관통/폭발/방어 관통 같은 대응 핵심 능력.
  - `legendary`: 매우 드물게 등장, 한 런에 0-1개 기대, 투사체 추가 같은 큰 파워 변화. 클리어 필수 조건이 되면 안 된다.
- P7 일반 아이템 확정안:
  - `윤활 베어링`: 공격 속도 소폭 증가
  - `연장 샤프트`: 사거리 소폭 증가
  - `경량 손잡이`: 이동 속도 소폭 증가
  - `강화 드릴촉`: 피해량 소폭 증가
  - `보강 흉갑`: 최대 체력 소폭 증가
  - `응급 압축팩`: 라운드 중 미량 지속 회복
  - `보강 장갑판`: 받는 피해 소폭 감소. 단, 최소 피해는 남기고 보스 돌진/자폭/독 장판 같은 핵심 패턴을 무력화하지 않는다.
- P7 레어 아이템 확정안:
  - `관통 드릴촉`: 방패 라인/거미떼 대응
  - `폭약 코어`: 거미떼/밀집 적 대응
  - `장갑 파쇄날`: 방패 좀비/보스 대응
  - `반동 스프링`: 자폭 광부/빠른 좀비 대응, 넉백 강화
- P7 전설 아이템 확정안:
  - `쌍열 드릴 챔버`: 드릴촉을 한 발 더 발사한다. 너무 강하면 피해량 보정이나 발사 각도를 조정한다.
- `_roll_shop_stock()`에 rarity weight를 추가한다.
- 전설은 존재하지만 보장하지 않는다. 후반 상점일수록 확률을 조금 올리되, 기대값은 한 판에 0-1개 정도로 둔다.
- 레어/전설 pity 또는 seen-count 보정은 첫 P7 패스에서는 과하게 만들지 않는다. 필요하면 debug로 등장률만 확인한다.
- `_scaled_shop_cost()`는 rarity와 wave를 함께 반영한다.
- `GameUI._make_option_card()` 또는 `OreUITheme.option_card_style()`을 확장해 rarity 라벨/테두리/색상을 표시한다.

Success:

- 상점에서 일반/레어/전설이 시각적으로 즉시 구분된다.
- 레어/전설은 강하지만 자주 나오지 않고 비싸다.
- 리롤만으로 완성 빌드를 쉽게 만들기 어렵다.

### Phase 5: P7 Relic Contracts

- `relic_catalog`를 P7 기준으로 전면 재작성한다.
- 유물은 라운드 보상 사이클과 분리하고 3/5/7라운드 후 계약 이벤트에서만 등장한다.
- 계약은 플레이어 능력치를 직접 올리지 않는다.
- 계약은 몹 팩 수를 늘리지 않는다. 몹 수 증가는 곧 보상 증가로 이어져 위험 선택이 아니라 쉬운 경제 선택이 될 수 있기 때문이다.
- 계약은 기존 위험의 수준, 방어, 지속 시간, 전조 시간, 엘리트 승급처럼 “질”을 올린다.
- 계약으로 강화된 위험 몹/엘리트/패턴은 처치 시 추가 광석을 준다. 위험 단계와 광석 보상은 함께 증가한다.
- 계약 카드는 보상 수치를 직접 보여주지 않고, 하단에 “위험한 광맥일수록 더 많은 광석을 품는다.” 정도의 공통 암시만 둔다.
- 계약 이벤트마다 3개 선택지를 보여주고 1개를 고른다.
- 같은 계약은 중복 선택 가능하며 최대 III단계까지 누적된다.
- R5/R7 계약 선택지 중 하나는 가능하면 이전에 고른 계약의 다음 단계를 제안한다.
- 엘리트 몹은 새 행동 패턴을 만들지 않고 기존 몹의 강화판으로 둔다. 체력/피해/속도/방어 중 일부가 강화되고, outline/aura/작은 표식으로 구분하며, 처치 시 일반 몹보다 광석을 더 준다.
- P7 계약 후보:
  - `과열된 발걸음`: 빠른 좀비 이동 속도 증가
  - `날카로운 투척`: 투척 좀비 투사체 속도 또는 피해 증가
  - `거친 광맥`: 일반 몹 체력/피해 소폭 증가
  - `선별된 사냥감`: 일부 기존 몹이 엘리트로 승급
  - `금 간 방패의 맹세`: 방패 좀비의 정면 방어 강화
  - `질척이는 독맥`: 독 장판 유지 시간 증가
  - `짧아진 도화선`: 자폭 광부의 돌진 전조 감소
  - `깨어난 우두머리`: 보스 패턴 간격 감소 또는 패턴 강화
- R3 계약 후보는 아직 등장하지 않은 방패 좀비/독 거미/자폭 광부/보스 강화 계약을 제외한다. R3 후보는 `과열된 발걸음`, `날카로운 투척`, `거친 광맥`, `선별된 사냥감`으로 제한한다.
- R5 계약 후보는 R3 후보 전체에 `금 간 방패의 맹세`, `질척이는 독맥`, `짧아진 도화선`을 추가한다.
- R7 계약 후보는 이전 후보 전체와 필요 시 `깨어난 우두머리`를 포함한다.

Success:

- 유물을 고른 뒤 다음 구간에서 “이 계약 때문에 전장 위험의 질이 올라갔다”가 보인다.
- 계약 이벤트가 3번뿐이므로 선택 하나의 무게가 느껴진다.
- 계약은 직접 강화가 아니라 위험 처치 -> 광석 -> 상점 구매 루프로 보상된다.

### Phase 6: New Enemy Archetypes

- 새 enemy kind 3종 추가:
  - `shield_zombie`: 5R 중간 보스가 1-2마리 소환해 예고하고, 6R부터 일반 웨이브에 섞는다. 정면 피해를 크게 줄이고 느리게 전진해 다른 적을 보호하는 전선 역할을 한다. 대응은 관통, 방어 관통, 폭발, 측면 이동, 사거리 확보.
  - `toxic_spider`: 7R부터 해금. 체력이 낮고 직접 피해는 약하지만 죽을 때만 독 장판을 남긴다. 독 장판은 3-4초 유지되고, 밟으면 약한 지속 피해를 주며, 즉사 위험보다 이동 경로를 잠깐 망가뜨리는 역할을 한다.
  - `bomb_miner`: 8R부터 해금. 느리게 접근하다가 일정 거리에서 멈추고 0.6-0.9초 전조 후 짧게 돌진한다. 돌진 종료 또는 플레이어 충돌 시 폭발하며, 플레이어에게 큰 피해를 주고 주변 몹에게 약간의 피해를 준다.
- 각 몹은 한 가지 압박만 담당한다.
- 새 몹은 P6 스폰 예고 시스템을 그대로 사용한다.
- 디자인 체크포인트: 새 몹의 최종 이름/색상/실루엣/아이콘이 필요하면 사용자에게 질문한다.

Success:

- 새 몹은 한꺼번에 쏟아지지 않고 구간별로 학습된다.
- 새 몹마다 요구하는 플레이 대응이 다르다.

### Phase 7: Mid Boss and Final Boss

- 5R 중간 보스:
  - 후반 패턴을 미리 보여주는 시험관문 역할.
  - 멈춤 -> 돌진 전조 -> 짧은 돌진.
  - 바닥 장판 생성.
  - 방패 좀비 1-2마리 소환.
  - 첫 플레이어가 실수하면 위험하지만, 전조를 보면 넘길 수 있는 난이도로 둔다.
- 10R 최종 보스:
  - 첫 P7 플레이에서 거의 못 깨도 괜찮지만, 패턴을 보면 다음에 깰 수 있겠다는 느낌을 줘야 한다.
  - 체력 100-70%: 돌진 + 장판.
  - 체력 70-35%: 돌진 + 장판 + 소환.
  - 체력 35-0%: 돌진 + 장판 + 소환 + 탄막.
  - 소환은 방패 좀비 1마리, 빠른 좀비 2마리, 장판 거미 2-3마리, 자폭 광부 1마리 같은 소량 후보에서 고른다. 몹 수로 밀어붙이지 않도록 소환 캡을 둔다.
  - 계약으로 엘리트 출현이 강화되어 있으면 낮은 확률로 소환몹이 엘리트가 될 수 있다.
  - 탄막은 정교한 탄막 슈팅이 아니라 보스가 잠깐 멈추고 여러 방향으로 느린 돌/광산 파편을 뿌리는 단순 패턴이다.
  - 후반 유물 위험과 몹 패턴의 결산 역할.
- 보스 패턴에는 반드시 시각적/시간적 예고가 있어야 한다.
- 기존 `boss` kind를 분기할지, `mid_boss`/`final_boss` kind로 분리할지 worker가 코드 단순성을 기준으로 선택한다. 단, debug 출력에서는 중간/최종 보스가 구분되어야 한다.

Success:

- 5R 보스는 “큰 느린 좀비”가 아니라 패턴을 읽고 피해야 하는 적이 된다.
- 10R 보스는 돌진/장판/소환/탄막으로 최종 결산 압박을 준다.

### Phase 8: Game Over Summary, Tuning, and Debug Harness

- 사망 시 게임오버 요약 화면을 표시한다.
- P7 게임오버 요약 필수 항목:
  - 도달 라운드
  - 처치 수
  - 획득/사용한 광석
  - 선택한 계약 목록과 단계
  - 구매한 희귀/전설 아이템
- 일반 아이템 전체 목록은 P7 게임오버 요약에서 생략하고, 나중에 전체 빌드 상세로 확장한다.
- P7 전용 debug/capture 커맨드 후보:
  - `--debug-p7-reward-routes`: 1-9R 클리어 후 route가 기대대로인지 출력.
  - `--debug-p7-shop-rarity`: 여러 번 상점 roll을 돌려 common/rare/legendary 빈도와 가격 범위 출력.
  - `--debug-p7-relic-contracts`: 3/5/7 계약 이벤트 후보, 중복 제안, 단계별 위험/광석 보상 modifier 출력.
  - `--debug-p7-boss-patterns`: 중간/최종 보스 패턴 상태가 발생하는지 확인.
  - `--capture-p7-shop-rarity-ui`: 등급 카드 UI 캡처.
  - `--capture-p7-contract-ui`: 계약 이벤트 UI 캡처.
  - `--capture-p7-boss-patterns`: 보스 예고/장판/탄막 캡처.
  - `--capture-p7-game-over-summary`: 사망 요약 화면 캡처.
- 기존 검증 커맨드를 유지한다.
- `--smoke-playtest`는 P7에서는 항상 승리해야만 하는 테스트가 아닐 수 있다. 하지만 자동 smoke는 “루프가 멈추지 않고 결과를 낸다”를 확인해야 한다. 필요하면 smoke player를 강하게 만들어 승리 smoke와 일반 난이도 smoke를 분리한다.

Success:

- 새 흐름을 콘솔과 캡처로 빠르게 검증할 수 있다.
- P7 worker가 사용자 테스트 전 자체 회귀를 충분히 돌릴 수 있다.

### Phase 9: Documentation and Commit

- `todos/017-ready...`를 구현 결과에 맞게 `complete`로 갱신한다.
- `todos/README.md`에 P7 완료 상태를 반영한다.
- 이 plan의 status를 complete로 갱신한다.
- 커밋은 최소 두 개 이상을 권장한다.
  - P7 structure/economy pass.
  - P7 enemy/boss pattern pass.
  - 필요하면 P7 tuning/fix pass.
- 원격 main 푸시는 사용자 플레이 테스트와 승인 후 진행한다.

## Alternative Approaches Considered

### A. 5라운드 유지 + 보스 페이즈만 강화

검증 속도는 빠르지만, 사용자가 원하는 roguelike식 “첫 실패 -> 성장 필요 -> 더 나아감” 감각을 만들기에는 루프가 너무 짧다. 상점과 계약 이벤트 빈도도 부족하다.

### B. 7라운드 확장

5라운드보다 여정감은 생기지만, 사용자가 원하는 상점/경제/계약 리듬을 충분히 검증하기에는 여전히 짧다.

### C. 10라운드 확장

P7 범위는 커지지만, 실패/재도전 욕구, 중간 보스, 최종 보스, 계약 이벤트, 상점 등급 경제를 한 사이클 안에서 검증하기에 가장 적합하다. 이 접근을 선택한다. (see brainstorm: `docs/brainstorms/2026-06-03-p7-threat-economy-and-p8-weapon-identity-brainstorm.md`)

## System-Wide Impact

### Interaction Graph

- `_process` -> `_update_game` -> `wave_timer` 만료 -> `_finish_round`.
- `_finish_round` -> `_open_post_round_reward` -> reward chain queue -> 스탯 보상/계약/상점/승리 중 필요한 순서로 연다.
- 선택 overlay -> `GameUI.option_selected` -> `_on_ui_option_selected` -> active choice handler -> 다음 reward chain 또는 `_start_next_round`.
- `_spawn_enemies` -> `_pick_enemy_kind` -> P7 wave table / relic contract modifier -> `_queue_spawn_warning`.
- `_update_enemies` -> enemy kind별 behavior -> 장판 hazard/탄막/돌진/소환 상태 업데이트.
- `_draw` -> spawn warnings, hazards, enemies, boss telegraph, projectiles -> CanvasLayer UI.
- `GameUI.show_choice` -> rarity/contract/stat 카드 표시.

### Error & Failure Propagation

- Reward router가 잘못되면 특정 라운드 후 진행이 막힌다. `--debug-p7-reward-routes`로 모든 route를 검증해야 한다.
- P7 boss death와 wave transition이 겹치면 승리/다음 reward가 중복될 수 있다. boss defeat path는 일반 round timeout과 분리해야 한다.
- 장판 hazard와 폭발 이펙트는 `sparks`처럼 life를 가진 상태로 관리해야 하며, P6의 emerging enemy cleanup 버그를 반복하지 않아야 한다.
- 상점 rarity roll은 확률이므로, debug 출력으로 빈도와 가격 범위를 확인해야 한다.

### State Lifecycle Risks

- 라운드 종료 시 `enemies`, `bullets`, `enemy_projectiles`, `pickups`, `spawn_warnings`, 새 hazard 배열, boss pattern state를 모두 비워야 한다.
- 연속 reward chain에서 `_hide_overlay`, `mode`, `active_choice_method`, `active_choice_options`가 꼬이지 않도록 한다.
- 계약 이벤트는 라운드 보상과 분리되어야 한다. “상점 후 계약”이나 “계약 후 상점” 같은 예외 흐름은 명시적 queue로 관리한다.
- smoke playtest가 자동 선택을 할 때 disabled/cost/route 상태를 처리하지 못하면 멈출 수 있다.

### API Surface Parity

- 승리/패배 overlay, smoke 출력, debug 출력은 P4의 run report summary를 계속 공유해야 한다.
- 상점 UI, 스탯 보상 UI, 계약 UI는 모두 `GameUI.show_choice`를 사용하되, 카드 타입/rarity/metatext가 구분되어야 한다.
- Pause overlay의 상태 요약은 10라운드, rarity 구매, 계약 수, 중간/최종 보스 구분을 반영해야 한다.

### Integration Test Scenarios

1. 1R 클리어 후 스탯 보상 -> 다음 라운드 시작.
2. 2R 클리어 후 큰 상점 -> 구매/리롤/다음 라운드.
3. 3R 클리어 후 계약 이벤트 -> 상점 -> 선택한 계약 위험이 4-5R에 반영.
4. 5R 중간 보스 처치 후 스탯 보상 -> 계약 이벤트 -> 상점 연속 흐름.
5. 7R 클리어 후 스탯 보상 -> 계약 이벤트 -> 상점 연속 흐름.
6. 9R 최종 준비 상점 후 10R 최종 보스 진입.
7. 상점 rarity가 UI와 가격/등장률에 반영.
8. 새 몹 3종이 해금 라운드 전에는 나오지 않고, 해금 후에는 적절히 등장.
9. 중간/최종 보스 패턴 예고와 피해 판정이 정상 동작.
10. 게임오버 요약이 도달 라운드/처치/광석/계약/희귀·전설 구매를 표시.
11. 기존 P3-P6 debug/smoke 회귀가 깨지지 않음.

## SpecFlow Analysis

### User Flow Overview

1. 플레이어가 런을 시작한다.
2. 1-3R에서 기본 패턴을 학습하고 첫 계약 전 준비를 한다.
3. 3R 후 계약 이벤트에서 기존 적/기본 난이도 위험을 선택하고, 상점에서 대응을 준비한다.
4. 4-5R에서 첫 계약 위험과 중간 보스 패턴을 겪고, 중간 보스가 소환하는 방패 좀비를 예고로 본다.
5. 5R 보스 후 스탯 보상 -> 계약 -> 상점 순서로 후반 위험을 선택하고 대응을 준비한다.
6. 6-7R에서 방패 좀비와 독/장판 거미, 누적 계약 위험을 겪는다.
7. 7R 후 스탯 보상 -> 계약 -> 상점 순서로 마지막 위험 방향을 정한다.
8. 8-9R에서 자폭 광부와 누적 계약 위험을 겪고, 9R 최종 준비 상점 후 10R 최종 보스에 진입한다.
9. 죽으면 게임오버 요약을 보고 실패 지점과 선택을 복기한다. P7에서는 영구 성장 보상은 없다.

### Missing Elements & Gaps

- 상점 아이템/스탯 보상/유물 계약의 기능과 1차 이름은 확정됐다. 아이콘과 최종 시각 표현은 아직 확정되지 않았다.
- 새 몹과 보스 패턴의 시각 디자인은 구현 중 사용자 확인이 필요할 수 있다.
- P7에서 smoke playtest가 “승리”를 목표로 할지 “결과 산출”을 목표로 할지 worker가 분리해야 한다.
- 보스 강화 계약은 보상 사용 시간이 짧아질 수 있으므로, R7 후보로만 제한하거나 낮은 우선순위로 다루는지 worker가 구현 중 debug로 검증해야 한다.

### Recommended Resolutions

- 디자인 관련 미확정 사항은 worker가 질문하고, 임의 확정하지 않는다.
- 첫 P7 implementation은 스프라이트 완성보다 읽히는 primitive/색상/예고를 우선한다.
- smoke는 강한 자동 플레이어용 “route victory smoke”와 일반 난이도용 “difficulty probe”를 분리하는 것을 고려한다.

## Acceptance Criteria

### Functional Requirements

- [x] `MAX_ROUNDS`가 10라운드 구조로 동작한다.
- [x] 1R 스탯, 2R 상점, 3R 계약+상점, 4R 상점, 5R 중간 보스 후 스탯+계약+상점, 6R 상점, 7R 스탯+계약+상점, 8R 상점, 9R 최종 준비 상점, 10R 최종 보스 흐름이 동작한다.
- [x] P7에서는 영구 성장 시스템을 구현하지 않는다.
- [x] 라운드 길이는 R1 25초, R2 35초, R3 45초, R4 50초, R5 보스 처치, R6 55초, R7 60초, R8 65초, R9 70초, R10 보스 처치로 시작한다.
- [x] 계단식 난이도와 “어려워졌다 -> 강화 후 대응해서 조금 쉬워짐” 리듬이 smoke/debug/capture에서 1차 확인된다.
- [x] 상점 아이템 목록이 P7 기준으로 전면 재작성된다.
- [x] 상점 아이템은 common/rare/legendary rarity를 가진다.
- [x] 상점 UI에서 rarity가 라벨/색상/테두리로 읽힌다.
- [x] 일반 아이템 7개, 레어 아이템 4개, 전설 대표 아이템 `쌍열 드릴 챔버`가 구현된다.
- [x] 레어는 관통/폭발/방어 관통/넉백 강화 같은 핵심 대응 능력을 포함한다.
- [x] 전설은 투사체 추가처럼 빌드 파워를 크게 바꾸는 능력을 포함하며 매우 드물고, 한 판에 반드시 보장되지 않는다.
- [x] 스탯 보상 목록이 P7 기준으로 전면 재작성되고, 레어/전설급 능력을 직접 주지 않는다.
- [x] 유물 계약 목록이 P7 기준으로 전면 재작성된다.
- [x] 유물은 3/5/7라운드 후 계약 이벤트에서 선택한다.
- [x] 유물 계약은 플레이어 스탯을 직접 올리지 않고, 몹 팩 수를 늘리지 않으며, 위험의 질과 광석 보상을 함께 올린다.
- [x] 계약은 최대 III단계까지 중복 선택 가능하고, R5/R7 선택지 중 하나는 가능하면 이전 계약의 다음 단계를 제안한다.
- [x] 계약 카드는 보상을 수치로 직접 쓰지 않고, 위험 강화와 보상 암시 문구만 보여준다.
- [x] 엘리트 몹은 기존 몹의 강화판으로 출현하고 outline/aura/표식으로 구분된다.
- [x] 방패 좀비, 독/장판 거미, 자폭 광부가 추가된다.
- [x] 새 몹은 구간별로 하나씩 해금된다.
- [x] 방패 좀비는 5R 중간 보스 소환으로 예고되고 6R부터 일반 웨이브에 섞인다.
- [x] 독/장판 거미는 죽을 때만 3-4초 유지되는 독 장판을 남긴다.
- [x] 자폭 광부는 느린 접근 -> 정지 -> 전조 -> 짧은 돌진 -> 자폭 패턴을 가진다.
- [x] 5R 중간 보스는 멈춤 후 돌진, 장판, 방패 좀비 소환 패턴을 가진다.
- [x] 10R 최종 보스는 체력 페이즈별로 돌진, 장판, 소환, 탄막 패턴을 확장한다.
- [x] 보스와 위험 패턴에는 플레이어가 읽을 수 있는 예고가 있다.
- [x] 사망 시 게임오버 요약 화면이 도달 라운드, 처치 수, 획득/사용 광석, 선택 계약과 단계, 구매한 희귀/전설 아이템을 보여준다.

### Quality Gates

- [x] Godot headless load 통과.
- [x] `git diff --check` 통과.
- [x] `--debug-spider-relic-wave2` 통과 또는 P7에 맞게 갱신된 equivalent 통과.
- [x] `--debug-boss-pierce-splash` 통과.
- [x] `--debug-emerging-death-cleanup` 통과.
- [x] `--debug-p7-reward-routes` 통과.
- [x] `--debug-p7-shop-rarity` 통과.
- [x] `--debug-p7-relic-contracts` 통과.
- [x] `--smoke-playtest`가 P7 루프에서 멈추지 않고 결과를 낸다.
- [x] `--capture-p7-shop-rarity-ui` 캡처 확인.
- [x] `--capture-p7-contract-ui` 캡처 확인.
- [x] `--capture-p7-boss-patterns` 캡처 확인.
- [x] `--capture-p7-game-over-summary` 캡처 확인.
- [x] UI 변경은 headless만으로 끝내지 않고 실제 캡처로 확인한다.
- [x] 디자인 판단이 필요한 부분은 최종 시각 스타일 리스크로 남기고, P7 구현은 기존 asset과 primitive 예고로 제한했다.

## Success Metrics

- 첫 일반 난이도 블라인드 플레이에서 대부분 6-8라운드 사이 실패가 발생하지만, 죽음이 억울함보다 학습으로 남는다.
- 2-3번째 플레이에서는 상점/스탯/계약 대응을 더 잘해서 9-10라운드까지 가거나 클리어할 수 있다.
- 플레이어는 실패 후 “다음에는 더 잘할 수 있겠다”와 “영구 성장도 필요하겠다”를 느낀다.
- 3/5/7 계약 선택 이후 다음 구간 위험과 광석 보상 증가가 실제로 체감된다.
- 레어/전설 아이템은 강하지만 쉽게 완성 빌드를 만들 정도로 자주 나오지 않는다.
- 상점/스탯/계약/보스 리듬이 길어진 10라운드에서도 늘어지지 않는다.
- 게임오버 요약이 P7 실패 지점과 선택을 복기하는 데 도움이 된다.

## Dependencies & Risks

Dependencies:

- P6의 `WORLD_SIZE`, 카메라, 화면 안 스폰 예고, pause/status overlay가 main에 반영되어 있다.
- P4 run report와 smoke/debug 출력이 유지되어야 한다.
- Godot 실행 파일은 `/Users/highfence/Dev/Sweep/engine/godot/bin/godot.macos.editor.arm64`를 사용한다.

Risks:

- P7은 scope가 크다. 라운드 구조, 경제, 몹, 보스, UI를 한 번에 바꾸므로 내부 체크포인트가 없으면 버그가 누적될 수 있다.
- 새 몹 3종과 보스 패턴이 모두 들어가면 난이도가 억울해질 수 있다.
- 상점 rarity가 너무 빡세면 플레이어가 대응하지 못하고, 너무 느슨하면 P7 목표가 실패한다.
- 계약이 몹 팩 증가로 구현되면 위험 선택이 아니라 쉬운 보상 선택이 될 위험이 있다.
- 계약이 직접 스탯 보상으로 구현되면 상점 루프와 분리될 위험이 있다.
- 보스 강화 계약은 선택 후 보상을 상점에서 쓸 시간이 적어질 수 있다.
- UI rarity 색상/라벨이 기존 P6 상점 상태 요약과 겹쳐 읽기 어려울 수 있다.

Mitigations:

- worker는 Phase별 debug/capture를 만들고, 한 단계씩 검증한다.
- 새 패턴은 반드시 예고를 갖는다.
- smoke/debug 출력에 라운드, route, rarity roll, active contracts, contract level, ore modifier, boss pattern state를 남긴다.
- 계약 구현은 몹 수 증가가 아니라 위험 품질/엘리트 승급/패턴 강화 중심으로 제한한다.
- 디자인 판단이 필요한 항목은 사용자에게 질문한다.
- 첫 P7 구현은 완벽한 밸런스보다 “압박과 대응 리듬이 있는지”를 검증한다.

## Worker Sub Thread Protocol

P7 구현은 별도 worker thread/worktree에서 진행한다. 현재 대화는 기획실로 유지한다.

Worker에게 넘길 핵심 규칙:

- 이 plan과 origin brainstorm을 먼저 읽는다.
- 새 worktree/branch에서 작업한다.
- `main`/`origin/main`에 직접 푸시하지 않는다.
- 디자인 판단이 필요한 몹 실루엣, 보스 예고, rarity 색상, 아이템/계약 아이콘과 최종 문구는 사용자 확인 없이 확정하지 않는다.
- 내부 체크포인트마다 debug/capture를 만들고 결과를 보고한다.
- 최종적으로 커밋하되, main 병합/원격 푸시는 사용자 플레이 테스트 후 진행한다.

## Verification Commands

기본 검증:

```bash
/Users/highfence/Dev/Sweep/engine/godot/bin/godot.macos.editor.arm64 --headless --path /Users/highfence/Documents/Bro-exile --quit
```

```bash
/Users/highfence/Dev/Sweep/engine/godot/bin/godot.macos.editor.arm64 --headless --path /Users/highfence/Documents/Bro-exile -- --smoke-playtest
```

기존 회귀:

```bash
/Users/highfence/Dev/Sweep/engine/godot/bin/godot.macos.editor.arm64 --headless --path /Users/highfence/Documents/Bro-exile -- --debug-boss-pierce-splash
```

```bash
/Users/highfence/Dev/Sweep/engine/godot/bin/godot.macos.editor.arm64 --headless --path /Users/highfence/Documents/Bro-exile -- --debug-emerging-death-cleanup
```

P7 신규 후보:

```bash
/Users/highfence/Dev/Sweep/engine/godot/bin/godot.macos.editor.arm64 --headless --path /Users/highfence/Documents/Bro-exile -- --debug-p7-reward-routes
```

```bash
/Users/highfence/Dev/Sweep/engine/godot/bin/godot.macos.editor.arm64 --headless --path /Users/highfence/Documents/Bro-exile -- --debug-p7-shop-rarity
```

```bash
/Users/highfence/Dev/Sweep/engine/godot/bin/godot.macos.editor.arm64 --headless --path /Users/highfence/Documents/Bro-exile -- --debug-p7-relic-contracts
```

UI/전투 캡처:

```bash
/Users/highfence/Dev/Sweep/engine/godot/bin/godot.macos.editor.arm64 --path /Users/highfence/Documents/Bro-exile -- --capture-p7-shop-rarity-ui
```

```bash
/Users/highfence/Dev/Sweep/engine/godot/bin/godot.macos.editor.arm64 --path /Users/highfence/Documents/Bro-exile -- --capture-p7-contract-ui
```

```bash
/Users/highfence/Dev/Sweep/engine/godot/bin/godot.macos.editor.arm64 --path /Users/highfence/Documents/Bro-exile -- --capture-p7-boss-patterns
```

```bash
/Users/highfence/Dev/Sweep/engine/godot/bin/godot.macos.editor.arm64 --path /Users/highfence/Documents/Bro-exile -- --capture-p7-game-over-summary
```

## Future Considerations

- P8에서 무기/장비를 근접, 원거리, 마법/기묘한 광산 장비로 넓힌다.
- P9에서 단일 광석 경제를 다중 화폐 경제로 확장한다.
- 유물은 장기적으로 광산에서 하나씩 발견하는 영구 성장/컬렉션 요소가 될 수 있다.
- P7에서 rarity 경제가 충분히 작동하면 P8 무기 등급과 P9 화폐 용도를 연결한다.

## Sources & References

### Origin

- **Brainstorm document:** `docs/brainstorms/2026-06-03-p7-threat-economy-and-p8-weapon-identity-brainstorm.md`
  - 10라운드 구조, 영구 성장 제외, 5R/10R 보스, 3/5/7 계약 이벤트, 상점 rarity, 목록 전면 재작성, 게임오버 요약, worker sub thread 운영 결정을 carried forward했다.

### Internal References

- `AGENTS.md`: 한글 문서 작성과 Godot runbook.
- `scripts/main.gd`: 라운드, 전투, 보상, 상점, 유물, 적 행동, debug/capture의 현재 중심 파일.
- `scripts/ui/game_ui.gd`: 선택/상점/계약 카드와 overlay UI.
- `scripts/ui/ore_ui_theme.gd`: 카드/버튼 style helper.
- `docs/architecture/2026-05-31-godot-ui-system.md`: `main.gd`와 `GameUI` 책임 분리.
- `docs/plans/2026-06-03-feat-p4-p5-prototype-validation-plan.md`: run report, smoke/debug, UI capture 검증 패턴.
- `docs/plans/2026-06-03-feat-p6-map-camera-ui-spawn-readability-plan.md`: P6 카메라/스폰/상태 overlay 구조.
- `docs/solutions/ui-bugs/invisible-godot-ui-text-GodotPort-20260522.md`: UI는 실제 캡처로 검증해야 한다는 learning.
