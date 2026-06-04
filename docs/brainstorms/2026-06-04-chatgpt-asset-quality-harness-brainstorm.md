---
date: 2026-06-04
topic: chatgpt-asset-quality-harness
kind: brainstorm
status: draft
---

# ChatGPT 에셋 품질 하네스 브레인스토밍

## What We're Building

Bro-exile의 에셋 제작을 매일 자동으로 보조하는 하네스를 만든다. 목표는 에이전트가 `main`의 최신 게임 상태를 보고 부족한 플레이어, 적, 무기, 아이템 에셋 후보를 생성하되, `main`에 직접 덮어쓰지 않고 검증된 후보 브랜치와 리뷰 자료를 만드는 것이다.

가장 중요한 문제는 “ChatGPT가 한 번에 균질한 게임 에셋을 뽑을 수 있는가”가 아니다. 실제 목표는 **균질하지 않은 생성 결과를 품질 게이트, 후처리, 게임 내 캡처, 사람의 선택 단계로 좁혀서 안정적인 후보만 남기는 것**이다.

OpenAI 공식 문서 기준으로 이미지 생성은 텍스트 프롬프트 생성과 기존 이미지 편집을 모두 지원하며, Responses API는 이미지 입력과 출력이 이어지는 multi-turn 흐름에 적합하다. 또한 Responses API의 이미지 생성 결과에는 `revised_prompt`를 확인할 수 있으므로, 자동화 하네스는 원본 프롬프트뿐 아니라 모델이 확장한 프롬프트도 기록해야 한다.

참고:

- https://developers.openai.com/api/docs/guides/image-generation
- https://platform.openai.com/docs/api-reference/images
- https://help.openai.com/en/articles/11084440-images-in-chatgpt

## Repository Context

이미 저장소에는 다음 기반이 있다.

- `docs/art/asset-generation-principles.md`: Brotato식 구조를 참고하되 직접 복제하지 않는 에셋 원칙.
- `docs/art/player-asset-harness.md`: 플레이어 파츠 리그를 Godot에서 bake하고 64px 프리뷰와 metadata를 만드는 검증 흐름.
- `assets/sprites/characters/p1_monsters_runtime_v1/metadata.json`: 일반 몬스터는 단일 이미지와 런타임 변형으로 움직이는 방향.
- `scenes/tools/player_asset_harness.tscn`, `scenes/tools/zombie_asset_harness.tscn`: 에셋이 실제 게임용 시트/프리뷰로 bake되는지 검증하는 초기 하네스.

따라서 새 하네스는 완전히 새로운 제작기가 아니라, 기존 원칙 위에 **자동 후보 생성, 정규화, 품질 검수, 리뷰 리포트**를 얹는 형태가 맞다.

## Approaches Considered

### Approach A: Prompt-Only Daily Generator

매일 새 프롬프트로 필요한 에셋을 생성하고 폴더에 저장한다. 가장 빠르지만 품질 편차와 스타일 붕괴를 잡을 장치가 거의 없다.

장점은 단순하고 비용이 낮다는 점이다. 단점은 같은 프롬프트라도 모델 업데이트, 프롬프트 해석, 구도 변화에 따라 결과가 크게 흔들릴 수 있다는 점이다. 이 방식은 스케치 수집에는 좋지만 실제 게임 에셋 교체 자동화에는 약하다.

### Approach B: Candidate Factory + Quality Gates

매일 필요한 에셋마다 3-6개 후보를 만들고, 고정된 후처리와 검증 게이트를 통과한 것만 리뷰 후보로 남긴다. 후보는 바로 `main`에 들어가지 않고 캡처 이미지, 64px 프리뷰, metadata와 함께 브랜치 또는 리포트로 제안된다.

장점은 품질 편차를 “생성 단계”가 아니라 “선별 단계”에서 다룰 수 있다는 점이다. 단점은 하네스가 더 필요하고 생성 비용이 늘어난다는 점이다. 그래도 우리 상황에서는 가장 실용적인 기본안이다.

### Approach C: Locked Style Anchor + Iterative Editing

처음부터 매번 새 이미지를 만들지 않고, 승인된 기준 이미지와 style anchor를 참조 이미지로 넣어 편집 또는 변주를 요청한다. 플레이어, 좀비, 무기군처럼 장기적으로 유지할 얼굴이 있는 에셋에 좋다.

장점은 스타일 안정성이 가장 높다는 점이다. 단점은 기준 이미지가 약하면 계속 같은 약점을 복제하고, 새 카테고리 탐색에는 답답할 수 있다는 점이다. Approach B 안에 “승인된 에셋은 항상 참조로 넣는다”는 규칙으로 흡수하는 것이 좋다.

