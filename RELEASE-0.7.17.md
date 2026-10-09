# RFLUASETUP 0.7.17 BETA

## 설치

`SD-CARD/SCRIPTS/RFLUASETUP` 폴더를 송신기 SD 카드의 같은 위치에 덮어씁니다. 화면 하단에서 `0.7.17 BETA`를 확인합니다.

## 변경 사항

- Easy Setup → Servo / Swash Setup에 Main Rotor / Swash Direction과 Main Rotor Geometry 추가.
- Geometry에서 Cyclic Roll, Cyclic Elevator, Collective 및 Swash Trim 설정. 선택한 축의 각도만 조정하며 다른 축의 설정은 유지.
- 고정 rear view, 우측을 향한 elevator 측면 그림, 피치 게이지 및 +12° / 0° / -12° 버튼.
- 공통 Override ON/OFF, 헤더 Apply & Save, 큰 우측 게이지.
- 값 오른쪽 버튼으로 조정 단위 0.1 / 1 / 10 선택.
- 항목 선택 후 스크롤로 즉시 값 조정. 선택된 항목을 다시 클릭하면 수동 입력창 열기.
- Calibration은 FC RAM에 적용하고 Apply & Save에서 EEPROM 저장 및 읽기 검증.
- Full Setup 메뉴를 5열로 표시하고 Power 다음 Motors / Governor / Servos 배치.
- MSP 입력 읽기 호환 처리와 빠른 변경값 병합. 다른 명령의 늦은 오류 응답이 현재 요청을 실패시키던 통신 큐 오류 수정.

## 검증

Lua 모듈과 실제 main 메뉴 경로를 대상으로 축 독립성, 스크롤/터치 입력, 조정 단위, 지연 응답, 저장/종료 및 통신 큐 오류 응답 매칭 테스트 통과. 실제 FC/송신기 연결 검증은 별도로 필요합니다.
