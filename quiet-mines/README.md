# Quiet Mines — original no-guess Minesweeper on XTEINK X4 Pro

A completely static, offline Minesweeper implementation for the X4 Pro. Twelve independently authored mine layouts, with four 6×6 fields (6 mines), four 7×7 fields (8 mines), and four 8×8 fields (10 mines).

## Rules

Uncover all squares **without mines**. Each revealed digit counts mines in its eight neighboring squares. An empty zero square automatically reveals its surrounding safe area in **one static redraw**.

Every field has a marked **S** starting square. For this campaign, **open S first**; its zero-clue flood and subsequent clue deductions are verified to clear the board without guessing. The first OPEN action must be on S to protect the intended no-guess route.

Tap **FLAG** to switch from opening squares to placing/removing flag markers; the same button then displays OPEN to switch back. An opened mine ends the current field until **RESET**. **UNDO** restores the last step in a live field; completed or failed fields remain fixed until reset. PREV/NEXT navigate unlocked levels and physical page buttons navigate only.

Save files preserve open squares, flags, failed stages, undo history and global unlocks. No timer, animation, scrolling or internet.

## Install

Download the latest successful **quiet-mines-xtapp** from [GitHub Actions](https://github.com/BigCatMellow/xteink/actions/workflows/quiet-mines.yml). Unzip `quiet-mines.xtapp`, copy into **SD:/Apps/**, install via Licorice **All Files** and open in **Ink App**. Preserve firmware-managed **XTApps/** data.

Source and tests: `app/index.lua`, `app/levels.lua`, `app/ui.lua`, `app/icon.png`, `tests/validate_levels.py`, `tests/test_game.lua`, `docs/DEVICE_TESTING.md`.

The independent solver repeatedly derives forced safe cells and mines from displayed clue arithmetic starting at S; every level passes without guessing. Actual X4 Pro input, text rendering and sleep/wake remain to be verified on hardware.
