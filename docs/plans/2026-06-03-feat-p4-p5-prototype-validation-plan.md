---
title: "feat: P4/P5 프로토타입 검증 마일스톤"
type: feat
status: complete
date: 2026-06-03
origin: docs/brainstorms/2026-06-02-p3-relic-contract-loop-brainstorm.md
related_origins:
  - docs/brainstorms/2026-06-01-prototyping-quest-dashboard-brainstorm.md
---

# feat: P4/P5 프로토타입 검증 마일스톤

## Overview

P3는 `라운드 클리어 -> 유물 선택 -> 상점 -> 다음 라운드` 흐름을 완성했고, 플레이어가 누적 위험/보상을 직접 선택하는 첫 루프를 만들었다. 다음 단계는 새 콘텐츠를 크게 늘리기보다, P3 루프를 반복 검증할 수 있게 만들고, 선택한 유물/부품이 전투에서 즉시 체감되는지 확인하는 것이다.

이 계획은 내일 진행할 두 마일스톤을 정의한다.

- P4: 플레이테스트 관측/안정화
- P5: 빌드 체감/전투 피드백 강화

P4는 “무엇이 일어났는지 기록할 수 있는가?”를 답하고, P5는 “내가 고른 빌드가 전투에서 다르게 느껴지는가?”를 답한다.

## Current Status

- P4는 구현 완료. 종료 화면, smoke/debug 출력, `--capture-run-report-ui`에서 런 리포트를 확인했다.
- P5는 구현 완료. 부품별 전투 피드백, 몹 넉백/피격감, 이동 속도 완화, separation, 전투 피드백 캡처를 확인했다.

## Origin Decisions

P3 브레인스토밍은 유물을 “숨은 디버프”로 만들지 않고 HUD/상점/종료 화면에서 계속 보여야 한다고 결정했다. P4는 이 원칙을 종료 리포트와 디버그 시나리오로 확장한다. 유물 선택 후 상점 대응을 하고 싶어져야 한다는 P3 성공 기준도 P5의 핵심 검증 질문으로 이어진다. (see brainstorm: `docs/brainstorms/2026-06-02-p3-relic-contract-loop-brainstorm.md`)

프로토타입 퀘스트 대시보드 브레인스토밍은 기능 구현보다 검증 질문을 중심으로 퀘스트를 쪼개고, Markdown 보드를 기준 화면으로 삼기로 했다. P4/P5는 각각 별도 퀘스트 카드로 추가하고, 결과는 `todos/README.md`와 개별 퀘스트 Work Log에 남긴다. (see brainstorm: `docs/brainstorms/2026-06-01-prototyping-quest-dashboard-brainstorm.md`)

## Local Research Findings

### Repository Research Summary

- Godot 프로젝트의 핵심 게임 상태와 선택 처리 흐름은 `scripts/main.gd`에 있다.
- UI 렌더링은 `scripts/ui/game_ui.gd`의 `show_choice`, `show_end`, `update_hud`, `render_relics` 패턴을 따른다.
- P3 이후 이미 존재하는 검증 커맨드는 `--smoke-playtest`, `--debug-spider-relic-wave2`, `--debug-boss-pierce-splash`이다.
- `todos/008-ready-p2-run-report.md`는 P4의 직접적인 선행 퀘스트다. 종료 화면 요약 확장과 smoke 출력 강화를 권장한다.
- `todos/011-pending-p2-shop-and-reward-choice-pass.md`는 P5의 직접적인 선행 퀘스트다. 상점/보상 선택지가 빌드 방향을 만든다는 느낌을 강화하자는 내용이다.
- 계획 문서는 한글로 작성하고, 기획/리뷰/README성 문서는 한국어를 기본으로 한다는 프로젝트 규칙이 `AGENTS.md`에 있다.

### Institutional Learnings

- `docs/solutions/ui-bugs/invisible-godot-ui-text-GodotPort-20260522.md`는 Godot UI는 headless 성공만으로 충분하지 않고 실제 캡처로 텍스트/레이아웃을 확인해야 한다고 기록한다.
- P4/P5에서 종료 리포트와 전투 피드백 UI를 건드릴 경우, `--capture-ui` 또는 새 캡처 커맨드로 실제 화면을 확인해야 한다.

### External Research Decision

외부 리서치는 생략한다. P4/P5는 새 프레임워크, 보안, 결제, 외부 API가 아니라 기존 Godot 프로토타입의 계측/피드백 강화 작업이다. 현재 코드베이스와 문서에 충분한 패턴이 있다.

## Proposed Milestones

## P4: 플레이테스트 관측/안정화

### Goal

