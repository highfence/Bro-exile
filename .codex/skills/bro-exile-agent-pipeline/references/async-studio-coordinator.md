# Async Studio Coordinator 계약

## 권위

- 제품 범위는 spec lock, lifecycle은 candidate todo의 최신 committed `pipeline-state`, 실행 생존성은 Orca가 결정한다.
- terminal text와 `worker_done`만으로 lane을 완료하지 않는다. Work Log와 산출물이 같은 local checkpoint commit에 있어야 한다.
- Orca task/dispatch ID가 현재 dispatch와 다르면 stale completion으로 버린다.

## Serial DAG

1. Planner는 spec completeness만 audit한다. 새 제품 결정을 만들지 않는다.
2. spec의 `writer_lanes`를 적힌 순서대로 한 번에 하나씩 실행한다.
3. Validator는 writer terminal을 재사용하지 않는 fresh context에서 검증한다.
4. Producer는 demo bundle과 inbox projection을 만든다.

항상 `max-concurrent=1`이다. code/asset 반려는 initial implementation 뒤 최대 두 번 같은 candidate에서 고친다. design 반려, deadline, repair budget exhaustion은 한 질문과 stable fallback을 남기고 새 dispatch를 열지 않는다.

## Completion payload

완료 payload에는 `taskId`, `dispatchId`, role, terminal, candidate commit, handoff path와 artifacts를 넣는다. candidate가 dirty하거나 handoff가 해당 commit에 없으면 incomplete다.

## 금지 동작

remote push, main merge/update, force ref update, 승인 전 runtime asset promotion, public upload/release, shell interpolation을 하지 않는다. 외부 문자열은 Git/Orca argv의 검증된 한 항목으로만 전달한다.
