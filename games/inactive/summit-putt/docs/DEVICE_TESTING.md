# Summit Putt — hardware test checklist

Code-level and renderer tests do not establish that the device input or display works. Verify on a real X4 Pro with XTOS Licorice.

1. Install the successful build artifact as `summit-putt.xtapp`; open Ink App.
2. Confirm the header, full 7×7 course, cards, four direction controls, UNDO and RESTART all fit 480×800 portrait with no clipping.
3. At level 1, select a card, then tap a valid direction. Check the ball moves the precise distance and the card is crossed out.
4. Tap a blocked direction: no card is spent. Check feedback appears.
5. Tap UNDO: verify ball and consumed card return. Leave the app; relaunch: both position and undo history persist.
6. Make a wrong sequence to run out of cards; confirm that you can undo or restart and no progress is permanently lost.
7. Solve level 1; check NEXT PUZZLE unlocks level 2. Exit and return: progress remains.
8. Use physical page buttons to select available cards; check no double-press issue.
9. On level 9, verify the arrow on the ramp is visible, entering uphill works only in the indicated direction, and flat ground cannot climb an un-ramped high edge.
10. Finish all ten stages. Level 10 should show completion and let you replay.
11. Inspect ghosting, card selected outline, the hole and ball outlines, and whether small text remains legible.

If any step fails, record the firmware build, step, and a photo. This package is **not hardware-verified** until these pass.