P3 루프를 반복 테스트 가능한 상태로 만든다. 플레이테스트 후 “느낌상 이상했다”가 아니라, 어떤 유물/부품/라운드/상점 선택이 있었는지 보고 다음 수정을 고를 수 있어야 한다.

### Player/Designer Feeling

“이번 런에서 무엇을 골랐고, 어디서 강해졌고, 어디서 위험해졌는지 바로 복기할 수 있다.”

### Proposed Solution

1. 런 통계 상태를 `scripts/main.gd`에 모은다.
2. 승리/패배 overlay에 P3 런 리포트를 보여준다.
3. smoke/debug 출력에 동일한 요약 값을 넣는다.
4. P3에서 발견한 고위험 조합을 headless 디버그 시나리오로 유지한다.
5. `todos/014-complete-p4-run-report-and-debug-harness.md`를 생성하고 대시보드에 연결했다.

### Suggested Metrics

- 결과: victory/game over, 도달 라운드, 생존 시간, 보스 처치 여부
- 경제: 획득 광석, 사용 광석, 리롤 횟수, 구매 횟수
- 선택: 선택한 유물과 중복 수, 구매한 부품 목록과 중복 수
- 전투: 처치 수, 적 타입별 처치 수, 보스에게 준 피해
- 회귀 테스트: spider relic wave2, boss pierce splash, smoke playtest 결과

### P4 Acceptance Criteria

- [x] 승리/패배 화면에 유물, 구매 부품, 광석, 리롤, 보스 처치 여부가 보인다.
- [x] 같은 유물/부품 중복은 `xN`처럼 압축해서 읽힌다.
- [x] smoke playtest 출력에 P4 런 리포트 요약이 포함된다.
- [x] `--debug-spider-relic-wave2`와 `--debug-boss-pierce-splash`가 계속 통과한다.
- [x] UI 변경은 실제 캡처로 확인한다.
- [x] `todos/README.md`에 P4 메인 퀘스트가 추가된다.

### P4 Scope Boundaries

포함:

- 한 판 종료 후 결과 요약
- 콘솔 smoke/debug 출력 강화
- 수동 플레이테스트 메모로 옮기기 쉬운 형식

제외:

- 영구 저장되는 런 히스토리
- Godot 내부 개발자 대시보드
- CSV/JSON 분석 파이프라인
- 완성형 밸런스 대시보드

## P5: 빌드 체감/전투 피드백 강화

### Goal

상점 부품과 유물 선택이 전투 화면에서 즉시 체감되게 만든다. P3의 위험/보상 선택은 작동하지만, 플레이어가 “내가 이 빌드라서 이 위험을 감당했다”고 느끼려면 관통, 폭발, 방어 관통, 공속, 사거리 같은 효과가 화면에서 선명해야 한다.

### Player Feeling

“이건 내가 방금 산 부품 덕분에 정리됐다.”

### Proposed Solution

1. 무기 부품별 전투 피드백을 정리한다.
2. 관통/폭발/방어 관통/공속/사거리 효과의 시각 차이를 만든다.
3. 보스와 엘리트에게 피격 피드백을 더 강하게 준다.
4. 거미팩, 엘리트 좀비, 투척 좀비의 위험 신호를 더 빨리 읽히게 한다.
5. `todos/015-complete-p5-build-feedback-and-combat-readability.md`를 생성하고 대시보드에 연결했다.

### Priority Feedback Targets

- 관통 드릴촉: 적을 지나가는 궤적과 다중 히트가 보인다.
- 파편 폭약: 폭발 반경과 직격 피해가 명확하다.
- 균열 탄심: 보스/엘리트에게 방어 관통 히트가 구분된다.
- 급속 방아쇠: 발사 리듬이 빨라졌다는 감각이 난다.
- 긴 총열: 사거리와 탄속 증가가 체감된다.
- 스프링 장화: 이동 대응이 쉬워졌다는 감각이 난다.

### P5 Acceptance Criteria

- [x] 최소 4개 핵심 부품이 서로 다른 시각/숫자 피드백을 가진다.
- [x] 폭발+관통 조합이 거미팩과 보스 모두에서 읽힌다.
- [x] 보스 HP/피격 피드백이 명확해서 데미지 누락처럼 느껴지지 않는다.
- [x] 유물 위험에 맞는 대응 부품을 샀을 때 전투가 다르게 느껴진다.
- [x] P4 런 리포트에서 P5 변경 후 빌드/부품 선택이 확인된다.
- [x] UI/전투 캡처로 가독성을 확인한다.

### P5 Scope Boundaries

포함:

- 프로토타입 수준의 시각 피드백
- 전투 가독성 개선
- 보스/엘리트/거미팩의 체감 개선

제외:

