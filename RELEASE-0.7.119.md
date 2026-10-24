# 0.7.119 BETA — motor save isolation candidate

2026-10-25

모터/기어비 저장 시 무관한 FEATURE·ESC 설정을 재전송하지 않도록 수정한 후보입니다. RPM 센서를 명시적으로 변경할 때 최신 FEATURE를 읽어 bit30만 병합하며 읽기·쓰기 실패 시 저장을 차단합니다.

전체 저장 경로 감사에서 GYRO, CONFIGURATION, RECEIVER, FAILSAFE, POWER, BEEPER, BLACKBOX의 9개 문제를 재현했습니다. 해당 메뉴의 수정은 아직 포함하지 않았습니다. 여러 FC 교체·재연결 시 캐시 처리와 실물 FC 검증은 남아 있습니다. 전체 수정 완료 또는 비행 준비 완료 버전이 아닙니다.

Includes the 572-entry catalogue (468 verified / 104 unverified), Easy Setup motor menu and governor RPM reference from 0.7.118. Motor-only save avoids unrelated FEATURE/ESC writes. Explicit RPM sensor edits merge only bit30 into freshly read FEATURE data; read/write failures block persistence.

Known unresolved findings: see [save-path audit](docs/SAVE-PATH-AUDIT-2026-10-25.md). Other menu fixes are not included. Multi-FC reconnect behavior and hardware validation remain incomplete.

Validation: 190 Lua compilation checks, 1,896 profile checks, 312 rendered screens and motor isolation failure regressions passed. Audit reproduced nine fault cases and one positive control using simulated FC responses; no hardware writes performed.
