---
status: complete
priority: p1
issue_id: "014"
tags: [prototype, m1, d4, playtest, metrics, debug, godot, quest]
dependencies: ["013"]
milestone: M1
delivery: D4
chain: validation
quest_title: "M1-D4 런 리포트와 디버그 하네스"
---

# 014. M1-D4 런 리포트와 디버그 하네스

## Quest Card

- 목표: P3 루프를 한 판 끝낸 뒤, 선택/경제/전투 결과를 바로 복기할 수 있는 런 리포트를 만든다.
- 플레이어 감정: “이번 런에서 무엇을 골랐고 어디까지 통과했는지 바로 알겠다.”
- 완료 보상: 플레이테스트 결과가 기억이 아니라 다음 수정의 재료로 남는다.
- 실패 신호: 승리/패배 화면이나 smoke 출력만 보고는 어떤 빌드와 위험이 있었는지 알 수 없다.

## Problem Statement

P3는 유물 선택과 상점 대응 루프를 만들었지만, 플레이테스트가 끝난 뒤 선택한 유물, 구매한 부품, 광석 흐름, 보스 처치 여부를 한눈에 복기하기 어렵다. P4에서는 새 콘텐츠를 크게 늘리기보다, 현재 루프를 반복 검증할 수 있는 관측 장치를 붙인다.

## Acceptance Criteria

- [x] 승리/패배 화면에 결과, 도달 라운드, 생존 시간, 보스 처치 여부가 보인다.
- [x] 유물, 구매 부품, 광석 획득/사용/보유, 리롤 횟수, 구매 횟수가 보인다.
- [x] 같은 유물/부품 중복은 `xN`처럼 압축해서 읽힌다.
- [x] smoke playtest 출력에 P4 런 리포트 요약이 포함된다.
- [x] `--debug-spider-relic-wave2`와 `--debug-boss-pierce-splash` 출력에 같은 리포트 요약이 포함된다.
- [x] `--capture-run-report-ui`로 종료 리포트 UI를 실제 캡처할 수 있다.
- [x] P3 회귀 테스트와 smoke playtest가 통과한다.

## Implementation Notes

- 런 통계는 `scripts/main.gd`에서 메모리 상태로만 관리한다.
- 기록 대상은 광석 획득/사용, 리롤, 구매 목록, 처치 수, 적 타입별 처치 수, 보스 피해, 보스 처치 여부다.
- 승리/패배 overlay, smoke 출력, debug 출력은 같은 리포트 요약 함수를 공유한다.
- 영구 저장되는 런 히스토리, JSON/CSV 분석, Godot 내부 대시보드는 P4 범위에서 제외한다.

## Work Log

### 2026-06-03 - P4 런 리포트 구현

**By:** Codex

**Actions:**
- 런 통계 상태를 `_reset_run`에서 초기화하고, 광석/상점/처치/보스 피해 이벤트에 기록 훅을 붙였다.
- 승리/패배 종료 화면을 `P4 런 리포트`로 바꾸고, 유물/구매/경제/전투 요약을 5줄로 압축해 표시했다.
- smoke/debug 출력에 같은 리포트 요약을 붙였다.
- `--capture-run-report-ui` 캡처 커맨드를 추가했다.
- 종료 overlay 폭과 본문 높이를 조정해 리포트 텍스트가 안정적으로 읽히게 했다.

**Verification:**
- Godot headless 로드 검증 통과.
- `--debug-spider-relic-wave2` 통과. 거미 알 화석 1개 상태에서 2라운드 거미팩 2회, 거미 10마리 스폰을 확인했다.
- `--debug-boss-pierce-splash` 통과. 보스 주변 8방향 모두 13 피해가 들어갔다.
- `--smoke-playtest` 통과. 결과는 `VICTORY`, 도달 라운드는 `5/5`, 보스 처치가 기록됐다.
- `--capture-run-report-ui`로 `/private/tmp/orebound-godot-run-report-ui.png`를 생성하고, 리포트 UI 렌더를 확인했다.

**Learnings:**
- P4 리포트는 모든 수치를 자세히 보여주기보다, 선택/경제/전투를 메모로 옮기기 쉬운 5줄로 압축하는 편이 읽기 좋다.
- smoke/debug 출력과 종료 화면이 같은 요약 함수를 공유하면, 수동 플레이와 자동 회귀 결과를 같은 언어로 비교할 수 있다.