- 최종 사운드 디자인
- 최종 VFX 에셋 시스템
- 모든 무기/아이템의 완성형 이펙트
- 새 장기 성장 시스템

## Technical Considerations

### Architecture

- `scripts/main.gd`는 게임 상태, 런 통계, 디버그 커맨드, 전투 이벤트 기록을 담당한다.
- `scripts/ui/game_ui.gd`는 종료 리포트와 HUD/overlay 표시를 담당한다.
- 기존 `show_end(..., relics)` 구조를 확장하되, 카드 안에 텍스트가 넘치지 않도록 리포트는 짧고 압축된 항목으로 시작한다.
- P4 통계는 먼저 메모리 상태로만 유지한다. 파일 저장은 제외한다.
- P5 피드백은 기존 `sparks`, `floating_text`, bullet shape, enemy HP bar를 우선 재사용한다.

### System-Wide Impact

- Interaction graph: 전투 이벤트가 `main.gd`의 통계 상태를 갱신하고, 종료 시 `_show_game_over_overlay` 또는 `_show_victory_overlay`가 `GameUI.show_end`로 전달한다.
- Error propagation: smoke/debug 커맨드는 실패 조건을 명확히 `quit(1)`로 반환해야 한다.
- State lifecycle risks: 런 통계는 `_reset_run`에서 반드시 초기화되어야 한다.
- API surface parity: 승리/패배 overlay, smoke 출력, debug 출력은 같은 요약 함수를 공유하는 편이 좋다.
- Integration test scenarios: 전체 smoke, 거미 유물 2라운드, 보스 폭발/관통, UI 캡처가 최소 세트다.

## SpecFlow Analysis

### User Flow Overview

1. P4 happy path: 플레이어가 한 판을 끝낸다 -> 종료 overlay에서 런 요약을 본다 -> 다음 수정점을 말할 수 있다.
2. P4 debug path: 개발자가 headless 커맨드를 실행한다 -> 특정 조합의 기대 결과가 출력된다 -> 실패 시 재현 조건이 남는다.
3. P5 happy path: 플레이어가 유물 위험을 고른다 -> 상점에서 대응 부품을 산다 -> 다음 전투에서 부품 효과를 시각적으로 확인한다.
4. P5 boss path: 플레이어가 폭발+관통 또는 방어 관통 빌드로 보스를 때린다 -> HP/피격 피드백으로 피해가 들어간다는 확신을 얻는다.

### Missing Elements & Gaps

- 리포트 수치 범위: P4에서 모든 전투 수치를 추적하면 범위가 커진다. 첫 버전은 선택/경제/결과 중심으로 제한하고, 적 처치 수와 보스 피해만 추가 후보로 둔다.
- 화면 밀도: 종료 overlay에 너무 많은 정보를 넣으면 읽기 어렵다. 요약 5줄 이내와 유물/부품 스트립 중심으로 시작한다.
- VFX 과밀: P5에서 폭발/관통/피격 텍스트가 동시에 많아질 수 있다. 큰 적과 직격/치명 조합부터 우선한다.
- 캡처 기준: UI는 headless만으로 검증하지 않고 실제 캡처를 남긴다.

### Critical Questions

1. P4 런 리포트를 화면에만 보여줄지, 나중에 파일로 저장할지.
   - 기본 가정: 내일은 화면/콘솔만 한다.
2. P5에서 사운드까지 포함할지.
   - 기본 가정: 내일은 시각 피드백만 한다.
3. 런 리포트에 피해량을 정확히 넣을지.
   - 기본 가정: 보스 피해와 적 처치 수 정도만 우선하고, 무기별 DPS는 나중으로 미룬다.

## Implementation Phases

### Phase 1: P4 Quest Setup

- `todos/014-complete-p4-run-report-and-debug-harness.md` 생성
- `todos/README.md`에 P4 메인 퀘스트 추가
- P4 acceptance criteria를 대시보드에 연결

Success:

- 내일 작업 시작 시 P4 카드만 보고 바로 착수할 수 있다.

### Phase 2: P4 Run Report Implementation

- `main.gd`에 런 통계 상태 추가
- 유물/부품/경제/리롤/결과 요약 함수 추가
- `GameUI.show_end`에 리포트 표시 영역 추가
- smoke/debug 출력에 요약 추가
- UI 캡처 커맨드로 종료 리포트 확인

Success:

- 한 판 종료 후 선택과 결과를 메모로 옮길 수 있다.

### Phase 3: P5 Quest Setup

- `todos/015-complete-p5-build-feedback-and-combat-readability.md` 생성
- `todos/README.md`에 P5 메인 퀘스트 추가
- P4 통계가 P5 검증에 어떻게 쓰이는지 명시

