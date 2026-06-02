# Orebound Arena

P2 5라운드 아레나 전투/상점 강화 루프를 빠르게 플레이 테스트하기 위한 Godot 프로토타입입니다. Brotato식 기본 구조를 출발점으로 삼되, 자산과 명칭은 독자적으로 유지합니다.

## 실행

### Godot 프로토타입

Godot 4.3 이상에서 이 폴더를 열고 실행합니다. 메인 씬은 `res://scenes/main.tscn`입니다.

```bash
/Users/highfence/Dev/Sweep/engine/godot/bin/godot.macos.editor.arm64 --path /Users/highfence/Documents/Bro-exile
```

P2 worktree에서 실행할 때는 아래 경로를 사용합니다.

```bash
/Users/highfence/Dev/Sweep/engine/godot/bin/godot.macos.editor.arm64 --path /Users/highfence/Documents/Bro-exile/.worktrees/codex/p2-upgrade-shop-loop
```

### 브라우저 프로토타입

레거시 정적 프로토타입은 `index.html`을 브라우저에서 직접 열어 실행할 수 있습니다.

- `WASD` 또는 방향키: 이동
- 마우스: 조준 방향
- `Space`: 대시
- `P`: 일시 정지

## 현재 루프

- P2는 5라운드 전투 루프 위에 라운드 사이 상점 강화 루프를 붙인 버전입니다. 1-4라운드는 제한 시간 생존, 5라운드는 보스 좀비 처치가 목표입니다.
- 라운드 1: 기본 좀비. 적당한 속도로 플레이어에게 접근합니다.
- 라운드 2: 빠른 좀비. 기본 좀비와 색이 다르고 더 빠르게 압박합니다.
- 라운드 3: 거미떼. 체력이 낮지만 4-5마리씩 묶여 스폰됩니다.
- 라운드 4: 돌 던지는 좀비. 거리를 유지하며 원거리 투사체를 던집니다.
- 라운드 5: 방어력 높은 보스 좀비. 이전 몹 일부가 조연으로 누적되고, 보스를 처치하면 승리합니다.
- 라운드 1-4 종료 후에는 체력이 완전히 회복되고 상점 씬으로 이동합니다.
- 기본 공격은 드릴촉 발사기입니다. 상점에서는 광석으로 기존 드릴촉 무기에 부품을 붙이거나 이동/생존 아이템, 회복을 구매하고 리롤한 뒤 다음 라운드를 시작합니다.
- 상점은 다음 라운드의 새 위협에 대응하는 부품을 최소 1개 보장합니다. 빠른 좀비는 공격 속도, 거미떼는 관통/광역, 투척 좀비는 사거리/이동 속도, 보스는 방어 관통으로 대응합니다.
- P2에서는 레벨업 보상과 계약 카드는 아직 검증하지 않습니다. 성장 루프의 주인공은 상점입니다.

## Godot 포트

- `project.godot`는 Godot 프로젝트와 입력 액션을 정의합니다.
- `scenes/main.tscn`은 메인 씬입니다.
- `scripts/main.gd`는 현재 단일 파일 게임 루프입니다.
- 최종 아트 전까지 단순 도형 드로잉으로 전투와 UI를 검증합니다.
- P2 부품 아이콘은 `assets/sprites/items/p2_parts/`에 있습니다. 생성 스크립트는 `scripts/tools/generate_p2_part_icons.py`입니다.
- P2 worktree에는 `main`의 P1 몬스터 런타임 비주얼 커밋도 반영되어 있습니다.

## 검증 커맨드

```bash
/Users/highfence/Dev/Sweep/engine/godot/bin/godot.macos.editor.arm64 --headless --path /Users/highfence/Documents/Bro-exile --quit
/Users/highfence/Dev/Sweep/engine/godot/bin/godot.macos.editor.arm64 --headless --path /Users/highfence/Documents/Bro-exile -- --smoke-playtest
/Users/highfence/Dev/Sweep/engine/godot/bin/godot.macos.editor.arm64 --path /Users/highfence/Documents/Bro-exile -- --capture-choice-ui
/Users/highfence/Dev/Sweep/engine/godot/bin/godot.macos.editor.arm64 --path /Users/highfence/Documents/Bro-exile -- --capture-shop-ui
```

P2 worktree 검증:

```bash
/Users/highfence/Dev/Sweep/engine/godot/bin/godot.macos.editor.arm64 --headless --path /Users/highfence/Documents/Bro-exile/.worktrees/codex/p2-upgrade-shop-loop --quit
/Users/highfence/Dev/Sweep/engine/godot/bin/godot.macos.editor.arm64 --headless --path /Users/highfence/Documents/Bro-exile/.worktrees/codex/p2-upgrade-shop-loop -- --smoke-playtest
```

## 다음 확장 훅

- 채굴 가능한 타일과 광맥.
- 전투 성능과 채굴 성능을 맞바꾸는 도구형 무기.
- 바이옴 레이어별 적/자원 테이블.
- 패시브 트리 또는 아틀라스식 런 변형.
- 아이템 접사, 희귀도, 소켓형 지원 보석.
