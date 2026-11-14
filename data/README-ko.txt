Pirate II 적 정의·타임라인 편집 안내 (v24.16)
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
   collision                  탄환/레이저 및 콕핏 접촉(contact_bounds) 판정 경계
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

   schema_version=2,time_unit="seconds"입니다.at는 스테이지 시작 후 경과 초입니다.
   at=1은1초,at=10은10초,at=2.75는2초750ms입니다.소수 초를 그대로 쓰십시오.
   실행은60Hz이므로 시각을 지난 첫 시뮬레이션 틱에서 처리됩니다.일시정지 중 시간은 멈춥니다.
   시간순으로 정렬하고 같은 시각의 기존 순서는 유지하십시오.200개 상한은 없습니다.
   v24.16에서 기존 값에0.9를 곱해 실제 등장 시점을 보존했습니다.
   예전schema_version1/authored_30_ticks파일은 자동 추측하지 않고 오류로 거부합니다.

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

6. 접촉·나선 공격(v24)
   collision.contact_bounds는 해당 개체의 pos 기준[xmin,ymin,xmax,ymax]입니다.
   보스 본체의 pos.x는 중심, 일반 적·파츠는 좌측 기준이므로 각각 명시합니다.
   주인공 콕핏 반지름4px와 겹치면10×난이도 피해, 기존 피격 무적시간을 적용합니다.
   damageable은 탄환/레이저에 대한 설정이며 살아 있는 기체 접촉은 별도입니다. 단 role=supply 보급기는 접촉 피해가 없습니다.
   ID5의 attack은 spiral 설정입니다. interval_seconds=0.1, speed=7(기존 메타 px/틱),
   step_degrees=15, initial_degrees=-90(위쪽), projectile_kind=6입니다.
   각 개체가 독립된 발사시계·각도를 가지며 기체 중심X<=200이면 시계방향입니다.

v24.1: cross_fighter_b는 수평 속도가0일 때만0.1초마다15도씩 회전 발사합니다.
수직 이동 중에는 발사하며, 수평 이동 중에는 각도를 유지하고 발사 대기시간을 초기화합니다.

7.1071 패턴의 상승 고도(v24.6)
   scripts/enemy_depth.gd에서SURFACE_Y=250, BLEND_DISTANCE=60, LOWER_SCALE=0.8, LOWER_BRIGHTNESS=0.65를 조정합니다.
   이동 감속 경계·접촉 예외·크기/밝기·뒤쪽 그리기 순서가 같은 규칙을 공유합니다. 탄환/레이저 피격은 별도입니다.

8.보스 본체 공격(v24.8)
   ID91 attack.type=alternating: interval_seconds=0.3,
   enraged_interval_seconds=0.15, ports=[[-40,50],[40,50]],
   horizontal_base=1,speed_y=9,projectile_kind=1.
   살아 있는 주먹이 없으면 간격이 절반으로 바뀝니다.기존 좌우 교대·속도식은 유지합니다.
   ID94 attack.type=spiral: interval_seconds=0.1,step_degrees=10,
   initial_degrees=90(아래쪽),speed=7,projectile_kind=6,
   ports=[[-25,50],[25,50]],rotation_directions=[-1,1],min_y=49.
   방향값-1은 화면상 반시계,+1은 시계입니다.본체Y>49이며 살아 있는 파츠가 있을 때 동작합니다.
   두 본체 모두 전역 발사 위상이 아닌 독립된 초 단위 시계를 사용합니다.
9.folding_wing_fighter(ID8) 하강 확산탄(v24.10)
   attack.type=speed_spread,interval_seconds=0.12,speed=9,max_vertical_speed=10,
   max_spread_degrees=90,projectile_kind=1,ports=[[30,25],[10,25]],
   spread_directions=[-1,1].하강 시작 속도를 기록하고 시작~최대 속도를 각도0~90도로 매핑합니다.
   현재 이동 패턴은 하강 속도2로 시작하므로2→6→10에서 수직→45도→수평이 됩니다.
   하강이 멈추거나 상승하면 발사 시계와 시작 속도를 초기화합니다.미사일은 별도 독립0.6초 시계입니다.

