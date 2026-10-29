# 0.7.123 — Easy Setup save verification

Date: 2026-10-29 KST. Baseline: local 0.7.122 STEAM OPTIONS. User confirmed radio version 0.7.122; FC firmware version not supplied. No physical radio/FC was connected to these tests.

## What the reported message means

`SAVED / VERIFY MISMATCH / RTN TO RETRY` was emitted after command 250 acknowledged and command 120 returned a different requested field. It is not evidence that nothing was saved. The old code persisted before checking RAM and did not identify the mismatch. The exact reason for the user's hardware discrepancy has not been established. Plausible categories (not diagnoses): FC normalization, a stale transport reply, and a firmware/layout incompatibility.

## Changes

- Center/default/direction saves now fresh-merge explicit patches, check DISARM, write selected S1–S3, read back all eight fields of each affected servo before EEPROM, recheck DISARM, issue EEPROM, and verify again. Full-block verification detects unexpected changes to limits/rates/flags too.
- Verification may retry reads up to three times, with isolated receive buffers and a short reply-settle delay. Writes are not retried by this verification loop. Persistent mismatches remain failures and show `S<number> field: expected -> actual` in the footer. Post-save mismatch never reports verified success.
- `mspServos` explicitly resets the read cursor and isolates command 120/212 responses. Callback-protected servo writes have one send attempt; timeout becomes an explicit failure rather than automatic write replay.
- Defaults write only fields changed from the opened draft, preserving unrelated fields changed since the draft opened. Explicit reverse changes merge bit 0 only. Existing direction/geometry protection remains enabled.
- Board alignment and ACC Trim now require DISARM, acknowledged write, exact pre-EEPROM readback, another DISARM check, EEPROM ACK and post-save readback. Short reads, refused writes, ARM, mismatches, timeouts and duplicate button presses cannot produce a verified-success state. Main UI navigation/input is held while these bounded transactions run.
- Main Rotor Direction, Geometry and the legacy Easy Servo wizard now verify before EEPROM as well as afterwards. Tail already had pre/post verification and its existing regression passes. Easy motor uses the existing 0.7.119 isolation changes; receiver remains read-only and accelerometer calibration remains a distinct explicit action.

## Verification

- `node test-servo-save-07123.cjs`: ALL center save, all 191 Lua files compile, pre/post mismatch distinction, no EEPROM on preverify mismatch, diagnostic field/value, stale read retry without duplicate writes, write/EEPROM refusal, fresh defaults merge, direction and geometry flags, ARM, reused receive-buffer cursor.
- `node test-easy-save-07123.cjs`: alignment/ACC Trim ACK order, duplicate guard, exact pre/post readback, write/read/EEPROM failure, normalization and ARM.
- `node test-current-integration-07123.cjs`: current main.lua host touch path through Easy Servo > mount > ALL > roller > center review > confirm > verified save > return; Geometry navigation.
- `node test-rotor-save-07123.cjs`: Main Rotor pre/post mismatch, rejected write, ARM; Geometry normal save and pre-EEPROM mismatch.
- `node test-regressions-07123.cjs`: existing Tail fresh-merge/failure/direction/override guards and Geometry live/rollback/transport/sign/calibration regressions.
- Test fixtures simulate MSP; they do not prove EEPROM retention across a real power cycle, mechanical centering, servo timing or compatibility with an unspecified firmware version.

## Remaining audit scope

This is an Easy Setup save-path repair, not a full firmware or all-menu certification. The previous Full Setup audit (`write-save-path-audit.py`, `audit-all-save-paths.lua`) recorded nine separate findings: stale full Feature masks in Gyro/Configuration/Receiver, false ready states on failed reads in Receiver/Power/Gyro, a cached RX provider write from Failsafe, and failed-read writes in Beeper/Blackbox. Those Full Setup findings were not changed in this patch and must not be represented as fixed. The earlier motor isolation repair and catalog data are preserved.

`NOT SAVED` means this operation did not send EEPROM; RAM may already contain temporary writes. An EEPROM ACK followed by a RAM readback cannot independently prove durable storage; check with PC and a controlled reboot when safe. Do not silently accept an FC-adjusted value or issue automatic compensating writes that could change a direction or unrelated setting.
