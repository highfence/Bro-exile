---
title: "feat: 자동 에셋 품질 하네스"
type: feat
status: active
date: 2026-06-04
origin: docs/brainstorms/2026-06-04-chatgpt-asset-quality-harness-brainstorm.md
---

# feat: 자동 에셋 품질 하네스

## Overview

Bro-exile의 에셋 제작을 매일 자동으로 보조하는 후보 생성/검증 하네스를 만든다. 이 기능의 목표는 에이전트가 매일 새벽 1시에 최신 `main`을 보고, 현재 게임 코드와 매니페스트에서 필요한 에셋을 찾아 후보를 생성하고, 정규화와 Godot 캡처 검증을 거쳐 리뷰 가능한 리포트를 남기는 것이다.

핵심 방향은 **자동 교체가 아니라 자동 후보 생산**이다. `main`에 직접 덮어쓰거나 바로 push하지 않고, 후보 이미지, 64px 프리뷰, 실제 게임 캡처, 검증 메타데이터, 원본 프롬프트와 `revised_prompt`를 묶은 리뷰 자료를 만든다. 사람이 승인한 후보만 이후 실사용 에셋으로 승격한다. (see brainstorm: `docs/brainstorms/2026-06-04-chatgpt-asset-quality-harness-brainstorm.md`)

## Origin Decisions

- 매일 1회, 새벽 1시 실행을 기본 자동화 주기로 둔다. (see brainstorm: `docs/brainstorms/2026-06-04-chatgpt-asset-quality-harness-brainstorm.md`)
- 자동화는 `main`에 직접 push하지 않는다. 후보 브랜치, 리포트, 캡처를 만든다. (see brainstorm)
- 균질한 품질은 프롬프트 하나로 보장하지 않고, 후보 생성 수량, 후처리, 품질 게이트, 실제 Godot 캡처, 사람 리뷰로 만든다. (see brainstorm)
- Approach B, 즉 `Candidate Factory + Quality Gates`를 기본으로 한다. 승인된 style anchor가 있는 핵심 캐릭터는 Approach C의 reference 기반 edit/multi-turn refinement를 부분 적용한다. (see brainstorm)
- 일반 적은 단일 이미지와 Godot runtime transform을 기본으로 한다. (see brainstorm)
- 플레이어와 장기 핵심 캐릭터는 승인된 style anchor를 참조 이미지로 사용한다. (see brainstorm)
- 모든 결과는 `prompt`, `revised_prompt`, source refs, model/action, output path, verification metadata를 남긴다. (see brainstorm)
- 완전 자동으로 `main` 에셋을 교체하는 방식, 매번 완성 스프라이트 시트를 생성하는 방식, prompt-only로 품질을 해결하는 방식은 제외한다. (see brainstorm)
- 브레인스토밍의 open question은 없다. 이 계획의 미해결 항목은 제품 방향이 아니라 구현 시 확인할 운영 설정, 예를 들어 API 키와 일일 생성 예산이다. (see brainstorm)

## Local Research Findings

### Repository Research Summary

- `docs/art/asset-generation-principles.md`는 Brotato 리소스를 구조와 운영 방식으로만 참고하고, 형태/캐릭터/아이콘/실루엣/장식은 직접 복제하지 않는다고 정의한다.
- 같은 문서는 에셋을 `256x256` 셀, RGBA 투명 PNG, 48-64px 가독성, 후처리/프리뷰/중복 검사 기준으로 관리하라고 정한다.
- 플레이어는 파츠 기반 리그를 우선한다. 본체, 헬멧, 램프, 벨트, 가방은 core body에 남기고 장갑/부츠를 별도 파츠로 움직이는 현재 방향과 맞는다.
- `docs/art/player-asset-harness.md`는 Godot에서 `idle_left`, `idle_right`, `move_left`, `move_right` 프레임과 256px 시트, 64px 프리뷰, `metadata.json`을 만드는 검증 흐름을 이미 문서화한다.
- `scripts/tools/player_asset_harness.gd`는 실제로 투명 `SubViewport`에서 플레이어 리그를 캡처하고, alpha bbox, cell scale, loop match, adjacent duplicate pair를 메타데이터로 기록한다.
- `scripts/tools/zombie_asset_harness.gd`는 단일 좀비 이미지를 runtime motion으로 움직여 `idle`/`move` 양방향 시트와 프리뷰를 만든다.
- `assets/sprites/characters/p1_monsters_runtime_v1/metadata.json`은 일반 몬스터가 단일 full-frame PNG와 scale/rotation/bob/flip/shadow 기반 runtime animation으로 움직인다는 원칙을 이미 갖고 있다.
- `scripts/main.gd`는 player part texture, zombie/enemy texture, `--capture-stage1`, `--capture-monster-roster` 같은 실제 게임 캡처 커맨드를 소유한다. 자동화 리포트는 이 캡처 패턴을 재사용해야 한다.
- `docs/solutions/ui-bugs/invisible-godot-ui-text-GodotPort-20260522.md`는 headless 성공만으로는 충분하지 않고 실제 렌더 캡처를 봐야 한다는 institutional learning을 남긴다. 에셋 자동화도 파일 검증만으로 통과시키지 않고 실제 게임 배경 위 캡처를 포함해야 한다.

