# 0.7.129 local validation

Based on 0.7.128. Changed SD files:
- RFLUASETUP\main.lua
- RFLUASETUP\PAGESX\centerTrim.lua
- RFLUASETUP\PAGESX\easyServo.lua

Passed: front/rear Easy Setup and mounting diagrams; Center Trim hitbox indices; actual simulated MSP override payloads for AILERON/ELEVATOR; release; no implicit config or EEPROM writes.
Passed existing servo-save verification, ARM/error handling, geometry/tail/receiver/host regressions, slow pitch/Preview recovery and all 194 Lua syntax checks.
Physical transmitter/FC validation remains pending. No GitHub upload performed.
