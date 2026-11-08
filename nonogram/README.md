# Nonogram — picture-logic puzzles for XTEINK X4 Pro

Presentation follows the [shared game design contract](../docs/GAME_DESIGN.md): Poppins/Inter, rounded controls and stronger monochrome lines. That document owns design changes, reasons and per-game exceptions.

An original, offline, black-and-white nonogram game for XTOS Licorice. Solve rows and columns of numbered clues to reveal a hidden pixel picture.

**v0.5.0:** the complete clue/board composition is now centered in the game area; grid lines are 3px and the frame/marks 4px. Presentation uses the shared family implementation and keeps the large touch cells, existing levels, generated seeds and saves. See the [current shared design contract](../docs/GAME_DESIGN.md) for the decisions and reasons.

**v0.4.0 typography:** real Poppins SemiBold headings, Poppins Medium controls and Inter Medium clues/help, packaged as crisp monochrome glyph images. No reader font settings or custom TTF loader are required. The app reuses a bounded glyph cache and falls back to native text if image decoding/drawing fails. See the [actual packaged-glyph preview](docs/design/bitmap/native-vs-bitmap.png) and [font implementation details](docs/DESIGN.md#typeface-study-and-v04-implementation). The [local release installer](../releases/nonogram-0.4.0.xtapp) is an update for the same app ID and save format.

**v0.3.0 design pass:** larger boards, stronger grid lines and marks, rounded controls, aligned clues with line-match ticks, and a Check button that becomes Next after solving. See the [design rationale and space allocation](docs/DESIGN.md) and [before/after host preview](docs/design/before-after.png). Existing levels, generated seeds and saves remain compatible.

**Twelve hand-authored pictures:** four **5×5**, four **7×7**, and four **8×8**. The pictures are independently verified to have **exactly one solution** based only on the visible clues.

**Endless continuation (v0.2.0):** NEXT continues after picture 12 with generated **abstract patterns**, cycling through 5×5, 7×7 and 8×8. Each candidate must have exactly one solution from its clues, with at most three runs per line. Generation has a bounded search and a guaranteed unique geometric fallback. These patterns are not promised to depict recognizable objects. Puzzle numbers support up to 999,999,999; finite grids can eventually repeat.

Upgrades retain the original pictures, app ID, progress, correct-but-unsubmitted boards and undo. Stable numbered seeds reproduce generated boards; their marks, CHECK state and undo are archived in 64 save files rather than one file per puzzle. Saves remain subject to the device's byte quota. If saving fails, navigation stays on the current puzzle and a message asks you to keep it open.

## Rules

Each row and column has a sequence of numbers. A number is the length of a run of filled cells; separate runs require at least one blank cell between them. Fill the picture in the grid without seeing its name until you submit a completed solution.

- **Tap a cell:** blank → solid black → X (known empty) → blank.
- **UNDO:** restore the previous cell state (up to 16 moves of per-level history).
- **RESET:** clear only the current picture and its undo history. Other pictures and global unlocks remain.
- **CHECK:** verify the filled picture against the unique answer. Wrong attempts leave the grid editable. The game does not auto-submit even if all cells are already correct.
- **PREV:** revisit an unlocked earlier puzzle.
- **NEXT:** appears at the top when a later puzzle is unlocked.
- After CHECK succeeds, the primary button becomes **Next**. An unfinished earlier puzzle can also use the header's **Next** when a later puzzle is already unlocked.
- Page buttons navigate unlocked levels, never fill cells.

Row and column clue counts are shown above and beside the grid. Live row/column status reports how many run sequences currently match the clues, without revealing which cells are wrong. Progress, correct-but-unsubmitted grids, unlocked stages, completed pictures and the per-level undo histories are saved locally.

**No animation, countdown, sound, network or gray shading.** Every interaction causes only a new static e-ink frame.

## Level verification

`tests/validate_levels.py` independently solves all original pictures plus generated samples and forced fallbacks, rejecting ambiguous clues. Lua tests replay the originals and generated continuations through the tap and CHECK controls, verify v1 save migration and save/resume before submission, preserve undo through level visits, and measure layouts with standard and enlarged variable-width fonts.

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