### External Research Decision

이 계획은 OpenAI 이미지 생성/편집과 unattended automation을 포함하므로 외부 리서치를 OpenAI 공식 문서로 제한해 확인했다.

- OpenAI 이미지 생성 도구는 텍스트 프롬프트와 선택적 이미지 입력을 받아 생성 또는 편집을 수행할 수 있다.
- Responses API의 image generation tool은 generate/edit action을 제어할 수 있고, 결과에 `revised_prompt`를 포함할 수 있다.
- API reference 기준 이미지 응답에는 base64 image data, background/output format/quality/size, usage metadata 같은 저장 가능한 필드가 있다.
- 투명 배경 옵션은 모델/엔드포인트별 지원 차이가 있다. 따라서 자동화는 `background: transparent`만 믿지 않고, 실패 시 chroma-key 또는 후처리 alpha normalization을 품질 게이트에 넣어야 한다.

## Problem Statement

현재 프로젝트는 게임 기획과 전투 루프가 빠르게 바뀌고 있다. 플레이어, 좀비, 일반 적, 무기/아이템 아이콘 일부는 이미 방향성이 잡혔지만, 에셋은 사용자의 수동 피드백과 개별 이미지 생성에 많이 의존한다. 프로토타이핑에서는 자연스러운 상태지만, 게임 디자인이 매일 바뀌는 동안 에셋만 뒤처지면 다음 문제가 생긴다.

- 코드에는 새 적, 보스, 계약, 아이템, 무기 이름이 생기지만 대응 에셋은 placeholder로 남는다.
- AI 이미지 생성 결과가 매번 예쁘더라도 스타일, 크기, 배경, 64px 가독성, pivot, 게임 배경 위 대비가 흔들린다.
- 완성 스프라이트 시트를 한 번에 만들면 프레임 반복, 포즈 붕괴, 캐릭터 정체성 흔들림이 자주 발생한다.
- 반대로 사람 손으로만 관리하면 에이전트 자원을 제대로 쓰지 못하고, 에셋 리뷰가 사용자의 병목이 된다.

따라서 필요한 것은 “한 번에 정답 에셋을 뽑는 프롬프트”가 아니라, 매일 반복되는 작은 공장이다. 이 공장은 부족한 에셋만 찾아 후보를 만들고, 기계적으로 탈락시킬 수 있는 것은 탈락시키고, 최종 판단이 필요한 것만 사용자가 빠르게 볼 수 있게 정리해야 한다. (see brainstorm)

## Proposed Solution

`Candidate Factory + Quality Gates`를 만든다. 자동화는 다음 순서로 동작한다.

1. 최신 `main` 기준으로 에셋 요구사항을 수집한다.
2. `assets/asset_manifest.json`과 현재 파일 시스템을 비교해 `missing`, `placeholder`, `needs_refresh` 항목만 후보 생성 대상으로 고른다.
3. 에셋 타입별 prompt pack을 조립한다.
4. 핵심 캐릭터는 승인된 style anchor를 참조로 edit/refinement를 우선하고, 일반 적/아이템/무기는 generate 후 정규화한다.
5. 후보별로 RGBA/alpha/cell/bbox/64px/중복/스타일 규칙을 검증한다.
6. Godot asset harness 또는 main scene capture를 실행해 실제 게임 배경 위에서 읽히는지 확인한다.
7. 후보를 `assets/candidates/...`와 `docs/reports/assets/...`에 저장하고, 필요하면 후보 브랜치에 commit한다.
8. 사용자가 승인하면 별도 promotion 단계에서만 `assets/sprites/...` 또는 `assets/sprites/items/...`의 실사용 경로로 승격한다.

## Scope Boundaries

### In Scope

- 에셋 매니페스트와 gap detection.
- 에셋 타입별 prompt pack.
- 후보 생성 결과의 메타데이터 저장.
- deterministic post-processing과 validation.
- 기존 player/zombie harness 및 main scene capture 연동.
- daily 1AM Codex cron automation 설계.
- 후보 리포트와 human review/promotion 흐름.

### Out of Scope

- 자동화가 `main`에 직접 에셋을 교체하고 push하는 기능.
- Brotato 원본 리소스의 형태, 캐릭터, 아이콘, 장식을 복제하는 기능.
- 모든 캐릭터를 frame-by-frame 완성 스프라이트 시트로 생성하는 기능.
- 최종 아트 승인까지 완전 자동화하는 기능.
- 상용 배포용 법무/IP 검수 자동화. 1차 버전은 내부 프로토타입 보조 도구다.

## Technical Approach

### Architecture

#### 1. Asset Manifest

새 파일 `assets/asset_manifest.json`을 단일 source of truth로 둔다. 첫 버전은 사람이 읽고 수정하기 쉬운 JSON으로 시작하고, 필요하면 이후 YAML/JSON Schema를 붙인다.

