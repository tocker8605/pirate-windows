스테이지·구획별 고해상도 배경

stage01: region01-ocean / region02-coast / region03-forest
stage02: region01-green-valleys / region02-snow-peaks / region03-forest-ridges
stage03: region01-night-snow / region02-night-outpost / region03-night-ocean
stage04: region01-earth / region02-space / region03-moon-surface / region04-lunar-cavern

지구 파노라마는1024x1536, 나머지12개 구획은1254x1254입니다.
모두 내장 image_gen 도구로 기존 컨셉을 참고해 개별 제작했습니다.
생성에 사용한 전체 프롬프트와 파일별 해상도는 generation-prompts.json에 있습니다.

리소스 목록과 바인딩: scripts/background_assets.gd
현재 스테이지에 필요한3~4개 이미지만 렌더러에서 보유합니다.
이미지 교체 시 파일 경로를 유지하면 해당 구획만 교체할 수 있습니다.
PNG 임포트는 무손실, 크기 제한 없음, 선형 필터를 사용합니다.

논리 화면은400x480, 반복 지형의 월드 높이는480px로 유지합니다.
원래 background_regions.gd의 구획 경계·반복 해제와 타임라인 속도를 사용합니다.
4면 지구와 달 표면은 한 번 통과하고, 우주와 달 지하는 반복합니다.
타이틀과4면은 같은 region01-earth.png를 공유합니다.
스크롤 셰이더의 기존 루프 혼합과 구획 전환 연출을 유지합니다.

기존 assets/renewed의 배경은 비교용으로 남겨두며 새 렌더러에서 참조하지 않습니다.
