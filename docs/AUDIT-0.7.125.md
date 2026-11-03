# 0.7.125 — setup graphics, receiver response, rear camera

Date: 2026-11-03 KST. Baseline 0.7.124 was reported much faster on the user's radio. The user subsequently reported faster operation with 0.7.125; this is preliminary feedback, not a complete hardware benchmark or all-feature validation. GitHub publication: 2026-11-04.

## Graphics changes

- Retains the 0.7.124 fast native solid attitude mesh. RESET Z now also sets the camera yaw to pi, giving a straight rear view with the tail toward the observer and the nose ahead. The model's elevation projection was corrected to a slight view from above rather than below. Roll/Pitch are not zeroed, FC attitude is not rewritten, and the action still sends no MSP write. The optional camera argument is part of the mesh's projection-cache key.
- Board mounting illustration replaces dotted rectangles with native thick line quads (two filled triangles), native circles where pixel scaling permits, and native line fallback. Its actual primitive-call count on an 800x480 mock is 599 -> 46 (92.3% reduction). This excludes labels and the rest of the page. It is not a measured FPS or latency ratio.
- Servo center uses a native circle for the 64-segment ring and native filled circles for the three dots. Mini swash mounting diagrams also use native circles. Unequal horizontal/vertical scaling and unavailable filled-circle APIs retain line/scanline fallback.
- New optional `fastGraphics.lua` attaches picture-command caching and precomputed ellipse samples to the real center, tail, direction and geometry hosts. Geometry, Tail, main-rotor direction diagrams and swash options replay cached drawing commands while their relevant inputs are unchanged. Changing geometry axis/override/angle/view/trim, tail mode/override/target, or diagram selection invalidates the corresponding entry. Each ID stores only its latest entry, not a growing history of slider values.
- Cache records only drawing functions. Buttons, controls, hitboxes, input handling, telemetry and configuration writes are never recorded. Host functions are restored after errors. Nested native fallbacks record only the outer operation to prevent replaying both an operation and its children. Geometry's transformed ellipses also reuse unit-circle samples and hoist tilt trig out of the vertex loop.
- These setup illustrations remain guides to requested servo/pitch movement, not a new measurement of physical blade angle. Easy mounting drawing remains a mounting guide; live FC attitude still appears in its separate Live/3D view.

## Receiver

`receiver`, `receiverPreview` and `easyReceiver` route their fast updates to MSP_RC 105 rather than the five-read status group. Target period is 0.1 seconds, one pending request, bounded single-attempt reply wait. Channel table is updated in place, original function-ordered RC interpretation and channel mapping are preserved. Short/odd/oversized/non-byte replies preserve the last valid channel data and report an error. No receiver configuration is written by this loop.

MSP_ANALOG 110 is independently requested at a target one-second interval so RSSI and analog values continue to update; it does not replace or block the channel loop with a five-message group. Existing write/configuration queue work is respected. Easy link status and receiver preview distinguish stale/error data. Actual achieved rates depend on link response times and radio scheduling. A group already pending from the previous page may finish once during transition.

## Checks

- `node test-graphics-receiver-07125.cjs`: board drawing-call comparison, native/fallback rendering, dedicated RC payload/units/busy/queue/error guards, no unrelated metadata overwrite, exact cached drawing replay/invalidation, host restoration on drawing failure.
- `node test-receiver-host-07125.cjs`: actual main.lua host navigation; a receiver update at 100ms and none at 90ms; only RC in the fast path; one-second analog/RSSI; RESET Z chooses pi camera; ordinary Status and attitude-only paths still function.
- `node test-fast-setup-07125.cjs`: 193 Lua files compile; 0.7.123 center/default/reverse/EEPROM checks and board/ACC save gates; current host touch controls; Tail and Geometry regression. Geometry suite uses the real optional drawing cache.
- `node test-attitude-07125.cjs`: native 45-call mesh retained, deadband/cache/camera/units/error checks, 1,521 compound pose bounds, wire fallback, rear-reset preview generated from actual renderer primitives.

No firmware update, protocol-version change or automatic FC configuration migration is included. Previous nine separate Full Setup audit findings remain unresolved. Runtime source changes from 0.7.124: main.lua, attitudeHeli.lua, centerTrim.lua, easyGeometry.lua, easyTail.lua, easyMainRotor.lua, and new fastGraphics.lua. Catalogue and MSP configuration-writer files are unchanged.
