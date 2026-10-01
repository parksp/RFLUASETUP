# 0.6.88 — 스와쉬 서보 기본 설정 / 리버스·센터 트림

SD카드와 FC 설정을 먼저 백업하고 SD-CARD 내용물을 카드 루트에 복사하세요. Easy Setup의 3. SERVO / SWASH SETUP으로 진입합니다.

**펄스폭·주파수 설정은 서보를 연결하기 전에 제조사 사양과 대조하세요. 모터 연결을 분리하고 블레이드를 제거한 상태에서 시험하세요. 실제 기체 검증은 아직입니다.**

## 메뉴

1. SWASH SERVO DEFAULT SETUP: S1/S2/S3 공통 기본 설정.
2. SERVO REVERSE SETUP / SERVO CENTER PULSE TRIM: 기존 트림 기능. 긴 제목은 두 줄로 표시합니다.

2번 오른쪽 CUSTOM FINE SERVO SETUP은 기존 FULL SETUP → SERVOS를 엽니다. 이 바로가기에서 RTN을 누르면 현재 하위 메뉴로 돌아옵니다. Full Setup 자체의 기존 저장 방식은 바꾸지 않았습니다.

## 1번 기본 설정

실제 설정을 읽어 초안으로 보여줍니다. 버튼 선택이나 숫자 입력만으로 FC 값을 쓰지 않습니다.

| 선택 | Center | Min | Max | Scale Neg | Scale Pos | Rate | Geo |
|---|---:|---:|---:|---:|---:|---:|---|
| 1520 | 1520 | -700 | 700 | 500 | 500 | 333 Hz | ON |
| 760 | 760 | -350 | 350 | 250 | 250 | 333 Hz | 현재 초안 유지 |

두 프리셋 모두 Speed와 각 서보의 Reverse 상태는 유지합니다. 펄스를 다시 선택하면 해당 표의 기본값도 다시 들어가므로 이후 필요한 항목을 수정하세요.

- 1. PULSE: 1520/760 선택.
- 2. RATE / SPEED: 50, 100, 200, 250, 333, 560 Hz 목록. Custom Rate로 원하는 값을 숫자 키패드에서 직접 입력할 수 있습니다. Speed(ms)도 직접 입력 가능합니다. 선택/입력은 S1/S2/S3 모두에 적용됩니다.
- 3. REVERSE: S1/S2/S3의 Normal/Reverse를 각각 선택합니다.
- 4. LIMITS / GEO: Min/Max/Scale Neg/Scale Pos를 직접 입력합니다. 세 서보의 Geo 상태도 바꿀 수 있습니다. 공통값을 입력하면 세 서보가 동일하게 변경됩니다.

숫자 입력은 기존 편집기의 허용 범위에서 가능합니다. 이 범위는 FC 데이터 범위이지 모든 서보에서 안전한 범위라는 뜻이 아닙니다. 서보별 개별 수치가 필요하면 CUSTOM FINE SERVO SETUP을 사용하세요.

333 Hz는 요청하신 초깃값이며 자동 호환성 판단이 아닙니다. 목록 중 높은 숫자를 무조건 선택하지 마세요. 실제 허용 Hz, 전압, 펄스폭을 제조사 사양과 대조하세요. FC 타이머 공유 및 펄스 길이 때문에 실제 가능한 출력 주파수도 제한될 수 있습니다. Rate 변경 후 재시작 필요 여부는 해당 FC/펌웨어 지침을 따르세요.

## 저장 경고 / 확인

REVIEW & SAVE S1-S3를 누르면 다음 경고와 3개 서보의 적용 예정값이 표시됩니다.

`WARNING: CURRENT SAVED VALUES WILL BE CHANGED.`

뜻: **현재 저장된 값이 변경됩니다.**

- CANCEL: 초안으로 돌아가며 FC에는 쓰지 않습니다.
- CONFIRM & SAVE: Override 해제, 최신 설정 읽기와 DISARM 확인 후 S1/S2/S3만 기록하고 EEPROM 저장·재조회 검증합니다. S4 꼬리 설정은 변경하지 않습니다.
- RTN: 저장 전에는 초안을 버리고 돌아갑니다. 저장 중에는 완료 후 복귀하되, 응답 단절 시 최대 3초 뒤 미확인 경고와 함께 화면을 빠져나옵니다.

`DEFAULTS SAVED / VERIFIED`만 정상 저장 완료입니다. 실패·단절이면 일부 설정만 반영됐을 수 있으니 성공으로 간주하지 말고 재조회하세요. 해제는 전원 차단이 아닌 정상 FC 제어 복귀입니다.

## 2번 트림 화면

FRONT/REAR 선택 때 작은 스와쉬와 기수 방향 화살표를 표시합니다. 큰 스와쉬의 빨간 HELI FRONT 화살표도 항상 위쪽입니다. S1은 FRONT에서 위쪽, REAR에서 아래쪽입니다. Normal/Reverse 버튼은 각 선 중앙에 배치했습니다.

기존 ALL ON/OFF, AILERON/ELEVATOR TRIM, 현재 출력 펄스 표시, CENTER APPLY 확인창과 RTN 안전 처리는 유지합니다. 개별 서보 순차 전송 방식은 변경하지 않았습니다. 기본 동작 주의사항은 CENTER-TRIM-0.6.86.md를 참고하세요.

## 검증 및 참고

모의 FC에서 두 프리셋, 모든 Hz 목록, 직접 키패드 입력, 초안 무저장, 취소/확인·선택 범위 저장, S4 보존, Reverse/Geo, ARM/쓰기 실패, 단절 RTN, 기존 Full Setup 및 리시버 회귀를 검사했습니다. 147개 Lua 문법 검사 및 800×480 렌더 확인. 실기 검증은 미실시입니다.

- Rotorflight 공식 초기값과 보정 안내: https://rotorflight.org/docs/setup/setup-servos
- 제조사 예시 333 Hz: https://www.savoxusa.com/products/savsb2263mg-ce-ryan-cavalieri-edition-low
- 제조사 예시 760 us / 560 Hz 스와쉬 서보: https://www.mksservosusa.com/product.php?productid=366

760의 250/250은 공식 초기값입니다. 실제 각도를 측정한 Scale 보정 및 기계적 간섭 확인을 대신하지 않습니다. Geo 사용 시에도 센터와 실제 각도 보정이 필요합니다.
