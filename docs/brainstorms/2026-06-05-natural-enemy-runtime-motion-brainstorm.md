---
date: 2026-06-05
topic: natural-enemy-runtime-motion
---

# Natural Enemy Runtime Motion

## What We're Building

single-image enemy asset의 runtime motion을 더 자연스럽게 만든다. 현재 fast/boss 후보 이미지는 마음에 들지만, 움직임이 “달랑달랑 흔들리는 이미지”처럼 보인다. 목표는 적을 스프라이트 시트로 다시 만들지 않고도, 각 적의 역할에 맞는 움직임으로 보이게 하는 것이다.

자연스러움의 기준은 실제 해부학적 보행이 아니라 64px 게임 화면에서의 설득력이다. fast zombie는 몸이 앞으로 쏠리며 추격하는 느낌, boss zombie는 무겁게 딛고 오는 느낌, 기본 좀비는 절뚝이며 다가오는 느낌, shield zombie는 버티며 압박하는 느낌이 나야 한다.

## Repository Research Summary

- `scripts/animation/zombie_rig.gd`와 `scripts/main.gd`의 `_draw_single_image_enemy_sprite()`는 모두 단일 이미지에 `sin`, `cos`, `abs(sin)` 기반의 lateral, hop, rotation, squash를 적용한다.
- `scripts/main.gd`는 enemy 타입별 수치를 다르게 주지만, 움직임 공식 자체는 같다. 그래서 fast/boss도 역할 차이보다 같은 리듬의 흔들림이 먼저 보인다.
- 플레이어는 장갑/부츠 파츠가 따로 있어 접지감과 보행 힌트를 만들 수 있다. 반면 enemy는 단일 full-frame PNG라 발이 실제로 교차하지 않는다.
- 기존 하네스는 loop, duplicate, alpha 안정성은 확인하지만, 접지감, 무게감, 역할별 리듬 차이는 검증하지 않는다.
- 현재 에셋 원칙은 일반 적을 single-image runtime transform으로 운용하는 방향이다. 따라서 첫 개선은 새 스프라이트 시트 생성보다 motion profile 개선이 맞다.

## Approaches Considered

### Approach A: Current Formula Tuning

현재 `_draw_single_image_enemy_sprite()`와 `zombie_rig.gd`의 수치만 줄인다. hop과 lateral 이동을 낮추고 rotation을 완화하면 바로 덜 달랑거린다.

장점은 가장 빠르고 위험이 낮다는 점이다. 단점은 모든 적이 여전히 같은 종류의 흔들림을 공유해서, fast/boss/normal의 리듬 차이가 제한된다.

### Approach B: Role-Specific Motion Profiles

추천 접근이다. 단일 이미지 정책은 유지하되, enemy 타입별로 서로 다른 motion profile을 둔다. 예를 들어 `shamble`, `sprint`, `heavy`, `brace`가 각기 다른 phase, vertical envelope, lean, squash, shadow timing을 가진다.

fast는 위아래 hop보다 전진 lean과 낮은 빠른 보폭감을 강조한다. boss는 lateral 이동을 거의 줄이고, 낮은 주기의 무거운 squash와 shadow compression으로 접지감을 만든다. shield는 앞으로 밀고 오는 brace 느낌을 살리고, 기본 좀비는 약한 절뚝임으로 둔다.

장점은 에셋을 더 만들지 않고도 역할별 움직임을 분리할 수 있다는 점이다. 단점은 motion profile contract와 하네스 preview 옵션이 필요해져, 단순 수치 튜닝보다는 설계가 조금 늘어난다.

### Approach C: Minimal Additive Contact Cues

단일 body 이미지는 유지하되, 그림자, 작은 먼지, impact pulse, ground contact marker 같은 아주 작은 보조 cue를 붙인다. 특히 boss의 stomp와 fast의 발 디딤 타이밍을 보강할 수 있다.

장점은 접지감이 좋아진다는 점이다. 단점은 시각 효과가 과하면 작은 화면에서 노이즈가 되고, 일반 적마다 효과가 많아지면 구현과 밸런싱이 커진다. Approach B 이후 부족한 적에게만 제한적으로 쓰는 편이 좋다.

## Recommended Direction

Approach B를 기본으로 하고, Approach C를 필요한 타입에만 얹는다. 지금 단계에서 full sprite sheet를 생성하거나 적 파츠를 분해하는 것은 과하다. fast/boss 후보는 단일 이미지로 이미 충분히 읽히므로, 먼저 움직임의 해석만 바꾸는 것이 가장 작고 효과적인 개선이다.

핵심은 “움직임 수치”가 아니라 “역할별 motion vocabulary”다. fast는 빠른 발놀림처럼 보여야 하고, boss는 느리고 무거워야 하며, shield는 방어 자세가 유지되어야 한다. 같은 bob 공식에 수치만 다르게 넣으면 이 차이가 약해진다.

## Key Decisions

- single-image enemy asset 방향은 유지한다.
- enemy 움직임은 타입별 motion profile로 분리한다.
- 하네스 preview는 `move_left/right`만이 아니라 profile 이름과 의도를 메타데이터에 남겨야 한다.
- 자연스러움 검증은 alpha/loop 검증만으로 충분하지 않다. 64px preview와 stage capture에서 접지감, 역할 구분, 과한 흔들림 여부를 봐야 한다.
- fast/boss 승격 전에는 새 asset path 교체와 motion profile 개선을 함께 확인해야 한다.

## Success Criteria

- fast zombie는 64px에서 “통통 튀는 이미지”가 아니라 낮고 빠르게 추격하는 적으로 보인다.
- boss zombie는 좌우로 달랑거리지 않고, 느리고 묵직하게 몸을 싣는 느낌이 난다.
- 기본 좀비, fast, shield, boss의 runtime preview가 한눈에 다른 리듬으로 보인다.
- stage1 실제 배경 위에서 shadow와 body가 따로 놀지 않는다.
- 기존 single-image enemy pipeline과 후보 생성 하네스는 유지된다.

## Open Questions

없음. 세부 수치와 profile 이름은 계획/구현 단계에서 정하면 된다.

## Next Steps

→ `/workflows-plan`으로 motion profile contract, harness preview 옵션, stage capture 검증 절차를 계획한다.
