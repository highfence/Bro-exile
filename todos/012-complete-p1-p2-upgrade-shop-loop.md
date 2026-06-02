---
status: complete
priority: p2
issue_id: "012"
tags: [prototype, p2, shop, upgrades, godot, quest]
dependencies: ["004", "005", "007"]
chain: p2
quest_title: "P2 상점 강화 루프"
---

# 012. P2 상점 강화 루프

## Quest Card

- 목표: 각 라운드 종료 후 상점에서 기존 드릴촉 무기에 부품을 붙이고 다음 라운드로 넘어가게 만든다.
- 플레이어 감정: “이번에 산 강화가 다음 라운드에서 느껴진다.”
- 완료 보상: P1 전투 루프 위에 첫 성장 루프가 붙는다.
- 실패 신호: 상점에 들어가도 살 게 없거나, 사도 다음 전투가 비슷하다.

## Problem Statement

P1은 라운드 사이에 체력만 완전 회복하고 다음 라운드로 넘어간다. P2에서는 라운드 사이 선택을 통해 플레이어가 강해지는 루프를 검증해야 한다.

## Findings

- 기존 코드에는 상점 UI, 상점 카탈로그, 무기 강화, 패시브 아이템 적용, 리롤 기능이 이미 남아 있다.
- P1에서는 보상 드롭과 상점 연결을 꺼둔 상태다.
- P2에서는 레벨업 보상보다 상점 강화 루프를 먼저 검증한다.
- 사용자가 읽은 몹 위협에 맞춰 기존 무기에 대응 부품을 붙이는 방향이 P2 질문에 더 잘 맞는다.

## Proposed Solutions

### A. 상점 중심 성장

라운드 종료 시 광석 보상을 지급하고 상점을 연다. 플레이어는 구매/리롤 후 다음 라운드를 시작한다.

- 장점: 기존 상점 코드를 활용하고 P2 목표에 정확히 맞는다.
- 단점: 광석 보상과 가격의 임시 밸런스가 필요하다.
- 노력: 낮음.
- 위험: 낮음.

### B. 레벨업 보상 중심 성장

적 처치 XP로 레벨업 보상을 고르게 한다.

- 장점: 전투 중 성장감이 있다.
- 단점: P2 상점 검증과 질문이 갈라진다.
- 노력: 중간.
- 위험: 중간.

### C. 상점 + 레벨업 동시 활성화

기존 성장 루프를 모두 켠다.

- 장점: 풍부하다.
- 단점: 어떤 선택이 재미를 만들었는지 검증하기 어렵다.
- 노력: 중간.
- 위험: 중간.

## Recommended Action

A로 간다. P2의 주인공은 상점이고, 레벨업 보상은 다음 단계로 미룬다.

## Acceptance Criteria

- [x] 라운드 1-4 종료 후 상점 씬이 열린다.
- [x] 라운드 종료 시 체력이 완전히 회복된다.
- [x] 라운드 종료 보상 또는 적 드롭으로 최소 1개 강화 구매가 가능하다.
- [x] 상점에서 부품/아이템/회복/리롤/다음 라운드 선택이 동작한다.
- [x] 구매한 부품 또는 아이템 효과가 다음 라운드에 반영된다.
- [x] smoke playtest가 상점을 자동 이용하고 라운드 5 승리까지 도달한다.

## Work Log

### 2026-06-01 - 퀘스트 생성

**By:** Codex

**Actions:**
- P2 상점 강화 루프를 P1 다음 메인 퀘스트로 생성했다.

**Learnings:**
- P2는 보상/계약 전체가 아니라 “스테이지마다 강화한다”를 먼저 증명한다.

### 2026-06-01 - 구현 및 검증

**By:** Codex

