---
status: complete
priority: p1
issue_id: "017"
tags: [prototype, m1, d7, threat, economy, contracts, boss, godot, quest]
dependencies: ["016"]
milestone: M1
delivery: D7
chain: threat-economy
quest_title: "M1-D7 10라운드 위협/경제 재정비"
---

# 017. M1-D7 10라운드 위협/경제 재정비

## Quest Card

- 목표: 10라운드 한 사이클에서 난이도, 상점 rarity, 계약, 중간/최종 보스, 사망 복기 루프를 검증한다.
- 플레이어 감정: “처음에는 6-8R에서 막히지만, 패턴과 상점 대응을 이해하면 더 갈 수 있겠다.”
- 완료 보상: 한 판의 실패 지점, 선택한 계약, 희귀/전설 구매가 런 요약과 debug/capture로 복기된다.
- 실패 신호: 라운드 흐름이 꼬이거나, 계약이 직접 스탯 보상이 되거나, 새 위협이 예고 없이 억울한 피해를 준다.

## Problem Statement

P6 이후 전투 공간과 가독성은 좋아졌지만 게임은 여전히 5라운드 기준이라 쉽게 끝난다. 상점과 유물도 10라운드 roguelike식 실패/학습 루프를 검증하기에는 리듬이 짧고, 유물은 위험의 질보다 직접 보상에 가까운 구조였다.

## Findings

- `scripts/main.gd`가 라운드, 전투, 상점, 유물, debug/capture 대부분을 소유한다.
- 기존 `_finish_round()`는 라운드 종료 후 유물 선택으로 바로 이동해 P7의 `stat -> contract -> shop` 연속 흐름을 표현하기 어렵다.
- `GameUI.show_choice()`와 `OreUITheme.option_card_style()`을 확장하면 상점 rarity와 계약 카드를 같은 overlay 체계로 표시할 수 있다.

## Proposed Solutions

- reward chain queue를 추가해 라운드별 보상 순서를 명시적으로 처리한다.
- 상점 아이템에 `common`, `rare`, `legendary` rarity를 추가하고 확률/가격/UI를 함께 조정한다.
- 기존 유물 목록을 P7 계약 목록으로 교체하고, 계약은 위험 품질과 처치 광석 보상만 강화한다.
- 새 적 3종과 보스 패턴은 임시 primitive/기존 asset 조합으로 읽히게 구현하고, 최종 시각 스타일은 별도 디자인 확인 대상으로 남긴다.

## Recommended Action

P7 확정 명세를 구현하고, debug/capture 명령으로 라우트, rarity, 계약, 보스 패턴, 게임오버 요약을 검증한다. 완료 뒤 계획 문서와 dashboard를 갱신한다.

## Acceptance Criteria

- [x] `MAX_ROUNDS`가 10으로 확장된다.
- [x] R1-R10 라운드 길이와 R5/R10 보스 라운드가 동작한다.
- [x] 라운드별 보상 라우터가 스탯/상점/계약/최종 준비 상점을 올바른 순서로 연다.
- [x] P7 스탯 보상은 무료 기본 체급 보정만 제공한다.
- [x] 상점은 common/rare/legendary rarity와 rarity UI를 가진다.
- [x] P7 일반 7개, 레어 4개, 전설 1개 아이템이 구현된다.
- [x] 계약은 R3/R5/R7 후 등장하고 최대 III단계까지 누적된다.
- [x] 계약은 플레이어 스탯을 직접 올리지 않고 위험 품질과 광석 보상만 강화한다.
- [x] 방패 좀비, 독 거미, 자폭 광부가 해금 라운드에 맞춰 등장한다.
- [x] 5R 중간 보스와 10R 최종 보스가 예고 있는 패턴을 가진다.
- [x] 사망 요약은 도달 라운드, 처치 수, 획득/사용 광석, 계약, 희귀/전설 구매를 보여준다.
- [x] P7 debug/capture 명령이 추가된다.

## Work Log

### 2026-06-04 - P7 구현 완료

**By:** Codex

**Actions:**
- `MAX_ROUNDS := 10`과 라운드별 duration, R5/R10 보스 라운드를 추가했다.
- `_finish_round()`를 reward chain queue 기반으로 바꾸고, R1/R2/R3/R4/R5/R6/R7/R8/R9 보상 경로를 P7 명세대로 연결했다.
- P7 스탯 보상, 상점 rarity 아이템, 계약 목록을 전면 재작성했다.
- 방패 좀비, 독 거미, 자폭 광부와 중간/최종 보스 패턴을 추가했다.
- rarity 카드 테두리/라벨과 계약 단계/게임오버 요약 UI를 추가했다.
- `--debug-p7-reward-routes`, `--debug-p7-shop-rarity`, `--debug-p7-relic-contracts`, `--debug-p7-boss-patterns`를 추가했다.
- `--capture-p7-shop-rarity-ui`, `--capture-p7-contract-ui`, `--capture-p7-boss-patterns`, `--capture-p7-game-over-summary`를 추가했다.

**Verification:**
- Godot headless load 통과
- `--debug-p7-reward-routes` 통과
- `--debug-p7-shop-rarity` 통과
- `--debug-p7-relic-contracts` 통과
- `--debug-p7-boss-patterns` 통과
- `--smoke-playtest` 승리 통과
- `--debug-boss-pierce-splash` 통과
- `--debug-emerging-death-cleanup` 통과
- P7 capture 4종 렌더 확인

**Learnings:**
- P7 reward chain은 단순 분기보다 명시적 queue가 훨씬 안전하다.
- 계약을 직접 보상이 아니라 위험 품질과 처치 광석 보너스로 제한하면 상점 경제와 연결이 선명해진다.
- 임시 primitive 예고만으로도 보스 돌진/장판/탄막은 최소 판독 가능하지만, 최종 색상/실루엣은 플레이테스트 후 별도 확정이 필요하다.
