# Pirate II — Windows / Godot 포팅

자작 VB6 게임 **Pirate II**를 Godot 4.7.2로 이식한 프로젝트입니다. 현재 기준 버전은 **v7**입니다.

## 실행 및 개발

Godot 4.7.2 일반판에서 `project.godot`를 열고 F5로 실행합니다.
Windows 배포판은 별도의 VB6 또는 Godot 설치 없이 실행할 수 있습니다.

- 방향키: 이동, Z: 사격, X: 레이저, C: 실드
- Space: 타이틀 시작·선택, P: 일시정지
- Ctrl+R: 재시작, Esc: 타이틀 복귀, F11: 전체화면, M: 음소거

일반 1~4스테이지, BOSS RUSH, 원본 HUD·타이틀·이미지·음악을 포함합니다.
상세 조작과 빌드 방법은 [README-ko.txt](README-ko.txt)를 참고하십시오.

## 검증 및 빌드

```powershell
.\tools\test.ps1 -Godot 'C:\Tools\Godot\Godot_v4.7.2-stable_win64_console.exe' -Render
.\tools\build.ps1 -Godot 'C:\Tools\Godot\Godot_v4.7.2-stable_win64_console.exe'
```

빌드에는 해당 Godot 버전의 Windows Export Templates가 필요합니다.
검증은 총 389개이며, GPU 화면 비교를 포함합니다. 테스트 로그는 `work/test-logs`에 생성됩니다.
일부 캠페인 테스트에는 무적과 상태 주입을 사용합니다.

## 수정 기록

- **v7**: 일반 4스테이지의 시작 속도 2·배경 모드 2를 복원하여 초반의 잘못된 배경 반복 수정.
- **v6**: 원본 재대조, 발사·충돌·슬롯·피격·전환 수정 및 모듈 분리.
- [v7 수정 내역](AUDIT-v7.txt), [v6 대조 내역](AUDIT-v6.txt), [검증 기록](VALIDATION.txt)

원본 EXE와 전체 구간의 프레임별 완전 일치를 검증한 것은 아닙니다.
음악은 원본 MIDI를 GeneralUser GS로 렌더링하여 이전 Windows MIDI 음색과 차이가 있습니다.

## 저장소 구성

- `scripts/`: 게임 진행, 전투, 화면, 오디오 모듈
- `assets/`: 원본에서 가져온 게임 이미지·오디오 및 변환된 음악
- `data/`: 스테이지 이벤트
- `tests/`: 동작·수식·캠페인·화면 회귀 검사
- `tools/`: 빌드·검증·패키징 도구

원본 VB6 코드 폴더는 별도로 보존합니다. 이 저장소는 포팅 프로젝트를 관리합니다.
생성된 빌드·엔진 캐시·임시 로그·캡처는 Git에서 제외합니다.

## 제작 및 제3자 고지

원작: Pirate II / Tocker Ent (원본 프로젝트 표기).
Godot 및 음원 관련 라이선스와 고지는 [licenses/](licenses/)를 참고하십시오.
이 저장소에서 게임 코드·원본 게임 리소스의 별도 오픈소스 라이선스를 부여하지는 않습니다.
