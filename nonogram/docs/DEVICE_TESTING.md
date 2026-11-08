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
13. Upgrade from v0.1.1 with an unfinished board and undo history; preserve both. Complete picture 12 and use NEXT to generate an abstract pattern.
14. Test generated 5×5, 7×7 and 8×8 patterns. Check clue spacing, save before CHECK, revisit earlier puzzles and reopen. Keep marks, undo and the exact generated pattern. Record generation latency.

Automated tests pass only the host model. Hardware verification is still necessary.

## v0.3 design pass

- Confirm the grid frame and controls have rounded corners, with 3px emphasis on the board and Check/Next. If the firmware ignores the radius option, report it rather than accepting the host preview as proof.
- Check the new 68px (5×5), 48px (7×7) and 44px (8×8) touch cells. Tap cell edges, the last row/column and the adjacent clue gutter; only the intended square changes.
- Confirm the longest three-run generated clues stay readable and aligned. Line-match ticks must remain separate from clue numbers and the board frame.
- Check the Help target, inactive Prev/Undo appearance, feedback line, and full rounded button hit areas with the native fonts.
- Solve a board and use the footer's Next. Revisit it and verify completion, earlier unfinished boards and their undo are preserved. Reset must affect only the current board.
- Compare the host before/after preview with the actual display, including black-cell separation, X weight and ghosting after several edits. Record firmware and observations.

## v0.4 Poppins/Inter bitmap fonts

- Install over the existing Nonogram app. Confirm the title is Poppins SemiBold, the rounded controls use Poppins Medium, and clues/help use Inter. Compare with `design/bitmap/8x8.png` and `help.png`.
- If “System fonts active” appears, record the firmware version and which screen triggered it. The app should remain playable with existing saves intact.
- Record first-frame load time, then repeatedly mark cells, undo, navigate and reopen help. Later frames should reuse decoded glyphs without a growing delay.
- Inspect small numbers, tabular digit spacing, `1 2 1` clues, letters with descenders, and long counters. No glyph may erase its neighbor, cross a control border, or lose the bottom of a letter.
- Leave/relaunch and sleep/wake repeatedly. Confirm fonts return, no resource exhaustion/reset occurs, and unfinished boards and undo survive.
- Check the actual black/white PNG polarity and whether glyphs look crisp at native size. Host pixel checks cannot establish the reader's decoding/rendering behavior or heap overhead.