```json
{
  "version": 1,
  "assets": [
    {
      "id": "enemy_fast_zombie",
      "kind": "enemy_single_image",
      "status": "accepted",
      "runtime_policy": "single_image_transform",
      "current_asset": "res://assets/sprites/characters/p1_monsters_runtime_v1/fast_zombie.png",
      "style_anchor_refs": [
        "res://assets/sprites/characters/miner_zombie_v1/zombie_idle.png"
      ],
      "harness": "zombie_runtime",
      "review_policy": "manual_promotion",
      "last_reviewed_at": "2026-06-04",
      "notes": "Cute mine-zombie family, readable at 64px."
    }
  ]
}
```

권장 `kind`:

- `player_layered_character`
- `enemy_single_image`
- `enemy_special_state`
- `weapon_ingame`
- `weapon_icon`
- `item_icon`
- `item_on_character`
- `effect_sprite`
- `ui_icon`

권장 `status`:

- `accepted`: 실사용 가능, 자동화가 직접 교체하지 않는다.
- `placeholder`: 현재 파일은 있지만 교체 후보를 만들 수 있다.
- `missing`: 요구사항은 있지만 파일이 없다.
- `needs_refresh`: 코드/디자인 변경으로 새 후보가 필요하다.
- `candidate`: 생성됐지만 승인 전이다.
- `rejected`: 리뷰에서 탈락한 후보다.

#### 2. Gap Detector

Gap detector는 repo-local deterministic script로 둔다. 첫 구현은 작은 스크립트 하나로 충분하다. 언어는 구현 시 선택하되, Godot 실행 환경과 별개로 빠르게 파일을 스캔할 수 있는 방식이 좋다.

입력:

- `assets/asset_manifest.json`
- `scripts/main.gd`의 `res://assets/...` 참조
- `assets/sprites/**/metadata.json`
- `docs/art/*.md`
- 선택적으로 `todos/*.md`, 최신 plan/brainstorm 문서

출력:

- `missing`: manifest에는 있는데 파일이 없는 항목
- `untracked_reference`: 코드가 참조하지만 manifest에 없는 항목
- `placeholder`: placeholder icon/path가 반복 사용되는 항목
- `stale`: manifest의 `needs_refresh` 또는 오래된 review date
- `protected`: `accepted`라서 자동 교체 금지인 항목

첫 버전의 detector는 “필요한 모든 에셋을 완벽하게 추론”하지 않아도 된다. 대신 코드가 이미 참조하는 asset path, manifest에서 수동으로 표시한 상태, placeholder 반복 사용을 안정적으로 잡는 것을 MVP로 한다.

#### 3. Prompt Packs

Prompt pack은 에셋 타입별로 관리한다.

권장 위치:

```text
docs/art/prompt-packs/
  character-layered.md
  enemy-single-image.md
  weapon-ingame.md
  weapon-icon.md
  item-icon.md
  effect-sprite.md
```

모든 prompt pack은 다음 공통 규칙을 포함한다.

- Bro-exile original cute toy-like mine survival game asset.
- Cute but slightly grotesque mine creature tone.
- Thick dark outline, compact readable silhouette, soft sprite-like shading.
- Transparent PNG or flat chroma-key background fallback.
- Designed to remain readable at 48-64px.
- No text, no watermark, no UI frame, no background scene.
- Do not copy Brotato characters, icons, silhouettes, or decorative details.
- Fit within a 256x256 game cell with clear alpha around the silhouette.

핵심 캐릭터 prompt pack은 style anchor를 사용한다. 일반 적 prompt pack은 단일 이미지와 runtime transform을 전제로 한다. 무기/아이템 prompt pack은 캐릭터와 분리된 인게임 이미지와 UI 아이콘을 분리해서 요청한다.

#### 4. Candidate Generator

자동화는 generation backend를 인터페이스처럼 다룬다.

첫 구현 옵션:

- Codex/ChatGPT image generation을 사용하는 manual candidate run.
- OpenAI Responses API image generation tool을 사용하는 unattended cron run.
- 기존 이미지 reference 기반 edit run.

generation result는 다음 메타데이터를 반드시 남긴다.

```json
{
  "asset_id": "enemy_poison_spider",
  "candidate_id": "2026-06-04-enemy_poison_spider-c03",
  "provider": "openai",
  "model": "implementation-selected",
  "action": "generate",
  "prompt_pack": "docs/art/prompt-packs/enemy-single-image.md",
  "prompt": "full prompt text used for the request",
  "revised_prompt": "model revised prompt when available",
  "source_refs": [
    "assets/sprites/characters/miner_zombie_v1/zombie_idle.png"
  ],
  "output_original": "assets/candidates/2026-06-04/enemy_poison_spider/c03/original.png",
  "output_normalized": "assets/candidates/2026-06-04/enemy_poison_spider/c03/normalized_256.png"
}
```

후보 수 기본값:

- missing/placeholder item icon: 3 candidates.
- enemy single image: 4 candidates.
- weapon icon/ingame pair: 4 candidates.
- player/core character: 2 candidates plus iterative edit, 자동 일일 실행에서는 기본 제외하고 수동 요청 시만 실행.

