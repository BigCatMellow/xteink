# Sudoku v0.3 physical checks — not yet performed

User photos on 2026-11-08 confirm v0.2 renders on the reader, but its box
boundaries and use of space are inadequate. The revised v0.3 layout is host
tested only. Preserve existing progress when applying the update.

1. Install from SD:/Apps and launch in Ink App. Record firmware version and initial generation time.
2. Check the 468px board, clearly heavier 3×3 box boundaries, bold fixed clues, selection, status, and three-column number pad. Box boundaries must remain 4px bars while minor cell lines are 1px. Givens no longer have inner boxes.
3. Tap a blank square and each digit. Givens cannot be overwritten. ERASE and UNDO affect only editable values.
4. Add notes, select another square and return. Notes appear below the selected square and on number buttons; squares with notes show a dot.
5. Enter a peer's noted number. Its note disappears; UNDO restores it. Repeat after leaving and reopening.
6. Enter a duplicate value and verify a corner X marks the clash. CHECK reports wrong entries without deleting them.
7. Fill a correct board, leave before CHECK, and reopen. CHECK completes it; the solved board survives relaunch.
8. Open NEW, then close it. The current puzzle must remain unchanged. Generate each difficulty and record latency; generation must not time out or reset the reader.
9. Start a second puzzle while the first is unfinished. Revisit both with the menu and page keys, including after relaunch. Preserve values, notes and undo.
10. RESET THIS PUZZLE clears only its entries and notes. Other saved puzzles remain intact.
11. Check help, long status messages, touch rectangles, note dots and clash markers under the real fonts. Leave idle: no periodic redraw.
12. Verify the new rounded native launcher icon and readable numerals at the actual launcher size, plus sleep/wake save behavior. Check standalone Sudoku and the Sudoku inside Games Hub v0.2.0.