10.대형기 조준 부채탄과 양방향 나선(v24.11)
   ID42 attack.type=aimed_fan,interval_seconds=0.2,speed=10,count=7,
   spread_degrees=180,projectile_kind=6.실제 이미지 중심에서 콕핏을 향해 발사합니다.
   중앙탄 기준 좌우90도,30도 간격이며 발사 후 추적하지 않습니다.기존 미사일은 유지합니다.
   ID5 attack.opposed=true이면 같은 중심에서180도 반대 방향 탄도 함께 발사합니다.
   회전각은 한 쌍마다15도 진행하며 기존0.1초 간격과 수평 정지 조건을 유지합니다.

11.3면 보스 파츠 전멸 후 양쪽4way(v24.12)
   ID93 attack.type=paired_aimed_fan,speed=9,count=4,
   spread_degrees=45,projectile_kind=6,ports=[[-30,70],[30,70]].
   각 발사점에서 콕핏 방향을 중심으로 -22.5,-7.5,+7.5,+22.5도에 발사합니다.
   fire_channels의enrage.interval_seconds=0.3으로 일정하게 발사합니다.파츠가 모두 파괴돼야 활성화됩니다.
   본체의 기존 랜덤 미사일은 별개로 유지하며 조준탄은 발사 후 추적하지 않습니다.

12.4면 중앙 코어 사출 후 이동(v24.13)
   scripts/boss_core_motion.gd:HP200미만 사출,pattern2401,이동속도5(기존30ms단위).
   사출 후 위로 상승·감속한 뒤 화면 중앙(200,240)으로 이동해 정지합니다.실제 이미지 크기50x80과
   draw_offset(0,-8)을 반영해 논리좌표(175,208)에 고정합니다.
   본체와 분리된 상태를 유지하며 파이어볼 공격과 피격 규칙은 그대로입니다.

13.전역 발사 카운터 제거(v24.15)
   일반 적·보스·파츠의 공격 주기는 각 정의의fire_channels에서 초 단위로 편집합니다.
   예:ID92의 {"name":"enrage","interval_seconds":0.09,"gate":"no_parts"}.
   name은 scripts/enemy_fire.gd 또는 boss.gd의 이름 있는 탄 묶음과 연결됩니다.
   같은 기체도 missiles/aim 등 공격마다 잔여시간이 따로 있습니다.
   새 기체는 고유 시계를 시작하고 첫 주기가 지난 뒤 발사합니다.
   이동·좌표·파츠 조건이 꺼지면 해당 시계의 잔여시간을 비웁니다.재활성화 후 한 주기를 기다립니다.
   window_seconds=[반복주기,발사시작,발사종료]는 의도된 연사/휴지 구간입니다.
   보스2/3양팔의 기존 교대·휴지 구간은 개체 생성 시각 기준으로 유지됩니다.
   휴지 중에는 탄을 모으지 않으며,구간 재개 후 첫 발사까지 한 주기를 기다립니다.
   기존attack 설정의 나선/가속확산/7way 및1면 본체도 독립 시계로 동작합니다.
   1면 본체의 좌우 교대 시간은attack.side_hold_seconds=1.8입니다.
   scripts/attack_timer.gd가 잔여 시간·창 경계·동시 이벤트 순서·큰 시간 간격을 처리합니다.
   전역1~25발사 위상은 삭제했습니다.이동/에너지 회복/타이틀 연출 시계는 별개입니다.
   FIRE-TIMERS-v24.15.txt에서 전체 주기를 확인할 수 있습니다.

14.초 단위 스테이지 시계(v24.16)
   scripts/game.gd의stage_elapsed_seconds가 각 스테이지의 시뮬레이션 경과 초입니다.
   스테이지 진입 시0으로 초기화하고,실행 중 delta_seconds만큼 증가합니다.프레임 번호로 환산하지 않습니다.
   적의 공격 독립 타이머와 같은 delta_seconds를 사용하며 타이틀/이동 메타 시계와는 별개입니다.
   stage01~04,stage11~14의 모든683개 이벤트를 초 단위로 변환했습니다.
   TIMELINE-v24.16.txt에 변경 전후 예와 검증 항목을 정리했습니다.

15.2면 보스 구체와 보스전 실드 점수(v24.17)
   ID92.fire_channels의enrage.projectile_kind=5는 분홍색 원형 플라스마탄입니다.
   interval_seconds=0.09,좌우2발 동시,초기 속도식은 유지합니다.화염의 중력 가속은 없습니다.
   projectile_kind가 지정되면1~8의 정수여야 합니다.
   보스가 존재하는 동안 실드로 적탄을 막아도 점수는0입니다.탄소거와 실드4소모는 유지합니다.
   보스 파괴 연출 중에도 적용하며 다음 스테이지 일반 구간에서는25*난이도 점수를 다시 얻습니다.

