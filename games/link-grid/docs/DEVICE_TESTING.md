# Link Grid — physical X4 Pro test plan

**Acceptance requires the actual XTEINK X4 Pro with XTOS Licorice.**

1. Install the latest successful `link-grid.xtapp` from **All Files**; launch from **Ink App**.
2. Verify 480 × 800 portrait layout: top title/status, 4×4 or 5×5 centered board, instruction line and PREV/RESET/NEXT controls. No clipped text or off-screen elements.
3. On level 1, tap a non-fixed tile. It should turn exactly 90 degrees in **one static screen update**. Verify **no animation or mid-move frames**.
4. Tap an empty tile and a small black-marked fixed tile. Neither should rotate or trigger unnecessary redraws.
5. Verify lines that face each other connect exactly across shared cell borders. No offset or disconnected endpoints.
6. Tap RESET to restore the starting board. Leave the app and reopen to confirm tile changes persist, then RESET again.
7. Solve level 1: CONNECTED appears and NEXT becomes available. NEXT unlocks level 2; an unsolved level 2 cannot be skipped.
8. Use PREV and NEXT to move between previously unlocked levels. A prior unlocked level should be accessible without losing overall progress.
9. On levels 11–20, check 5×5 tiles remain large enough to tap accurately and the 5×5 board remains in the visible touch area.
10. Press physical page buttons: navigate only when possible; never accidentally rotate a tile.
11. Solve level 20 and confirm ALL 20 PUZZLES SOLVED appears. Reboot and confirm the same completed board returns.
12. Verify minimal e-ink ghosting and no display refresh while idle. No timers, animation, Wi-Fi, Bluetooth, or sound should be required.

Report the firmware build and photograph any confusing line junction, inaccessible button, or crash. CI validates the mathematical puzzles, but cannot substitute for hardware verification.
