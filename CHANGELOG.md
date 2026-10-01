# Changelog

## 0.6.91 BETA

- Multiple green trim targets can be selected independently of held red overrides. Tapping an enabled servo toggles only its trim selection, never disables or recenters it. All seven nonempty subsets use same-sign increments while preserving their existing relative offsets.
- OVERRIDE ALL enables missing S1-S3 and selects all three green, restoring normal grouped trim. Empty selection locks movement; ALL OFF releases. Axis modes and REAR Elevator correction remain unchanged.
- Mock tests cover seven subsets, selection/deselection without output reset, ALL return, distinct held offsets, queued movement, save including red-held outputs, group bounds, ARM/failure/RTN, actual main touch and default setup. Full Setup arrows and 147 Lua syntax checks pass; hardware validation remains required.

## 0.6.90 BETA

- Separate held overrides from the independent trim target. ALL ON holds S1-S3 red; selecting S1/S2/S3 makes only that target green. Selection/reselection never disables or re-centers an enabled servo; each commanded offset is retained and restored to the ruler when revisited.
- No movement from ALL ON until an individual target or AILERON/ELEVATOR mode is chosen. Axis modes retain existing grouped behavior and 0.6.89 REAR Elevator correction; entering them clears individual selection without resetting held positions.
- CENTER APPLY still previews and saves all enabled servos' actual outputs, including red held members. ALL OFF/RTN/reverse/save clear the temporary targets as before.
- Mock independent target/retained offset/reselection/coalescing/save/bounds/ARM/failure/offline and real-main touch tests pass, along with defaults, Full Setup arrows, receiver mapping and 147 Lua syntax checks. Physical radio/FC validation remains required.

## 0.6.89 BETA

- Correct REAR ELEVATOR TRIM signs: S1 +, S2/S3 - for an increasing ruler. FRONT stays S1 -, S2/S3 +. Negative ruler movement inverts these signs. Servo configuration Reverse bits, Aileron, defaults and normal trim behavior are unchanged.
- Explicit mock tests for positive/negative/neutral elevator movement in both mount orientations, no config/tail writes, real-main REAR touch route and existing safety/default/Full Setup regressions pass. 147 Lua syntax checks pass. Hardware tilt validation remains required.

## 0.6.88 BETA

- New item 1: SWASH SERVO DEFAULT SETUP, with draft-only Pulse, Rate/Speed, independent Reverse and Limits/Geo tabs. 1520 preset: center 1520, -700/+700, scales 500/500, Geo ON, rate 333. 760 preset: center 760, -350/+350, scales 250/250, rate 333; retain Geo state. Speed and reverse are retained until explicitly edited.
- Rate choices 50/100/200/250/333/560 Hz plus custom keypad entry. Speed, limits and scales are manually editable for S1-S3. These choices do not certify servo compatibility.
- Explicit overwrite warning and S1-S3 value table before applying. Only CONFIRM & SAVE releases overrides, refreshes configs, checks DISARM, writes S1-S3, saves and verifies. No draft writes; S4 untouched. Existing disconnect RTN timeout also covers defaults.
- Item 2: SERVO REVERSE SETUP / SERVO CENTER PULSE TRIM; right-side CUSTOM FINE SERVO SETUP opens existing Full Setup Servos and returns to this submenu.
- Normal/Reverse buttons sit at swash spoke midpoints. FRONT/REAR choice includes miniature swashes and red nose arrows; the large swash also shows HELI FRONT independently of S1 placement.
- Mock preset/confirmation/manual keypad/all-rate/flags/ARM/failure/offline tests and prior Full Setup/receiver regressions pass; 147 Lua files pass syntax checks. No hardware validation.

## 0.6.87 BETA