Success:

- P5가 “예쁘게 만들기”가 아니라 “선택 체감 검증”으로 읽힌다.

### Phase 4: P5 Feedback Implementation

- 관통/폭발/방어 관통/보스 피격 피드백 우선 구현
- 거미팩과 엘리트 좀비의 위험 신호 조정
- P4 리포트와 smoke/debug로 회귀 확인
- 전투 캡처로 피드백 가독성 확인

Success:

- 플레이어가 최소 1회 “이 부품 덕분에 이 유물을 감당했다”고 말할 수 있다.

## Dependencies & Risks

Dependencies:

- P3는 `main`에 반영되어 있어야 한다.
- 기존 Godot 실행 파일과 headless 검증 커맨드를 그대로 사용한다.
- P4가 먼저 완료되어야 P5 변경 체감을 기록하기 쉽다.

Risks:

- 리포트가 너무 길어져 종료 화면이 읽기 어려워질 수 있다.
- 피드백 이펙트가 많아져 전투 가독성이 오히려 나빠질 수 있다.
- 디버그 커맨드가 늘어나면서 `main.gd`가 더 커질 수 있다. P4 이후 필요하면 테스트 헬퍼 분리를 검토한다.

## Verification Plan

P4/P5 공통:

```bash
/Users/highfence/Dev/Sweep/engine/godot/bin/godot.macos.editor.arm64 --headless --path /Users/highfence/Documents/Bro-exile --quit
```

```bash
/Users/highfence/Dev/Sweep/engine/godot/bin/godot.macos.editor.arm64 --headless --path /Users/highfence/Documents/Bro-exile -- --smoke-playtest
```

P4 회귀:

```bash
/Users/highfence/Dev/Sweep/engine/godot/bin/godot.macos.editor.arm64 --headless --path /Users/highfence/Documents/Bro-exile -- --debug-spider-relic-wave2
```

```bash
/Users/highfence/Dev/Sweep/engine/godot/bin/godot.macos.editor.arm64 --headless --path /Users/highfence/Documents/Bro-exile -- --debug-boss-pierce-splash
```

UI/전투 캡처:

```bash
/Users/highfence/Dev/Sweep/engine/godot/bin/godot.macos.editor.arm64 --path /Users/highfence/Documents/Bro-exile -- --capture-ui
```

P4 완료 후 새 캡처 커맨드 후보:

```bash
/Users/highfence/Dev/Sweep/engine/godot/bin/godot.macos.editor.arm64 --path /Users/highfence/Documents/Bro-exile -- --capture-run-report-ui
```

P5 완료 후 새 캡처 커맨드 후보:

```bash
/Users/highfence/Dev/Sweep/engine/godot/bin/godot.macos.editor.arm64 --path /Users/highfence/Documents/Bro-exile -- --capture-combat-feedback
```

## Success Metrics

P4:

- 플레이테스트 한 판 후 30초 안에 선택 유물, 구매 부품, 사망/승리 원인을 말할 수 있다.
- smoke/debug 출력이 회귀 여부를 한 줄로 판단하게 해준다.

P5:

- 관통/폭발/방어 관통 중 최소 2개는 화면만 보고 구분된다.
- 보스에게 피해가 들어가는지 헷갈리지 않는다.
- 유물 위험과 대응 부품의 연결이 플레이 중 최소 1회 체감된다.

## Sources & References

- Origin brainstorm: `docs/brainstorms/2026-06-02-p3-relic-contract-loop-brainstorm.md`
  - 유물은 숨은 디버프가 되면 안 된다.
  - 유물 선택 후 상점에서 대응 부품을 사고 싶어져야 한다.
  - 같은 유물 중복은 위험 누적 감각을 만들어야 한다.
- Related brainstorm: `docs/brainstorms/2026-06-01-prototyping-quest-dashboard-brainstorm.md`
  - 퀘스트는 기능보다 검증 질문 중심으로 쪼갠다.
  - Markdown 대시보드를 기준 화면으로 둔다.
  - 플레이테스트 결과를 쌓아 두는 형식이 필요하다.
- Existing quest: `todos/008-ready-p2-run-report.md`
  - 종료 화면 요약과 smoke 출력 강화가 P4의 직접 기반이다.
- Existing quest: `todos/011-pending-p2-shop-and-reward-choice-pass.md`
  - 빌드 방향과 위험 대응 체감이 P5의 직접 기반이다.
- Institutional learning: `docs/solutions/ui-bugs/invisible-godot-ui-text-GodotPort-20260522.md`
  - UI 작업은 실제 캡처로 검증해야 한다.
- Main loop: `scripts/main.gd`
- UI layer: `scripts/ui/game_ui.gd`
