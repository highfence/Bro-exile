---
status: pending
priority: p2
issue_id: "018"
tags: [m1, d8, shop, items, relics, design]
dependencies: ["019", "023"]
milestone: M1
delivery: D8
chain: design
quest_title: "M1-D8 강화/아이템/유물 목록 재검토"
owner_lane: planning
supporting_slice: "020"
artifacts:
  - "todos/020-pending-p2-m1-d11-multi-currency-economy.md"
---

# 018. M1-D8 강화 목록, 아이템 목록, 유물 목록 재검토

P8 무기 정체성 검증 이후, 무기별 강화 목록과 기존 상점 아이템/유물 목록을 한 번에 재검토한다.

## Problem Statement

P8에서는 검증 범위를 좁히기 위해 같은 강화 효과 풀을 유지하고, 선택 무기에 맞춰 표시명과 설명만 바꾸기로 했다. 이 방식은 무기 기본 감각 차이를 확인하는 데는 좋지만, 장기적으로는 강화 목록, 아이템 목록, 유물 목록이 새 무기 체계와 어울리도록 다시 설계되어야 한다.

특히 P7에서 만든 상점 등급 경제와 계약형 유물은 드릴촉 중심 구조에서 출발했다. P8 이후 곡괭이, 네일건, 랜턴 같은 무기 계열이 들어오면 각 강화와 유물이 어떤 무기 판타지, 위험 대응, 경제 선택을 담당하는지 함께 정리할 필요가 있다.

## Findings

- P8 디자인에서 스타터 무기는 `곡괭이`, `네일건`, `랜턴`으로 확정됐다.
- P8 구현 범위에서는 상점 강화 효과 풀을 완전히 분리하지 않고, 선택 무기에 맞는 표시명/설명 치환으로 처리한다.
- 기존 상점 아이템에는 `관통 드릴촉`, `폭약 코어`, `장갑 파쇄날`, `쌍열 드릴 챔버`처럼 드릴촉/투사체 중심 표현이 남아 있다.
- 사용자는 이후 강화 목록, 아이템 목록, 유물을 함께 고민하는 시간을 별도로 갖고 싶다고 명시했다.

## Proposed Solutions

### Option 1: P8 직후 별도 브레인스토밍 세션

**Approach:** P8 플레이 검증 후 무기별 플레이 감각을 확인하고, 그 결과를 바탕으로 강화/아이템/유물 목록을 재작성한다.

**Pros:**
- 실제 플레이 감각을 본 뒤 목록을 설계할 수 있다.
- 무기별 강점과 약점에 맞는 강화 방향을 정하기 쉽다.
- P8 구현 범위를 부풀리지 않는다.

**Cons:**
- P8 동안에는 일부 아이템 이름/효과가 임시 느낌으로 남을 수 있다.

**Effort:** 1-2 design sessions

**Risk:** Low

---

### Option 2: P8 구현 전에 목록을 먼저 재작성

**Approach:** P8 구현 시작 전에 무기별 강화/아이템/유물 목록을 전면 설계한다.

**Pros:**
- 처음부터 더 완성된 판타지로 구현할 수 있다.
- 상점 카드와 아이콘 방향을 일찍 맞출 수 있다.

**Cons:**
- 아직 무기 기본 감각이 검증되지 않아 설계가 빗나갈 수 있다.
- P8 범위가 커지고 구현이 늦어진다.

**Effort:** 2-4 design sessions plus implementation updates

**Risk:** Medium

---

### Option 3: P9 경제 재정비와 함께 처리

**Approach:** 다중 화폐 경제를 다룰 때 강화/아이템/유물 목록도 함께 재설계한다.

**Pros:**
- 화폐 용도, 상점, 장비 강화, 유물 보상을 한 번에 맞출 수 있다.
- 장기 구조 관점에서는 가장 일관적이다.

**Cons:**
- P8-P9 사이에 임시 목록이 오래 남을 수 있다.
- 무기별 강화 감각 피드백을 바로 반영하기 어렵다.

**Effort:** Larger milestone-level planning

**Risk:** Medium

## Recommended Action

전면 목록 재설계는 보류한다. 공개 데모에서는 020 화폐 playable slice가 요구하는 최소 장비 강화 sink만 이 todo에서 가져간다.

## Technical Details

**Affected files likely include:**
- `scripts/main.gd` - `shop_catalog`, `relic_catalog`, weapon part application
- `scripts/ui/game_ui.gd` - item/relic card display if new metadata is needed
- `assets/sprites/items/` - item/relic/weapon icons
- `docs/superpowers/specs/2026-06-04-p8-weapon-identity-design.md` - P8 origin decisions
- `docs/brainstorms/` and `docs/plans/` - future design output

## Resources

- P8 design: `docs/superpowers/specs/2026-06-04-p8-weapon-identity-design.md`
- P7 plan: `docs/plans/2026-06-03-feat-p7-ten-round-threat-economy-plan.md`
- P7/P8/P9 brainstorm: `docs/brainstorms/2026-06-03-p7-threat-economy-and-p8-weapon-identity-brainstorm.md`

## Acceptance Criteria

- [ ] 무기별 강화 역할이 정리되어 있다.
- [ ] 일반/레어/전설 아이템 목록이 새 무기 체계와 충돌하지 않는다.
- [ ] 유물/계약 목록이 P7 위협 경제와 P8 무기 체계를 모두 고려한다.
- [ ] 아이템/유물 이름, 설명, 아이콘 방향이 광산 판타지와 맞는다.
- [ ] P9 다중 화폐 경제와 연결할 항목과 P8 직후 처리할 항목이 분리되어 있다.

## Work Log

### 2026-06-04 - Initial Capture

**By:** Codex

**Actions:**
- P8 grill-me 명세 확인 중 사용자 요청에 따라 별도 TODO로 캡처했다.
- P8에서는 같은 효과 풀을 유지하고 무기별 표시명/설명 치환으로 처리하기로 했다.
- 강화 목록, 아이템 목록, 유물 목록의 전면 재검토는 P8 범위 밖으로 분리했다.

**Learnings:**
- P8의 핵심은 무기 기본 감각 검증이므로, 목록 재설계까지 한 번에 포함하면 검증 변수가 많아진다.
- 사용자는 장기적으로 아이템/유물/강화 체계를 함께 재검토하는 별도 시간을 원한다.

## Notes

- P8 구현 중 아이템 이름이 임시로 느껴지더라도, 목록 전면 재검토는 이 TODO에서 다룬다.

## Work Log (continued)

### 2026-07-12 - Producer Currency Slice Mapping

**By:** Producer

**상태:**
- done

**Actions:**
- 이 backlog를 독립 active slice로 두지 않고 020 화폐 playable slice의 장비 강화 sink 기준으로 연결했다.
- 기존 옵션과 과거 Work Log는 보존하며, 전면 목록 재설계는 공개 데모 첫 화폐 검증 범위 밖으로 둔다.

**Verification:**
- queue projection과 supporting link만 검증했다.

**Questions:**
- 없음.

**Next Handoff:**
- 020 Planner가 장비 강화 화폐의 최소 sink를 정할 때 이 todo를 읽는다.
