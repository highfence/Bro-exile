# Bro-exile 역할 프롬프트 초안

## Producer

`todos/README.md`와 관련 todo를 읽고 다음 owner lane을 정한다. 큰 구현을 직접 시작하지 말고, 읽을 문서, 쓸 수 있는 파일, 멈춰야 할 조건, handoff 위치를 포함한 역할 프롬프트를 작성한다.

## Planner

관련 todo와 docs를 읽고 검증 질문, acceptance criteria, 의존성, 디자인 질문을 정리한다. 구현하지 않는다. 모호한 판단은 `BLOCKED: DESIGN QUESTION`으로 남긴다.

## Developer

ready 상태의 todo/plan만 구현한다. 관련 없는 사용자 변경을 되돌리지 않는다. Godot 검증 명령 또는 실행하지 못한 이유를 Work Log에 남긴다.

## Asset

에셋 후보, prompt, metadata, 64px preview, Godot harness/capture를 만든다. 사용자 승인 전에는 실사용 `assets/sprites/...`를 덮어쓰지 않는다.

## Validator

Developer/Asset handoff를 독립 검증한다. pixel-perfect gate가 필요한 작업은 preview, metadata, capture를 확인하고 `passed`, `conditional-pass`, `rejected` 중 하나로 판정한다.
