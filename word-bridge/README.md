# Word Bridge — short word-ladder puzzles on XTEINK X4 Pro

Presentation follows the [shared game design contract](../docs/GAME_DESIGN.md): Poppins/Inter, rounded controls and stronger monochrome lines. That document owns design changes, reasons and per-game exceptions.

A completely offline, black-and-white word-chain game for **XTOS Licorice** on XTEINK X4 Pro (480×800). Each level supplies twelve fixed four-letter English word cards, a start word, a goal word, and a strict move budget.

## Rules

Choose a word that differs from the current word by **exactly one letter**. Each word card can be used at most once. The aim is to reach the goal in the minimum possible number of moves. Misleading first moves make it possible to run out of moves, in which case **UNDO** can retrace your decisions.

- Tap a word card to make a move; a small circle indicates an adjacent eligible word, and filled dots indicate cards you have already used.
- **UNDO** removes the most recently selected word.
- **HINT** rings one shortest-path next step, if a solution remains; one hint per level.
- **RESET** clears the current word sequence and restores that level's hint.
- **PREV** and **NEXT** revisit unlocked levels. Page buttons also navigate unlocked levels.
- A finished word sequence remains readable after winning. Current paths and unused hints are preserved when visiting other puzzles and after relaunch.

There are **12 original word-bank puzzles**, with shortest solutions of 3–7 moves. The first word cards are not all equivalent: every level has at least one apparently eligible opening that cannot finish within the available moves.

## Why e-ink works

No keyboard, drag, animation, timer, networking, sound, or grayscale is required. All twelve words stay on one static page. A tap changes one state and redraws once.

## Verification

`tests/validate_levels.py` independently reconstructs the one-letter graph for every authored bank, calculates each shortest route by BFS and checks misleading alternative first moves. `tests/test_game.lua` replays independently specified winning sequences, tests hint usage, saved word paths and returns, input hitboxes, help and enlarged-font layouts. App packages are also checked by the repository-wide game quality gate.

## Install

1. Open the [Word Bridge workflow](https://github.com/BigCatMellow/xteink/actions/workflows/word-bridge.yml).
2. Download the **word-bridge-xtapp** artifact from the latest successful run.
3. Extract `word-bridge.xtapp`, place it in **`SD:/Apps/`** on the card, and install through Licorice **All Files**.
4. Launch through **Ink App → Word Bridge**.

Leave the firmware-managed `XTApps/` folder alone. Updating over an existing installation preserves its private save. This version has **not been physically tested**; see [device testing](docs/DEVICE_TESTING.md).

## Files

- `app/index.lua`: gameplay, renderer, hints, saves and touch input
- `app/levels.lua`: twelve original word-bank puzzles
- `app/ui.lua`: synced measured text/layout library
- `assets/icons/word-bridge.svg` and `app/icon.png`: unique 1-bit launcher icon
- `tests/validate_levels.py`: independent shortest-path verifier
- `tests/test_game.lua`: gameplay and static layout regressions
- `docs/DEVICE_TESTING.md`: hardware checks
