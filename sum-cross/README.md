# Sum Cross — Kakuro (Cross Sums) for XTEINK X4 Pro

An original Kakuro-inspired logic puzzle game for the XTEINK X4 Pro running XTOS Licorice. No color, animations, external fonts, networks or drag gestures.

## Rules

Each white square contains a digit **1–9**. Each across or down sequence of white squares must add up to the total printed in its starting black clue cell. **Digits cannot repeat within a run.** On the black clue cells the DOWN sum is printed near the upper-right and the ACROSS sum near the lower-left, separated by a diagonal stroke.

Tap a white square, then tap a big digit on the two-row **1–9 keypad**. **CLR** erases the selected cell. UNDO restores up to twelve previous digit changes. **RESET** clears this puzzle only. **CHECK** submits the finished grid; incorrect grids remain editable. A correct but unsubmitted answer is preserved across relaunch, as are every puzzle's marks and undo history. PREV and NEXT and physical page buttons navigate unlocked levels.

**12 original compact Kakuro grids:** four 5×5, four 6×6 and four 7×7. Every white cell belongs to one across and one down run. An independent exact cross-sums constraint solver proves **one unique digit solution** for each grid. Early puzzles use smaller clusters of intersecting sums, while later grids use more.

## Install

Download a successful **sum-cross-xtapp** artifact from the [Sum Cross workflow](https://github.com/BigCatMellow/xteink/actions/workflows/sum-cross.yml). Extract `sum-cross.xtapp`, copy to **SD:/Apps/** and install through Licorice **All Files**. Do not delete firmware-managed **XTApps/** storage.

Source: `app/index.lua`, `app/puzzles.lua`, `app/ui.lua`, `app/icon.png`, `tests/validate_levels.py`, `tests/test_game.lua` and `docs/DEVICE_TESTING.md`.

CI checks uniqueness, complete keypad solutions, premature submissions, undo, partial saves and enlarged-font layout. On-device touch precision and readable two-number clue cells must still be tested.
