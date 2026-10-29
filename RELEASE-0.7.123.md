# RFLUASETUP 0.7.123 BETA

## English

Easy Setup servo center saves now verify the selected S1–S3 configuration before EEPROM and again afterwards. Persistent mismatches show the servo, field and expected/actual values instead of reporting verified success. Read retries do not resend writes. Untouched fresh configuration fields and direction/geometry bits are preserved.

Board alignment and ACC Trim require acknowledged writes and exact pre/post-save readback. Main Rotor Direction and Geometry also check before EEPROM. Includes the 0.7.122 STEAM catalogue: 20 brands / 586 entries, 478 manufacturer-documented, 3 dealer references and 105 manual entries.

The user reports the center-save behavior appears to work. This is preliminary feedback, not complete physical validation; the original hardware mismatch cause and FC firmware version remain unconfirmed. All 191 Lua files compile and simulated FC normal/failure/ARM/bit-preservation, host touch, Tail and Geometry regression tests pass. Nine separate Full Setup audit findings remain unresolved; see [current audit](docs/AUDIT-0.7.123.md) and [earlier Full Setup audit](docs/SAVE-PATH-AUDIT-2026-10-25.md).

Download the attached ZIP, copy the contents of SD-CARD to the radio SD card, and check that the footer says 0.7.123 BETA. See [installation](INSTALL-0.7.123.txt).

SHA256: `6230E0769405C5146F10F9DFF442724625793487910D07B0E7439385392D4659`

## 한국어

Easy Setup 서보 센터 저장 전에 실제 FC 값을 확인하고, EEPROM 저장 후에도 재검증합니다. 불일치가 계속되면 서보 번호·항목·예상값 → 실제값을 표시합니다. 읽기 재확인 과정에서 쓰기를 반복하지 않으며, 편집하지 않은 설정과 리버스/지오메트리 비트를 보존합니다.

보드 정렬·ACC Trim은 쓰기 성공 응답과 저장 전후 검증을 요구하며, 메인로터 방향·지오메트리에도 EEPROM 저장 전 검증을 추가했습니다. 0.7.122의 STEAM 자료를 포함합니다: 20개 제조사 / 586개 항목, 제조사 문서 478개·판매처 참고 3개·수동 입력 105개.

사용자로부터 센터 저장이 되는 것 같다는 초기 확인을 받았습니다. 전체 실물 검증을 완료했다는 뜻은 아니며, 원래 하드웨어 불일치 원인과 FC 펌웨어 버전은 미확정입니다. 191 Lua 문법 및 모의 FC의 정상/실패/ARM/리버스 보존, 실제 메인 호스트 터치 경로, 테일·지오메트리 회귀 검사는 통과했습니다. 기존 Full Setup의 별도 9개 감사 항목은 미해결입니다. [이번 검사 기록](docs/AUDIT-0.7.123.md)을 확인하세요.

첨부 ZIP의 SD-CARD 내용을 조종기 SD 카드에 복사하고 하단의 0.7.123 BETA를 확인하세요. [설치 안내](INSTALL-0.7.123.txt)