16.코어 상승 사출(v24.19)
   scripts/boss_core_motion.gd의launch/transfer/settled단계로 처리합니다.
   HP200미만에서 수직 상승 후 감속하고 정점에 이르면 중앙으로 이동합니다.
   코어 전체 이미지와draw_offset을 반영해 화면 위아래8px여백을 유지합니다.
   상단 가까이에서 사출되면 초기 상승속도/높이를 줄입니다.상단 여유가 없으면 중앙 이동으로 넘어갑니다.
   상승은 초 단위 해석식으로 적분하며 큰시간간격에서도 정점/중앙을 지나치지 않습니다.

17.코어 사출 후 목표점(v24.20)
   이미지 중심을 다시 화면 정중앙(200,240)에 고정합니다.
   논리좌표는draw_offset/크기를 반영한(175,208)입니다.상승 사출과 화면경계 처리는 유지합니다.

18.코어 정중앙 도착 후 원형 탄막(v24.21)
   목표는 이미지 중심(200,240)/논리좌표(175,208)로 복원했습니다.
   이동 중에는 기존fire_channels/flame을 사용하고 도착하면 이 공격을 멈춥니다.
   도착 후0.25초부터radial채널이 발사합니다.분홍색구체30발,12도간격,탄속7.
   각 발사마다 전체각도를 시계방향1도씩 회전합니다.초기 기준방향은90도(아래)입니다.
   ID133.fire_channels의radial에서interval_seconds/count/spacing_degrees/
   rotation_step_degrees/initial_degrees/speed/projectile_kind를 편집합니다.
   count*spacing_degrees는360이어야 합니다.gate=core_settled.

19.3면 보스(v24.22)
   본체ID93 hp=1500.미사일은 기존0.48초 주기입니다.
   left_enrage/right_enrage는 각각0.3초,gate=part_missing,part_id=121/122입니다.
   파괴된 팔 쪽에서만 발사하며 남은 구체 여부는 관계없습니다.
   attack.ports=[[-43,46],[43,46]]은 본체 어깨 연결 구멍의 중심입니다.
   기존count=4/spread_degrees=45/speed=9/projectile_kind=6을 유지합니다.
   ID123/124의rotating_cross:0.3초,count4,spacing90도,projectile_kind3,speed9.
   rotation_step_degrees=3,rotation_direction=+1/-1로 서로 반대 회전합니다.
   initial_degrees=90.각도는 기체별로 관리하며 발사묶음마다 갱신합니다.
   구체 이동패턴은 유지하며 gate=always로 모든 높이에서 발사합니다.

20.3면 구체 정지 지점(v24.23)
   ID123/124 hp=400,rotating_cross.rotation_step_degrees=10.
   motion.type=boss_health_stations,upper_center=[100,100]/[300,100],
   lower_center=[100,240]/[300,240],lower_below_ratio=0.5,speed=5(기존30ms메타단위).
   좌표는 이미지 중심 기준입니다.본체 HP가 실제 최대 HP의50%미만이면 아래쪽 단계로 이동합니다.
   현재 본체최대1500이므로750미만.정확히750에서는 위쪽에 머뭅니다.
   아래쪽 단계로 이동하면 유지합니다.자체 구체 HP는 이 전환 조건과 관계없습니다.
   gate=orb_stationary:이동 중 발사 중단,도착 후0.3초 대기 후 재개.
   회전방향은123시계(+1),124반시계(-1),발사마다10도.이동 중 각도는 보존합니다.
   stage03/13의 두 구체 pattern은0이며 예전2203/2204코드는 삭제했습니다.
   scripts/boss_orb_motion.gd가 이동과 정지 상태를 관리합니다.

21.하단 구체 X추종과 Y기준 발사(v24.24)
   본체HP50%이하(현재750이하)에서 하단 단계가 시작됩니다.
   초기 중심(100,100)/(300,100)은 유지합니다.
   하단 중심Y=240고정,X는본체pos.x-35/+35를 천천히 추종합니다.
   motion.lower_follow={x_offset:-35/+35,speed:1}.속도1은현재약33.33px/초입니다.
   motion.speed=5는기존진입/Y이동 속도입니다.하단X와Y는독립적으로 적분합니다.
   하단X는lower_follow.x_offset을 사용하고,lower_center에서는Y값을 사용합니다.
   gate=orb_y_stationary:Y이동중에는발사하지 않고,Y고정후에는X추종중에도발사합니다.
   Y도착후0.3초부터재개합니다.X추종으로발사시계/회전각이초기화되지 않습니다.


