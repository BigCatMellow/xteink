# Island Links — original Bridges/Hashi logic game for XTEINK X4 Pro

Updates are applied directly from the computer while the SD card is mounted;
see the [family release procedure](../docs/GAME_UPDATES.md). All active games
are also available inside Games Hub, so new games do not require separate
installation when using the updated hub. Never uninstall to update.


Presentation follows the [shared game design contract](../docs/GAME_DESIGN.md): Poppins/Inter, rounded controls and stronger monochrome lines. That document owns design changes, reasons and per-game exceptions.

A compact, static monochrome version of the classic **Bridges (Hashiwokakero)** logic puzzle, with 12 original boards specifically built for the 480×800 XTEINK X4 Pro on XTOS Licorice.

## Rules

The number on each island says how many bridge lines must touch it in total. Islands connect only horizontally or vertically to their **nearest visible neighbor**. Two islands can have **one or two** parallel bridges, or none. Bridges never cross and **all islands must belong to one connected network**.

Touch a connection path between two islands to cycle through **zero → one → two → zero** bridges. Lines appear or disappear on a single static e-ink redraw, never in motion. Potential connections show a small short dash.

- **UNDO** returns to the last bridge configuration.
- **RESET** restarts the board.
- **PREV/NEXT** navigate previously unlocked levels; NEXT unlocks after solving.
- Reader page buttons navigate levels without drawing bridges.

Levels 1–3 have 7 islands, 4–7 have 8, and 8–12 have 9. Each of the 12 authored configurations is independently solver-verified to have **exactly one** valid connected noncrossing solution; every level requires at least two double bridges.

Progress and a bounded undo history are saved locally. The app needs no internet, sound, animation, scrolling or timers.

Previous/Next now retain each visited board instead of silently restarting it.
Existing version-1 saves remain readable. Layout and save regressions are checked
by the repository [game quality gate](../docs/GAME_QUALITY.md).

## Install on X4 Pro

1. Open [Island Links builds](https://github.com/BigCatMellow/xteink/actions/workflows/island-links.yml).
2. Download the latest successful **island-links-xtapp** artifact, extract `island-links.xtapp`.
3. Copy the XTApp to the microSD root using USB mode and install from **All Files**.
4. Launch from **Ink App → Island Links**.

The build and simulator tests do not prove actual touch accuracy or font rendering. See `docs/DEVICE_TESTING.md` for physical acceptance tests.

## Source

- `app/index.lua`: original 12 boards, geometric link derivation, degree/connection solver, monochrome renderer, touch and save/restore.
- `app/manifest.json`: Licorice app declaration.
- `tests/test_game.lua`: end-to-end gameplay, input, undo, and e-ink rendering.
- `tests/validate_levels.py`: independent exact-solution uniqueness checker.
- `docs/DEVICE_TESTING.md`: hardware verification steps.
- `.github/workflows/island-links.yml`: build and package job.

Rules background: [Hashiwokakero / Bridges](https://www.nikoli.co.jp/en/puzzles/hashiwokakero/). All levels and the user interface are independently authored.
