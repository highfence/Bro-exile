<!-- BEGIN COMPOUND CODEX TOOL MAP -->
## Compound Codex Tool Mapping (Claude Compatibility)

This section maps Claude Code plugin tool references to Codex behavior.
Only this block is managed automatically.

Tool mapping:
- Read: use shell reads (cat/sed) or rg
- Write: create files via shell redirection or apply_patch
- Edit/MultiEdit: use apply_patch
- Bash: use shell_command
- Grep: use rg (fallback: grep)
- Glob: use rg --files or find
- LS: use ls via shell_command
- WebFetch/WebSearch: use curl or Context7 for library docs
- AskUserQuestion/Question: ask the user in chat
- Task/Subagent/Parallel: run sequentially in main thread; use multi_tool_use.parallel for tool calls
- TodoWrite/TodoRead: use file-based todos in todos/ with file-todos skill
- Skill: open the referenced SKILL.md and follow it
- ExitPlanMode: ignore
<!-- END COMPOUND CODEX TOOL MAP -->

## Project Writing Language

- 사용자와 함께 작성하는 기획 문서, 브레인스토밍 문서, 계획 문서, 리뷰 문서, README성 설명 문서는 기본적으로 한글로 작성한다.
- 외부 API 이름, 코드 식별자, 파일명, 클래스명, 함수명, 에러 메시지, 원문 인용이 필요한 용어는 영어를 유지할 수 있다.
- 사용자가 명시적으로 영어 문서를 요청한 경우에만 영어로 작성한다.

## Game Runbook

- 주 개발 대상은 Godot 프로젝트다. Godot 프로젝트 루트는 이 저장소 루트이며, 메인 씬은 `res://scenes/main.tscn`이다.
- 로컬에서 확인된 Godot 실행 파일은 `/Users/highfence/Dev/Sweep/engine/godot/bin/godot.macos.editor.arm64`이다.
- 실제 게임 실행:
  ```bash
  /Users/highfence/Dev/Sweep/engine/godot/bin/godot.macos.editor.arm64 --path /Users/highfence/Documents/Bro-exile
  ```
- Headless 로드 검증:
  ```bash
  /Users/highfence/Dev/Sweep/engine/godot/bin/godot.macos.editor.arm64 --headless --path /Users/highfence/Documents/Bro-exile --quit
  ```
- UI 렌더 캡처 검증:
  ```bash
  /Users/highfence/Dev/Sweep/engine/godot/bin/godot.macos.editor.arm64 --path /Users/highfence/Documents/Bro-exile -- --capture-ui
  ```
  캡처 결과는 `/private/tmp/orebound-godot-ui.png`에 저장된다.
- 레거시 브라우저 프로토타입은 `index.html`을 브라우저에서 직접 열어 실행할 수 있다.

## Asset Workflow Context

- 에셋 제작, 캐릭터 애니메이션, 몬스터 이미지, prompt pack, asset harness, 후보 promotion 작업은 먼저 `.codex/skills/bro-exile-asset-workflow/SKILL.md`를 연다.
- Skill discovery를 사용할 수 없는 에이전트는 `docs/art/agent-asset-workflow.md`를 읽고 `python3 scripts/tools/asset_workflow_context.py --format markdown`를 실행한다.
- 자동 생성 에셋은 실사용 경로에 바로 덮어쓰지 않는다. 후보 생성, normalization, 64px preview, Godot harness, stage capture, 사용자 승인 후 promotion 순서를 따른다.

## GitHub Task Management

- 진행 예정 작업은 GitHub Issue를 먼저 만들고 `docs/operations/github-issue-workflow.md`에 따라 관리한다.
- `pending` 또는 `ready` todo는 frontmatter에 `github_issue: "https://github.com/highfence/Bro-exile/issues/<number>"`를 반드시 가진다.
- GitHub Issue는 작업 목록, 논의, 담당자, 의존성, 연결 PR을 관리하고, `todos/`는 상세 acceptance criteria와 append-only Work Log를 보존한다.
- 상태, 우선순위, owner lane을 바꿀 때 GitHub Issue와 todo를 같은 작업 턴에 동기화한다. 제품 우선순위나 방향 변경은 사용자 승인 없이 확정하지 않는다.
- 구현 PR에는 `Closes #<issue-number>`를 넣고, 역할 handoff와 Validator 결과는 이슈와 todo 양쪽에서 추적 가능하게 남긴다.
- 새 역할 dispatch 전 `python3 scripts/tools/validate_agent_pipeline.py`로 GitHub 링크와 pipeline projection을 검증한다.

## Agent Pipeline Context

- 장기 작업 운영은 `docs/operations/2026-06-05-agent-team-operating-model.md`와 `docs/operations/agent-pipeline-quickstart.md`를 따른다.
- Producer는 `todos/README.md`를 읽고 Planner, Developer, Asset, Validator 중 하나로 작업을 라우팅한다.
- 역할 에이전트는 채팅 요약만으로 끝내지 않고 관련 todo의 `Work Log`나 report에 handoff를 남긴다.
- Codex local skill을 사용할 수 있으면 `.codex/skills/bro-exile-agent-pipeline/SKILL.md`를 먼저 연다.

## Pixel Perfect Context

- 에셋, UI, 애니메이션, capture, promotion 작업은 `docs/quality/2026-06-30-pixel-perfect-quality-gates.md`를 기준으로 검증한다.
- Pixel-perfect 검증이 필요한 작업은 `.codex/skills/bro-exile-pixel-perfect/SKILL.md`를 함께 적용한다.
- Headless load 성공만으로 visual QA를 통과 처리하지 않는다. 64px preview, metadata, 실제 Godot capture 경로를 handoff에 남긴다.
- UI 텍스트가 관련된 변경은 `--capture-ui` 또는 동등한 캡처 결과에서 실제 픽셀이 보이는지 확인한다.

## Async Studio Context

- Product Owner 부재 중 비동기 playable slice를 실행할 때는 `docs/operations/async-studio-runbook.md`와 `.codex/skills/bro-exile-agent-pipeline/references/async-studio-coordinator.md`를 먼저 읽는다.
- spec lock 검토와 명시적 `start --yes` 전에는 worktree, Git ref 또는 Orca task를 만들지 않는다.
- live run은 한 writer lane만 허용하고 Validator는 fresh terminal을 사용한다.
- role 완료는 candidate의 committed Work Log handoff와 artifacts로만 인정한다.
- `keep / adjust / cut`은 local-only다. 별도 승인 없이 push, main merge, runtime asset promotion 또는 public release를 하지 않는다.
