# Fast 3D Attitude comparison — 2026-11-03 KST

Baseline: local/published 0.7.123. Candidate: 0.7.124 BETA. No physical transmitter or FC was used. This candidate has not been published to GitHub.

The comparison reference is the EdgeTX RFSuite Alignment source at commit `e732396220c99918b3524f977d034d8fd441746f`:
https://github.com/rotorflight/rotorflight-lua-edgetx-suite/blob/e732396220c99918b3524f977d034d8fd441746f/src/rfsuite/app/pages/setup/alignment/page.lua
It requests attitude every 0.25 seconds, reuses scene tables and applies a 0.3-degree Roll/Pitch deadband. The new mesh here was independently constructed; the retained LVGL UI architecture was not copied or added to this classic EdgeTX tool.

## Implemented

- `statusAttitude` and `configuration3d` request only MSP_ATTITUDE 108, retaining the existing nominal 0.2-second scheduling and original units/signs. No status/RX/analog/altitude reads are added by those screens. Other status/instrument/receiver pages retain the existing multi-telemetry group. One old group may finish when transitioning from another page.
- One attitude read can be pending. Busy/queued transactions are respected. This request has one send attempt and a 1.2-second reply timeout, avoiding write-path interference or an unbounded live-read queue. Exact six-byte payload/byte validation preserves prior valid values on malformed replies. Header distinguishes LIVE, stale data after one second, and read/data errors. RESET Z remains a local display offset and sends no writes.
- Independently constructed solid helicopter with canopy panels, frame, tapered boom, fin, tail rotor, skids, mast and fixed rotor blades. Triangle/line primitives are depth sorted. Native LCD lines replace dotted rectangles; native filled triangles add shaded surfaces. When filled triangles are unavailable the mesh falls back to native wire edges.
- Model, projection and drawing-order tables are built once and reused. Reproject/sort only when Roll/Pitch moves more than 0.3 degrees relative to the last drawn pose, Yaw changes, view offset changes, or viewport changes. Readout values remain raw received data. There is no synthetic attitude interpolation or rotor animation.
- All calls retain native EdgeTX signatures: drawLine has six arguments, drawFilledTriangle seven. Filled triangles are documented for color EdgeTX since 2.4:
https://luadoc.edgetx.org/latest/api-reference/display-lcd/lcd-draw-filled-triangle/
- Shared new renderer also appears in the receiver stick preview and Configuration 3D display. Configuration's smaller viewport uses a reduced scale to keep the mesh inside the card. Easy mounting-direction illustration remains unchanged.

## Measurements and checks

| Test pose (Roll, Pitch, Yaw) | Old rectangle calls | New line + triangle calls | Reduction |
|---|---:|---:|---:|
| 0, 0, 0 | 426 | 45 | 89.4% |
| 20, 15, 35 | 498 | 45 | 91.0% |
| -45, 30, 90 | 663 | 45 | 93.2% |

Counts cover the helicopter alone, excluding page labels/cards/buttons, under the native filled-triangle path. This is a Lua drawing-call comparison, not a radio frame-time/FPS/latency measurement. GPU/firmware rendering cost, serial response time and the radio's Lua scheduling still determine real performance. The classic screen still redraws its background and controls; it does not adopt RFSuite's retained UI object system.

- `node test-fast-attitude-07124.cjs`: above counts, unchanged scene reused over 200 draws, deadband/Yaw/Z changes, 1,521 compound rotations within main viewport, wire fallback, one read-only request, original units/signs, queue/short/error/stale guards, all 192 Lua files compile. Six preview PNGs are rendered from the actual old/new renderer primitives.
- `node test-host-attitude-07124.cjs`: real main.lua menu entry, attitude-only commands, native LCD signatures, displayed units/signs, RESET Z, Back, ordinary status telemetry restored.
- `node test-regression-07124.cjs`: 0.7.123 servo ALL/center/default/direction/failure checks, board/ACC save gates, current host touch save, Tail and Geometry regression suites pass against 0.7.124 sources.

Only main.lua and the new PAGESX/attitudeHeli.lua differ in runtime source from 0.7.123. EEPROM/servo/mixer write logic and catalogue data are unchanged. The earlier nine separate Full Setup audit findings remain unresolved. Test actual responsiveness on the same transmitter/receiver/FC link before calling this hardware validated.
