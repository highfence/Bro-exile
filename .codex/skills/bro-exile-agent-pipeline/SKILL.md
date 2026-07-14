---
name: bro-exile-agent-pipeline
description: >-
  Bro-exile의 새 세션에서 개발 파이프라인을 재개하고 todo queue와 active slice를 검증해
  Producer가 Planner, Developer, Asset, Validator로 라우팅하거나 spec lock 기반 Async Studio를
  preview, start, resume하여 다음 playable demo를 준비할 때 사용한다. "파이프라인 재개",
  "새 방식", "Async Studio", "spec lock", "퇴근 후 데모", "다음 playable slice",
  "진행 중인 Studio 상태" 요청에 적용한다.
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

## Spec-Locked Async Studio

Product Owner가 부재한 동안 다음 playable slice를 진행할 때는 다음 자료를 추가로 읽는다.

1. `references/spec-lock-template.md`
2. `references/async-studio-coordinator.md`
3. `references/demo-bundle-template.md`
4. `docs/operations/async-studio-runbook.md`

`run_agent_studio.py preview`는 읽기 전용이다. `bootstrap`, `start`, `resume`, `decision`은 반드시 Product Owner의 명시적 `--yes`가 있어야 한다. studio start 뒤에는 candidate worktree만 writable authority이며, root의 동명 todo나 projection을 실행 권위로 사용하지 않는다.
