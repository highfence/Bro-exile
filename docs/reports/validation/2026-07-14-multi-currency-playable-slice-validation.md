---
date: 2026-07-14
topic: multi-currency-playable-slice
kind: validation
status: passed-awaiting-product-owner
---

# 다중 화폐 playable slice 검증

## 판정

**passed**. `ore`, `catalyst`, `forge_core`의 source, pickup, typed wallet, 지정 sink, HUD·상점·종료 report가 같은 runtime에서 닫히며 기존 체크포인트와 스타터 무기 세 경로의 회귀도 통과했다.

자동·시각 gate는 통과했지만 slice 완료는 아니다. Product Owner가 같은 플레이어로 두 런을 이어서 플레이하고, 첫 런의 적→화폐 가설이 두 번째 런의 목표 파밍과 sink 사용 증가로 이어지는지 확인해야 한다.

## 구현 계약 검증

- fresh wallet은 세 ID를 `balance/acquired/spent = 0`으로 만들고 retry에서 초기화된다.
- 모든 일반 enemy family는 하나의 primary currency를 가지며 최종 라운드 spend currency drop은 비활성화된다.
- part/item은 광석, reroll은 촉매, 스타터 무기 단련은 강화핵만 소비한다.
- 단련은 무기별 고정 recipe를 rank마다 한 번 적용하고 III에서 멈춘다. 네일건의 cooldown과 range는 단련으로 바뀌지 않는다.
- 가격은 `{currency_id, amount: int}`만 허용한다. 소수·음수·미등록 화폐와 숫자형 유료 fallback은 거부된다.
- UI에서 전달된 option은 stable ID와 generation으로 active option을 다시 찾고, canonical option의 가격·효과만 적용한다.
- `acquired - spent == balance`를 정수 ledger로 검증하고 unknown pickup과 사망 시 미수거 pickup은 획득으로 계산하지 않는다.

## 자동 검증

- Godot headless load: exit 0.
- `demo_validation_harness`: `DEMO_RULE_HARNESS_PASS`.
  - 대표 고정 광석 비중 `0.25`.
  - 첫 상점 예산 `16`.
  - 목표 catalyst discovery proxy `2 → 6`, 무관 ore fixture 유지.
- `--debug-u4-currency-contract`: `failures=0`.
- full smoke:
  - 곡괭이: victory, 광석 `34`, 라운드 고정 `12`, 구매 2회, 단련 I.
  - 네일건: victory, 광석 `56`, 라운드 고정 `12`, 구매 3회, 단련 I.
  - 랜턴: victory, 광석 `61`, 라운드 고정 `12`, 구매 3회, 단련 I.
- checkpoint smoke: safe, risk, shop, elite 모두 PASS.
- `DEBUG_DEMO_RULE_SEAMS`, U3 checkpoint/balance, P7 reward/rarity/relic/boss/pause/legendary, P8 weapon route 모두 exit 0 또는 `failures=0`.
- pipeline validator test 10개와 현재 queue validation 통과.
- `git diff --check` 통과.

macOS headless 실행의 system CA certificate 경고는 모든 명령에서 확인됐지만 exit code와 pass marker에는 영향을 주지 않았다.

## 시각 검증

1280×720 실제 Godot 렌더를 열어 다음을 확인했다.

- `/private/tmp/orebound-godot-shop-ui.png`: 광석 구매, 촉매 reroll, 강화핵 단련, 무료 exit가 한 화면에 보이고 3열 카드가 잘리지 않는다.
- `/private/tmp/orebound-godot-combat-feedback.png`: diamond, ring, hex pickup과 HUD의 광/촉/핵 잔액이 구분된다.
- `/private/tmp/orebound-godot-run-report-ui.png`: 승리 report의 세 ledger, 단련 rank, 라운드 고정 광석이 읽힌다.
- `/private/tmp/orebound-godot-p7-game-over-summary.png`: 패배 report의 세 ledger와 보스 결과가 패널 안에 들어온다.
- `/private/tmp/orebound-godot-checkpoint-hud.png`, `/private/tmp/orebound-godot-checkpoint-ui.png`: 기존 위험 경로 HUD와 선택 UI가 wallet HUD와 충돌하지 않는다.

첫 패배 capture 한 번은 패널 스타일이 보이지 않는 일시적 렌더 결과가 나왔고 같은 명령을 새 HOME으로 재실행했을 때 정상 렌더가 확인됐다. 기존 Godot UI 학습대로 headless 성공만 사용하지 않고 최종 PNG 픽셀을 판정 근거로 삼았다.

## 코드 리뷰와 남은 위험

프로젝트 `AGENTS.md`의 순차 main-thread 규칙에 따라 correctness, testing, maintainability, project standards, adversarial 관점을 별도 pass로 적용했다.

- 수정 완료: 소수 가격의 정수 절삭, 양수 scalar 가격의 광석 fallback, 동일 stable ID 변조 option, 실제 런 고정 광석 과점.
- 수정 완료: fractional ledger가 정수 invariant를 통과하던 검증 구멍.
- blocking code finding은 남지 않았다.
- 구조적 부채: `scripts/main.gd`가 여전히 큰 orchestration 파일이다. 이번 slice의 registry와 pure economy 규칙은 별도 파일로 분리했지만 다음 대형 시스템을 추가하기 전 runtime controller 분리를 검토하는 편이 안전하다.
- 제품 gate: 자동 플레이는 discovery 감정과 “다음 런을 한 번 더” 의도를 증명하지 못한다.

## Product Owner 플레이 렌즈

1. 첫 런은 평소처럼 플레이하고, 어떤 적이 어떤 화폐를 준다고 느꼈는지 한 줄로 적는다.
2. 두 번째 런은 원하는 sink 하나를 먼저 정한다: 상점 구매, reroll, 단련.
3. 그 화폐를 줄 것 같은 적과 위험 경로를 능동적으로 고른다.
4. 첫 런보다 목표 화폐 획득과 대응 sink 사용이 실제로 늘었는지 report로 비교한다.
5. 종료 직후 “다른 경로로 한 번 더”가 생기는지 keep / adjust / cut으로 판정한다.

## 다음 상태

- owner lane: Producer / Product Owner.
- user gate: awaiting-user-approval.
- 승인 전에는 020을 `complete`로 닫거나 021을 활성화하지 않는다.