#### 5. Normalizer

Normalizer는 생성 이미지를 게임 후보로 만들기 위한 deterministic 단계다.

필수 작업:

- 이미지 로드 성공 확인.
- RGBA8 변환.
- alpha bbox 계산.
- 빈 이미지/너무 작은 실루엣/너무 큰 실루엣 탈락.
- 256x256 cell에 중앙 또는 지정 pivot 기준으로 pack.
- 64px preview 생성.
- chroma-key 또는 배경 잔여물 제거.
- 산발적인 alpha noise 제거.
- 후보별 `normalization.json` 저장.

적용 기준:

- full-frame enemy는 점유 최대축이 256px cell 기준 150-224px 사이를 목표로 한다.
- item/weapon icon은 64px에서 형태가 읽혀야 하며, 과한 내부 디테일은 감점한다.
- 플레이어 파츠는 기존 `player_asset_harness`와 같은 cell/pivot/preview 계약을 따라야 한다.

#### 6. Quality Gates

Quality gate는 hard gate와 review gate로 나눈다.

Hard gate:

- PNG 로드 실패.
- RGBA/alpha 정보 없음.
- alpha bbox가 비어 있음.
- cell size/padding 기준 위반.
- 텍스트/워터마크/서명처럼 보이는 요소 탐지.
- 배경 잔여물이 alpha 외곽에 넓게 남아 있음.
- 64px preview에서 거의 보이지 않음.
- animation sheet 후보에서 adjacent duplicate가 과다.

Style gate:

- 플레이어 노란 헬멧과 너무 겹치는 적 팔레트.
- Bro-exile 광산 정체성이 약함.
- Brotato 원본의 형태나 실루엣을 직접 따라 한 느낌.
- 귀여움/기괴함 균형이 무너짐.
- 작은 화면에서 역할 구분이 안 됨.

Game gate:

- `player_asset_harness` 또는 `zombie_asset_harness` 통과.
- `--capture-stage1` 또는 `--capture-monster-roster`에서 실제 배경 위 가독성 확인.
- 피격 flash, facing flip, scale/bob/rotation transform에서 깨지지 않음.
- 플레이어, 적, pickup, bullet과 색/실루엣이 구분됨.

#### 7. Review Report

자동화는 결과를 Markdown 리포트로 남긴다.

권장 위치:

```text
docs/reports/assets/
  2026-06-04-asset-automation-report.md
```

리포트 구성:

- Run summary: date, branch, commit sha, automation id, generation budget.
- Gap detector result: missing/placeholder/needs_refresh/protected.
- Candidate grid: 후보별 원본, normalized, 64px preview.
- Godot capture: stage1/monster roster/harness capture 이미지 경로.
- Gate result: pass/fail/warn와 탈락 사유.
- Prompt provenance: prompt pack, prompt, revised_prompt, source refs.
- Recommended action: accept candidate, request more variants, keep current asset, mark rejected.

이미지 파일은 Markdown에서 바로 볼 수 있도록 상대 경로를 병기하되, Codex 최종 응답에서는 절대 경로를 같이 제시하는 방식을 사용한다.

#### 8. Human Promotion

자동화가 후보를 만들면 사용자는 다음 중 하나를 선택한다.

- `accept`: 후보를 실사용 asset path로 승격한다.
- `revise`: 후보를 style anchor로 삼아 추가 edit run을 요청한다.
- `reject`: 탈락 사유와 함께 `rejected`로 기록한다.
- `defer`: 다음 자동화에서 다시 생성하지 않도록 일정 기간 보류한다.

Promotion 단계는 별도 명령 또는 별도 plan/workflow로 분리한다. 이 계획의 핵심은 후보 생성과 검증이며, promotion은 반드시 사용자의 명시적 승인 후 수행한다.

### Automation Contract

Codex app automation은 구현 완료 후 별도 요청에서 생성한다. 이 계획은 그 자동화가 따라야 할 계약만 정의한다.

스케줄:

- 매일 1회.
- 사용자 로컬 시간 기준 새벽 1시.
- worktree 환경에서 실행.
- 대상 cwd는 `/Users/highfence/Documents/Bro-exile`.
- 시작 기준은 원격 `main`의 최신 상태.

자동화 prompt에는 다음 규칙을 넣는다.

```text
Inspect the latest Bro-exile main branch for asset gaps. Use docs/art/asset-generation-principles.md, docs/art/player-asset-harness.md, assets/asset_manifest.json, and the current game code as source of truth. Generate only review candidates for missing, placeholder, or needs_refresh assets. Do not overwrite accepted assets and do not push directly to main. Save prompt, revised_prompt when available, source refs, normalized PNGs, 64px previews, Godot captures, and a Markdown review report. If no actionable gaps exist, report no-op with evidence. Cap generation to the configured daily budget.
```

자동화는 실패해도 `main`을 더럽히지 않아야 한다. 후보 브랜치나 리포트 작성 전 단계에서 실패하면 no-op summary만 남긴다.

## Implementation Phases

