# Rectangle Rooms — physical X4 Pro acceptance

1. Install `rectangle-rooms.xtapp` from **SD:/Apps/** and launch in Ink App on XTOS Licorice.
2. Verify all numbered 5×5, 6×6, and 7×7 boards fit inside portrait 480×800 with room controls below.
3. Tap two corners around a valid numbered rectangle. Confirm one new static border appears with no animation.
4. Tap two corners around an invalid area, a region without a clue, or a region containing two clues. The board must reject each and provide readable feedback.
5. Try overlapping a placed room; it must be rejected.
6. Press UNDO, then RESET. Neither should remove unlocked progress from other levels.
7. Select a first corner, leave and reopen the app: the selection should remain active.
8. Complete a stage, unlock the next, then return to the earlier stage; its solved partition should persist.
9. Partially complete a later puzzle, visit another stage, reopen and return: placed room outlines must be preserved.
10. Inspect numbers 10–16 and very narrow rectangles for clipping or unclear borders on the 7×7 boards.
11. Test physical page buttons and confirm they navigate only.
12. Leave idle, sleep and wake; there must be no animation or periodic refresh.

CI validates mathematical uniqueness and simulated UI only; physical hardware acceptance remains outstanding.
