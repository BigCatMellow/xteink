# Sudoku for XTEINK X4 Pro

Updates are applied directly from the computer while the SD card is mounted;
see the [family release procedure](../../docs/GAME_UPDATES.md). All active games
are also available inside Games Hub, so new games do not require separate
installation when using the updated hub. Never uninstall to update.


Presentation follows the [shared game design contract](../../docs/GAME_DESIGN.md): Poppins/Inter, rounded controls and stronger monochrome lines. That document owns design changes, reasons and per-game exceptions.

Offline XTEINK Sudoku 0.5.0 adapts the features of [Meditation Sudoku](https://github.com/BigCatMellow/meditation/blob/main/index.html) to the 480x800 1-bit screen. The board stays 468x468, while the keypad retains large 60px targets.

**Selection highlighting:** Selecting a square draws static 2px row/column guide outlines and brackets its 3x3 box. Matching numbers get a short underline. The minor grid rules are now 2px; the major box rules and frame are 5px. Outlines, selected cells, and buttons are heavier without obscuring numbers.

**Notes:** Each pencil mark is a miniature seven-segment number in its own 3x3 slot. When NOTES is on, tap a filled digit to lock it, then tap empty squares to add/remove that number. NEW > MULTI allows multiple square selection for notes/erase; NEW > CLEAR NOTES clears all candidates and is undoable. AUTO CLEAN, HIGHLIGHT, CONFLICTS, and MULTI can be toggled in NEW. Settings and note caps are saved. There are up to 100 undo snapshots per puzzle.

**Difficulty:** Beginner, Easy, Medium, Hard and Expert offer new v2 rotationally symmetric puzzles targeting 45, 38, 32, 26 and 22 clues respectively. The XTEINK generator uniquely solves each accepted puzzle, but does not yet reproduce Meditation's browser-only human-technique classifier or ten-attempt retries. Legacy v1 Easy/Medium/Hard puzzles are never regenerated using the new profile.

**Interaction:** CHECK marks incorrect entries with static corner crosses rather than animations; double-tap erases editable entries. Existing page-key history, pencil notes, correct-but-unsubmitted status, saved solutions and app identifiers remain preserved. The visual controls replace browser colors and keyboard shortcuts.

See [Meditiation feature parity matrix](../../docs/design/sudoku-meditation-2026-11-17/FEATURE_PARITY.md) for source-derived evidence and limitations.

Seeds are stable across relaunches. Numbered saves use 64 archive files plus an index to avoid the firmware's 512-file limit. History grows with play and remains subject to the device's storage quota. Failed saves are reported and block navigation away from the current puzzle.

First installation: open `sudoku.xtapp` from **SD:/Apps/** using All Files, then **Ink App → Sudoku**. Updates keep app ID `sudoku` and preserve saves. The preferred update workflow is [computer-side direct updates](../../docs/GAME_UPDATES.md) while the card is mounted; the first physical direct-update check remains pending. Never uninstall to update.

v0.3.0 follows the user's stock-Sudoku reference for board/keypad density while preserving our fonts and rounded controls. [Before/after](../../docs/design/sudoku-2026-11-08/before-after.png), [state previews](../../docs/design/sudoku-2026-11-08/states.png) and rationale in the [design record](../../docs/GAME_DESIGN.md). Generators, puzzle seeds, notes, submission and save formats are unchanged.

The quality gate tests touch input, conflicts, notes, cleanup, undo, saved puzzle visits, unsubmitted solutions, help/menu/solved layouts and large counters using variable-width fonts. A separate Python solver checks generated puzzles and their unique answers. Source and packaged native icon pixels are verified. These host checks do not establish on-device generation speed, touch accuracy, font rendering or sleep/resume; see [device checks](docs/DEVICE_TESTING.md).

## v0.5.0 — genuinely new seeded puzzles

NEW now chooses a fresh per-session numeric seed, not just the next
sequential puzzle number. The seed is stored alongside the board, notes,
history, difficulty and submission state. Reopening a puzzle reproduces
its exact givens and solution; old records without a seed still use
their original numbered v1/v2 generator, without migration or lost progress.

The algorithm remains the Sudoku generator ported from
[BigCatMellow/meditation](https://github.com/BigCatMellow/meditation):
randomized completed grids, symmetry-preserving clue removal and exact
one-solution checking. The Meditation browser's full ten-attempt human-
technique difficulty classification is not claimed as implemented on
the reader; a unique solution is not itself a human difficulty score.
