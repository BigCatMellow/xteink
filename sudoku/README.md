# Sudoku for XTEINK X4 Pro

Presentation follows the [shared game design contract](../docs/GAME_DESIGN.md): Poppins/Inter, rounded controls and stronger monochrome lines. That document owns design changes, reasons and per-game exceptions.

Offline, static monochrome Sudoku for XTOS Licorice. The seeded generation, uniqueness checks, notes and undo are adapted from the Sudoku in [BigCatMellow/meditation](https://github.com/BigCatMellow/meditation/blob/main/index.html). The interface is rewritten for the reader's 480×800 portrait touch screen; it has no animation or network requirement.

Tap a square, then a number. **Bold numbers are fixed clues**; a corner X marks a row, column or box clash. The 468px board has solid 3×3 box boundaries and fine cell lines. A three-column number pad sits beside **Notes**, **Undo** and **Erase**. Notes toggles pencil marks; a dot identifies a square with notes. Select it to read its candidates below the board and see their outlined number buttons. Entering a value cleans that number from peer notes. Undo restores values and notes together (32 moves per puzzle); Erase clears the selected editable square.

**CHECK** reports incorrect entries or confirms completion. Correct-but-unsubmitted grids remain saved and editable. Completed grids remain read-only until an explicit reset. **NEW** opens a menu with Easy, Medium and Hard, START NEW, previous/next saved puzzles, and RESET THIS PUZZLE. Starting another puzzle preserves unfinished ones and their undo histories. Physical page keys also revisit generated puzzles; merely opening the menu never replaces a board.

Difficulty changes the target clue count (45, 36 or 30), not a guaranteed human technique rating. The generator shuffles a valid completed grid and removes givens only when an exact solver confirms one solution. A bounded solver rejects removals it cannot verify in time. A contradiction is never counted as a solved board. The supply is procedural, with numbers up to 999,999,999; finite boards may eventually repeat.

Seeds are stable across relaunches. Numbered saves use 64 archive files plus an index to avoid the firmware's 512-file limit. History grows with play and remains subject to the device's storage quota. Failed saves are reported and block navigation away from the current puzzle.

First installation: open `sudoku.xtapp` from **SD:/Apps/** using All Files, then **Ink App → Sudoku**. Updates keep app ID `sudoku` and preserve saves. The preferred update workflow is [computer-side direct updates](../docs/GAME_UPDATES.md) while the card is mounted; the first physical direct-update check remains pending. Never uninstall to update.

v0.3.0 follows the user's stock-Sudoku reference for board/keypad density while preserving our fonts and rounded controls. [Before/after](../docs/design/sudoku-2026-11-08/before-after.png), [state previews](../docs/design/sudoku-2026-11-08/states.png) and rationale in the [design record](../docs/GAME_DESIGN.md). Generators, puzzle seeds, notes, submission and save formats are unchanged.

The quality gate tests touch input, conflicts, notes, cleanup, undo, saved puzzle visits, unsubmitted solutions, help/menu/solved layouts and large counters using variable-width fonts. A separate Python solver checks generated puzzles and their unique answers. Source and packaged native icon pixels are verified. These host checks do not establish on-device generation speed, touch accuracy, font rendering or sleep/resume; see [device checks](docs/DEVICE_TESTING.md).
