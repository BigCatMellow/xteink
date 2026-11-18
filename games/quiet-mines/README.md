# Quiet Mines — randomly generated no-guess Minesweeper on XTEINK X4 Pro

Updates are applied directly from the computer while the SD card is mounted;
see the [family release procedure](../../docs/GAME_UPDATES.md). All active games
are also available inside Games Hub, so new games do not require separate
installation when using the updated hub. Never uninstall to update.


Presentation follows the [shared game design contract](../../docs/GAME_DESIGN.md):
Poppins/Inter, larger play areas, clear semantic boundaries and rounded controls.
The current release is also available inside Games Hub, with no separate
installation needed when using the updated hub.


A static, offline Minesweeper implementation for the X4 Pro. **All new fields are generated from a randomized seed** and independently checked for a no-guess solution before being offered.

## Current gameplay (v0.5.0): no prebuilt levels

Fresh play opens with generated Field 1 (internal archive ID 25), with Easy 8×8, Normal 10×10, and Hard 12×12 available. **New** creates another verified board, and **Prev** from Field 1 cannot enter the old fixed campaign. Historical fields are stored only in `app/legacy_levels.lua` to keep previously installed saves readable, including their marks and history. They are not offered to new players. The older sections below describe those pre-v0.5.0 releases and legacy save support.

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

## v0.4.0 — procedural fields by default

A new installation starts with a generated field at archive ID 25, not
with an authored field. The **New** button always generates another
board, even before the current one is solved. The difficulty selector
cycles **Easy (8×8, 10 mines)**, **Normal (10×10, 18 mines)** and
**Hard (12×12, 27 mines)**. The top-right selector changes the *next*
board, leaving the current field untouched. The browser preview also
generates and replays layouts from explicit integer seeds.

The user's mobile HTML supplied the method: seed a PRNG, place mines
outside the safe-start neighborhood, flood-reveal S, apply basic
arithmetic and overlapping-number subset deductions, and accept only
candidates proven solvable. The Lua implementation uses bounded attempts
to avoid unresponsive generation, and rejects candidates that fail.
**It never falls back to an unchecked board.** If no suitable field is
found within the attempt budget, existing progress stays intact and
New can be retried. The independent Python solver separately validates
generated fields against their hidden mine positions.

Legacy fields 1–24 still exist only to reopen existing saves; they are
not the source of random boards. New fields store their *actual mine
positions* with their seed, progress and undo in a 64-shard archive.
That protects an unfinished layout even if the generation algorithm
later changes. A completed generated board does not unlock an empty
archive slot; a real new board must be generated and saved first.

Random selection guarantees different seeds, not mathematically perfect
uniqueness across an unlimited number of boards. No-guess solvability is
verified, but human challenge, real-device generation latency, save quota,
12×12 finger targets and e-ink ghosting still require physical checks.

## v0.5.1 — clean portrait field

All generated 8×8/10×10/12×12 layouts keep their exact mine positions and
solver guarantees. The grid is now one continuous shared 2px grid with a 4px
frame, not separate inset rectangles in each unopened tile. The latter are
identified by a minimal right/bottom one-pixel bevel, so opened blank cells
remain distinguishable. The meaningless 5×5 boundary emphasis was removed.

Large bottom controls have restrained one-pixel shadows and one emphasized
outline for Flag mode/Hints, not a second decorative box. The browser
preview mirrors these changes. No hitbox, hint, undo, or save format changed.
