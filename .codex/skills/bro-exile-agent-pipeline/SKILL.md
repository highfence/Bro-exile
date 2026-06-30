---
name: bro-exile-agent-pipeline
description: Bro-exile에서 Producer가 todo queue를 읽고 Planner, Developer, Asset, Validator 역할 에이전트로 구현 목표를 라우팅할 때 사용한다.
---

# Bro-exile Agent Pipeline

## 목적

Bro-exile의 반자동 에이전트 팀 운영을 재개할 때 사용한다. Producer가 큐를 읽고, 한 번에 하나의 구현 목표를 골라 Planner, Developer, Asset, Validator 중 적절한 역할로 넘긴다.

## 시작 절차

1. `docs/operations/agent-pipeline-quickstart.md`를 읽는다.
2. `docs/operations/2026-06-05-agent-team-operating-model.md`를 읽는다.
3. `todos/README.md`에서 현재 큐와 추천 순서를 확인한다.
4. 관련 todo, plan, brainstorm, report를 필요한 만큼만 연다.
5. owner lane을 정하고 역할 프롬프트를 작성한다.

## 라우팅 기준

- `pending`이고 검증 질문이 흐리면 Planner.
- `ready`이고 구현 acceptance criteria가 명확하면 Developer.
- `asset`, `art`, `sprite`, `icon`, `harness`, `animation`이 있으면 Asset.
- Developer 또는 Asset 완료 보고 이후 완료 처리 전이면 Validator.
- UI/전투/경제/에셋이 섞인 작업은 Producer가 쪼갠다.

## Handoff

역할 에이전트는 채팅 요약만 남기지 않는다. 관련 todo의 `Work Log` 또는 report에 handoff를 남긴다.

필수 항목:

- 상태: done / blocked / needs-review / passed / conditional-pass / rejected.
- 수행한 일.
- 변경한 파일 또는 산출물.
- 실행한 검증과 결과.
- 사용자 질문.
- 다음 owner lane.

## Pixel-Perfect 연결

에셋, UI, animation, capture 관련 작업은 `.codex/skills/bro-exile-pixel-perfect/SKILL.md`를 함께 적용한다.
