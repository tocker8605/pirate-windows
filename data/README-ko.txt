Pirate II 적 정의·타임라인 편집 안내 (v21)
==========================================

1. HP 등 적의 기본 속성은 enemies.json 한 곳에서 편집합니다.
   변경한 뒤에는 게임 실행을 종료하고 F5로 다시 시작하십시오. 정의는 실행 시작 때 한 번 읽습니다.
   entities 아래의 숫자 키가 적 종류의 definition_id입니다.
   예: "1"의 hp를5에서8로 바꾸면 모든 스테이지의1번 적 기본 HP가8이 됩니다.
   보스 본체91~94와 각 파츠도 같은 파일에서 관리합니다.

   hp                         기본 최대/현재 HP
   score                      처치 점수
   score_scales_with_difficulty 난이도 배점 배율 사용 여부
   role                       enemy / part / boss / supply
   damageable                 탄환·레이저 피격 가능 여부
   collision                  실제 탄환/레이저 판정 경계
   explosion_ticks/death_sound 처치 연출·소리
   damage_smoke               연기 시작 조건·크기·발생 위치
   drop/boss_rush_drop         일반/Boss Rush 처치 드롭
   draw_size/draw_offset      그리기 크기와 논리 위치 대비 오프셋
   part_side                  좌측-1 / 우측1 / 독립0
   open_at_y/open_kind/on_defeat 보급기 개방·아이템 분리·이탈 상태 전이
   stage/music                보스의 소속 스테이지·음악

   기존 적의 비대칭 충돌 판정과 종류별 연기 시작 HP는 그대로 옮겼습니다.
   보스 연기는 below_ratio=0.4로 실제 최대 HP에 비례합니다.
   그 외 적은 기존 임계값을 보존하기 위해 below_hp를 사용합니다.
   위 두 연기 조건은 동시에 지정하지 않습니다.
   런타임에서 피해를 받아도 정의 파일의 기본값은 바뀌지 않습니다.

2. stage01~04.json은 일반 모드, stage11~14.json은 Boss Rush 타임라인입니다.
   각 이벤트는 이름 있는 객체입니다. 예:

   {"at":10,"action":"spawn","definition_id":1,"position":[120,-50],"pattern":1011}
   {"at":20,"action":"scroll","mode":2,"speed":25}
   {"at":100,"action":"banner","name":"warning"}

   spawn: 등장 시각, 적 종류, 위치, 이동 패턴을 지정합니다.
   scroll: 배경 루프 모드와 목표 속도를 지정합니다.
   banner: warning / mission 안내를 지정합니다.
   보스도 spawn으로 생성하며 별도의 HP 하드코딩이 없습니다.
   동일 시각의 이벤트는 파일의 순서대로 전부 처리합니다.
   기존의 한 업데이트당 최대5기 생성 제한은 제거했습니다.

   at의 단위는 authored_30_ticks입니다. 30개 게임 메타 단위에 해당하며,
   현재 고정 속도1에서는 at=1이 약0.9초, at=10은 약9초입니다.
   시간순으로 정렬하고 같은 시각의 기존 순서는 유지하십시오.

3. 정말 필요한 개체만 기본 HP를 덮어쓸 수 있습니다.

   {"at":10,"action":"spawn","definition_id":1,"position":[120,-50],"pattern":1011,"overrides":{"hp":50}}

   일반 이벤트에 hp를 직접 추가하면 오류입니다. overrides에만 명시합니다.
   새 HP는 그 개체의 최대 HP에도 적용되며 다음에 등장하는 적에는 전파되지 않습니다.

4. ID 구분
   definition_id: enemies.json의 적 종류 ID. 사람이 타임라인에서 지정합니다.
   entity_id: 실행 중 동적 저장소가 부여하는 개체 고유 ID. 직접 지정하지 않습니다.
   런타임 kind는 정의 조회용 종류 ID이며 기존 이동·공격 알고리즘과 연결됩니다.
   이 숫자를 크기나 보스 파츠 여부의 범위로 해석하던 코드는 명시적 속성으로 바꿨습니다.

5. 검증
   tools/test.ps1의 enemy_catalog 검사는 v20 기준683개 이벤트의 이관,
   33종 기본 HP, 인스턴스 독립성, 명시적 HP 예외, 잘못된 설정,
   같은 시각300기 생성과 이벤트 순서를 검증합니다.
   tests/fixtures/timeline_v20.json은 이관 확인용 과거 스냅샷입니다.
   실제 게임에서는 읽지 않으며 실행본에서도 제외됩니다.
   밸런스를 의도적으로 변경할 때는 검사의 HP 기대값도 함께 갱신하십시오.
