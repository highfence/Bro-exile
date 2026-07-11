---
status: pending
priority: p2
issue_id: "020"
tags: [prototype, m1, d11, economy, currency, shop, design]
dependencies: ["019", "023"]
milestone: M1
delivery: D11
chain: economy
quest_title: "M1-D11 다중 화폐 경제"
pipeline_slice: true
queue_order: 2
owner_lane: planning
validator_verdict: not-run
user_gate: not-requested
artifacts:
  - "docs/plans/2026-07-12-001-feat-public-demo-vertical-slice-pipeline-plan.md"
  - "todos/011-pending-p2-shop-and-reward-choice-pass.md"
  - "todos/018-pending-p2-upgrade-item-relic-review.md"
last_handoff: "2026-07-12 - Producer Queue Rebaseline Handoff"
routing_reason: ""
---

# 020. M1-D11 다중 화폐 경제

## Quest Card

- 목표: 하나의 광석 경제를 여러 목적별 화폐로 나누는 방향을 검토한다.
- 플레이어 감정: “이번 런에서 어떤 자원을 노릴지에 따라 상점과 성장이 달라진다.”
- 완료 보상: 리롤, 능력 획득, 장비 강화가 같은 통화 경쟁을 하지 않게 된다.
- 실패 신호: 화폐가 늘었지만 선택이 깊어지지 않고 관리 부담만 커진다.

## Problem Statement

현재 경제는 광석 중심으로 통합되어 있어 상점 리롤, 능력 구매, 장비 강화가 모두 같은 자원을 사용하게 될 가능성이 높다. 사용자는 POE처럼 화폐가 쓰임에 따라 나뉘고, 각 화폐가 유물/콘텐츠/위험 보상과 연결되는 구조를 원한다.

## Findings

- 공개 데모 첫 세분화는 023 체크포인트 slice 승인 뒤 진행하고, 011 상점/보상 선택과 018 강화 sink를 같은 playable slice에 흡수한다.
- 첫 설계에서는 너무 많은 화폐보다 3종 안팎의 목적 분리가 적절하다.
- 후보 역할은 상점 리롤, 능력/부품 획득, 장비 강화다.
- 계약 보상은 직접 능력치 상승보다 위험한 몹을 잡았을 때의 보상 품질 상승과 연결되는 쪽이 더 적절하다.

## Proposed Solutions

### Option 1: 3화폐 첫 검증

리롤 화폐, 능력 화폐, 강화 화폐만 먼저 도입한다.

- 장점: 목적이 선명하고 구현 범위가 낮다.
- 단점: POE식 변환/제작 깊이는 아직 약하다.

### Option 2: 3화폐 + 희귀 변환 재료

기본 3화폐에 상점 선택지를 바꾸거나 등급을 조정하는 희귀 재료를 추가한다.

- 장점: 장기 경제 방향이 조금 더 보인다.
- 단점: D11 첫 검증치고 변수가 늘어난다.

## Recommended Action

023 체크포인트 slice 승인 뒤 3화폐의 source와 sink를 한 판에서 함께 검증한다. 이 playable slice가 승인된 뒤 D9 캐릭터, D10 시뮬레이션으로 넘어간다.

## Acceptance Criteria

- [ ] D8 무기 체계와 충돌하지 않는 화폐 역할을 정한다.
- [ ] 상점 리롤, 능력 획득, 장비 강화의 지불 자원이 분리되어 있다.
- [ ] 계약/위험 보상이 어떤 화폐 품질을 올리는지 정리되어 있다.
- [ ] 첫 구현 범위와 보류할 장기 경제 요소가 분리되어 있다.

## Work Log

### 2026-06-05 - Todo Capture

**By:** Codex

**Actions:**
- 다중 화폐 경제 방향을 M1-D9 pending todo로 기록했다.
- 이후 캐릭터/아키타입 매트릭스를 먼저 정리하기로 하면서 이 todo를 M1-D10으로 이동했다.
- 숙련도별 자동 시뮬레이션을 먼저 만들기로 하면서 이 todo를 M1-D11로 한 번 더 이동했다.
- D11 세분화는 D8, D9, D10, 018 완료 이후 진행하도록 의존성을 걸었다.

**Learnings:**
- 경제 시스템은 무기/아이템 체계가 흔들리는 동안 먼저 세분화하면 다시 바뀔 가능성이 크다.

### 2026-07-12 - Producer Queue Rebaseline Handoff

<!-- pipeline-state
{"artifacts": ["docs/plans/2026-07-12-001-feat-public-demo-vertical-slice-pipeline-plan.md", "todos/011-pending-p2-shop-and-reward-choice-pass.md", "todos/018-pending-p2-upgrade-item-relic-review.md"], "owner_lane": "planning", "routing_reason": "", "status": "pending", "user_gate": "not-requested", "validator_verdict": "not-run"}
-->

**By:** Producer

**상태:**
- pending

**Actions:**
- 기존 020, 011, 018을 하나의 플레이 가능한 화폐 source/sink slice로 묶었다.
- 공개 데모 큐에서 023 체크포인트 slice 다음, D9 캐릭터 slice 이전으로 이동했다.
- 과거 D11 명칭과 Work Log는 역사로 보존하고, 첫 구현은 3화폐의 획득과 소비가 한 판 안에서 닫히는 범위로 제한한다.

**Verification:**
- 큐/상태 계약만 검증한다. 경제 구현 검증은 이 slice 활성화 뒤 수행한다.

**Questions:**
- 023 Product Owner 승인 뒤 Planner가 화폐 이름과 수치를 구현 시점에 확정한다.

**Next Handoff:**
- 023이 `complete/approved`가 되면 이 todo를 `ready`로 바꾸고 Planner에 넘긴다.
