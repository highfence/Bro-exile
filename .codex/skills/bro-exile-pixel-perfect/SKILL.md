---
name: bro-exile-pixel-perfect
description: Bro-exile의 픽셀 단위 시각 검증, 64px preview, alpha bbox, sprite cell, Godot capture, pixel UI fallback, asset promotion gate를 확인할 때 사용한다.
---

# Bro-exile Pixel Perfect

## 목적

Bro-exile에서 에셋, UI, 애니메이션, 캡처 품질을 픽셀 단위로 검증한다. headless 성공만으로 완료 처리하지 않고, 작은 preview와 실제 Godot 렌더 캡처를 근거로 남긴다.

## 시작 절차

1. `docs/quality/2026-06-30-pixel-perfect-quality-gates.md`를 읽는다.
2. 작업이 에셋, UI, animation, capture, promotion 중 무엇인지 분류한다.
3. 에셋 작업이면 `.codex/skills/bro-exile-asset-workflow/SKILL.md`도 함께 적용한다.
4. 관련 todo의 acceptance criteria와 기존 report를 확인한다.
5. 최소 검증 명령을 실행하고, preview/capture/metadata 경로를 handoff에 남긴다.

## 필수 확인

- 48-64px preview에서 역할이 읽히는가.
- RGBA alpha bbox가 비어 있지 않은가.
- fixed cell, frame count, hframes/vframes가 의도와 맞는가.
- adjacent duplicate frame이 animation을 속이지 않는가.
- 실제 게임 배경 위에서 플레이어, 적, UI, 투사체가 구분되는가.
- UI 텍스트는 `--capture-ui` 결과에서 실제로 보이는가.

## 금지

- headless exit code 0만으로 visual QA를 통과 처리하지 않는다.
- preview 없이 실사용 에셋으로 promotion하지 않는다.
- 사용자 승인 없이 candidate를 production asset path에 덮어쓰지 않는다.
- font renderer가 실패하는 상황에서 UI 텍스트를 보인다고 가정하지 않는다.

## Handoff

다음을 남긴다.

- 실행한 명령.
- preview path.
- capture path.
- metadata path.
- gate 결과.
- 남은 리스크.
- 다음 owner lane.
