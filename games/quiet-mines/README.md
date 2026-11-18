# Quiet Mines — original no-guess Minesweeper on XTEINK X4 Pro

Updates are applied directly from the computer while the SD card is mounted;
see the [family release procedure](../../docs/GAME_UPDATES.md). All active games
are also available inside Games Hub, so new games do not require separate
installation when using the updated hub. Never uninstall to update.


Presentation follows the [shared game design contract](../../docs/GAME_DESIGN.md):
Poppins/Inter, larger play areas, clear semantic boundaries and rounded controls.
The current release is also available inside Games Hub, with no separate
installation needed when using the updated hub.


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

## Quiet Mines 0.3.0: board-first logic campaign

The original 12 no-guess 6×6–8×8 fields are unchanged, including their
numbering and saved marks. Fields 13–20 are 10×10 with 18 mines; fields
21–24 are 12×12 with 27 mines. The advanced fields were chosen from
candidate layouts using independently tested **direct and subset-difference
deduction**. Each can be completed from the marked zero-safe S start
without guessing. A small opening and many inference steps do not themselves
prove that every field will feel challenging; human playtesting is still needed.

The new **Hint** button computes its move from visible numbers and the
player's flags. It identifies one forced OPEN or FLAG square and highlights
it without writing to the board or consulting a hidden answer. It applies
the familiar 0/all neighboring-mines rules, then overlapping-constraint
subset logic. Because flags are player assertions, an incorrect flag can
mislead deductions; revise uncertain flags before trusting a hint.

The 480×800 layout uses a centered square field up to 460px wide, thick
monochrome borders and five wide bottom controls (Prev, Flag/Open,
Hint, Undo, Reset). There are no touch-unfriendly 14×14 boards: the
12×12 fields provide 38px cells, which still need physical finger-accuracy
testing. Browser-first 14×14 generated puzzle settings are not copied as
a claim of device support. Native fields are predefined for immediate,
deterministic opening rather than doing hundreds of regeneration attempts
on the reader.

**Save migration:** Existing `quiet-mines.txt` files with only B1–B12 are
accepted. Their boards, flags, mode, undo stacks and failures are retained;
new fields are added blank. If field 12 had been cleared, field 13 unlocks.
Changing the number of fields never renumbers or regenerates old boards.

The HTML reference's generator can return a highest-scoring candidate even
when none passes the no-guess constraints. This build uses only curated
fields with independent solver verification and has no fallback to an
unchecked layout.

Host geometry and solver checks are not proof of physical rendering or
persistent-storage capacity on the X4 Pro. Verify 12×12 taps, actual
font widths, repeated saved moves, reinstall-over-existing and sleep/wake
before treating v0.3.0 as device-tested.
