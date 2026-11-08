# Link Grid — XTEINK X4 Pro

Updates are applied directly from the computer while the SD card is mounted;
see the [family release procedure](../docs/GAME_UPDATES.md). All active games
are also available inside Games Hub, so new games do not require separate
installation when using the updated hub. Never uninstall to update.


Presentation follows the [shared game design contract](../docs/GAME_DESIGN.md): Poppins/Inter, rounded controls and stronger monochrome lines. That document owns design changes, reasons and per-game exceptions.

An original **minimalist tile-and-line puzzle** for **XTOS Licorice**, designed for the XTEINK X4 Pro's 480 × 800 monochrome e-ink display. Inspired by the elegant single-tap puzzles of *klocki*; **not a port or reproduction** of its levels, assets, or proprietary rules.

**Status: v0.2.** All 20 puzzles are frozen and independently solver-checked for a **unique connected solution**. CI verifies source, measured layouts, navigation, saves and packaging. The app still needs a smoke test on a physical X4 Pro.

## Rules

The board contains tiles with black line segments. **Tap a tile to rotate its lines clockwise 90 degrees.** When all line ends match their neighbors, no line leaves the board, and **every nonempty tile belongs to one connected network**, the level is complete.

- **Empty tile:** no lines; it cannot be rotated.
- **Endpoint:** one line arm. **Corner:** two adjacent arms.
- **Straight:** opposite arms. **Junction:** three arms. **Cross:** four arms.
- **Corner square marker:** this is a **fixed anchor tile** and cannot rotate.
- **NEXT** appears after solving, or when visiting a level you previously unlocked.
- **PREV** moves to an earlier level. **RESET** restores the original orientation of that level.

Puzzles 1–10 use **4×4** boards, and 11–20 use **5×5** boards. The early puzzles teach the arm-matching idea; later boards contain more branches and larger networks.

**No random dice, no timers, no animation, no gray shades.** A tap updates the entire screen once; there are no intermediate states, moving pieces, fading, or refresh loops. The game works fully offline.

## Why the levels aren't random

The 20 boards were generated and selected offline, then **frozen into the app**. A separate Python constraint solver checks every authored tile type, fixed tile, board boundary, matched connection, and full-network connectivity.

The CI verifier rejects a puzzle if it:
- starts already solved;
- has zero or multiple valid solutions;
- has fewer than four incorrectly oriented tiles;
- changes a fixed tile or loses a connection;
- has a disconnected valid-looking network.

The Lua gameplay tests independently exercise **all 20 correct solutions** as tap sequences, including save/restart and unlock behavior. This guards against solvable-but-broken levels, though real enjoyment still requires playtesting.

## Controls

- **Touch a tile:** rotate 90°; the screen redraws once.
- **RESET:** try the current board again.
- **PREV/NEXT:** navigate cleared or unlocked levels.
- **Physical page buttons:** previous/next level where permitted. Buttons never rotate a tile accidentally.

Progress and current tile orientations save automatically to `link-grid.txt` in the app's private storage. No account or network access needed.

Previous/Next now retain each visited board instead of silently restarting it.
Existing version-1 saves remain readable. Layout and save regressions are checked
by the repository [game quality gate](../docs/GAME_QUALITY.md).

## Install on Licorice

1. Open the [Link Grid build workflow](https://github.com/BigCatMellow/xteink/actions/workflows/link-grid.yml).
2. Select the latest **successful** run and download the **link-grid-xtapp** artifact.
3. Unzip `link-grid.xtapp`, copy it to the root of the microSD card in USB mode.
4. On the reader, open **All Files**, tap the package and confirm installation.
5. Start **Ink App → Link Grid**. If Ink App is hidden, tap **Settings → About → Model** ten times quickly.

No firmware replacement is necessary. Installing over an existing version preserves app data, but uninstalling can remove it.

## Source files

- `app/index.lua` — game rules, fixed puzzles, renderer, touch controls, saving.
- `app/manifest.json` — XTOS Licorice app manifest.
- `tests/test_game.lua` — host-stub tap gameplay, progress and graphics testing.
- `tests/validate_levels.py` — independent puzzle-solution and uniqueness checker.
- `docs/DEVICE_TESTING.md` — physical X4 Pro acceptance checks.
- `.github/workflows/link-grid.yml` — Python/Lua tests, Lua 5.5 compatibility check and package build.

## Hardware caveat

The project is a prototype. The device itself has not yet been used to verify touch target alignment, glyph sizes, contrast, persistence through sleep, or any firmware-specific differences. The automated build passing is not proof of device compatibility.
