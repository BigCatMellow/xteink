# Rectangle Rooms — Shikaku logic puzzles on XTEINK X4 Pro

Presentation follows the [shared game design contract](../docs/GAME_DESIGN.md): Poppins/Inter, rounded controls and stronger monochrome lines. That document owns design changes, reasons and per-game exceptions.

An original, offline **numbered rectangle partition** puzzle game, inspired by the paper-and-pencil Shikaku rules. Designed for the XTEINK X4 Pro's 480×800 monochrome display running XTOS Licorice.

## Rules

Divide the grid into rectangles so that every cell belongs to exactly one rectangle. **Each rectangle contains exactly one number**, and that number must equal the rectangle's **area** (width × height).

**Tap two opposite corners** to outline a room. A locally valid rectangle is added immediately. The game will reject a rectangle if its area does not match its clue, if it contains zero or multiple clues, or if it overlaps a previously placed room. Some locally valid choices can later block a complete solution—use **UNDO** to remove the most recent room.

- **UNDO** also cancels the current first-corner selection.
- **RESET** clears only the current level, preserving all global unlocks.
- **PREV/NEXT** navigate previously unlocked levels; physical page buttons navigate but never place rectangles.
- All twelve levels, completed and incomplete room partitions, and first-corner selections are stored separately and survive app relaunch.
- Complete a stage by covering every cell with valid non-overlapping rectangles.

## Difficulty / verification

There are **twelve original boards**: four 5×5, four 6×6, and four 7×7. They contain 5–10 numbered rooms. The independent Python solver uses geometric candidate enumeration and exact-cover search to confirm each numbered grid has **exactly one valid full partition**, not just that one example happens to work. Each puzzle has several clues with multiple locally possible rectangles.

Lua host tests reconstruct all twelve unique partitions through actual two-corner taps, including undo/restart, returned in-progress boards, help screen, and scaled-font layout.

## Why it works on e-ink

Each puzzle is just numbers and borders. Nothing slides, flashes, fades, or updates periodically. One touch causes one static redraw. No internet, keyboard, audio, or grayscale required.

## Install

1. Open [Rectangle Rooms builds](https://github.com/BigCatMellow/xteink/actions/workflows/rectangle-rooms.yml).
2. Download a successful **rectangle-rooms-xtapp** artifact.
3. Extract `rectangle-rooms.xtapp` and copy it into **`SD:/Apps/`** on the microSD.
4. Install using Licorice **All Files** and launch via **Ink App → Rectangle Rooms**.

Do not remove the firmware-managed `XTApps/` folder when updating. The app is **simulator-verified, not physically verified** until the X4 Pro acceptance checklist is completed.

## Files

- `app/index.lua`: area constraints, rectangle drawing, inputs and saving
- `app/puzzles.lua`: twelve original numbered grids
- `app/ui.lua`: synced measured-text helper
- `assets/icons/rectangle-rooms.svg` and `app/icon.png`: native 1-bit launcher icon
- `tests/validate_levels.py`: independent exact-cover uniqueness solver
- `tests/test_game.lua`: complete gameplay, save, hitbox and layout tests
- `docs/DEVICE_TESTING.md`: physical test plan
