---
status: pending
priority: p1
issue_id: "022"
github_issue: "https://github.com/highfence/Bro-exile/issues/3"
tags: [prototype, m1, d10, simulation, playtest, balance, validation, godot]
dependencies: ["019", "021"]
milestone: M1
delivery: D10
chain: validation
quest_title: "M1-D10 숙련도별 자동 시뮬레이션 검증"
pipeline_slice: true
queue_order: 4
owner_lane: planning
validator_verdict: not-run
user_gate: not-requested
artifacts:
  - "docs/plans/2026-07-12-001-feat-public-demo-vertical-slice-pipeline-plan.md"
last_handoff: "2026-07-12 - Producer Queue Rebaseline Handoff"
routing_reason: ""
---

# 022. M1-D10 숙련도별 자동 시뮬레이션 검증

## Quest Card

- 목표: 플레이어 숙련도별 자동 시뮬레이션을 돌려 현재 난이도와 디자인 변경의 영향을 반복 검증한다.
- 플레이어 감정: “이 변경이 실제로 더 좋아졌는지, 그냥 쉬워졌거나 불합리해졌는지 확인할 수 있다.”
- 완료 보상: 새 무기, 캐릭터, 아이템, 유물, 경제를 바꿀 때마다 난이도 리포트를 비교할 수 있다.
- 실패 신호: 자동 검증이 실제 플레이 감각과 동떨어지거나, 한 가지 봇 행동에 맞춰 게임이 과하게 튜닝된다.

## Problem Statement

현재 게임은 수동 플레이테스트와 몇몇 debug/smoke 명령으로 검증하고 있다. 하지만 앞으로 캐릭터, 아키타입, 아이템, 유물, 다중 화폐 경제가 늘어나면 디자인 변경마다 “이 게임이 적절히 어려운지”를 수동 감각만으로 판단하기 어렵다.

자동 검증은 사람 플레이를 대체하는 도구가 아니라, 플레이어 숙련도별 기준선을 제공하는 계기판이어야 한다. 조작을 거의 하지 않는 플레이어, 투박하게 움직이지만 보상은 어느 정도 고르는 플레이어, 거리 유지와 보상 선별을 적극적으로 하는 플레이어가 각각 어디까지 진행하는지 비교하면 난이도와 빌드 경제의 상태를 더 잘 볼 수 있다.

## Findings

- 사용자는 플레이어 실력에 따라 어느 정도까지 진행되는지 검증하는 시뮬레이션을 원한다.
- 시뮬레이션은 조작 능력뿐 아니라 보상/위험 선택 수준도 달라야 한다.
- 디자인 변경 시마다 결과를 비교하고 보고할 수 있어야 한다.
- 자동 시뮬레이션은 절대적인 정답이 아니라 회귀/밸런스 경향을 보는 도구다.
- 체크포인트, 화폐, D9 캐릭터 slice가 승인된 뒤 이 검증 도구를 만들면 공개 데모 축의 회귀와 난이도 경향을 함께 볼 수 있다.

## Simulation Profiles

### Profile 1: 방치형/랜덤 플레이어

- 조작을 거의 하지 않거나 최소한만 한다.
- 보상, 계약, 상점 선택을 랜덤하게 고른다.
- 목적: 게임이 아무 입력 없이도 너무 멀리 진행되지 않는지 확인한다.

### Profile 2: 투박한 초보 플레이어

- 기본 이동과 회피는 하지만 완벽한 거리 유지나 타겟 우선순위는 없다.
- 다음 라운드 위험과 보상을 어느 정도 연결해 선택한다.
- 목적: 초보 플레이어가 초반에 학습할 시간을 얻되, 중후반에서는 패턴 이해가 요구되는지 확인한다.

### Profile 3: 거리 유지형 숙련 플레이어

- 주변 적과 적절한 거리를 계속 유지하려고 한다.
- 위험, 다음 스테이지, 현재 빌드를 고려해 보상을 적극적으로 선별한다.
- 목적: 숙련 플레이어가 빌드와 움직임으로 더 멀리 진행할 수 있는지 확인한다.

