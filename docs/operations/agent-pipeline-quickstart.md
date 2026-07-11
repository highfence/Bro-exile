---
date: 2026-06-30
topic: agent-pipeline-quickstart
kind: operations
status: active-reference
---

# 에이전트 파이프라인 빠른 시작

이 문서는 Bro-exile 작업을 새 Codex 또는 Claude Code 세션에서 다시 시작할 때 읽는 짧은 진입점이다.

## 시작 순서

1. `AGENTS.md`의 프로젝트 규칙을 확인한다.
2. `todos/README.md`에서 현재 큐와 다음 추천 순서를 확인한다.
3. `docs/operations/agent-pipeline-current-state.md`에서 현재 active dispatch와 owner lane을 확인한다.
4. `python3 scripts/tools/validate_agent_pipeline.py`를 실행한다. 실패하면 새 dispatch 전에 projection/state drift를 고친다.
5. `docs/operations/2026-06-05-agent-team-operating-model.md`에서 Producer, Planner, Developer, Asset, Validator 역할을 확인한다.
6. 에셋, 픽셀, UI, 캡처 관련 작업이면 `docs/quality/2026-06-30-pixel-perfect-quality-gates.md`도 읽는다.
7. 현재 작업이 애매하면 Producer가 먼저 owner lane을 정한다.

## Producer 기본 루프

Producer는 한 번에 하나의 구현 목표만 고른다.

1. consistency validator가 출력한 active slice와 허용 transition을 확인한다.
2. 관련 todo와 plan/report를 읽는다.
3. owner lane을 정한다.
4. 역할 에이전트에게 읽을 문서, 쓸 수 있는 파일, 멈춰야 할 조건, handoff 위치를 지정한다.
5. Developer 또는 Asset 결과는 완료 처리 전에 Validator에게 넘긴다.
6. Validator `passed` 뒤 실제 플레이 단위를 Product Owner에게 승인받는다.
7. 승인 뒤 현재 todo를 닫고 다음 하나만 활성화한다.
8. 최종 상태와 사용자 결정 질문만 요약한다.

## 공개 데모 상태 계약

- `pipeline_slice: true` todo의 frontmatter가 canonical state다.
- `status`, `owner_lane`, `validator_verdict`, `user_gate`, `artifacts`를 각각 기록한다.
- Work Log는 지우거나 덮어쓰지 않고 끝에 append하며, 최신 handoff에 frontmatter와 동일한 `pipeline-state` JSON marker를 남긴다.
- `todos/README.md`와 현재 상태판은 projection이다. canonical todo와 다르면 dispatch를 중단한다.
- Validator `passed`는 `awaiting-user-approval`이지 `complete`가 아니다.
- Product Owner가 실제 플레이 단위를 승인한 뒤에만 현재 slice를 `complete/approved`로 닫고 다음 slice를 `ready`로 만든다.
- Validator `rejected`는 code/asset 결함을 Developer/Asset으로, design gap을 Planner로 되돌린다.

## 역할별 시작점

| 역할 | 먼저 읽을 것 | 산출물 |
| --- | --- | --- |
| Producer | `todos/README.md`, 현재 상태판, 운영 모델 | 큐 정리, 역할 프롬프트, 사용자 보고 |
| Planner | 관련 todo, brainstorm/plan | acceptance criteria, 디자인 질문, plan |
| Developer | 관련 todo/plan, `AGENTS.md` | Godot 구현, 검증 명령, Work Log |
| Asset | `bro-exile-asset-workflow`, pixel-perfect gates | 후보, preview, metadata, capture, report |
| Validator | todo, handoff, pixel-perfect gates | passed / conditional-pass / rejected 판정 |

## 로컬 Skill

- `.codex/skills/bro-exile-agent-pipeline/SKILL.md`: Producer/역할 라우팅.
- `.codex/skills/bro-exile-agent-pipeline/references/role-prompts.md`: 역할별 프롬프트 템플릿.
- `.codex/skills/bro-exile-asset-workflow/SKILL.md`: 에셋 후보/하네스/승격.
- `.codex/skills/bro-exile-pixel-perfect/SKILL.md`: 픽셀 단위 시각 검증.

## 완료 조건

큰 작업은 채팅 요약만으로 끝내지 않는다. 관련 todo의 `Work Log`나 링크된 report에 handoff가 남아야 한다.

운영 계약 자체를 변경했으면 다음 두 명령도 통과해야 한다.

```bash
python3 scripts/tools/test_validate_agent_pipeline.py
python3 scripts/tools/validate_agent_pipeline.py
```