### Phase 1: Foundation Manifest And Report Shape

Tasks:

- `assets/asset_manifest.json` 초안 작성.
- 현재 player, zombie, runtime monsters, item icons, weapon references를 manifest에 등록.
- `docs/art/prompt-packs/` 생성.
- `docs/reports/assets/README.md` 또는 간단한 report template 작성.
- 후보 디렉터리 정책 결정: `assets/candidates/YYYY-MM-DD/<asset-id>/<candidate-id>/`.

Success:

- manifest만 보고 accepted/placeholder/missing 후보를 구분할 수 있다.
- 현재 사용 중인 player/zombie/monster asset은 `accepted` 또는 `prototype_accepted` 상태로 보호된다.
- report template은 candidate image, 64px preview, Godot capture, gate result, prompt provenance를 담을 자리가 있다.

Estimated effort:

- 0.5-1 day.

### Phase 2: Gap Detector And Deterministic Validator

Tasks:

- gap detector script 추가.
- manifest path 존재 여부 검사.
- `scripts/main.gd`의 `res://assets/...` 참조를 읽어 manifest 누락을 보고.
- placeholder 반복 사용 탐지. 예를 들어 여러 아이템이 같은 임시 icon을 공유하면 `placeholder_candidate`로 표시.
- normalized PNG validator 추가.
- validation output을 JSON과 Markdown에 모두 연결.

Success:

- generation 없이 dry-run을 실행해 actionable asset gap report를 만들 수 있다.
- accepted asset은 자동 후보 대상으로 잡히지 않는다.
- 누락 파일, 알파 없음, 빈 bbox, 잘못된 cell size를 deterministic하게 실패시킨다.

Estimated effort:

- 1 day.

### Phase 3: Candidate Generation Adapter

Tasks:

- generation backend 인터페이스 정의.
- OpenAI Responses API image generation tool 또는 Codex image generation을 사용하는 manual run부터 연결.
- API 키와 생성 예산은 환경 변수/automation secret으로만 다루고 repo에 저장하지 않는다.
- `prompt`, `revised_prompt`, `provider`, `model`, `action`, source refs를 candidate metadata에 저장.
- 모델별 투명 배경 지원 차이를 검증하고, transparent 실패 시 chroma-key 또는 alpha post-processing fallback을 적용.
- 하루 생성량 제한을 둔다.

Success:

- enemy/item/weapon 중 최소 한 타입에서 3개 이상 후보를 만들고 각 후보에 metadata를 저장한다.
- `revised_prompt`가 제공되는 backend에서는 반드시 저장된다.
- generation 실패는 run 전체를 깨지 않고 해당 asset의 failure로 기록된다.

Estimated effort:

- 1-2 days.

### Phase 4: Godot Harness And Capture Integration

Tasks:

- player 후보는 `player_asset_harness`로 검증한다.
- enemy single image 후보는 `zombie_asset_harness` 또는 일반화된 `single_image_enemy_harness`로 검증한다.
- `--capture-stage1`, `--capture-monster-roster`를 후보 리포트에 연결한다.
- 캡처 파일 경로와 검증 결과를 report에 포함한다.
- `docs/solutions/ui-bugs/invisible-godot-ui-text-GodotPort-20260522.md`의 learning에 따라 headless load와 실제 capture를 분리해 확인한다.

Success:

- 하나의 enemy 후보가 normalized PNG, 64px preview, runtime transform sheet, monster roster capture까지 한 리포트에서 확인된다.
- Godot 실행 실패, 렌더 캡처 실패, 빈 캡처는 hard failure로 기록된다.
- 기존 player/zombie harness의 metadata와 새 report metadata가 같은 용어를 쓴다.

Estimated effort:

- 1-2 days.

### Phase 5: Review And Promotion Workflow

Tasks:

- report의 후보별 action block 정의.
- 사용자가 승인한 candidate를 manifest에 `accepted`로 승격하는 promotion script 또는 수동 절차 문서화.
- 승격 시 원본 후보 metadata를 실사용 asset metadata에 복사하거나 링크.
- 탈락한 후보는 `rejected`와 사유를 남겨 같은 실패를 반복하지 않게 한다.
- accepted asset은 다음 자동화에서 보호한다.

Success:

- 후보 하나를 승인해 실사용 asset path로 옮기는 절차가 재현 가능하다.
- 승격 후 `scripts/main.gd` 또는 scene 참조가 깨지지 않는다.
- rejected/deferred 상태가 다음 gap detector에 반영된다.

Estimated effort:

- 0.5-1 day.

### Phase 6: Daily 1AM Codex Automation

Tasks:

- Codex app recurring automation으로 daily 1AM cron을 생성한다.
- worktree 환경에서 실행하게 한다.
- 자동화 prompt에는 이 plan, brainstorm, asset principles, player harness docs, manifest, report template 경로를 명시한다.
- 첫 3회는 dry-run 또는 generation budget 1로 운영해 noise를 확인한다.
- 안정화 후 generation budget을 enemy/item 중심으로 늘린다.
- 자동화는 candidate branch/report만 만들고 `main` 직접 push를 금지한다.

