---
date: 2026-07-12
topic: u3-product-owner-balance-feedback
kind: playtest
status: implementation-ready
---

# U3 Product Owner 밸런스 피드백

## 판정

- Product Owner gate: `changes-requested`
- 체크포인트 구조와 나머지 기능은 이번 패스에서 유지한다.
- 수정 목표는 공격의 한 발 감각, 스타터 무기별 보상 정합성, R5/R10 보스 압박이다.

## 수치 계약

| 항목 | 현재 | 목표 | 의도 |
| --- | ---: | ---: | --- |
| 곡괭이 cooldown / damage | 0.82 / 28 | 1.05 / 35 | 더 느리고 묵직한 근접 타격 |
| 네일건 cooldown / damage / range | 0.46 / 12 / 520 | 0.62 / 15 / 360 | 연사와 화면 장악을 줄이고 한 발 피해 보강 |
| 랜턴 cooldown / damage | 1.05 / 13.5 | 1.35 / 17 | 펄스 간격을 읽을 수 있게 하고 타격감 보강 |
| R5 중간보스 HP / speed | 360 / 44 | 680 / 70 | 순식간에 삭제되지 않고 추격 압박 형성 |
| R10 보스 HP / speed | 860 / 44 | 1,550 / 74 | 빌드 검증 시간이 생기고 수동 회피 강제 |
| 보스 독 장판 반경 | 94 | 128 | 장판이 동선 선택을 실제로 제한 |

스타터 무기의 기본 DPS는 크게 올리지 않는다. 느린 cadence와 높은 hit damage를 동시에 적용해 공격을 읽기 쉽게 만들고, 체감 난이도는 낮아지지 않도록 한다. 일반 적 수와 spawn curve는 이번 패스에서 유지해 원인 변수를 제한한다.

## 보상 정합성 계약

- `range` 보정은 제거하지 않고 현재 선택 무기에 맞게 이름과 설명을 바꾼다.
- 곡괭이: 사거리가 아니라 `휘두름 범위/곡괭이 자루`로 설명한다.
- 네일건: `못 비행 거리/압축 레일`로 설명한다.
- 랜턴: `빛 펄스 반경/확산 렌즈`로 설명한다.
- damage/cooldown 보정도 가능하면 같은 무기별 용어를 사용한다.
- 곡괭이·랜턴 카드에 화살촉, 드릴촉, 투사체 사거리 표현이 나오면 실패다.

## 구현 경계

- 유지: R3/R5/R7 checkpoint route, risk/reward 수치, 상점/엘리트 구조, 일반 적 roster와 spawn curve.
- 변경: starter `weapon_catalog`, stat reward decoration/selection seam, boss base stats, boss pool radius.
- 새 무기, 새 적, 새 패턴, 새 에셋은 추가하지 않는다.

## 검증 시나리오

1. 전용 debug에서 세 starter의 cooldown/damage/range가 목표 수치와 일치한다.
2. 곡괭이·네일건·랜턴 각각의 stat option에서 `range` 카드 문구가 무기 용어와 일치한다.
3. R5/R10 boss 생성 결과의 HP/speed와 pool radius가 목표 수치와 일치한다.
4. 기존 U2/U3/P7/P8 debug와 pipeline validator가 회귀 없이 통과한다.
5. 실제 Godot reward overlay capture에서 무기별 한글 문구가 보이고 카드가 겹치지 않는다.
6. Product Owner가 다시 플레이해 공격이 더 묵직하고 보스/장판이 충분히 위협적인지 최종 판단한다.

## 남은 취향 게이트

- 수치 자동 검증은 감각 승인을 대체하지 않는다.
- 일반 구간이 여전히 쉽다면 다음 조정은 적 수 또는 spawn interval 중 하나만 골라 별도 패스로 진행한다.
