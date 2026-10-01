# RFLUASETUP 0.6.91 BETA

## 한국어

**개발 중인 미완성 BETA입니다. Easy Setup은 현재 서보 센터 설정까지 구현한 중간 단계입니다. 전체 기체 설정이나 비행 준비가 완료되는 버전이 아닙니다.**

**TX16S MK2:** 사용자도 잠깐 실행·동작을 확인했으며 적용 가능한 것으로 보인다고 보고했습니다. 짧은 사용자 확인이며 전체 기능·안전성·장기간 사용 검증은 아직 아닙니다.

### 주요 변경

- 1. SWASH SERVO DEFAULT SETUP: S1/S2/S3 기본 설정. 1520 프리셋은 Center 1520, Min/Max -700/+700, Scale 500/500, Geo ON. 760 프리셋은 Center 760, Min/Max -350/+350, Scale 250/250. 두 프리셋의 초기 Rate는 333 Hz이며 제조사 사양에 맞춰 변경해야 합니다.
- Rate 목록 50/100/200/250/333/560 Hz와 직접 입력, Speed 및 Limits/Scale 직접 입력, 개별 Reverse 설정. 기존 저장값이 변경된다는 경고와 적용 예정값을 확인한 뒤에만 저장합니다.
- 2. SERVO REVERSE SETUP / SERVO CENTER PULSE TRIM: FRONT/REAR 선택 그림과 기수 방향 표시. 스와쉬 선 중앙의 Normal/Reverse 버튼, 현재 출력 펄스와 Center Apply 확인창.
- 초록색 서보 조합만 함께 트림하고 빨간색 서보는 현재 위치를 유지합니다. 선택을 바꿔도 기존 임시 조정값을 유지합니다. OVERRIDE ALL은 세 서보를 모두 선택하며 ALL OFF는 해제합니다.
- AILERON/ELEVATOR 조정과 REAR 엘리베이터 방향 수정. Full Setup 서보 설정 바로가기 및 Override 좌우 화살표 오류 수정.
- 연결 단절 시 RTN 대기를 제한하고 경고와 함께 복귀합니다. 화면 복귀는 기체의 해제·저장 성공을 뜻하지 않습니다.

### 설치 / 주의사항

배포 ZIP을 풀고 `SD-CARD/SCRIPTS`를 SD카드 루트로 복사하세요. 경로는 `/SCRIPTS/RFLUASETUP/main.lua`, 표시 버전은 `0.6.91 BETA`입니다. 기존 SD카드와 FC의 dump/diff를 먼저 백업하고 파일을 서로 다른 버전과 섞지 마세요.

**모터 연결을 분리하고 블레이드를 제거한 상태에서만 시험하세요.** 실제 서보의 펄스폭·주파수·전압 사양을 확인하세요. 현재 대상은 TX16S MK3/EdgeTX 및 NEXUS Gyro/Rotorflight 환경이며, 모든 조합의 실기 검증은 완료되지 않았습니다.

모의 FC의 다중 선택/저장/실패/RTN, 실제 Lua 이벤트 경로, 화면 렌더, Full Setup 회귀 및 147개 Lua 문법 검사를 수행했습니다. 이는 실제 비행 검증이 아닙니다. Easy Setup 이후 단계는 계속 개발 중입니다. 여러 서보 조정 명령은 여전히 순차 전송되므로 완전한 동시 구동은 아닙니다.

## English

**This is an unfinished BETA, still in development. Easy Setup is at an intermediate stage, implemented through servo center setup. This is not a complete helicopter setup or flight-ready release.**

**TX16S MK2:** The user also reports a brief run/operation check and that the tool appears to work. This is preliminary user feedback, not complete feature, safety or long-term validation.

### Changes

- Item 1, SWASH SERVO DEFAULT SETUP, configures S1/S2/S3. The 1520 preset uses center 1520, limits -700/+700, scales 500/500 and Geo ON. The 760 preset uses center 760, limits -350/+350 and scales 250/250. Both initially select 333 Hz; change this to match the servo manufacturer's specification.
- Rate choices of 50/100/200/250/333/560 Hz plus manual entry; editable speed, limits and scales; independent servo reverse settings. An overwrite warning and proposed values are shown before explicit save confirmation.
- Item 2, SERVO REVERSE SETUP / SERVO CENTER PULSE TRIM, adds FRONT/REAR diagrams and nose-direction arrows, Normal/Reverse controls on the swash spokes, measured output pulses and Center Apply confirmation.
- Trim any green-selected subset while red servos hold their positions. Switching selections preserves temporary offsets. OVERRIDE ALL selects all three; ALL OFF releases them.
- AILERON/ELEVATOR modes, corrected REAR Elevator direction, a shortcut to Full Setup Servos, and the Full Setup override-arrow crash fix.
- Bounded RTN waiting on lost connection, with a warning on return. Returning to the menu does not confirm hardware release or a successful save.

### Installation / limitations

Extract the distribution ZIP and copy `SD-CARD/SCRIPTS` to the SD-card root. Verify `/SCRIPTS/RFLUASETUP/main.lua` and `0.6.91 BETA`. Back up the card and FC dump/diff first; do not mix files from different versions.

**Disconnect the motor and remove blades for bench testing.** Verify each servo's pulse, frequency and voltage specifications. The target environment is TX16S MK3/EdgeTX with NEXUS Gyro/Rotorflight; validation across physical hardware combinations is incomplete.

Testing covers simulated FC multi-selection/save/failure/RTN scenarios, actual Lua event paths, screen rendering, Full Setup regressions and syntax checks for 147 Lua files. This is not flight validation. Later Easy Setup stages remain in development. Multi-servo commands are still transmitted sequentially, not atomically.
