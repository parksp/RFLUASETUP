# RFLUASETUP 전체 저장 경로 1차 감사 — 2026-10-25

**모터 항목 외에도 동일 계열 문제가 확인됐습니다. 정상 동작을 보장할 수 있는 상태가 아닙니다.**

FULL SETUP 18개 메뉴의 실행 진입·읽기·라이브 적용·저장 경로와 EASY SETUP 공유 경로를 정적으로 검토하고, 수신기/텔레메트리 보존 및 읽기 실패 9개 시나리오를 실제 Lua 함수로 재현했습니다. 모든 메뉴의 모든 조합·실물 FC·여러 펌웨어 버전을 전부 검증했다는 뜻은 아닙니다.

검토 대상은 기존 0.7.117/0.7.118과 모터 경로만 수정한 0.7.119 작업 후보입니다. 0.7.119는 다른 메뉴의 문제를 해결한 통합 수정본이 아니며 아직 설치 ZIP으로 배포하지 않았습니다. 이번 전체 감사에서는 다른 메뉴의 애플리케이션 코드를 변경하지 않았습니다.

## 재현 결과

조건은 오래된 화면 캐시 또는 읽기 오류/응답 누락입니다. 모든 정상 사용에서 항상 설정이 바뀐다는 뜻은 아닙니다. 수신기 SERIAL RX(bit3)가 사라지면 CRSF provider 값이 9로 남아 있어도 UI에서 NONE으로 해석될 수 있습니다. 사용자 실물 FC 로그를 확보하지 않았으므로 이번 연결 끊김의 유일한 원인이라고 확정하지 않습니다.

|우선순위|메뉴|발동 조건|확인된 영향|
|---|---|---|---|
|P1|GYRO|기능 토글 시 공통 FEATURE 전체를 오래된 gyFeature로 전송|수신기 SERIAL RX(bit3)와 TELEMETRY(bit10)가 같이 꺼질 수 있음|
|P1|CONFIGURATION|Feature 토글이 cfgFeature 전체를 재전송|변경한 Feature 이외 수신기/텔레메트리 등 공통 기능을 덮어쓸 수 있음|
|P1|RECEIVER|텔레메트리 ON/OFF도 rxFeature 전체를 전송|stale mask에서 텔레메트리 ON 시 provider=9라도 프로토콜 표시 NONE 재현|
|P2|RECEIVER|읽기 7개가 모두 실패해도 완료 콜백이 CONNECTED / READY 표시|캐시/초기값과 실제 읽은 값을 구분하지 않고 편집할 수 있음|
|P1|FAILSAFE|RX_CONFIG 읽기 실패 뒤 pulseMin만 수정해도 RX_CONFIG 전체 전송|캐시된 provider=2가 함께 전송됨; 실제 CRSF=9를 덮어쓸 수 있음|
|P2|POWER|읽기 실패 완료도 CONNECTED / READY; battery writer 미차단|캐시/초기 배터리·프로필 용량을 27바이트 설정으로 쓸 수 있음|
|P2|GYRO|Feature/filter/custom axis 읽기가 모두 실패해도 CONNECTED / EXPERT 표시|읽지 못한 기능/필터를 이전 값으로 편집할 수 있음|
|P2|BEEPER|읽기 실패 후 tone 수정 허용|tone 수정이 기본 beep mask=0와 digital mask=0도 전송|
|P2|BLACKBOX|두 읽기 모두 실패해도 CONNECTED; 설정 편집 허용|분모만 바꿔도 기본 Logging Device NONE 등 전체 설정을 전송|

P1은 수신기·연결 또는 무관한 설정을 직접 바꿀 수 있는 경로를 우선 표시한 것입니다. P2도 읽기 실패 상태에서는 기본값 재전송을 유발할 수 있어 수정 대상입니다.

## 구분해서 확인한 사항

- 기존 MOTOR는 SAVE에서 모터(222), 공통 Feature(37), ESC 텔레메트리(216)를 무조건 재전송했습니다. 오래된 Feature 캐시가 RX_SERIAL/TELEMETRY를 지우는 현상을 이전 코드에서 재현했습니다.
- 0.7.119 모터 수정 후보는 모터/기어비만 저장할 때 37·216·수신기45·CRSF74를 보내지 않는 검사를 통과했습니다. RPM 센서를 명시적으로 바꿀 때만 최신 Feature를 읽어 bit30만 병합합니다. 읽기 오류·짧은 응답·쓰기 거절 시 EEPROM 저장을 막는 검사도 통과했습니다.
- PROFILE의 PID 값 변경은 PID API만, 목표 headspeed 변경은 해당 governor profile API만 호출했습니다. PROFILE SAVE는 EEPROM만 요청하여 다른 프로필 그룹을 재전송하지 않는 양성 대조를 통과했습니다.
- MODES/ADJUSTMENTS는 변경 슬롯만 보내는 구조가 있으며, BATTERY/RPM·카탈로그 참조는 FC를 쓰지 않는 기존 회귀를 유지했습니다. SERVOS/MIXER의 일부 읽기 실패·override 정리·명시 저장 회귀도 통과했습니다. 이는 해당 메뉴의 전 범위 무결성 인증은 아닙니다.
- EEPROM 명령 250은 FC의 현재 변경 상태 전체를 영구 저장합니다. 다른 메뉴에서 이미 라이브로 변경해 놓은 값까지 함께 저장되는 현상과, 이번에 발견한 불필요한 설정 재전송은 별개입니다.

## 추가 검증·수정이 필요한 순서

1. 모든 공통 Feature writer를 최신 읽기 + 명시적으로 바꾼 비트만 병합하는 방식으로 통일.
2. 그룹별 읽기 성공·원본 스냅샷·dirty 상태를 분리하고, 실패·부분 응답일 때 해당 그룹 쓰기 금지.
3. FAILSAFE의 pulse range처럼 다른 화면과 공유하는 RX_CONFIG는 최신 원본을 읽어 해당 필드만 병합.
4. API 버전별 페이로드 길이, 재접속·지연 응답·화면 이동·동시 외부 변경을 검사.
5. FC 설정 dump 전후 비교와 전원 재인가 후 CRSF 재연결을 실물에서 확인.

GOVERNOR, 프로필 전환 중 지연 응답, 직렬 포트 전체 설정, 모든 MSP API 버전의 부분 패킷에 대한 전수 동적 검증은 아직 남아 있습니다. 검토 중 근거가 확인되지 않은 항목은 정상으로 판정하지 않았습니다.

## 재현 파일

- audit-all-save-paths.lua / audit-all-save-paths.cjs: 감사 전용 fault injection. FC 연결이나 실물 쓰기 없음.
- test-motor-save-isolation-07119.lua: 모터 수정 후보의 보존/오류 차단 회귀.
- output/all-save-audit.log: 9개 문제와 1개 양성 대조 결과.
- output/SAVE-PATH-AUDIT-2026-10-25.json: 소스 SHA256·메뉴 범위·구조화 결과.
