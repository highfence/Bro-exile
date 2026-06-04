---
title: "P8 무기 정체성 검증 루프 goal prompt"
type: prompt
status: complete
date: 2026-06-04
origin: docs/plans/2026-06-04-feat-p8-weapon-identity-loop-plan.md
---

# P8 무기 정체성 검증 루프 `/goal` 프롬프트

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
