# 0.7.29 Tail interaction

Removed only the Tail override enable confirmation. Enabling still checks FC disarm status; OFF releases the override. Draft/type guards and explicit EEPROM save remain.

Slider previously processed BREAK coordinates as a new target. A release with zero coordinates would clamp to the negative endpoint. BREAK now ends dragging without changing the target. FIRST and SLIDE set the target; TAP-only events are supported.

Mock regressions passed: single-press ON/OFF, armed enable rejection, -20 touch, release with zero coordinates, drag endpoint, center TAP and no slider commands while OFF. Tail live save/restore and direction preservation regressions passed. All release Lua sources compile. Real transmitter/FC event validation remains outstanding.
