---
studio_demo_bundle: true
slice_id: "000"
spec_lock: "docs/spec-locks/000-example.md"
stable_commit: "0000000000000000000000000000000000000000"
candidate_commit: "1111111111111111111111111111111111111111"
validation_status: "passed"
change_summary: "이전 승인본과 달라진 플레이 경험을 한 문장으로 적는다."
validation_evidence: ["docs/reports/validation/example.md"]
deviations: []
variants: ["candidate"]
play_lens: "플레이 후 답할 질문 하나"
blocker_question: ""
visual_change: false
visual_evidence: []
launch_scene: "scenes/main.tscn"
---

# Demo Bundle

## Launch

Candidate를 첫 번째, stable fallback을 두 번째로 제공한다. 임의 shell command는 저장하지 않고 검증된 Godot scene만 기록한다.

## Change Summary

코드 목록보다 플레이어가 느낄 차이를 먼저 적는다.

## Validation

실행한 검증, 실패와 deviation, UI/에셋 변경 시 실제 renderer capture와 pixel-perfect evidence를 연결한다.

## Play Lens

Product Owner가 `keep / adjust / cut` 전에 답할 질문 하나만 적는다.
