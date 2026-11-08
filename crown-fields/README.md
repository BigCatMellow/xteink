# Crown Fields — region placement on XTEINK X4 Pro

An original offline logic puzzle using the classic one-per-row, one-per-column, one-per-region **Crowns/Queens** rules. All board layouts and icon artwork are independently generated, not copied from crowns.game.

**12 puzzles:** four 5×5, four 6×6, four 7×7. Every level has exactly **one** solution checked by an independent exhaustive solver. Every lettered region is connected. No color is required: borders between regions are thick, and each cell carries a region letter.

## Rules

Place one crown in every row, column and lettered region. Crowns may not touch horizontally, vertically, or diagonally. Tap a square to cycle **blank → X → crown → blank**. X marks an excluded cell.

Press **CHECK** to submit. The right arrangement is required; marking every crown without pressing CHECK preserves an unsubmitted solution between sessions. **UNDO** remembers the last 12 changes per level. **RESET** clears only the current puzzle. PREV and NEXT navigate unlocked stages, including via physical page buttons.

The app is black-and-white, offline, entirely static and has no animation, sound, timer or swipe gesture.

## Install

Download the latest successful **crown-fields-xtapp** artifact from the [build workflow](https://github.com/BigCatMellow/xteink/actions/workflows/crown-fields.yml). Extract `crown-fields.xtapp`, copy it to **SD:/Apps/**, install through Licorice **All Files**, and launch **Ink App → Crown Fields**. Do not delete firmware-managed **XTApps/** data.

Files: `app/index.lua`, `app/levels.lua`, `app/ui.lua` (synced UI), `app/icon.png`, `tests/test_game.lua`, `tests/validate_levels.py`, and `docs/DEVICE_TESTING.md`.

The independent solver checks connected regions and counts all valid arrangements, rather than only testing a known answer. CI checks full save/resume, partial and submitted progress, fonts and package icons. Physical X4 Pro validation is still required.
