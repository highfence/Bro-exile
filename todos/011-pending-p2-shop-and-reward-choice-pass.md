---
status: pending
priority: p2
issue_id: "011"
tags: [prototype, m1, d8, shop, rewards, buildcraft, quest]
dependencies: ["019", "023"]
milestone: M1
delivery: D8
chain: choice
quest_title: "상점/보상 선택감 정리"
owner_lane: planning
supporting_slice: "020"
artifacts:
  - "todos/020-pending-p2-m1-d11-multi-currency-economy.md"
---

# 011. 상점/보상 선택감 정리

## Quest Card

- 목표: 레벨업 보상과 상점 아이템이 빌드 방향을 만든다는 느낌을 강화한다.
- 플레이어 감정: “이번 런은 이 방향으로 커지고 있다.”
- 완료 보상: 계약 카드 보상이 실제 빌드 선택과 연결된다.
- 실패 신호: 어떤 선택을 해도 다음 전투가 비슷하게 느껴진다.

## Problem Statement

현재 상점과 보상은 기능적으로 동작하지만 P1 범위는 아니다. 5라운드 플레이어블 루프와 계약 카드 실험이 성립한 뒤, 위험/보상 계약과 연결되는 빌드 태그를 정리한다.

## Findings

- `stat_rewards`와 `shop_catalog`는 이미 `tag` 또는 `kind` 정보를 일부 가진다.
- 계약 카드 문서는 Swarm, Elite, Speed, Hazard 같은 위험 타입과 빌드 궁합을 강조한다.
- 현재 아이템은 기본 스탯 배율이 많아 선택의 색이 흐릴 수 있다.

## Proposed Solutions

### A. 아이템 태그와 툴팁 정리

상점/보상에 공격, 생존, 수집, 폭발, 기동 같은 태그를 명확히 붙인다.

- 장점: UI와 밸런스 모두에 도움이 된다.
- 단점: 체감은 아직 약할 수 있다.
- 노력: 낮음.
- 위험: 낮음.

### B. 계약 궁합 아이템 추가

Swarm에 강한 폭발, Elite에 강한 단일 피해, Speed에 강한 이동/방어 아이템을 추가한다.

- 장점: 위험 선택과 빌드 선택이 연결된다.
- 단점: 밸런스 조정이 필요하다.
- 노력: 중간.
- 위험: 중간.

### C. 보상 풀을 계약에 반응하게 만들기

선택한 계약에 따라 다음 보상/상점 제안이 달라진다.

- 장점: 시스템 연결감이 강하다.
- 단점: 1차 실험으로는 복잡할 수 있다.
- 노력: 높음.
- 위험: 높음.

## Recommended Action

A와 B를 작게 진행한다. C는 계약 카드 재미가 확인된 뒤로 미룬다.

## Acceptance Criteria

- [ ] 보상/상점 선택지에 빌드 태그가 명확히 표시된다.
- [ ] Swarm, Elite, Speed 중 최소 2개 계약과 궁합이 있는 아이템 또는 보상이 있다.
- [ ] 플레이테스트에서 “이 빌드라서 이 계약을 골랐다”는 판단이 1회 이상 나온다.
- [ ] 항상 좋은 선택지가 된 항목은 조정 후보로 기록한다.

## Work Log

### 2026-06-01 - 퀘스트 생성

**By:** Codex

**Actions:**
- P1 재정의에 따라 pending P2 backlog로 내렸다.
- 계약 카드 구현 이후에 보상 선택감을 맞추도록 의존성을 설정했다.

**Learnings:**
- 계약은 혼자 재미있을 수 없고, 빌드 선택지가 위험을 해석하게 만들어야 한다.

### 2026-07-12 - Producer Currency Slice Mapping

**By:** Producer

**상태:**
- done

**Actions:**
- 이 backlog를 독립 active slice로 두지 않고 020 화폐 playable slice의 상점/보상 sink 기준으로 연결했다.
- 기존 문제 정의와 acceptance criteria는 020 Planner가 source/sink 범위를 만들 때 입력으로 사용한다.

**Verification:**
- queue projection과 supporting link만 검증했다.

**Questions:**
- 없음.

**Next Handoff:**
- 020 Planner가 이 todo의 태그/선택감 기준을 구현 plan에 흡수한다.