v24.25 / 2026-11-14 — 3면 보스 본체 발악 조건
양팔 121·122가 모두 파괴된 이후에만 좌우 본체 조준탄을 함께 발사합니다.
원형 파츠 123·124의 생존 여부는 무관합니다. 발사 간격 0.3초, 각 4way/45도, 탄종과 발사 위치는 유지합니다.
양팔 파괴 후 첫 발사까지 0.3초를 기다리며, 이전 대기 시간을 누적하지 않습니다.
조건은 enemies.json의 parts_missing / part_ids 배열로 관리합니다.


v24.26 / 2026-11-14 — 3면 구체 하단 X 추종 가속
최고속도는 기존 초당33.333픽셀 유지. lower_follow.acceleration_seconds=0.4.
정지에서 최고속도까지0.4초, 최고속도에서 반대쪽 최고속도까지0.8초.
목표 변경 시 X속도를 보존하고 등가속으로 감속·가속합니다. 프레임 크기에 무관한 적분을 사용합니다.
목표 도착 시 초과 이동 없이 정지합니다. Y이동·도착 판정과 X이동 중 발사는 유지합니다.


v24.27 / 2026-11-14 — 2면 보스 조정
본체92 HP1250, 오른팔111 HP250, 왼팔112 HP250. 가운데113 HP300은 유지.
본체 발악은 가운데113 파괴 이후 발동합니다. 양팔 생존 여부는 무관합니다.
가운데 파츠가 살아 있는 동안 사출·왕복 이동하는 것은 발악 조건이 아닙니다.
분홍 구체 2발/0.09초 간격과 발사 위치는 유지. 파괴 후 첫 발사까지0.09초를 기다립니다.


v24.28 / 2026-11-14 — 격파 점수·공통 대미지·보스러시 배경
보스 본체 HP가0이 되는 일반탄/레이저 치명타 순간 점수를 지급하고 즉시 기록합니다.
본체 점수는 enemies.json에서1면5000/2면10000/3면20000/4면30000으로 관리하며 난이도 배율은 없습니다.
폭발 연출 종료/스테이지 전환 시에는 중복 지급하지 않습니다.
모든 적탄과 적·보스·파츠 접촉 대미지는10+난이도*5, 즉15/20/25/30/35입니다. 보급기 접촉 면제와 피격 무적은 유지.
보스러시4면은 일반4면의 지구/우주/달표면/달지하 셰이더를 공유합니다. 보스러시 전용 분기와 uniform은 삭제했습니다.
보스러시 시작 위치·스크롤 초기화는 다른 보스러시와 동일하게 유지합니다. 전용 시작 위치 변경은 없습니다.


v24.29 / 2026-11-14 — 5가지 구조 리팩토링
시간은 초, 속도는 픽셀/초로 이관. 엔티티 스키마2의 단위 선언과 explosion_seconds를 사용합니다.
주인공 탄은 동적 ID저장소, 명목50발 제한은 player.json 게임 규칙으로 분리했습니다.
스테이지·탄환·전투·아이템 모듈 및 공통/엔티티 스키마를 분리했습니다.
파츠 attachment 및 core_motion 값은 enemies.json에서 관리합니다.
기존 속도/조향/발사/연출 지속 시간 유지. 상세사항은 REFACTOR-v24.29.txt.


v24.30 / 2026-11-14 — 파티클 꼬리 단위 보정
속도 픽셀/초 전환 후 누락된 꼬리 길이 계수를0.051초 노출로 보정했습니다.
v24.28 정상 샘플 렌더링과0픽셀 차이. 상세사항: PARTICLE-FIX-v24.30.txt.


v24.31 /2026-11-15 — 일반 적 좌우 발사 지점
ID6와8의 발사 쌍 중심을5px 오른쪽으로 보정했습니다. 나머지4종은 기존 대칭 유지.
간격·탄종·속도·주기·조건은 유지합니다. 상세: TWIN-MUZZLES-v24.31.txt.