- Renamed submenu and screen to SERVO CENTER PULSE TRIM.
- Require explicit FRONT/REAR choice on every entry. The selection page issues no override commands; RTN cancels to the submenu. Selected mounting controls the initial diagram and existing Aileron sign mapping.
- Reorganized each servo into separate selection, live pulse and direction rows. Full Reverse/Normal labels use the small font. Kept red active AILERON TRIM/ELEVATOR TRIM buttons and left ALL controls, with dedicated spacing for green pulse values in both orientations.
- Tests cover mandatory choice, cancellation/no commands before choice, both orientation signs, pulse/action rectangle separation, confirmation and previous safety/Full Setup/receiver regressions. 147 Lua syntax checks pass. No hardware validation.

## 0.6.86 BETA

- Added left-side OVERRIDE ALL (S1-S3 only, existing positions held) and ALL OFF controls. Motion remains sequential acknowledged per-servo commands, unchanged from 0.6.85.
- Enlarged existing AILERON/ELEVATOR controls to AILERON TRIM / ELEVATOR TRIM, with full red active backgrounds and white text instead of tiny lamps. Modes remain mutually exclusive.
- Immediately schedule measured PWM refresh after individual/all override activation; green labels remain measured outputs, not estimates or saved centers.
- CENTER APPLY now previews selected actual PWM values and unchanged servos, then requires CONFIRM & SAVE. CANCEL retains the held output positions without saving; RTN releases and returns. Confirm rereads status/output; changed output values require renewed confirmation. Only confirmed centers are saved and verified.
- Tests cover actual main touch controls, confirmation/cancel/changed output, ALL ON/OFF and pending-move cancellation, group signs, partial failure/ARM/RTN, Full Setup arrows and mixer regression, receiver mapping and 147 Lua files. Hardware testing remains required.

## 0.6.85 BETA

- Fixed FULL SETUP / SERVOS / SERVO OVERRIDE left/right arrows and angle editor crashing with "attempt to index a function value". The mixer angle helper shadowed the servo angle table in later closures; renamed only the mixer helper and its call sites.
- Reproduced the original error in a negative-control test. Actual main.lua touch tests now pass for all four servo outputs, both arrows, zero crossing, numeric editor, slider endpoints/clamps and release, plus mixer arrows/editor. Center Trim 0.6.84 regressions and 147 Lua syntax checks pass. Physical radio/FC testing still required.

## 0.6.84 BETA

- Explicit mutually exclusive AILERON/ELEVATOR controls. Both hold all three servo overrides; Aileron moves only S2/S3 oppositely, Elevator moves S1 opposite S2/S3. Normal manual selection uses positive signs for every selected member.
- FRONT lateral signs are reversed from 0.6.83; REAR mirrors FRONT. Physical tilt direction requires bench validation with correctly set R/N and linkage.
- Green labels poll measured MSP_SERVO output (nominal 200 ms active, transport-dependent), hide stale values and never substitute requested angles for measured PWM. Latest input is coalesced and periodic work now runs during touch/roller events too.
- RTN waits at most three seconds for release/write responses. If the FC stops responding, clear the transport and pending motion, invalidate callbacks and return with RELEASE & SAVE NOT CONFIRMED. This is not confirmation of hardware release or saved configuration.
- Mocked axis/normal modes, live/stale output, partial enable failure, ARM guards, saves, offline exit during movement/read/write, stale callbacks and actual main touch/roller navigation tested. Hardware validation remains required.

## 0.6.83 BETA

- Added a new isolated Center Trim module. Easy item 3 opens a submenu containing 1. SERVO CENTER TRIM; the previous servo screen is no longer the entry point.
- Large swash diagram, red acknowledged-ON endpoints, per-servo S1/S2/S3 selection, current saved Centers, R/N controls, small Front/Rear control and a tall drag/roller ruler. Removed the old toolbar and PWM/arrow controls from this workflow.
- Group signs: single +; S1+S2 and S1+S3 +/+; S2+S3 +/-; all three -/+/+. Full group command batches are acknowledged in order and newer targets coalesce. Partial failures request global release.
- CENTER APPLY drains pending motion, checks DISARM, reads fresh actual PWM, releases overrides, updates only selected Centers, saves and verifies readback. R/N saves only the selected Reverse bit after release, retaining Geometry and other fields.
- RTN releases servo and mixer overrides before returning to the submenu. During writes it defers return until completion; failed releases keep the warning view open for retry.
- Simulated FC, real Lua touch/roller, all seven selection combinations, delayed/failure/ARM handling, scoped writes and 147-file Lua syntax tests pass. No physical radio/FC validation.

