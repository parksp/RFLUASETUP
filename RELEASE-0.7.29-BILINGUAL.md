# RFLUASETUP 0.7.29 BETA

## 한국어

Easy Setup에 메인로터 Geometry와 전용 Tail Setup을 추가하고, 설정값 읽기·응답 속도·미저장 복원을 개선했습니다.

- Tail Setup: 서보 테일과 모터 테일 설정, 전용 기본값 메뉴, 타입·방향·센터 트림·Yaw calibration·CW/CCW 한계값 편집.
- 테일 그림과 수평 오버라이드 슬라이더, CW/CENTER/CCW 및 ±22° 버튼. OFF 상태의 PWM 표시와 추적 애니메이션 제거.
- 숫자 선택 후 스크롤 조정, 재터치 또는 길게 눌러 수동 입력, 1/10/0.1 조정 단위.
- 테일 오버라이드는 확인창 없이 한 번 눌러 ON/OFF. FC DISARM 검사는 유지.
- 슬라이더를 놓을 때 좌표가 초기화되어 음수 끝점으로 튀는 경로 수정. 마지막 터치·드래그값을 유지하며 TAP도 지원.
- Geometry와 테일의 실시간 수치 변경은 FC RAM에 임시 적용. 영구 저장은 명시적인 APPLY & SAVE에서 수행.
- Geometry는 저장 없이 RETURN하면 편집 전 값으로 복원하고 재확인한 뒤 종료. 테일은 RETURN → DISCARD에서 미저장 수치 복원.
- 다른 방향·한계값을 보존하는 최신 데이터 병합과 저장·복원 읽기 검증. 외부 변경 충돌이나 복원 통신 실패 시 오류 표시.
- 입력 읽기 호환 처리, 대기 중인 최신값 병합, 같은 화면 프레임의 요청 처리 및 LCD 선 그리기를 개선.

ZIP의 `SD-CARD/SCRIPTS/RFLUASETUP` 폴더로 송신기의 `/SCRIPTS/RFLUASETUP` 전체를 교체하고 하단의 `0.7.29 BETA`를 확인하십시오.

모의 FC·터치·저장·복원·방향 보존·오류 처리 회귀 검사 및 150개 Lua 문법 검사 통과. 실기 전체 검증은 미완료이며 Easy Setup은 개발 중입니다. 통신 단절·스크립트 강제 종료는 복원을 완료하지 못할 수 있습니다. 일부 실기 MSP43 오류는 추가 확인이 필요합니다.

## English

This release adds Main Rotor Geometry and dedicated Tail Setup to Easy Setup, with improved input reads, response time and restoration of unsaved live edits.

- Servo and motor tail settings, dedicated defaults, type/direction/center trim/yaw calibration/CW and CCW limits.
- Tail illustration, horizontal override slider, CW/CENTER/CCW and ±22° presets. No PWM tracking while override is OFF.
- Select a numeric field and turn the roller; touch again or hold for direct entry. Steps: 1, 10 and 0.1.
- Single-press Tail override ON/OFF without an enable confirmation; FC disarm checks remain.
- Slider release retains the last pressed/dragged target instead of processing reset release coordinates. TAP events are supported.
- Live numeric edits affect FC RAM; explicit APPLY & SAVE persists settings.
- Geometry RETURN restores unsaved edited values and verifies before leaving. Tail RETURN → DISCARD restores unsaved live edits.
- Fresh-data merges preserve unrelated directions and limits; external conflicts or failed restores are reported.
- Improved compatible mixer input reads, latest-target coalescing, same-frame queue dispatch and native LCD lines.

Replace the entire transmitter `/SCRIPTS/RFLUASETUP` folder with `SD-CARD/SCRIPTS/RFLUASETUP` from the ZIP. Check `0.7.29 BETA` in the footer.

Simulated FC, touch, save/restore, direction-preservation and error regressions pass; all 150 Lua files compile. Physical validation remains incomplete. Forced termination or lost communication can prevent restoration. Reported physical MSP43 errors still require investigation.

ZIP SHA256: `424E4A3FB9521BD27233B753C8E0BE82643A4122E8DCBF9763144663DC299E0E`
