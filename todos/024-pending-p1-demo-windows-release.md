---
status: pending
priority: p1
issue_id: "024"
tags: [public-demo, windows, itch-io, release, vertical-slice]
dependencies: ["022"]
milestone: Public Demo
delivery: Windows Release
chain: release
quest_title: "Windows itch.io 공개 데모 출시"
pipeline_slice: true
queue_order: 5
owner_lane: planning
validator_verdict: not-run
user_gate: not-requested
artifacts:
  - "docs/plans/2026-07-12-001-feat-public-demo-vertical-slice-pipeline-plan.md"
last_handoff: "2026-07-12 - Producer Queue Rebaseline Handoff"
routing_reason: ""
---

# 024. Windows itch.io 공개 데모 출시

## Quest Card

- 목표: 승인된 vertical slice를 Windows itch.io 패키지로 검증하고 공개한다.
- 플레이어 감정: 설치부터 한 판 종료까지 막힘 없이 즐기고 “다음 런”을 선택한다.
- 완료 보상: 외부 플레이어가 받을 수 있는 첫 공개 데모와 첫 코호트 피드백이 생긴다.
- 실패 신호: 로컬 editor에서는 되지만 패키지 실행, 입력, 글꼴, 종료 요약 또는 다운로드 안내가 깨진다.

## Scope

- 구현 기준은 공개 데모 plan의 U8이다.
- Steam 연동과 macOS 출시 검증은 이 slice에 포함하지 않는다.
- 이전 네 slice가 모두 `complete`, `validator_verdict: passed`, `user_gate: approved`가 된 뒤에만 활성화한다.

## Acceptance Criteria

- [ ] Windows export preset과 재현 가능한 패키지 명령이 있다.
- [ ] packaged build에서 시작, 입력, 10라운드 종료, 재시작이 검증된다.
- [ ] 최소 5명의 첫 외부 플레이어 피드백과 다시 플레이 의향이 기록된다.
- [ ] 독립 Validator가 배포 후보를 판정하고 Product Owner가 공개 업로드를 승인한다.

## Work Log

### 2026-07-12 - Producer Queue Rebaseline Handoff

<!-- pipeline-state
{"artifacts": ["docs/plans/2026-07-12-001-feat-public-demo-vertical-slice-pipeline-plan.md"], "owner_lane": "planning", "routing_reason": "", "status": "pending", "user_gate": "not-requested", "validator_verdict": "not-run"}
-->

**By:** Producer

**상태:**
- pending

**Actions:**
- Windows itch.io 출시를 공개 데모 큐의 마지막 승인 slice로 추가했다.
- 자동 검증과 Validator 통과만으로 공개하지 않고 Product Owner 승인을 필수 gate로 두었다.

**Verification:**
- 큐/상태 계약만 검증한다. Windows export와 packaged build 검증은 이 slice 활성화 뒤 수행한다.

**Questions:**
- 활성화 시 지원 입력 범위와 외부 테스터 준비 상태를 확인한다.

**Next Handoff:**
- 022 승인 완료 뒤 Planner가 release checklist를 구체화한다.
