---
status: ready
priority: p1
issue_id: "023"
tags: [public-demo, checkpoint, risk, reward, vertical-slice]
dependencies: ["019"]
milestone: Public Demo
delivery: Checkpoint Risk Slice
chain: risk-reward
quest_title: "공개 데모 체크포인트 위험 선택 루프"
pipeline_slice: true
queue_order: 1
owner_lane: dev
validator_verdict: not-run
user_gate: not-requested
artifacts:
  - "docs/plans/2026-07-12-001-feat-public-demo-vertical-slice-pipeline-plan.md"
last_handoff: "2026-07-12 - Producer Queue Rebaseline Handoff"
routing_reason: ""
---

# 023. 공개 데모 체크포인트 위험 선택 루프

## Quest Card

- 목표: R3, R5, R7 뒤에 안전, 위험, 상점, 엘리트 중 하나를 능동적으로 고르는 플레이 가능한 한 조각을 만든다.
- 플레이어 감정: “현재 빌드로 어디까지 욕심낼지 내가 결정한다.”
- 완료 보상: 위험 선택이 같은 런의 보상을 키우고, 무리한 선택은 납득 가능한 폭사로 이어진다.
- 실패 신호: 선택이 고정 보상 화면처럼 느껴지거나, 안전 선택이 전투 외 회복과 중복되어 항상 정답이 된다.

## Scope

- 구현 기준은 `docs/plans/2026-07-12-001-feat-public-demo-vertical-slice-pipeline-plan.md`의 U2와 U3다.
- 체크포인트 선택은 기존 10라운드 전투를 보존하며 R3, R5, R7의 고정 보상 꼬리를 대체한다.
- 이 slice가 Validator 판정과 Product Owner 승인을 모두 받기 전에는 020 화폐 slice를 활성화하지 않는다.

## Acceptance Criteria

- [ ] R3, R5, R7 뒤에 체크포인트 선택이 정확히 한 번 열린다.
- [ ] 안전만 회복을 제공하며, 위험/상점/엘리트는 고유한 비용과 이득을 가진다.
- [ ] 선택한 위험과 보상이 다음 전투 및 런 종료 요약에서 추적된다.
- [ ] debug, smoke, 실제 플레이, UI capture 증거가 Work Log 또는 validation report에 남는다.
- [ ] 독립 Validator가 판정한 뒤 Product Owner가 실제 빌드를 승인해야 `complete`가 된다.

## Work Log

### 2026-07-12 - Producer Queue Rebaseline Handoff

<!-- pipeline-state
{"artifacts": ["docs/plans/2026-07-12-001-feat-public-demo-vertical-slice-pipeline-plan.md"], "owner_lane": "dev", "routing_reason": "", "status": "ready", "user_gate": "not-requested", "validator_verdict": "not-run"}
-->

**By:** Producer

**상태:**
- ready

**Actions:**
- 공개 데모의 첫 활성 slice로 체크포인트 위험 선택 루프를 지정했다.
- D9의 오래된 active dispatch를 닫고, 구현 순서를 체크포인트부터 시작하도록 재정렬했다.

**Verification:**
- `python3 scripts/tools/test_validate_agent_pipeline.py`
- `python3 scripts/tools/validate_agent_pipeline.py`

**Questions:**
- 없음. U2 characterization gate를 먼저 추가한 뒤 U3 구현으로 진행한다.

**Next Handoff:**
- Developer가 U2/U3 범위의 구현과 증거를 이 Work Log에 남긴다.
- Developer 완료 후 독립 Validator가 판정한다.