Success:

- 매일 1시에 실행 기록이 생긴다.
- no-op일 때는 이유와 검사 대상 commit sha를 남긴다.
- 후보가 있을 때는 review report와 후보 asset tree가 생긴다.
- 실패해도 accepted assets나 `main`에 영향이 없다.

Estimated effort:

- 0.5 day after Phases 1-5.

## Alternative Approaches Considered

### Approach A: Prompt-Only Daily Generator

매일 새 프롬프트로 이미지를 만들고 폴더에 저장하는 방식이다. 구현은 가장 빠르지만 스타일 붕괴, 배경 잔여물, pivot 불일치, 64px 가독성 실패를 잡을 장치가 없다. 스케치 수집에는 쓸 수 있지만 실제 게임 후보 자동화의 기본값으로는 부적합하다. (see brainstorm)

### Approach B: Candidate Factory + Quality Gates

선택한 접근이다. 후보를 여러 개 만들고, deterministic normalization, hard gate, style/game review gate를 거쳐 사람이 볼 수 있는 후보만 남긴다. 비용과 하네스가 늘어나지만 품질 편차를 “생성 단계”가 아니라 “선별 단계”에서 다룰 수 있다. (see brainstorm)

### Approach C: Locked Style Anchor + Iterative Editing

승인된 player/zombie/style anchor를 참조 이미지로 넣어 edit/refinement를 반복하는 방식이다. 장기 핵심 캐릭터에는 좋지만 새 카테고리 탐색에는 답답할 수 있으므로 Approach B 안의 모드로 흡수한다. (see brainstorm)

### Rejected: Direct Main Replacement

자동화가 `main`의 실사용 asset을 바로 교체하면 취향 판단과 아트 디렉션 리스크가 너무 크다. 프로토타입 단계라도 사용자 승인 전에는 후보 브랜치/리포트까지만 허용한다. (see brainstorm)

### Rejected: Always Generate Full Sprite Sheets

AI에게 8프레임 완성 시트를 매번 맡기면 프레임 반복, 포즈 붕괴, 캐릭터 정체성 흔들림이 잦다. 기존 에셋 원칙처럼 파츠 리그, pose guide, Godot runtime transform, bake를 우선한다. (see brainstorm)

## SpecFlow Analysis

### User Flow

1. 사용자는 평소처럼 main에서 게임 기획과 코드 작업을 진행한다.
2. 매일 새벽 1시에 asset automation이 최신 main을 별도 worktree에서 본다.
3. 자동화는 새로 필요한 에셋이나 placeholder를 찾아 후보를 만든다.
4. 사용자는 report에서 후보 grid, 64px preview, Godot capture를 본다.
5. 사용자는 accept/revise/reject/defer 중 하나를 선택한다.
6. accept한 후보만 promotion 절차를 통해 실사용 asset으로 들어간다.

### Agent Flow

1. automation starts on clean worktree.
2. fetch latest main and record commit sha.
3. run gap detector.
4. if no gaps, write no-op summary and stop.
5. for each selected gap, build prompt pack.
6. generate candidates within daily budget.
7. normalize and validate.
8. run Godot harness/capture.
9. write report and candidate metadata.
10. commit candidate branch if there are reviewable outputs.
11. summarize paths and failures.

### Edge Cases

- No actionable gaps: no-op report, no candidate branch required.
- API/generation unavailable: write failure report, do not modify accepted assets.
- Transparent background unsupported: fallback to chroma-key/alpha post-processing and mark warning.
- All candidates fail hard gates: report failed candidates and reasons, do not promote.
- Godot capture fails: keep normalized candidates but mark review status as blocked.
- Worktree has conflicts or dirty state: abort before generation.
- User has accepted an asset while automation is running: promotion must re-check manifest status before writing.
- Same placeholder appears in many items: cap daily generation so one noisy category does not consume the whole run.
- Candidate resembles Brotato too closely: reject or mark manual review required.
- Branch already exists for the day: append run id instead of force pushing.

### Acceptance Criteria Updates From SpecFlow

- Dry-run and no-op path must be first-class, not treated as failure.
- Promotion must re-check manifest state to prevent stale automation from overwriting a newly accepted asset.
- API failure and Godot failure must be separated in reports.
- Report must include enough visual proof for the user to judge without opening many folders manually.

## System-Wide Impact

### Interaction Graph

Daily automation triggers a worktree run. The worktree run invokes gap detector, which reads manifest and repo references. Gap detector selects assets, prompt builder prepares prompt packs, generation adapter creates raw candidates, normalizer writes normalized PNGs and metadata, Godot harness/capture renders game previews, report builder writes Markdown, and optional git step commits the candidate branch.

Promotion is a separate chain. User approval triggers promotion, promotion copies candidate output into the correct `assets/sprites/...` path, updates manifest, updates metadata, optionally updates `scripts/main.gd` or scene references, then runs Godot load/capture verification.

### Error & Failure Propagation

