# Nonogram — picture-logic puzzles for XTEINK X4 Pro

An original, offline, black-and-white nonogram game for XTOS Licorice. Solve rows and columns of numbered clues to reveal a hidden pixel picture.

**Twelve hand-authored pictures:** four **5×5**, four **7×7**, and four **8×8**. The pictures are independently verified to have **exactly one solution** based only on the visible clues.

## Rules

Each row and column has a sequence of numbers. A number is the length of a run of filled cells; separate runs require at least one blank cell between them. Fill the picture in the grid without seeing its name until you submit a completed solution.

- **Tap a cell:** blank → solid black → X (known empty) → blank.
- **UNDO:** restore the previous cell state (up to 16 moves of per-level history).
- **RESET:** clear only the current picture and its undo history. Other pictures and global unlocks remain.
- **CHECK:** verify the filled picture against the unique answer. Wrong attempts leave the grid editable. The game does not auto-submit even if all cells are already correct.
- **PREV:** revisit an unlocked earlier puzzle.
- **NEXT:** appears at the top when a later puzzle is unlocked.
- Page buttons navigate unlocked levels, never fill cells.

Row and column clue counts are shown above and beside the grid. Live row/column status reports how many run sequences currently match the clues, without revealing which cells are wrong. Progress, correct-but-unsubmitted grids, unlocked stages, completed pictures and the per-level undo histories are saved locally.

**No animation, countdown, sound, network or gray shading.** Every interaction causes only a new static e-ink frame.

## Level verification

`tests/validate_levels.py` builds a separate nonogram constraint solver from the fixed pixel patterns, searches possible row and column assignments and rejects any picture with more than one solution. Lua tests also replay all twelve boards through their actual tap and CHECK controls, verify submission and save/resume, navigate between unfinished levels, and check the display using both standard and enlarged variable-width font metrics.

## Install

1. Open [Nonogram's Actions workflow](https://github.com/BigCatMellow/xteink/actions/workflows/nonogram.yml).
2. Download the `nonogram-xtapp` artifact from its latest **successful** run.
3. Unzip `nonogram.xtapp` and copy it to **`SD:/Apps/`** on the microSD card.
4. Install through **All Files** and launch in **Ink App → Nonogram**.

Leave the firmware-managed `XTApps/` folder alone to preserve app data. No firmware replacement is needed.

## Source

- `app/index.lua` — logic, clues, UI, saves and input.
- `app/pictures.lua` — twelve original pixel pictures.
- `app/ui.lua` — synchronized measured-text helper.
- `app/icon.png` and `assets/icons/nonogram.svg` — native launcher icon.
- `tests/validate_levels.py` — independent unique-solution verifier.
- `tests/test_game.lua` — input, solve, submission, navigation, persistence and layout tests.
- `docs/DEVICE_TESTING.md` — physical acceptance checks.

**Hardware status:** The builds require testing on a real X4 Pro for touch alignment, font rendering and sleep/resume before being considered device-verified.