## Recommendation

추천은 **Approach B를 기본으로 하고, 승인된 에셋이 있는 경우 Approach C를 부분 적용**하는 것이다.

즉 하네스는 “이미지 생성기”가 아니라 다음 역할을 가진다.

1. **Asset Gap Detector**
   - `main`의 코드, 씬, todo, 문서를 보고 필요한 에셋 목록을 만든다.
   - `assets/asset_manifest.json` 같은 매니페스트와 비교해 `missing`, `placeholder`, `needs_refresh` 항목만 대상으로 삼는다.

2. **Prompt Pack Builder**
   - 에셋 타입별 프롬프트 템플릿을 사용한다.
   - 스타일 원칙, 금지 규칙, 캔버스, 투명 배경, 64px 가독성, 광산 정체성을 항상 포함한다.
   - 승인된 에셋이 있으면 참조 이미지로 넣고, 매 요청의 원본 프롬프트와 `revised_prompt`를 저장한다.

3. **Candidate Generator**
   - 한 에셋당 후보 3-6개를 만든다.
   - 플레이어/중요 캐릭터는 reference 기반 edit 또는 multi-turn refinement를 우선한다.
   - 일반 적/아이템은 단일 이미지 생성 후 runtime harness로 검증한다.

4. **Normalizer**
   - RGBA 투명 PNG 확인.
   - `256x256` 셀 정렬.
   - 기준선, pivot, alpha bbox, 여백, 최대 점유 크기 통일.
   - 필요 시 64px 프리뷰와 게임용 bake 시트를 만든다.

5. **Quality Gates**
   - 하드 게이트: 빈 이미지, 배경 잔여물, 텍스트/워터마크, 잘못된 크기, alpha 오류, 너무 작은 실루엣 탈락.
   - 스타일 게이트: 팔레트 과다 이탈, 플레이어와 색이 너무 겹침, Brotato 원본과 과하게 유사함, 64px에서 역할이 안 읽힘.
   - 게임 게이트: Godot 캡처에서 실제 배경 위 가독성 확인, 피격/이동/스케일 변형 시 깨짐 확인.

6. **Review Report**
   - 후보 grid, 64px preview, Godot scene capture, metadata, 탈락 사유를 한 번에 보여준다.
   - 자동화는 `accepted` 에셋을 직접 교체하지 않는다.
   - 사람이 선택하면 그때 실사용 에셋으로 승격한다.

## Key Decisions

- 매일 1회, 새벽 1시 실행을 기본 자동화 주기로 둔다.
- 자동화는 `main`에 직접 push하지 않는다. 후보 브랜치, 리포트, 캡처를 만든다.
- 균질한 품질은 프롬프트보다 검증 하네스에서 만든다.
- 일반 적은 단일 이미지 + runtime transform을 기본으로 한다.
- 플레이어와 장기 핵심 캐릭터는 승인된 style anchor를 참조 이미지로 사용한다.
- 모든 결과는 prompt, revised prompt, source refs, model/action, output path, verification metadata를 남긴다.

## Quality Bar

첫 버전의 품질 기준은 다음 정도면 충분하다.

- 64px에서 역할이 읽힌다.
- 배경이 투명하고 캔버스 기준선이 맞는다.
- 게임 배경 위에서 플레이어, 적, 픽업이 구분된다.
- 이미 승인된 에셋과 큰 스타일 충돌이 없다.
- 원본 레퍼런스를 직접 복제하지 않는다.
- 자동화 결과는 “바로 병합”이 아니라 “리뷰 가능한 후보”다.

## Rejected Ideas

- 완전 자동으로 `main` 에셋을 교체한다: 취향 판단과 아트 디렉션 리스크가 너무 크다.
- 매번 완성 스프라이트 시트를 생성한다: 프레임 반복, 포즈 붕괴, 정체성 흔들림이 잦다.
- prompt-only로 품질을 해결한다: 모델 출력은 본질적으로 변동성이 있으므로, 후처리와 검증 없이는 균질성을 만들기 어렵다.

## Resolved Questions

- 자동화 주기: 매일 1회, 새벽 1시.
- 첫 자동화 범위: 후보 생성과 리뷰 자료 작성까지. 직접 `main` 교체는 하지 않는다.
- 좀비/일반 적 방향: 단일 이미지 + Godot runtime transform 우선.

## Open Questions

없음. 다음 단계는 이 브레인스토밍을 바탕으로 `/workflows-plan`에서 매니페스트, 후보 생성, 검증, 리포트, cron automation 구성을 쪼개는 것이다.

## Next Steps

→ `/workflows:plan`으로 구현 계획을 만든다.
