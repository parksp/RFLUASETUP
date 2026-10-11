# 0.7.28 unsaved Easy Setup audit

Geometry previously left live RAM settings on RETURN without EEPROM250. It now tracks the original value for each edited field and signed axis rate, releases overrides, confirms DISARM, restores and verifies before leaving. Successful explicit save clears the rollback baseline. Subsequent edits establish a new baseline.

Restoration uses fresh mixer/input data, preserving unrelated direction, tail values and input limits. Changed tracked values must match the last attempted value or original; external edits cause a conflict instead of overwrite. Communication failures retain rollback state and prevent a successful exit message. Forced script termination cannot guarantee restoration.

Other Easy paths: Tail already restores live trim/calibration/limits through RETURN > DISCARD; type/direction/defaults require explicit save. Main Rotor, Board/Sensor alignment and ACC trim are drafts until save. Servo/Swash center and defaults use explicit CONFIRM & SAVE. Receiver Check is read-only. Accelerometer calibration is a separate explicitly confirmed MSP205 action, outside numeric draft rollback.

Validation: dedicated Geometry cases covered collective rollback, separate signed cyclic originals, geometry correction rollback, fresh direction/limit preservation, saved values remaining, external conflict, failed restore and retry, and RETURN during an in-flight update. Integrated UI, native drawing signature, Tail rollback and Servo/Swash regressions passed. All 150 Lua sources compiled. Physical FC/transmitter validation remains outstanding; no flight incident cause was established.