- Gap detector failures should fail the run early because generation without an asset list creates noise.
- Generation failures should be isolated per asset and recorded as `generation_failed`.
- Normalization failures should mark a candidate failed but allow sibling candidates to continue.
- Godot harness failures should mark the candidate `blocked_game_capture` and keep artifacts for inspection.
- Git failures should not discard generated artifacts; the automation should report the local candidate path and stop before push.
- Any failure after accepted asset mutation is unacceptable. This is why mutation belongs only to promotion, not daily generation.

### State Lifecycle Risks

- Partial generation may leave incomplete candidate folders. Mitigation: write into a run temp directory first, then finalize candidate metadata when gates complete.
- Repeated failed candidates may bloat the repo. Mitigation: keep rejected candidates in a dated folder and add retention policy later.
- Manifest drift can occur if code references assets not registered in manifest. Mitigation: gap detector reports `untracked_reference`.
- User-approved assets could be overwritten by stale automation. Mitigation: daily automation never writes accepted paths; promotion re-checks manifest.
- API secrets could leak into metadata. Mitigation: store provider/model/action and usage, never request headers or API keys.

### API Surface Parity

Manual and cron runs should share the same deterministic scripts and report format.

Surfaces that need parity:

- Manual local dry-run command.
- Manual one-asset generation command.
- Daily Codex automation.
- Promotion workflow.
- Existing Godot harness scenes.
- Main scene capture commands.

If only the cron path works, debugging becomes painful. If only the manual path works, daily automation will drift.

### Integration Test Scenarios

- Dry-run on current repo produces a report and exits successfully without generation.
- Manifest references a missing file and gap detector reports it as `missing`.
- Candidate PNG with no alpha or empty bbox fails hard gate.
- Enemy single-image candidate runs through zombie/single-image harness and produces 64px preview plus metadata.
- Main stage capture runs after candidate injection and writes a non-empty PNG.
- Accepted asset is never overwritten by daily automation.
- API failure creates a failure report and leaves `main` unchanged.

## Acceptance Criteria

### Functional Requirements

- [ ] `assets/asset_manifest.json` exists and covers current player, zombie, runtime monsters, key weapons, item icons, and placeholders.
- [ ] Gap detector can run without image generation and report `missing`, `placeholder`, `needs_refresh`, `accepted`, and `untracked_reference`.
- [ ] Prompt packs exist for player/layered character, enemy single image, weapon, item icon, and effect sprite.
- [x] Candidate generation stores raw output, normalized output, 64px preview, prompt, revised prompt when available, source refs, model/action, and output paths.
- [ ] Normalizer rejects empty images, bad alpha, wrong size, excessive background residue, and unreadable 64px previews.
- [ ] Existing player and zombie Godot harnesses are integrated into the report flow.
- [x] At least one enemy or item candidate can be generated, normalized, captured in Godot, and shown in a report.
- [ ] Daily 1AM Codex automation can be created after implementation and uses worktree execution.
- [ ] Automation never pushes or writes directly to `main`.
- [ ] Promotion requires explicit user approval.

### Non-Functional Requirements

- [ ] Daily run has a configurable generation budget.
- [ ] Runs are idempotent enough to retry without corrupting accepted assets.
- [ ] Secrets/API keys are not committed or logged.
- [ ] Reports are readable in Markdown and include visual paths.
- [ ] Candidate metadata is machine-readable JSON.
- [ ] New scripts can run locally without relying on a hidden Codex-only state, except the generation backend itself.

### Quality Gates

- [ ] Godot headless load passes before candidate capture.
- [ ] Candidate capture produces non-empty PNG files.
- [ ] 64px preview is generated for every reviewable candidate.
- [ ] Candidate metadata includes hard gate pass/fail and warnings.
- [ ] Style gate explicitly flags Brotato-copy risk.
- [ ] Accepted assets are protected by manifest status.

## Success Metrics

- Daily run completion rate: target 90%+ after stabilization.
- No-op accuracy: no false generation when all assets are accepted.
- Candidate pass rate after hard gates: target 30-70%; lower means prompts/normalizer are too strict or generation is poor, higher may mean gates are too weak.
- Human acceptance rate: target at least 1 accepted candidate per several useful runs, not necessarily daily.
- Review time: user can judge a run from one report in under 5 minutes.
- Safety: zero direct overwrites of accepted assets by daily automation.
- Provenance completeness: 100% of candidates have prompt, source refs, output paths, and verification metadata.

## Dependencies & Prerequisites

- Godot executable: `/Users/highfence/Dev/Sweep/engine/godot/bin/godot.macos.editor.arm64`.
- Existing project runbook commands from `AGENTS.md`.
- Existing player and zombie asset harness scenes.
- OpenAI image generation access for unattended candidate creation.
- API credentials supplied through environment/secret management, never repo files.
- Codex app recurring automation support.
- Stable style anchors for player, zombie, and first monster family.

## Risk Analysis & Mitigation

### Risk: Quality Is Still Uneven

Mitigation:

- Generate multiple candidates.
- Fail hard issues deterministically.
- Use approved anchors for core characters.
- Show 64px and game capture before user review.
- Keep accepted assets protected.

