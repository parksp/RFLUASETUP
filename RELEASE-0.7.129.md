# RFLUASETUP 0.7.129 BETA — Swash Servo Fix

## 한국어
- Easy Setup·Center Trim에서 엘리베이터 앞/뒤 모두 S2 왼쪽·S3 오른쪽으로 표시합니다.
- 앞쪽 엘리베이터 배치의 에일러론 센터 트림 방향을 수정했습니다.
- 0.7.128 Preview 자세 유지, 연속 피치 회전, 느린 화면에서 멈춤 방지·수신 복구 수정이 포함됩니다.
- 기존 Center/Reverse/Limit 저장값은 자동 교환하지 않습니다.
- 사용자가 조종기에서 수정 동작을 확인했습니다. 전체 비행 검증은 미완료입니다.

## English
- Correct S2-left/S3-right diagrams and selection cards for front/rear elevator layouts in Easy Setup and Center Trim.
- Correct front-layout aileron center-trim signs; retain elevator trim behavior.
- Includes Preview pose hold, continuous pitch rotation, slow-frame freeze fix and recovery on fresh RC data.
- No automatic exchange of existing servo configuration values. User confirmed operation on a transmitter; full flight validation remains pending.

## Installation / 설치
Back up existing files. Copy the complete SCRIPTS folder inside SD-CARD to the transmitter SD card.
기존 파일을 백업하고 SD-CARD 안의 SCRIPTS 전체를 복사하세요. 하단 0.7.129 BETA를 확인하세요.
Disconnect motor power and check servo numbering, trim and gyro correction directions before flight.

## Validation
194 Lua syntax checks; simulated front/rear diagram and selection indices, AILERON/ELEVATOR override payloads, release and no implicit configuration saves; existing save/ARM/error/geometry/tail/receiver/Preview regressions passed.
