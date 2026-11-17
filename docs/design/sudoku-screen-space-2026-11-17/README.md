# Sudoku screen-space pilot — November 17, 2026

## Decision

Keep the board square and essentially full-width at 468×468 on the
480×800 panel. The previous game already has no unexplained 48px
vertical gap between functional UI regions. The best small improvement
is taller, easier-to-touch controls without reducing board area.

| Feature | Previous v0.3.2 | Pilot v0.3.3 |
| --- | --- | --- |
| Board bounds | (6,108) 468×468 | (6,100) 468×468 |
| Level/difficulty row | y=74 | y=68 |
| Dynamic status text | y=590 | y=575 |
| Digit keys | 9 × 98×52 | 9 × 98×60 |
| First digit row | y=626 | y=604 |
| Notes, Undo, Erase | 132×52 each | 132×60 each |
| Bottom of bottom row | y=790 | y=792 |

Numeric touch area increases from 45,864 to 52,920 square pixels,
a **15.4% increase** without changing the actual game board. The
lowest controls still leave an 8px bottom margin, and the digit key
rows have 4px gaps.

## Required visual evidence

The script at scripts/render_sudoku_pilot.py runs the actual Lua game
drawing code with shipped bitmap glyphs before and after the change.
It captures first/empty, notes in progress, check feedback, solved,
menu, and Help states, and produces a side-by-side contact sheet
named before-after.png and the measurements as metrics.json.
The workflow in .github/workflows/sudoku-screen-space.yml uploads
these files as the sudoku-screen-space-before-after artifact.

Original source is taken reproducibly from Git commit
764788afef087f919ecf434a22c0af7590b6d2b8. The screenshot comparison
must be inspected; passing geometry tests alone is insufficient.
These are host renders, **not** photographs from the X4 Pro.

## Mechanical review

The reusable tests/screen_space.lua harness instruments measured UI
region, text, and button bounds. It reports the largest internal
blank band without treating intentional white pixels or screen-edge
margins as waste. Sudoku's gameplay test exercises normal and 125%
glyph-width models, requires a single 468px square board and nine
98×60 number keys, rejects unexplained 48px bands, and checks all
control bounds. Existing tests exercise all 81 board taps, nine
number taps, notes, undo, saves, generated levels, menus, solved
states, and bitmap glyph bounds. The bundled Games Hub engine is
regenerated from this exact standalone Sudoku code.

The gameplay state schema, puzzle seeds, app ID, note serialization,
fonts, and personal SD-card data are **unchanged**. The pilot is
source-only until installed and physically tested on Licorice.
