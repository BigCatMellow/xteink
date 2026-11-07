# Lantern Logic — static Light Up puzzles for XTEINK X4 Pro

An original implementation of the public-domain-style **Akari / Light Up** logic puzzle, with 16 newly generated, frozen and solver-verified boards. The app uses only black-and-white 480×800 graphics, tap input and a static redraw. No animation, networking, clocks or sound. It is a separate Ink App for XTOS Licorice.

## Rules

Place bulbs on white cells to illuminate every white square in the same row and column until blocked by a black wall. Two bulbs **must not see each other** along an unobstructed row or column. A digit on a black wall demands exactly that many bulbs in its four adjacent cells. Unnumbered walls only block light.

- Tap a white square: bulb → X (known empty) → clear.
- Illuminated white squares carry a tiny dot in their corner; no grayscale is used.
- Bulbs are outlined circles with four rays.
- A full board is solved when all white cells are lit, no two bulbs see one another, and all numbered walls are satisfied.
- A conflict remains visible as a message; the game does not silently fix incorrect moves.
- **UNDO**, **RESET**, **PREV**, and **NEXT** appear below the puzzle. NEXT unlocks after a correct solution.

Boards 1–5 are 5×5, 6–11 are 6×6, and 12–16 are 7×7. Every board has exactly one bulb configuration solving all constraints, verified independently by the project's Python solver.

## Install on Licorice

1. Visit the [Lantern Logic build](https://github.com/BigCatMellow/xteink/actions/workflows/lantern-logic.yml).
2. Download the latest successful **lantern-logic-xtapp** artifact, unzip and copy `lantern-logic.xtapp` to the reader's microSD root.
3. Open **All Files** and install the package; launch **Ink App → Lantern Logic**.

This is designed for your X4 Pro. The host-side build, tests, and app packaging cannot confirm physical display and touch behavior. See `docs/DEVICE_TESTING.md` before calling it device-tested.

## Structure

- `app/index.lua`: puzzle rules, board renderer, level data, touch input, save/restore.
- `app/manifest.json`: XTOS Licorice Ink App declaration.
- `tests/test_game.lua`: host emulator with all 16 solutions and input/undo checks.
- `tests/validate_levels.py`: independent exact-constraint uniqueness solver.
- `docs/DEVICE_TESTING.md`: physical-device acceptance criteria.

Rules reference: [Nikoli's Akari description](https://www.nikoli.co.jp/en/puzzles/akari/). No publisher's specific layouts or artwork were used.
