---
status: complete
priority: p1
issue_id: "019"
tags: [m1-d8, weapons, starter, shop, godot]
dependencies: []
---

# M1-D8 무기 정체성 검증 루프

M1-D8은 10라운드 위협/경제 루프 위에서 시작 무기 선택이 실제 플레이 감각을 바꾸는지 검증한다.

## Problem Statement

현재 일반 런은 기존 드릴촉을 자동 장착하고 바로 R1이 진행된다. 이 흐름은 곡괭이, 네일건, 랜턴처럼 서로 다른 무기 계열의 강점과 약점을 비교하기 어렵다.

M1-D8에서는 새 런 시작 직후 R1 타이머와 스폰이 진행되기 전에 스타터 무기 3종 중 하나를 선택해야 한다. 선택한 무기 하나만 들고 10라운드 루프를 시작하며, 상점은 선택 무기 전용 강화 표현과 플레이어 공용 스탯 아이템을 함께 보여줘야 한다.

## Findings

- 확정 스타터는 곡괭이, 네일건, 랜턴이다.
- D8 일반 플레이에서 드릴촉은 스타터에서 제외하고 legacy/debug 무기로만 남긴다.
- 조작은 기존 자동 공격을 유지한다.
- 곡괭이와 네일건은 가장 가까운 적을 기준으로 조준한다.
- 랜턴은 상시 오라가 아니라 쿨다운마다 플레이어 주변 적에게 피해를 주는 펄스다.
- 상점 강화 효과 풀은 유지하되 선택 무기에 맞는 표시명/설명으로 decorate한다.
- 강화 목록, 아이템 목록, 유물 목록 전면 재검토는 `018`의 후속 작업이다.

## Proposed Solutions

### Option 1: 기존 main/ui 책임 분리를 유지한 최소 구현

**Approach:** `scripts/main.gd`에서 선택 상태, 무기 catalog, 공격 타입, 상점 decoration, debug/capture를 소유하고 `scripts/ui/game_ui.gd`는 카드/HUD/일시정지 표시를 확장한다.

**Pros:**
- 기존 Godot 프로토타입 구조와 맞다.
- D8 범위가 명확하다.
- P7 회귀 검증을 그대로 유지하기 쉽다.

**Cons:**
- 무기/상점 데이터가 아직 `main.gd`에 남아 있어 장기 분리 작업은 후속으로 필요하다.

**Effort:** 1 worker pass

**Risk:** Medium

## Recommended Action

Option 1로 진행한다. 선택 UI, starter catalog, 세 무기 공격 시그니처, 상점 표시명/설명 decoration, D8 debug/capture를 구현하고 P7 회귀 검증을 함께 돌린다.

## Technical Details

**Affected files:**
- `scripts/main.gd`
- `scripts/ui/game_ui.gd`
- `assets/sprites/items/p8_weapons/`
- `todos/README.md`

## Resources

- D8 design: `docs/superpowers/specs/2026-06-04-p8-weapon-identity-design.md`
- P7/P8/P9 brainstorm: `docs/brainstorms/2026-06-03-p7-threat-economy-and-p8-weapon-identity-brainstorm.md`
- P7 plan: `docs/plans/2026-06-03-feat-p7-ten-round-threat-economy-plan.md`

## Acceptance Criteria

- [x] 새 런 시작 직후 R1 타이머/스폰 전 무기 선택 UI가 열린다.
- [x] 선택 전에는 `wave_timer`, `spawn_timer`, `enemies`, `bullets`가 진행되지 않는다.
- [x] 곡괭이, 네일건, 랜턴 중 하나를 선택하면 선택 무기 하나만 들고 R1이 시작된다.
- [x] 게임오버/승리 후 다시 시작하면 무기 선택 UI로 돌아간다.
- [x] 곡괭이는 가장 가까운 적 방향의 짧은 전방 부채꼴 근접 공격이다.
- [x] 네일건은 가장 가까운 적 방향의 빠른 직선 투사체다.
- [x] 랜턴은 1초 안팎 쿨다운의 플레이어 주변 적 피해 펄스다.
- [x] 상점은 선택 무기 전용 강화 표현과 플레이어 공용 스탯 아이템을 함께 보여준다.
- [x] 쌍열 드릴 챔버 계열은 무기별 공격 레인/타격 횟수 +1로 해석된다.
- [x] 곡괭이/네일건/랜턴 도트 아이콘이 선택 UI/HUD/상점/일시정지에서 재사용된다.
- [x] D8 debug/capture와 P7 회귀 검증이 통과한다.

## Work Log

### 2026-06-05 - Worker Start

**By:** Codex

**Actions:**
- D8 확정 문서와 관련 P7/P8/P9 문서, `018` 후속 TODO를 확인했다.
- worker worktree가 `codex/p8-weapon-identity-loop` 브랜치 위에 있는지 확인했다.
- D8 구현 전용 ready TODO를 생성했다.

**Learnings:**
- D8은 새 무기 목록 재설계가 아니라 시작 무기 감각 검증 루프다.
- 후속 목록 재설계는 `018`에 남기고, 이번 구현은 선택 무기에 맞는 표시명/설명 치환까지만 포함한다.

### 2026-06-05 - Implementation Complete

**By:** Codex

**Actions:**
- 시작 overlay 이후 스타터 무기 선택 overlay를 열고, 선택 전에는 `MODE_CHOICE`로 전투 업데이트가 진행되지 않게 했다.
- 곡괭이, 네일건, 랜턴 catalog와 도트 아이콘, HUD/상점/상태 요약 재사용 경로를 추가했다.
- 곡괭이 전방 부채꼴, 네일건 빠른 못 투사체, 랜턴 적 피해 펄스를 구현했다.
- 선택 무기별 상점 부품 이름/설명 decoration을 추가하고 원본 `shop_catalog`는 보존했다.
- `--debug-p8-weapon-routes`, `--capture-p8-weapon-select-ui`, `--capture-p8-shop-weapon-parts`, `--weapon=` smoke 선택 인자를 추가했다.
- D8 debug, smoke, P7 회귀, 기존 전투 회귀, UI capture를 실행했다.

**Learnings:**
- 랜턴 펄스는 `hazard_zones`를 쓰지 않고 별도 적 피해 루트로 두어 P7 플레이어 피해 장판과 분리하는 편이 안전하다.
- 상점 option은 표시 직전에 duplicate/decorate하면 기존 rarity/확률/비용 회귀를 흔들지 않고 무기 판타지를 얹을 수 있다.
