# Meditation Sudoku → XTEINK feature parity (2026-11-17)

Source inspected: https://github.com/BigCatMellow/meditation/blob/main/index.html
Sudoku CSS approximately lines 1039-1316, markup 1385-1438, logic 2096-2494.

| Meditation behavior | XTEINK implementation | Notes |
| --- | --- | --- |
| Highlight related row and column | 2px outline crosshair | No colored fills |
| Highlight related 3x3 box | Corner bracket markers | Static, minimal |
| Highlight same digit | Underline matching grid values; active numpad | Static |
| Pencil candidates drawn in cells | 3x3 miniature seven-segment numbers | No tiny external fonts |
| Pencil mode and locked digit | Tap filled number in Notes, then empty squares; keypad changes lock | Yes |
| Multi-select / batch notes | NEW > MULTI; touch toggles cells | Replaces Shift-click |
| Clear all notes | NEW > CLEAR NOTES, undoable | Yes |
| 100 undo snapshots | 100 per puzzle, saved | Yes |
| Auto-clean peer notes | NEW > AUTO CLEAN | Yes |
| Toggle highlighting/conflicts | NEW > HIGHLIGHT / CONFLICTS | Yes |
| Five difficulty levels | Beginner, Easy, Medium, Hard, Expert | Matching names/target clues |
| Rotational clue symmetry | New v2 puzzles use paired clue removal | Verified uniquely solvable |
| Browser advanced technique classifier | Not yet ported | Different perceived difficulty possible |
| Browser ten-attempt retry policy | Not ported | Device CPU budget limitation |
| Check wrong values | Static corner crosses, success message | No flashing animation |
| Browser mouse/keyboard gestures | Touch, menu, page keys, double-tap erase | Device-specific |
| Browser color/light/dark animations | Monochrome strokes only | Deliberate e-ink constraint |
| Restart, change difficulty | NEW menu | Existing XTEINK level persistence retained |

**Save compatibility:** v1 puzzle generation, saved cell values, note masks,
undo history and stable puzzle IDs are unchanged when loading existing levels.
New optional fields in the same version=1 storage format save presentation
settings, selected cells, locked digit and generation profile.

**Validation:** 480x800 bitmaps, 468px square, all 81 touch cells, thick
2/5px lines, row/column guide geometry, pencil vectors, 5 difficulty
profiles, old seed recovery, and both standalone and bundled Games Hub.
Physical e-ink rendering and response remain untested.
