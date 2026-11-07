# Nonogram — physical X4 Pro test

1. Install `nonogram.xtapp` from **SD:/Apps/** via All Files and launch in Ink App.
2. Confirm the title, row/column clues, board, live status and buttons fit the 480×800 portrait screen.
3. Tap one cell three times: black, X, empty; observe exactly one still refresh per tap and no animation.
4. Verify the numbers for one row indicate runs separated by blank cells, and the live count changes when a row's current filled runs match.
5. Test UNDO repeatedly, then leave and reopen. Undo history and cell marks should persist.
6. Press CHECK on an incomplete or incorrect board; it must remain editable and must not unlock NEXT.
7. Fill a complete valid picture, **leave without CHECK**, then reopen and confirm every painted square remains while the puzzle is still unsubmitted.
8. Press CHECK and confirm the picture name is revealed and NEXT becomes available.
9. Start level 2, make progress, visit level 1 and return. The unfinished second board must be unchanged.
10. Check readability of the largest 8×8 grid and its clue numbers; none should overlap cells or controls.
11. Revisit earlier solved levels. RESET should clear only that level without deleting other completed puzzles or unlocking progress.
12. Confirm the final picture survives reboot, and page buttons navigate only; no periodic refresh or sounds.

Automated tests pass only the host model. Hardware verification is still necessary.
