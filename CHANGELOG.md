# Changelog

## 0.6.33 BETA

- Changed Adjustments reading to official Rotorflight 2.3 slot-by-slot `MSP_GET_ADJUSTMENT_RANGE` command 156.
- Reads each Adjustment as an exact 14-byte record to avoid corruption of Function and AUX values over a long telemetry response.
- Preserves FC slot order and sends only changed Adjustment slots on SAVE.
- Retains live AUX display for Modes and Adjustments.
- Includes the current Full Setup, Status, Setup, Configuration, Receiver, Failsafe, Power, Motors, Governor, Servos, Mixer, Gyro, Rates, Profiles, Modes, Adjustments, Beepers, Sensors and Blackbox work.

This release remains an unfinished BETA build intended for controlled evaluation.
