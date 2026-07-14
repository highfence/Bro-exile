# Orebound Prototype Quest Board

<!-- pipeline-queue
{"active_slice": "021", "artifacts": ["docs/brainstorms/2026-06-07-m1-d9-character-archetype-matrix-brainstorm.md", "docs/operations/agent-pipeline-current-state.md", "docs/quality/2026-06-30-pixel-perfect-quality-gates.md"], "last_handoff": "2026-07-14 - Producer Activation Handoff", "order": ["023", "020", "021", "022", "024"], "owner_lane": "planning"}
-->

이 대시보드는 Bro-exile 프로토타입을 검증 가능한 사이드 퀘스트로 쪼개서 보는 현황판이다. 각 퀘스트는 “무엇을 만들까”보다 “무엇을 확인할까”를 먼저 적는다.

## GitHub Issue 연동

진행 예정 작업의 상태, 논의, 담당자, 의존성, PR은 [GitHub Issues](https://github.com/highfence/Bro-exile/issues)에서 관리한다. 개별 todo는 상세 acceptance criteria와 에이전트 Work Log를 보존한다. 새 작업 생성과 상태 동기화 규칙은 [GitHub Issue 작업 운영](../docs/operations/github-issue-workflow.md)을 따른다.

| todo | GitHub Issue | 현재 역할 |
| --- | --- | --- |
| 020 | [#1 다중 화폐 경제](https://github.com/highfence/Bro-exile/issues/1) | complete, Product Owner approved |
| 021 | [#2 캐릭터/아키타입 매트릭스](https://github.com/highfence/Bro-exile/issues/2) | active, planning |
| 022 | [#3 숙련도별 자동 시뮬레이션](https://github.com/highfence/Bro-exile/issues/3) | queued |
| 024 | [#4 Windows itch.io 공개 데모](https://github.com/highfence/Bro-exile/issues/4) | queued |
| 001 / 002 / 010 | [#5](https://github.com/highfence/Bro-exile/issues/5) / [#6](https://github.com/highfence/Bro-exile/issues/6) / [#8](https://github.com/highfence/Bro-exile/issues/8) | backlog |
| 006 | [#7](https://github.com/highfence/Bro-exile/issues/7) | complete |
| 011 / 018 | [#9](https://github.com/highfence/Bro-exile/issues/9) / [#10](https://github.com/highfence/Bro-exile/issues/10) | partially absorbed, D9 review inputs |

## 표기 규칙

| 표기 | 의미 |
| --- | --- |
| `M1` | 첫 번째 큰 마일스톤: 플레이 가능한 roguelike 전투/성장 프로토타입 |
| `D1`, `D2`... | M1 안의 검증 단위. 기존에 `P1`, `P2`처럼 불렀던 프로토타입 진행 단계를 옮긴 이름 |
| `priority: p1/p2/p3` | todo 시스템의 실제 우선순위. `p1`은 핵심 경로, `p2`는 중요하지만 보류 가능, `p3`는 나중에 해도 되는 작업 |

과거 Work Log 안의 `P1`, `P2` 표현은 당시 대화의 역사 기록으로 남긴다. 현재 대시보드와 새 todo는 `M1-D*`를 기준으로 읽는다.

## M1 목표

**한 판의 실패와 학습, 성장 선택이 성립하는 플레이어블 roguelike 프로토타입을 만든다.**

M1은 “아이디어가 있는 게임”이 아니라 “플레이어가 죽고, 배우고, 다음 런에서 더 나아갈 수 있는 게임”을 검증한다. D1-D8에서 기본 전투, 상점, 계약, 10라운드 위협 루프, 무기 정체성을 만들었다. 공개 데모 경로는 체크포인트 위험 선택, 다중 화폐의 획득/소비, 캐릭터, 시뮬레이션, Windows 출시 순서로 한 slice씩 닫는다.

## M1 진행도

| 단위 | 상태 | 퀘스트 | 검증 질문 |
| --- | --- | --- | --- |
| D1 | complete | [5라운드 플레이어블 루프](004-complete-p1-m1-d1-five-round-playable-loop.md) | 짧은 한 판이 시작과 끝을 가지는가? |
| D1 | complete | [적 아키타입과 웨이브 패턴](005-complete-p1-enemy-archetypes-and-wave-patterns.md) | 라운드마다 다른 전투 요구가 생기는가? |
| D1 | complete | [보스 좀비와 테스트 종료](007-complete-p1-boss-zombie-and-test-ending.md) | 테스트 종료 지점이 명확한가? |
| D2 | complete | [상점 강화 루프](012-complete-p1-m1-d2-upgrade-shop-loop.md) | 라운드 사이 강화가 다음 전투에서 체감되는가? |
| D3 | complete | [유물 계약 루프](013-complete-p1-m1-d3-relic-contract-loop.md) | 위험/보상 선택이 상점 대응과 연결되는가? |
| D4 | complete | [런 리포트와 디버그 하네스](014-complete-p1-m1-d4-run-report-and-debug-harness.md) | 한 판 결과를 바로 복기할 수 있는가? |
| D5 | complete | [빌드 체감과 전투 가독성](015-complete-p1-m1-d5-build-feedback-and-combat-readability.md) | 산 부품이 전투 화면에서 다르게 보이는가? |
| D6 | complete | [넓은 광산과 전투 화면 정리](016-complete-p1-m1-d6-map-camera-ui-spawn-readability.md) | 공간, UI, 스폰 예고가 답답함을 줄이는가? |
| D7 | complete | [10라운드 위협/경제 재정비](017-complete-p1-m1-d7-ten-round-threat-economy.md) | 10라운드 실패/학습 루프가 성립하는가? |
| D8 | complete | [무기 정체성 루프](019-complete-p1-m1-d8-weapon-identity.md) | 곡괭이/네일건/랜턴이 다른 플레이 결정을 만드는가? |
| D9 | ready | [캐릭터 3종과 빌드 아키타입 매트릭스](021-pending-p1-m1-d9-character-archetype-matrix.md) | 캐릭터별로 여러 아키타입과 교차 시너지를 만들 수 있는가? |
| D10 | pending | [숙련도별 자동 시뮬레이션 검증](022-pending-p1-m1-d10-skill-simulation-validation.md) | 플레이어 수준별 자동 검증으로 난이도 변화를 읽을 수 있는가? |
| D11 | complete | [다중 화폐 경제](020-pending-p2-m1-d11-multi-currency-economy.md) | 리롤/능력/강화 자원을 나누면 선택이 깊어지는가? |
| Demo | complete | [체크포인트 위험 선택 루프](023-ready-p1-demo-checkpoint-risk-loop.md) | 플레이어가 더 큰 위험을 능동적으로 선택하고 보상을 체감하는가? |
| Demo | pending | [Windows itch.io 공개 데모](024-pending-p1-demo-windows-release.md) | 외부 플레이어가 설치부터 다음 런까지 막힘 없이 경험하는가? |

## 지금 큐

| 추천 순서 | 상태 | 퀘스트 | 이유 |
| --- | --- | --- | --- |
| 1 | complete, approved | [공개 데모 체크포인트 위험 선택 루프](023-ready-p1-demo-checkpoint-risk-loop.md) | Product Owner가 balance revision 빌드를 현재 저장 지점으로 승인했다. |
| 2 | complete, approved | [다중 화폐 playable slice](020-pending-p2-m1-d11-multi-currency-economy.md) | Product Owner가 weighted currency distribution 빌드를 승인했다. |
| 3 | ready, planning | [M1-D9 캐릭터 3종과 빌드 아키타입 매트릭스](021-pending-p1-m1-d9-character-archetype-matrix.md) | 기존 제품 결정을 구현 가능한 D9 plan으로 정리한다. |
| 4 | pending, blocked by 021 approval | [M1-D10 숙련도별 자동 시뮬레이션 검증](022-pending-p1-m1-d10-skill-simulation-validation.md) | 완성된 데모 축을 숙련도별 deterministic 기준선으로 비교한다. |
| 5 | pending, blocked by 022 approval | [Windows itch.io 공개 데모](024-pending-p1-demo-windows-release.md) | packaged build와 첫 외부 코호트를 확인한 뒤 Product Owner 승인으로 공개한다. |

## 보류 큐

| ID | 상태 | 우선순위 | 퀘스트 | 메모 |
| --- | --- | --- | --- | --- |
| 001 | pending | p1 | [M1-D1 플레이테스트 렌즈 세우기](001-ready-p1-playtest-lens.md) | 5라운드 기준이 낡아 10라운드/공개 데모 렌즈로 재정의해야 한다. |
| 002 | pending | p1 | [M1-D1 핵심 루프 기준표](002-ready-p1-core-loop-scorecard.md) | 실제 scorecard 결과가 없고 현재 공개 데모 기준으로 재정의해야 한다. |
| 010 | pending | p2 | [시체 폭발 팩 클리어](010-pending-p2-corpse-explosion-pack-clear.md) | 전투 손맛 개선 후보. 아이템 재검토와 함께 봐도 된다. |

## 흡수 완료

| ID | 상태 | 퀘스트 | 흡수된 위치 |
| --- | --- | --- | --- |
| 003 | complete | [전투 가독성 스냅샷](003-complete-p1-combat-readability-snapshot.md) | M1-D8 품질 게이트 |
| 006 | complete | [광산 정체성 에셋 패스](006-ready-p2-mining-identity-asset-pass.md) | runtime player/zombie sprite, 64px harness, stage capture |
| 008 | complete | [런 리포트](008-complete-p2-run-report.md) | M1-D4 |
| 009 | complete | [계약 카드 첫 프로토타입](009-complete-p2-contract-card-first-prototype.md) | M1-D3, M1-D7 |

## 한눈에 보기

| ID | 우선순위 | 상태 | M/D | 체인 | 퀘스트 |
| --- | --- | --- | --- | --- | --- |
| 001 | p1 | pending | M1-D1 | validation | [플레이테스트 렌즈](001-ready-p1-playtest-lens.md) |
| 002 | p1 | pending | M1-D1 | design | [핵심 루프 기준표](002-ready-p1-core-loop-scorecard.md) |
| 003 | p1 | complete | M1-D8 | combat | [전투 가독성 스냅샷](003-complete-p1-combat-readability-snapshot.md) |
| 004 | p1 | complete | M1-D1 | core-loop | [5라운드 플레이어블 루프](004-complete-p1-m1-d1-five-round-playable-loop.md) |
| 005 | p1 | complete | M1-D1 | combat | [적 아키타입과 웨이브 패턴](005-complete-p1-enemy-archetypes-and-wave-patterns.md) |
| 006 | p2 | complete | M1-backlog | art | [광산 정체성 에셋 패스](006-ready-p2-mining-identity-asset-pass.md) |
| 007 | p1 | complete | M1-D1 | boss | [보스 좀비와 테스트 종료](007-complete-p1-boss-zombie-and-test-ending.md) |
| 008 | p2 | complete | M1-backlog | validation | [런 리포트](008-complete-p2-run-report.md) |
| 009 | p2 | complete | M1-superseded | risk-reward | [계약 카드 첫 프로토타입](009-complete-p2-contract-card-first-prototype.md) |
| 010 | p2 | pending | M1-backlog | combat | [시체 폭발 팩 클리어](010-pending-p2-corpse-explosion-pack-clear.md) |
| 011 | p2 | pending | M1-D8 | choice | [상점/보상 선택감 정리](011-pending-p2-shop-and-reward-choice-pass.md) |
| 012 | p1 | complete | M1-D2 | shop | [상점 강화 루프](012-complete-p1-m1-d2-upgrade-shop-loop.md) |
| 013 | p1 | complete | M1-D3 | risk-reward | [유물 계약 루프](013-complete-p1-m1-d3-relic-contract-loop.md) |
| 014 | p1 | complete | M1-D4 | validation | [런 리포트와 디버그 하네스](014-complete-p1-m1-d4-run-report-and-debug-harness.md) |
| 015 | p1 | complete | M1-D5 | combat-readability | [빌드 체감과 전투 가독성](015-complete-p1-m1-d5-build-feedback-and-combat-readability.md) |
| 016 | p1 | complete | M1-D6 | map-ui | [넓은 광산과 전투 화면 정리](016-complete-p1-m1-d6-map-camera-ui-spawn-readability.md) |
| 017 | p1 | complete | M1-D7 | threat-economy | [10라운드 위협/경제 재정비](017-complete-p1-m1-d7-ten-round-threat-economy.md) |
| 018 | p2 | pending | M1-D8 | design | [강화/아이템/유물 목록 재검토](018-pending-p2-upgrade-item-relic-review.md) |
| 019 | p1 | complete | M1-D8 | weapon-identity | [무기 정체성 루프](019-complete-p1-m1-d8-weapon-identity.md) |
| 020 | p2 | complete | M1-D11 | economy | [다중 화폐 경제](020-pending-p2-m1-d11-multi-currency-economy.md) |
| 021 | p1 | ready | M1-D9 | buildcraft | [캐릭터 3종과 빌드 아키타입 매트릭스](021-pending-p1-m1-d9-character-archetype-matrix.md) |
| 022 | p1 | pending | M1-D10 | validation | [숙련도별 자동 시뮬레이션 검증](022-pending-p1-m1-d10-skill-simulation-validation.md) |
| 023 | p1 | complete | Public Demo | risk-reward | [체크포인트 위험 선택 루프](023-ready-p1-demo-checkpoint-risk-loop.md) |
| 024 | p1 | pending | Public Demo | release | [Windows itch.io 공개 데모](024-pending-p1-demo-windows-release.md) |

## 상태 규칙

- `ready`: 승인됐고 시작할 수 있는 퀘스트. dependencies가 남아 있으면 선행 퀘스트 완료 뒤 시작한다.
- `pending`: 방향 확인, 우선순위 결정, 또는 세부 명세가 필요한 퀘스트.
- `complete`: 통과 조건을 확인했거나 뒤 마일스톤에 흡수되어 Work Log에 결과가 남은 퀘스트.
- 모든 `pending/ready` todo는 frontmatter에 고유한 `github_issue` 전체 URL을 기록한다.
- 상태 전환은 GitHub Issue와 todo에 같은 작업 턴에 반영하고, 완료 PR은 `Closes #<issue-number>`로 연결한다.

공개 데모 `pipeline_slice`에는 다음 축을 서로 대신하지 않도록 별도로 기록한다.

- `status`: `pending | ready | complete` lifecycle. 한 번에 정확히 하나만 `ready`다.
- `owner_lane`: `planning | dev | asset | validation | producer`.
- `validator_verdict`: `not-run | passed | conditional-pass | rejected`.
- `user_gate`: `not-requested | awaiting-user-approval | approved | changes-requested`.
- `artifacts`: handoff에서 확인한 저장소 상대 경로의 증거.
- todo frontmatter가 권위이고, 최신 Work Log의 `pipeline-state` marker는 그 상태를 만든 append-only 증거다. 두 값이 다르면 새 dispatch를 중단한다.
- `passed`는 `complete`가 아니다. Product Owner가 실제 플레이 단위를 승인해야 `user_gate: approved`, `status: complete`로 닫고 다음 slice를 `ready`로 만든다.

## 에이전트 운영 연동

- 장기 운영은 [반자동 에이전트 운영 팀](../docs/operations/2026-06-05-agent-team-operating-model.md)을 따른다.
- `todos/README.md`는 메인 Producer가 읽는 기본 queue다.
- 개별 todo의 `Work Log`는 Planner, Developer, Asset, Validator 에이전트의 handoff 기록 장소로 사용한다.
- `owner_lane`, `active_thread`, `worktree`, `blocked_questions`, `artifacts`, `last_handoff` 필드는 새 활성 작업부터 점진적으로 추가한다.
- 공개 데모 dispatch 전에는 `python3 scripts/tools/validate_agent_pipeline.py`가 `PIPELINE VALID`를 출력해야 한다.

## 플레이테스트 메모

```text
날짜:
무기:
도달 라운드:
가장 잘 읽힌 적/위협:
가장 흐렸던 적/위협:
상점에서 고른 핵심 선택:
이번 런에서 배운 점:
다음 수정:
판정: keep / adjust / cut
```
