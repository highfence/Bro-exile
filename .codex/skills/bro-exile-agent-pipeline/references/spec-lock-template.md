---
studio_spec_lock: true
slice_id: "000"
todo: "todos/000-example.md"
plan: "docs/plans/YYYY-MM-DD-example-plan.md"
demo_promise: "다음 플레이에서 증명할 경험을 한 문장으로 적는다."
player_outcome: "플레이어가 보고 느끼거나 결정할 observable result를 적는다."
must: ["반드시 성립해야 하는 결과"]
may: ["에이전트가 자율 결정해도 되는 구현 선택"]
must_not: ["이번 candidate에서 금지할 방향"]
acceptance_examples: ["happy: 정상 플레이 증거", "edge: 경계 편차에서도 유지할 결과", "failure: 새 제품 판단이면 한 질문으로 멈춘다"]
defaults: ["Product Owner 부재 중 사용할 기본값과 이유"]
variants: ["candidate"]
rejected_alternatives: ["새 플레이 증거 전에는 다시 열지 않을 대안"]
stop_conditions: ["새 재미 방향", "명세 모순", "runtime asset promotion", "remote push 또는 public release"]
repair_budget: 2
review_due_at: "2099-01-02T21:00:00+09:00"
review_deadline_override: ""
play_lens: "Product Owner가 플레이 후 답할 질문 하나"
unresolved_product_decisions: []
writer_lanes: ["dev"]
allowed_paths: ["scripts/game", "scripts/ui", "todos/000-example.md"]
---

# 000 Spec Lock

## Demo Promise

frontmatter의 `demo_promise`를 사람이 판단할 수 있는 맥락과 함께 설명한다.

## Player Outcome

코드 구조가 아니라 플레이어가 관찰할 결과를 적는다.

## Must / May / Must Not

필수 결과, 위임한 구현 판단, 금지 방향을 서로 겹치지 않게 적는다.

## Acceptance Examples

정상, 경계, 실패 또는 제품 blocker 사례를 Given/When/Then 수준으로 적는다.

## Defaults and Variants

부재 중 기본값과 최대 두 개의 launchable variant를 적는다.

## Rejected Alternatives

새 플레이 증거 전에는 다시 열지 않을 대안을 적는다.

## Stop Conditions

제품 판단, 명세 모순, 예산, 에셋 승격, 배포와 상태 무결성 중단 조건을 적는다.

## Play Lens

다음 PD 세션에서 답할 질문 하나만 적는다.