## Proposed Solutions

### Option 1: 기존 smoke playtest 확장

기존 `--smoke-playtest` 계열에 `--sim-profile=random|rough|skilled`, `--sim-runs=N`, `--seed` 같은 옵션을 추가한다.

- 장점: 기존 자동 검증 구조를 재사용한다.
- 장점: Godot 내부 상태와 런 리포트를 바로 활용할 수 있다.
- 단점: smoke playtest가 점점 커질 수 있다.

### Option 2: 별도 simulation command

`--simulate-skill-profiles` 같은 별도 명령으로 3개 프로필을 한 번에 여러 seed로 돌리고 요약 리포트를 출력한다.

- 장점: 목적이 명확하고 CI/회귀 검증에 붙이기 쉽다.
- 단점: 기존 smoke 코드와 중복을 조심해야 한다.

### Option 3: 외부 시뮬레이션 스크립트

Godot를 headless로 반복 실행하는 외부 스크립트를 만들고, 결과를 수집한다.

- 장점: 여러 seed/프로필 반복 실행과 리포트 저장이 쉽다.
- 단점: Godot 내부 의사결정과 결과 수집을 연결하는 코드가 추가로 필요하다.

## Recommended Action

Option 2를 목표로 하되, 내부 구현은 기존 smoke playtest 로직을 최대한 재사용한다. 첫 버전은 완벽한 AI가 아니라 세 가지 플레이어 수준의 “거친 기준선”을 만드는 데 집중한다.

## Acceptance Criteria

- [ ] 최소 3개 simulation profile이 정의되어 있다.
- [ ] 각 profile은 조작 수준과 보상/위험 선택 수준이 다르다.
- [ ] 여러 seed를 돌려 도달 라운드, 사망/승리, 생존 시간, 처치 수, 광석 흐름, 구매/계약 선택을 요약한다.
- [ ] profile별 결과가 한눈에 비교되는 콘솔 리포트 또는 파일 리포트가 있다.
- [ ] D8 무기별로 최소 smoke 수준의 simulation을 돌릴 수 있다.
- [ ] 디자인 변경 전후 결과를 비교할 수 있도록 seed와 profile 설정이 재현 가능하다.
- [ ] 자동 시뮬레이션이 수동 플레이테스트를 대체하지 않는다는 한계가 문서화되어 있다.

## Work Log

### 2026-06-05 - Initial Capture

**By:** Codex

**Actions:**
- 사용자 제안을 M1-D10 delivery todo로 캡처했다.
- 다중 화폐 경제보다 먼저 자동 검증 계기판을 만드는 흐름으로 큐를 조정했다.

**Learnings:**
- 앞으로 빌드/경제 시스템이 복잡해질수록 수동 플레이테스트만으로 난이도를 판단하기 어렵다.
- 숙련도별 자동 시뮬레이션은 게임을 대신 플레이하는 정답 AI가 아니라, 디자인 변경의 경향을 읽는 기준선이다.

### 2026-07-12 - Producer Queue Rebaseline Handoff

<!-- pipeline-state
{"artifacts": ["docs/plans/2026-07-12-001-feat-public-demo-vertical-slice-pipeline-plan.md"], "owner_lane": "planning", "routing_reason": "", "status": "pending", "user_gate": "not-requested", "validator_verdict": "not-run"}
-->

**By:** Producer

**상태:**
- pending

**Actions:**
- D10을 공개 데모 큐의 네 번째 slice로 유지하되 D9 승인 뒤에만 활성화하도록 고정했다.
- 시뮬레이션은 사람 플레이를 대체하지 않고 체크포인트, 화폐, 캐릭터 변경의 회귀 계기판으로 사용한다.

**Verification:**
- 큐/상태 계약만 검증한다. simulation 검증은 이 slice 활성화 뒤 수행한다.

**Questions:**
- 활성화 시 deterministic RNG와 fixed-step 세부 방식을 plan에서 확정한다.

**Next Handoff:**
- 021이 `complete/approved`가 되면 이 todo를 `ready`로 전환하고 Planner에 넘긴다.
