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
