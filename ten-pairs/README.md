# Ten Pairs — static Numberama-style matching

Updates are applied directly from the computer while the SD card is mounted;
see the [family release procedure](../docs/GAME_UPDATES.md). All active games
are also available inside Games Hub, so new games do not require separate
installation when using the updated hub. Never uninstall to update.


Presentation follows the [shared game design contract](../docs/GAME_DESIGN.md):
Poppins/Inter, larger play areas, clear semantic boundaries and rounded controls.
The current release is also available inside Games Hub, with no separate
installation needed when using the updated hub.


An original, offline number-clearing game for XTOS Licorice on XTEINK X4 Pro, inspired by the traditional **Numberama/Take Ten** rules also used in Easybrain's Number Match. The layouts, stage progression, interface, and artwork are independently authored.

## Rules and controls

Tap two digits that are **equal** or add up to **10**. A pair is reachable along a row, column, diagonal or forward reading sequence when all intervening squares have been cleared. Clearing makes two cells empty without a moving animation.

**ADD** appends the still-visible digits, in their current reading order, to new rows. This version caps sheets at **88 cells (11 rows)** to preserve 480×800 legibility. It does not collapse cleared rows. **UNDO** restores the prior board or cancels a partial selection, **HINT** circles one valid pair (two hints per sheet), and **RESET** starts the current sheet over. The goal is to eliminate every digit.

Includes **12 original 8-column, 32-digit starting sheets**. An independent exact interval solver verifies every starting sheet can be completely cleared without needing ADD. There can be several correct match sequences, and some chosen pairs may make the rest harder.

The board, appended rows, selected digit, hint count, unlocks and bounded undo history all save locally. No countdown, sounds, gray marks, animated clearing, advertisements or internet.

## Install

Download **ten-pairs-xtapp** from the latest successful [Ten Pairs workflow](https://github.com/BigCatMellow/xteink/actions/workflows/ten-pairs.yml). Extract `ten-pairs.xtapp` into **SD:/Apps/**, install through **All Files**, and open in **Ink App**. Leave firmware-managed **XTApps/** intact.

Source and acceptance: `app/index.lua`, `app/boards.lua`, `app/ui.lua`, `app/icon.png`, `tests/validate_levels.py`, `tests/test_game.lua`, `docs/DEVICE_TESTING.md`.

CI simulates a full 16-pair clearing sequence for all 12 boards, the ADD mechanic, Undo/hint and max-length layout. Test physical touch accuracy, font legibility and sleep behavior on real hardware.
