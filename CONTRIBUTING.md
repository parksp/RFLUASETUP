# Contributing to RFLUASETUP

RFLUASETUP is an early BETA project. Contributions should prioritize FC data integrity, predictable navigation and safe bench operation.

## Before changing code

1. Create a separate Git branch.
2. State the tested transmitter, EdgeTX version, FC, Rotorflight firmware, receiver and telemetry protocol.
3. Back up the FC configuration in Rotorflight Configurator.
4. Avoid changing unrelated menus in the same pull request.

## Validation required

- Run the Lua syntax checker on the complete `SD-CARD` tree.
- Confirm the page opens without a Script syntax error.
- Compare every read value with Rotorflight Configurator 2.3.0.
- Confirm edited values reach the intended MSP field.
- Confirm SAVE writes only the intended value or slot.
- Re-read the FC after saving.
- Bench-test with motor power disconnected for normal configuration work.
- Remove blades and secure the model before any motor or override test.

## Bug reports

Include the RFLUASETUP version, transmitter, EdgeTX version, FC target, Rotorflight firmware, receiver and telemetry protocol, complete error text, reproduction steps, and photos of both the Lua and matching Configurator screens.

## Pull requests

Use a clear title and explain the trigger, previous behavior, new behavior, MSP command or API involved, and validation performed. Do not include personal configuration dumps, model files, keys, passwords or private telemetry identifiers.
