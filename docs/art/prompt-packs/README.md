# 에셋 Prompt Pack

이 폴더는 자동 에셋 후보 생성에서 사용하는 프롬프트 원칙을 보관한다.

자동화는 prompt pack을 참고해 후보를 만들 수 있지만, 생성 결과를 `main`의 실사용 에셋으로 직접 교체하지 않는다. 후보는 `assets/candidates/...`와 `docs/reports/assets/...`에 저장하고, 사람이 승인한 뒤에만 promotion한다.

공통 규칙:

- Bro-exile 고유의 귀엽고 기괴한 광산 생존 게임 에셋으로 만든다.
- Brotato는 구조 참고용이며, 형태/실루엣/아이콘/장식을 복제하지 않는다.
- 48-64px에서 역할이 읽혀야 한다.
- 텍스트, 워터마크, UI 프레임, 배경 장면을 넣지 않는다.
- 투명 PNG가 이상적이지만, built-in image generation은 flat chroma-key 배경으로 받은 뒤 로컬에서 alpha 제거한다.

