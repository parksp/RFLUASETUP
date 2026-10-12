# Model Name text keyboard

Model ID is a numeric pilot configuration field (MSP12/13). Aircraft names use MSP10/11. Renamed Aircraft Name to Model Name and numeric Model ID to Model ID (0-99). Name text rows previously had no touch hit region; both label and value now open the existing ASCII keyboard.

Configuration swipe capture now excludes name keyboard, port editor and serial confirmation overlays, preventing popup keys from activating underlying rows. Numeric fields retain the numeric editor. English 0.7.29 baseline retained, including Geometry restore and Tail fixes.

Integrated tests passed: label/value keyboard entry, single-touch character, exact MSP11 payload, unchanged numeric ID, no EEPROM from name entry, cancellation/empty name/32-character limit. Existing menu and Geometry regressions pass. Hardware validation remains outstanding. Published source and installer are based on this tested local build.
