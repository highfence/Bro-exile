---
status: complete
priority: p2
issue_id: "006"
github_issue: "https://github.com/highfence/Bro-exile/issues/7"
owner_lane: producer
tags: [prototype, m1, art, readability, godot, quest]
dependencies: ["003"]
milestone: M1
delivery: backlog
chain: art
quest_title: "광산 정체성 에셋 패스"
---

# 006. 광산 정체성 에셋 패스

## Quest Card

- 목표: 플레이어, 적, 픽업, 무기 중 최소 2종을 광산 정체성이 보이는 임시 에셋으로 교체한다.
- 플레이어 감정: “이건 광산 생존 게임이다.”
- 완료 보상: 최종 아트 전에도 게임의 얼굴을 볼 수 있다.
- 실패 신호: 에셋이 예뻐도 64px 전투 화면에서 읽히지 않는다.

## Problem Statement

현재 전투는 도형 중심이라 시스템 검증에는 빠르지만, 게임 정체성과 플레이어 애착을 판단하기 어렵다.

## Findings

- 플레이어 캐릭터 스타일 가이드와 에셋 생성 원칙이 이미 있다.
- `assets/sprites/characters/` 아래 플레이어/광부/좀비 시안이 존재한다.
- 실제 Godot 전투 화면에 얹어 보지 않으면 크기와 대비를 판단하기 어렵다.

## Proposed Solutions

### A. 플레이어만 먼저 교체

헬멧 마스코트 플레이어를 현재 도형 플레이어 대신 그린다.

- 장점: 게임의 얼굴이 바로 생긴다.
- 단점: 적/픽업이 여전히 임시라 전체 인상은 제한적이다.
- 노력: 중간.
- 위험: 낮음.

### B. 플레이어와 기본 적 1종 교체

플레이어와 좀비/광산 생물 하나를 같이 적용한다.

- 장점: 전투 구도가 바로 읽힌다.
- 단점: 애니메이션/정렬 문제가 더 생길 수 있다.
- 노력: 중간.
- 위험: 중간.

### C. UI 아이콘부터 교체

상점/무기/아이템 아이콘을 먼저 광산풍으로 바꾼다.

- 장점: UI 선택감이 좋아진다.
- 단점: 전투 정체성 검증과는 거리가 있다.
- 노력: 중간.
- 위험: 낮음.

## Recommended Action

B를 목표로 하되, 플레이어 적용에서 막히면 A까지만 완료한다.

## Acceptance Criteria

- [x] 플레이어 에셋이 실제 전투 화면에 표시된다.
- [x] 기본 적 1종 또는 픽업 1종이 임시 에셋으로 표시된다.
- [x] 64px 수준에서 플레이어의 안전모/램프가 먼저 읽힌다.
- [x] 캡처를 보고 도형 버전보다 정체성이 좋아졌는지 기록한다.

## Work Log

### 2026-06-01 - 퀘스트 생성

**By:** Codex

**Actions:**
- 아트 체인의 P2 퀘스트로 생성했다.
- 가독성 스냅샷 이후 실제 에셋 패스로 이어지게 했다.

**Learnings:**
- 최종 아트보다 “전투 화면에서 정체성이 읽히는가”가 먼저다.

### 2026-07-14 - GitHub Issue Completion Review

**By:** Producer

**상태:**
- passed

**Actions:**
- 현재 runtime이 헬멧 마스코트 player parts와 miner zombie sprite를 직접 로드하고 실제 전투에서 렌더링하는 것을 확인했다.
- 기존 player/zombie harness의 64px preview, metadata, 실제 stage capture 결과를 이 todo의 완료 증거로 연결했다.

**Verification:**
- `scripts/main.gd`는 `player_helmet_mascot_semilayered_gloves_v1`과 `miner_zombie_v1/zombie_idle.png`를 로드해 player와 기본 zombie를 그린다.
- `docs/reports/assets/2026-06-04-asset-automation-dry-run-report.md`의 player/zombie harness는 8 frames, adjacent duplicate 0, loop alpha mismatch 0을 기록했다.
- 같은 report의 `/private/tmp/orebound-godot-stage1.png` 1280×720 capture에서 player와 zombie가 실제 게임 배경 위에 표시되고, player 64px preview에서 헬멧/램프 실루엣을 확인했다.

**Questions:**
- 없음. 후속 enemy 후보와 최종 아트 방향은 별도 asset issue로 관리한다.

**Next Handoff:**
- Producer가 GitHub #7을 completed로 닫고, 신규 asset promotion은 기존 pixel-perfect gate를 계속 적용한다.
