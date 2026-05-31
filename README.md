# Orebound Arena

20라운드 아레나 생존 루프를 빠르게 플레이 테스트하기 위한 Godot 프로토타입입니다. Brotato식 기본 구조를 출발점으로 삼되, 자산과 명칭은 독자적으로 유지합니다.

## 실행

### Godot 프로토타입

Godot 4.3 이상에서 이 폴더를 열고 실행합니다. 메인 씬은 `res://scenes/main.tscn`입니다.

```bash
/Users/highfence/Dev/Sweep/engine/godot/bin/godot.macos.editor.arm64 --path /Users/highfence/Documents/Bro-exile
```

### 브라우저 프로토타입

레거시 정적 프로토타입은 `index.html`을 브라우저에서 직접 열어 실행할 수 있습니다.

- `WASD` 또는 방향키: 이동
- 마우스: 조준 방향
- `Space`: 대시
- `P`: 일시 정지

## 현재 루프

- 20라운드 제한 시간 생존. 시간이 끝나면 즉시 막간 상점으로 넘어가고 20라운드 종료 시 승리합니다.
- 무기는 자동으로 가까운 적을 조준하며, 최대 6슬롯까지 보유하고 같은 무기를 구매하면 4단계까지 강화됩니다.
- 투사체, 관통탄, 전류, 근접 베기, 폭발탄 무기 타입이 있습니다.
- 적은 XP와 광석을 떨어뜨리고, 레벨업 시 3개 보상 중 하나를 고릅니다.
- 라운드 사이에는 광석으로 무기, 회복, 패시브 아이템을 여러 개 구매하거나 재고를 새로고침한 뒤 다음 라운드를 시작합니다.

## Godot 포트

- `project.godot`는 Godot 프로젝트와 입력 액션을 정의합니다.
- `scenes/main.tscn`은 메인 씬입니다.
- `scripts/main.gd`는 현재 단일 파일 게임 루프입니다.
- 최종 아트 전까지 단순 도형 드로잉으로 전투와 UI를 검증합니다.

## 검증 커맨드

```bash
/Users/highfence/Dev/Sweep/engine/godot/bin/godot.macos.editor.arm64 --headless --path /Users/highfence/Documents/Bro-exile --quit
/Users/highfence/Dev/Sweep/engine/godot/bin/godot.macos.editor.arm64 --headless --path /Users/highfence/Documents/Bro-exile -- --smoke-playtest
/Users/highfence/Dev/Sweep/engine/godot/bin/godot.macos.editor.arm64 --path /Users/highfence/Documents/Bro-exile -- --capture-choice-ui
/Users/highfence/Dev/Sweep/engine/godot/bin/godot.macos.editor.arm64 --path /Users/highfence/Documents/Bro-exile -- --capture-shop-ui
```

## 다음 확장 훅

- 채굴 가능한 타일과 광맥.
- 전투 성능과 채굴 성능을 맞바꾸는 도구형 무기.
- 바이옴 레이어별 적/자원 테이블.
- 패시브 트리 또는 아틀라스식 런 변형.
- 아이템 접사, 희귀도, 소켓형 지원 보석.