## 0.6.82 BETA

- Easy menu item 3 now opens a single SERVO / SWASH SETUP screen directly. Removed the 1/7 title, seven wizard tabs, BACK/NEXT stage navigation, Rate shortcut and Details shortcut from this screen.
- Expanded the compact swash, pulse picker, per-servo Override/Direction/Trim table and right ruler to use the available space. Center is a separate labeled row.
- Kept ALL ON, ALL OFF, APPLY & SAVE, RELOAD and return-to-menu controls. Retained acknowledged stop, draft/save verification, drag feedback and ARM/link checks; Full Setup is unchanged.
- Real Lua touch entry, both pulse presets, independent/ALL Override, ruler/arrow movement, exit, delayed commands and failure guards passed; 146 Lua files pass syntax checks. Hardware validation remains required.

## 0.6.81 BETA

- Added the approved compact left-side swash diagram, per-servo Override/Direction/Trim rows and right-side touch ruler in SWASH, SERVOS and TRIM. The other seven-step wizard functions are preserved.
- Override switches are independent; only acknowledged ON outputs have colored endpoints. Selected ON servo is orange. ALL remains scoped to S1-S3.
- Trim is a temporary Override command in 1-degree steps, not persistent servo trim or microseconds. Initial touch does not jump; drag values coalesce, and OFF servos cannot be adjusted.
- Optional 12 ms tone/haptic feedback is rate-limited and guarded for unavailable APIs. ARM/status polling takes priority over continuous drag commands.
- SERVO PULSE WIDTH offers 1520 us / 760 us. Confirmation updates all swash Center drafts; APPLY & SAVE/readback is required before testing. Center and actual selected PWM are labeled separately.
- Tested real Lua touch selection, presets, drag, independent toggles, all outputs, safety/failed replies and retained wizard functions; 146 Lua files pass syntax checks. No physical radio/FC validation.

## 0.6.80 BETA

- Replaced the Easy servo overview with SWASH > COLL DIR > SERVOS > TRIM > COLLECTIVE > CYCLIC > TAIL, with BACK/NEXT and per-stage apply/save.
- Added draft mixer direction, collective/cyclic calibration and limits, geometry correction, and standard S4 variable-pitch tail setup. Saves retain unrelated mixer fields and verify changed values by reading back.
- Distinguished draft Center from actual PWM. Tested the actual touch choice/confirmation path for 760/1520 on all three swash servos.
- Added explicit mixer axis tests, neutral ALL trim, acknowledged override release on navigation/save, and status polling while numeric dialogs are open.
- Preserved calibration direction signs and fractional values through the main numeric editor. Cyclic limit editing explicitly sets symmetric limits.
- Simulated FC, real Lua UI event tests, receiver mapping regression, syntax checks and 800x480 screen checks passed. No physical radio/FC or flight validation.


## 0.6.79 BETA

- Added one-tap, DISARM-checked OVERRIDE ALL for swash servos S1-S3 only. Selected-servo edits preserve other outputs and closing a popup retains ALL mode.
- ALL OFF, setup exit, save/reload and switching to Full Setup release overrides. Failed partial enable and status failures request global disable.
- Restored single-servo Override on S1/S2/S3 entry; settings remain available inside each popup.
- Placed Reverse switches at Y-arm midpoints, added actual output PWM beside each servo, and added the existing Full Setup Servo Override shortcut beside Elevator Front/Rear.
- Preserved receiver live mapping fix from 0.6.78; regression and Lua syntax checks passed. Hardware testing remains required.