### Risk: Automation Creates Too Much Noise

Mitigation:

- Only process `missing`, `placeholder`, and `needs_refresh`.
- Cap daily generation.
- Skip accepted assets.
- Add defer/rejected status.
- Start first runs with low budget.

### Risk: Brotato Reference Becomes Too Literal

Mitigation:

- Prompt packs say Brotato is structural reference only.
- Style gate flags direct silhouette/icon similarity.
- Reports include source refs and prompt provenance.
- Human promotion remains required.

### Risk: Generated PNGs Do Not Work In Game

Mitigation:

- Normalize into 256x256 cells.
- Require RGBA alpha and bbox checks.
- Run Godot harness/capture.
- Preview at 64px.
- Keep runtime animation in engine for enemies.

### Risk: Secrets Leak

Mitigation:

- Use environment variables or Codex automation secret handling.
- Never serialize request headers.
- Candidate metadata stores provider/model/action/usage only.

### Risk: Candidate Branches Accumulate

Mitigation:

- One dated report per run.
- Candidate folder includes run id.
- Later add retention policy for rejected candidates.
- No-op runs do not need candidate branches.

## Resource Requirements

- One implementation pass for manifest, gap detector, normalizer, report builder.
- One implementation pass for generation backend and prompt packs.
- One implementation pass for Godot capture integration.
- One manual review session to tune thresholds.
- Recurring daily automation budget for image generation.

## Future Considerations

- Add perceptual image comparison to detect candidates too close to Brotato references or existing accepted assets.
- Add palette extraction and contrast scoring against stage backgrounds.
- Add a small web/HTML report gallery if Markdown becomes hard to scan.
- Add per-category queues so weapons/items/enemies rotate fairly across days.
- Add batch promotion with checkboxes after the report format stabilizes.
- Add a visual regression baseline for player/enemy readability across capture scenes.
- Extend manifest to support animation state requirements for bosses and special enemies.

## Documentation Plan

- Update `docs/art/asset-generation-principles.md` with the automation rule: daily runs produce candidates only.
- Update `docs/art/player-asset-harness.md` with how it participates in the automatic report.
- Add `docs/art/prompt-packs/README.md`.
- Add `docs/reports/assets/README.md`.
- Add a short runbook for manual dry-run, one-asset generation, report review, and promotion.
- After the automation is created, document its name, schedule, worktree behavior, and failure handling.

## Sources & References

### Origin

- **Brainstorm document:** `docs/brainstorms/2026-06-04-chatgpt-asset-quality-harness-brainstorm.md`
  - Carried forward decisions: Approach B as default, Approach C only for approved anchors, daily 1AM cadence, no direct `main` replacement, prompt/revised prompt/source refs/verification metadata logging.

### Internal References

- `docs/art/asset-generation-principles.md:12`: project asset principles define a readable static/parts-based asset pipeline.
- `docs/art/asset-generation-principles.md:53`: runtime frames and icons use 256x256 cells by default.
- `docs/art/asset-generation-principles.md:61`: full generated sprite sheets are risky; use source character, pose guide, post-processing, and Godot enhancement.
- `docs/art/asset-generation-principles.md:200`: AI prompts must include identity, purpose, canvas, readability, prohibitions, and post-processing.
- `docs/art/asset-generation-principles.md:221`: new assets must pass alpha, cell, 64px, duplicate-frame, and game-background checks.
- `docs/art/player-asset-harness.md:14`: current player harness scope.
- `docs/art/player-asset-harness.md:95`: player asset production flow and promotion point.
- `scripts/tools/player_asset_harness.gd:52`: player harness run entry.
- `scripts/tools/player_asset_harness.gd:308`: player harness animation metadata and verification output.
- `scripts/tools/zombie_asset_harness.gd:74`: zombie harness metadata contract.
- `scripts/tools/zombie_asset_harness.gd:294`: zombie harness animation metadata and verification output.
- `assets/sprites/characters/p1_monsters_runtime_v1/metadata.json:2`: monster runtime style reference.
- `assets/sprites/characters/p1_monsters_runtime_v1/metadata.json:26`: monsters are intended to animate via scale, rotation, bob, flip, and shadow rather than frame-by-frame sheets.
- `scripts/main.gd:48`: current player part asset paths.
- `scripts/main.gd:53`: current zombie and monster asset paths.
- `scripts/main.gd:281`: `--capture-stage1` command path.
- `scripts/main.gd:283`: `--capture-monster-roster` command path.
- `scripts/main.gd:3885`: enemy sprite asset drawing path.
- `scripts/main.gd:3987`: player part sprite drawing path.
- `docs/solutions/ui-bugs/invisible-godot-ui-text-GodotPort-20260522.md`: use real Godot captures, not headless success alone, for visual validation.

### External References

- OpenAI image generation guide: https://developers.openai.com/api/docs/guides/tools-image-generation
- OpenAI Images API reference: https://developers.openai.com/api/reference/resources/images
- OpenAI Help Center, Images in ChatGPT: https://help.openai.com/en/articles/11084440-images-in-chatgpt