**Actions:**
- P1의 라운드 종료 카드를 상점 씬으로 교체했다.
- 라운드 클리어 광석 보상과 적 처치 광석 드롭을 켰다.
- 레벨업 보상은 P2 범위 밖으로 두고 비활성 상태를 유지했다.
- 상점에서 무기, 아이템, 회복, 리롤, 다음 라운드 선택이 이어지도록 기존 상점 함수를 P2 루프에 연결했다.
- Godot headless 로드, smoke playtest, 시작 UI 캡처, 상점 UI 캡처를 확인했다.

**Learnings:**
- 상점 루프는 기존 UI/카탈로그를 재사용해 빠르게 검증 가능했다.
- 최종 smoke 결과: `SMOKE_PLAYTEST result=VICTORY mode=victory wave=5 level=1 hp=260.0 ore=14 enemies=6 pickups=5 choices=16 elapsed=28.85 capture=skipped-headless`.

### 2026-06-01 - 부품형 강화로 전환

**By:** Codex

**Actions:**
- 기본 공격을 드릴촉 발사기로 바꿨다.
- 상점 카탈로그를 새 무기 구매가 아니라 기존 드릴촉 무기에 붙는 부품 중심으로 바꿨다.
- 빠른 좀비, 거미떼, 투척 좀비, 보스에 대응하는 대표 부품을 추가했다.
- 간단한 투명 PNG 부품 아이콘과 생성 스크립트를 추가했다.
- 상점 카드에 아이콘을 표시하도록 UI를 보강했다.

**Learnings:**
- “몹이 문제를 내고 상점 부품이 해법 후보를 준다”가 P2 검증 질문을 더 선명하게 만든다.
- 최신 smoke 결과: `SMOKE_PLAYTEST result=VICTORY mode=victory wave=5 level=1 hp=260.0 ore=3 enemies=7 pickups=4 choices=14 elapsed=27.09 capture=skipped-headless`.

### 2026-06-02 - 플레이 테스트 피드백 반영

**By:** Codex

**Actions:**
- 상점이 같은 선택지를 반복해서 보여주는 느낌을 줄이기 위해 이전 상점 노출 아이템과 이미 산 고유 부품을 우선 제외했다.
- 상점 후보를 노출 횟수가 적은 아이템 우선으로 정렬해 리롤/다음 상점의 변화를 더 크게 만들었다.
- 파편 폭약의 소규모 폭발이 드릴촉 탄환에도 실제로 붙도록 `splash` 전달을 수정했다.
- 거미가 35% 확률로 광석을 떨어뜨리도록 바꿨다.

**Learnings:**
- P2 상점은 순수 랜덤보다 “반복 회피 + 다음 위협 대응 보장”이 테스트 감각에 더 잘 맞는다.
- 최신 smoke 결과: `SMOKE_PLAYTEST result=VICTORY mode=victory wave=5 level=1 hp=248.0 ore=12 enemies=7 pickups=3 choices=16 elapsed=29.30 capture=skipped-headless`.

### 2026-06-02 - main 비주얼 커밋 반영

**By:** Codex

**Actions:**
- `main`의 `1c8f531 Apply P1 monster visuals to main scene` 커밋을 P2 worktree에 fast-forward로 반영했다.
- 보스가 멀리 스폰되면 자동 검증 플레이어가 원형 이동만 하다가 보스를 놓치는 문제가 있어, smoke playtest에서만 5라운드 보스를 추적하도록 보강했다.
- 보스 라운드에서는 보스가 사거리 안에 있을 때 자동 조준이 보스를 우선 타겟팅하게 했다.
- 몬스터 로스터 캡처로 새 캐릭터/몬스터 에셋 렌더링을 확인했다.

**Learnings:**
- 새 비주얼 적용 자체는 P2 상점 루프와 충돌하지 않았다.
- smoke 검증은 실제 플레이어처럼 보스를 추적해야 안정적으로 P2 완료 조건을 검증할 수 있다.
- 최신 smoke 결과: `SMOKE_PLAYTEST result=VICTORY mode=victory wave=5 level=1 hp=175.0 ore=1 enemies=8 pickups=0 choices=15 elapsed=26.08 capture=skipped-headless`.