## 0.6.78 BETA

- Fixed receiver live bars and stick preview using MSP_RC function order, with channel labels resolved through the FC map.
- Added Servo Select pulse presets and explicit Front S1 top / S2 right / S3 left layout.

## 0.6.77 BETA

- Fixed Easy Servo detail input stalls: periodic PWM/status reads no longer lock roller, touch or draft editing.
- Coalesced rapid Override edits to the latest target, without waiting for an extra PWM read on every step; close/switch invalidates pending targets.
- Avoided starting polls on input events and drawing swash geometry hidden behind the detail popup.
- Verified with deliberately delayed mock replies, rapid input and pending-close regression checks. Physical MK3/FC responsiveness is not yet verified.

## 0.6.76 BETA

- Follow-up: replaced the swash rectangle/connectors with one outer circle and three 120-degree radial lines, preserving FRONT/REAR orientation.
- Added SERVO Hz beside the swash type: displays the FC-read rate (or MIXED), confirms a shared Servo 1-3 draft rate, and writes only on final save.
- Enlarged the swash drawing and replaced detailed overview cards with S1/S2/S3 selectors. All servo details remain in their popups. Removed the 1520/760 overview controls without changing pulse settings.
- Selecting S1/S2/S3 automatically enables only that servo's Override at the existing protocol neutral value after a disarm check. Closing or switching waits for neutral/off acknowledgement.
- Replaced thin PWM arrow outlines with filled up/down triangles and placed editable Center immediately to the right of PWM, followed by SET CENTER. Swash lines use the existing filled-line renderer.
- PWM and Center values open numeric input. PWM uses freshly read FC center, travel, scales, reverse and geometry correction to convert the requested pulse into the existing Override command; displayed PWM remains actual FC feedback.

## 0.6.75 BETA

- Added Easy Setup step 3, SERVO / SWASH SETUP, based on 0.6.74.
- Grouped Servo 1-3 cards inside the swash diagram; tapping a card opens all settings in one popup.
- Added vertical up/down Override controls with live FC PWM displayed between the arrows.
- SET CENTER captures actual PWM into the draft, then neutralizes and disables Override.
- Center, limits, rate, Reverse, Geo and swash type stay local until REVIEW / APPLY & SAVE, even in auto-save mode.
- Added 1520/760 replacement warnings, single-servo Override switching, acknowledged stop before leaving, sequential save acknowledgement and read-back verification.
- FRONT/REAR is a diagram layout aid, not a change to mixer phase or output mapping.
- Verified using Lua compilation and a simulated FC; physical radio/servo testing remains required.


## 0.6.73 BETA

- Added EASY SETUP Step 2: Receiver Setup Check.
- Read-only verification of receiver protocol, telemetry state, sensor count, FC link, RSSI source, channel assignment, center and expected endpoints.
- Added live PWM bars for channels 1-8 with roller and touch scrolling.
- This guided page sends no receiver configuration writes and provides only REFRESH and BACK controls.
## 0.6.33 BETA

- Changed Adjustments reading to official Rotorflight 2.3 slot-by-slot `MSP_GET_ADJUSTMENT_RANGE` command 156.
- Reads each Adjustment as an exact 14-byte record to avoid corruption of Function and AUX values over a long telemetry response.
- Preserves FC slot order and sends only changed Adjustment slots on SAVE.
- Retains live AUX display for Modes and Adjustments.
- Includes the current Full Setup, Status, Setup, Configuration, Receiver, Failsafe, Power, Motors, Governor, Servos, Mixer, Gyro, Rates, Profiles, Modes, Adjustments, Beepers, Sensors and Blackbox work.

This release remains an unfinished BETA build intended for controlled evaluation.
