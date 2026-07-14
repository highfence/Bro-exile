---
date: 2026-07-14
topic: github-issue-workflow
kind: operations
status: active-reference
---

# GitHub Issue 작업 운영

Bro-exile의 진행 예정 작업은 GitHub Issue에서 상태, 논의, 담당자, 의존성, PR을 관리한다. `todos/`는 에이전트가 실행할 상세 명세와 append-only Work Log를 보존한다. 둘 중 하나를 없애지 않고 같은 작업을 한 쌍으로 연결한다.

## 기록 책임

| 위치 | 책임 |
| --- | --- |
| GitHub Issue | 작업 목록, 공개 상태, 담당자, 의존 이슈, 결정 논의, 연결 PR, 종료 여부 |
| `todos/NNN-*.md` | acceptance criteria, pipeline state, artifacts, 역할별 handoff, 검증 증거 |
| `todos/README.md` | Producer가 읽는 로컬 queue projection |
| PR | 구현 diff와 `Closes #<issue-number>`를 통한 자동 종료 연결 |

GitHub Issue가 열려 있는데 todo가 `complete`이거나, 이슈가 닫혔는데 todo가 `pending/ready`인 상태를 방치하지 않는다. 공개 데모 slice의 세부 lifecycle은 기존 규칙대로 todo frontmatter가 canonical record이며, 해당 전환을 같은 작업 턴에 GitHub Issue에도 반영한다.

## 새 작업 생성 순서

1. GitHub의 `작업` Issue form으로 목표, 우선순위, owner lane, 마일스톤, 선행 이슈, 완료 조건을 등록한다.
2. 단순 문의가 아니라 실행할 작업이면 `todos/NNN-*.md`를 만들거나 기존 todo를 연결한다.
3. todo frontmatter에 전체 URL 형식의 `github_issue`를 기록한다.
4. `todos/README.md`의 적절한 큐에 작업을 추가한다.
5. `python3 scripts/tools/validate_agent_pipeline.py`로 모든 `pending/ready` todo의 GitHub 링크와 pipeline projection을 검증한다.

GitHub 연결이 일시적으로 불가능하면 아이디어 메모는 남길 수 있지만, `github_issue`가 생기기 전에는 todo를 `pending/ready` 상태로 dispatch하지 않는다.

## 구현과 handoff

- 브랜치는 가능하면 `issue-<number>-<slug>` 또는 기존 프로젝트 branch 규칙을 사용한다.
- 커밋과 Work Log에는 `#<issue-number>`를 적어 검색 가능한 연결을 남긴다.
- PR 본문 첫 섹션에 `Closes #<issue-number>`를 넣는다.
- Developer 또는 Asset handoff 뒤 GitHub Issue에 현재 결과와 Validator가 확인할 증거를 요약한다.
- Validator 판정과 Product Owner gate는 todo Work Log에 상세히 남기고 이슈에도 같은 상태를 반영한다.
- priority 또는 제품 방향을 바꾸는 결정은 Product Owner 승인 없이 이슈와 todo 어느 쪽에서도 확정하지 않는다.

## 상태 대응

| GitHub | todo | 의미 |
| --- | --- | --- |
| open | `pending` | 방향, 의존성, 세부 명세가 남아 있다. |
| open | `ready` | 다음 owner lane이 실행할 수 있다. |
| open | Validator passed / 승인 대기 | Product Owner가 실제 플레이 단위를 확인할 때까지 닫지 않는다. |
| closed: completed | `complete`, `approved` | 검증과 사용자 gate를 모두 통과했다. |
| closed: not planned | `complete` 또는 별도 superseded 기록 | 흡수, 중복, 취소 이유를 이슈와 Work Log에 남겼다. |

## 현재 연결

| todo | GitHub Issue | 분류 |
| --- | --- | --- |
| T020 | [#1 다중 화폐 경제](https://github.com/highfence/Bro-exile/issues/1) | complete, Product Owner approved |
| T021 | [#2 캐릭터/아키타입 매트릭스](https://github.com/highfence/Bro-exile/issues/2) | active, planning |
| T022 | [#3 숙련도별 자동 시뮬레이션](https://github.com/highfence/Bro-exile/issues/3) | queued |
| T024 | [#4 Windows itch.io 공개 데모](https://github.com/highfence/Bro-exile/issues/4) | queued |
| T001 | [#5 플레이테스트 렌즈](https://github.com/highfence/Bro-exile/issues/5) | backlog, needs-rebaseline |
| T002 | [#6 핵심 루프 기준표](https://github.com/highfence/Bro-exile/issues/6) | backlog, needs-rebaseline |
| T006 | [#7 광산 정체성 에셋 패스](https://github.com/highfence/Bro-exile/issues/7) | complete |
| T010 | [#8 시체 폭발 팩 클리어](https://github.com/highfence/Bro-exile/issues/8) | backlog |
| T011 | [#9 상점/보상 선택감](https://github.com/highfence/Bro-exile/issues/9) | partially absorbed, D9 review input |
| T018 | [#10 강화/아이템/유물 재검토](https://github.com/highfence/Bro-exile/issues/10) | partially absorbed, D9 review input |
