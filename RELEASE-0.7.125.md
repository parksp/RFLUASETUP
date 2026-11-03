# RFLUASETUP 0.7.125 BETA

## English

**Improved 3D helicopter model and faster graphics.** The attitude view now uses solid surfaces, native lines/triangles and cached model coordinates. In three test poses the model uses 45 drawing calls instead of 426–663 (89–93% fewer calls). The user reported a substantial responsiveness improvement on the transmitter; these percentages are drawing-call reductions, not measured radio FPS gains.

- Dedicated attitude polling avoids the previous five-telemetry request group in the 3D view.
- RESET Z AXIS now gives a straight rear view, like hovering with the tail toward the pilot and the nose ahead. Real Roll/Pitch movement is retained.
- Receiver channel bars target 100ms updates through their own RC read. RSSI/analog updates run separately at a one-second target interval.
- Easy Setup board, swash, rotor-direction, geometry and tail drawings use lighter native primitives or reusable drawing-command caches. The board illustration drops from 599 to 46 native drawing calls in the test fixture.
- Previous center-save verification and direction-bit preservation are retained.

Easy Setup is nearing completion and has received further updates. Users already familiar with Rotorflight should be able to get close to their intended helicopter setup through the current Easy Setup workflow.

All 193 Lua files compile. Receiver scheduling, rear-view RESET Z, drawing-cache replay, pose bounds and prior servo/save/tail/geometry regression checks pass. Hardware feedback is positive but is not a complete all-feature validation. Nine separate prior Full Setup audit findings remain unresolved; see [audit](docs/AUDIT-0.7.125.md).

Copy all SCRIPTS contents from SD-CARD, including the new fastGraphics.lua and attitudeHeli.lua. Check the footer says 0.7.125 BETA. [Installation](INSTALL-0.7.125.txt).

SHA256: `04CEA9D2B132BF01CBF939C7AE4F23046782FBD59E2989F7863C99BF1F991537`

## 한국어

**3D 헬기 모델 개선과 화면 속도 개선을 적용했습니다.** 동체·캐노피에 면을 넣고 native 선/삼각형과 좌표 재사용으로 그리기를 가볍게 했습니다. 세 가지 시험 자세에서 헬기 그리기 호출이 426~663회에서 45회로 줄었고, 사용자가 조종기에서 큰 반응 속도 개선을 확인했습니다. 호출 수 감소 비율은 실제 FPS 개선 비율을 뜻하지 않습니다.

- 3D 자세 화면은 자세값을 전용으로 읽습니다.
- RESET Z AXIS는 호버링할 때처럼 테일을 보는 정후방 시점으로 맞춥니다. 실제 롤·피치는 계속 따라갑니다.
- Receiver 채널 바는 0.1초 목표로 전용 조회하고, RSSI는 1초 목표로 따로 갱신합니다.
- Easy Setup 보드·스와쉬·로터 방향·지오메트리·테일 그림의 그리기를 최적화했습니다.
- 이전 서보 센터 저장 검증과 리버스 비트 보존을 유지합니다.

Easy Setup은 이제 거의 마무리 단계이며, 추가 업데이트를 적용했습니다. 기존 Rotorflight 사용자라면 현재 Easy Setup 흐름으로 원하는 기체 설정에 상당히 근접할 수 있을 것으로 기대합니다.

193 Lua 문법 및 Receiver 갱신, 정후방 시점, 그림 캐시, 자세 범위, 기존 저장·테일·지오메트리 회귀 검사를 통과했습니다. 사용자 실기 확인은 전체 기능 검증 완료를 뜻하지 않습니다. 기존 Full Setup의 별도 감사 문제 9개는 미해결이며 [검사 기록](docs/AUDIT-0.7.125.md)에 남겼습니다.

SD-CARD의 SCRIPTS 내용을 전체 복사하고 하단 0.7.125 BETA를 확인하세요. [설치 안내](INSTALL-0.7.125.txt).
