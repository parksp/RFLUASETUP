# RFLUASETUP

[한국어](#rfluasetup) · [English](#english)

RFLUASETUP은 Rotorflight Configurator 2.3.0의 메뉴 구성과 설정 방식을 분석하여 EdgeTX 조종기용 Lua 인터페이스로 구현한 프로젝트입니다. 가능한 한 많은 Configurator 기능을 PC 없이 조종기에서 확인하고 설정할 수 있도록 만드는 것이 목표입니다.

현재 버전은 **0.6.33 BETA**입니다. 비행장에서 PC가 없을 때 설정값과 상태를 확인하는 보조 용도가 적당합니다.
## 조종기 실제 화면 / Actual Radio Screens

아래 사진은 RadioMaster TX16S MK3에서 RFLUASETUP 0.6.33 BETA를 실행한 실제 화면입니다.

| 메인 화면 / Main screen | 3D 헬리콥터 자세 / 3D Helicopter Attitude |
|---|---|
| <img src="docs/images/radio-main-01.jpg" alt="RFLUASETUP main screen on TX16S MK3" width="520"> | <img src="docs/images/radio-3d-attitude.jpg" alt="Live 3D helicopter attitude screen on TX16S MK3" width="520"> |

| MIXER OVERRIDE EASY | FULL SETUP |
|---|---|
| <img src="docs/images/radio-mixer-override.jpg" alt="Mixer Override Easy screen" width="520"> | <img src="docs/images/radio-full-setup.jpg" alt="Full Setup menu" width="520"> |
## 설치 조건

현재 설치와 동작을 확인한 조건은 아래 조합으로 한정됩니다.

| 항목 | 현재 확인 조건 |
|---|---|
| 조종기 | RadioMaster TX16S MK3 |
| 조종기 운영체제 | 해당 조종기에서 현재 사용 중인 EdgeTX 환경 |
| FC | NEXUS Gyro |
| FC 펌웨어 | 현재 사용 중인 Rotorflight 4.6.x 계열 |
| 비교 기준 | Rotorflight Configurator 2.3.0 |
| 화면 | TX16S MK3의 800 × 480 컬러 터치 화면 기준 |
| 통신 | 수신기 텔레메트리를 통한 MSP 통신이 정상적으로 구성된 모델 |
| SD 카드 경로 | `/SCRIPTS/RFLUASETUP` |

다른 EdgeTX 조종기, 화면 크기, FC, 수신기, 텔레메트리 방식과 펌웨어 버전은 아직 검증하지 않았습니다. 조건이 다르면 화면 배치, MSP 데이터 읽기, 실시간 갱신 또는 저장 기능이 정상적으로 동작하지 않을 수 있습니다.

설치 전에는 PC용 Rotorflight Configurator에서 FC 설정을 `dump` 또는 `diff`로 백업해야 합니다. 조종기 Lua를 사용할 때는 PC Configurator의 FC 연결을 종료하는 것을 권장합니다.

## 검증 범위

- 사용자가 하루 동안 집중해 만든 초기 결과물입니다.
- 장기간 실제 운용이나 다양한 기체 조합의 검증은 아직 진행되지 않았습니다.
- 현재는 설정값을 변경했을 때 값이 FC에 정상적으로 전달되는 수준까지만 확인했습니다.
- 현재 검증 대상은 **RadioMaster TX16S MK3의 현재 EdgeTX 환경**과 **NEXUS Gyro의 현재 Rotorflight 4.6.x 펌웨어** 조합입니다.
- 다른 조종기, 화면 해상도, FC 및 펌웨어에서의 동작은 보장하지 않습니다.

실제 비행에 적용하기 전에 Rotorflight Configurator 2.3.0과 모든 값을 비교하고, 모터와 블레이드를 안전하게 분리한 상태에서 벤치 테스트를 진행하십시오. 사용과 설정 변경의 판단 및 책임은 사용자에게 있습니다.

## 설치

1. 최신 Release ZIP을 내려받습니다.
2. ZIP 안의 `SD-CARD/SCRIPTS` 폴더를 조종기 SD 카드 최상위에 복사합니다.
3. 최종 경로가 `/SCRIPTS/RFLUASETUP/main.lua`인지 확인합니다.
4. 기존 버전이 있다면 폴더 전체를 교체합니다. 서로 다른 버전의 파일을 섞지 마십시오.
5. EdgeTX를 재시작하고 시스템 또는 TOOLS 페이지에서 RFLUASETUP을 실행합니다.
6. 상단의 `FC LINK`와 하단의 `v0.6.33 BETA`를 확인합니다.

자세한 내용은 [한국어 설치 안내](설치방법.txt)와 [한국어 사용자 매뉴얼](docs/RFLUASETUP-0.6.33-한국어-사용자-매뉴얼.docx)을 참고하십시오.

## English

RFLUASETUP is an EdgeTX transmitter Lua interface developed from the menus and configuration workflow of Rotorflight Configurator 2.3.0. The goal is to make as much of the Configurator as practical available directly from the transmitter.

This is an unfinished **0.6.33 BETA** build created through one day of focused development. Testing has so far confirmed only that edited values can be transferred to the FC. It is best suited for checking settings and status at the flying field when a PC is unavailable.

The current test target is RadioMaster TX16S MK3 with its current EdgeTX environment and NEXUS Gyro with the currently used Rotorflight 4.6.x firmware. Other hardware and firmware combinations are not guaranteed.
### Installation Requirements

- RadioMaster TX16S MK3
- The currently tested EdgeTX environment on that transmitter
- NEXUS Gyro
- The currently tested Rotorflight 4.6.x firmware
- Rotorflight Configurator 2.3.0 as the comparison reference
- Working receiver telemetry and MSP communication
- Installation path `/SCRIPTS/RFLUASETUP`

Other transmitters, display sizes, FCs, receivers, telemetry protocols, and firmware versions remain unverified. Back up the FC with `dump` or `diff` before installation and close the PC Configurator connection while using the transmitter Lua tool.

See [English installation](INSTALL-EN.txt) and the [English user manual](docs/RFLUASETUP-0.6.33-English-User-Manual.docx).

## Main Areas

- Status and live receiver channels
- Setup and Configuration
- Receiver, telemetry sensors, Failsafe and Power
- Motors, RPM gear ratio and motor override
- Governor and bypass curve
- Servos and Mixer
- Gyro, Rates and PID Profiles
- Modes and Adjustments
- Beepers, Sensors and Blackbox

## Collaboration

Bug reports, test results, translations and code improvements are welcome. Read [CONTRIBUTING.md](CONTRIBUTING.md) before submitting an issue or pull request.

## Credits

Created by **BLADE PARK**. This independent Lua project is based on the behavior and public source of Rotorflight Configurator and Rotorflight firmware. Rotorflight names, logos and upstream source remain the property of their respective owners and contributors.

## License

Released under the GNU General Public License v3.0. See [LICENSE](LICENSE).



