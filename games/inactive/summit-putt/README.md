# Summit Putt — XTEINK X4 Pro

Updates are applied directly from the computer while the SD card is mounted;
see the [family release procedure](../../docs/GAME_UPDATES.md). All active games
are also available inside Games Hub, so new games do not require separate
installation when using the updated hub. Never uninstall to update.


Presentation follows the [shared game design contract](../../docs/GAME_DESIGN.md): Poppins/Inter, rounded controls and stronger monochrome lines. That document owns design changes, reasons and per-game exceptions.

An original, offline card-routing golf puzzle made for **XTOS Licorice** on the XTEINK X4 Pro. Inspired by the *idea* of a golf ball controlled by single-use movement cards, not a port of **Golf Peaks**. Maps, title, graphics, level arrangements, and code are original; none of the commercial game's art or stages is included.

**Status:** v0.4 — measured typography, separated header/status/control rows, programmatic gameplay tests, an in-game rules guide, and packaging workflow; **not yet verified on a physical X4 Pro**.

## The difference from Paper Golf

Paper Golf asks you to plan a route by choosing clubs repeatedly. **Summit Putt makes the cards themselves a limited resource.** You begin each level with a specific hand (for example: `1 2 3`), and each card can be played **once**. The numbers are exact movement lengths. Choose the right card order and direction to reach the flag.

**No dice, no timing, and no chance.** Use only the cards provided; each level has a tested solution, but an incorrect order can leave you stuck. There are 10 original handcrafted levels, with height changes and uphill ramps introduced in levels 9 and 10.

## How to play

1. Select a numbered **card** from the bottom row.
2. Tap **UP, RIGHT, DOWN, or LEFT**.
3. The ball moves that exact number of squares, one cell at a time. A used card is crossed out.
4. Avoid blank gaps and water. The ball cannot move through them. Sand (when used) permits only a one-square shot.
5. Higher platforms are marked with doubled edges. To climb from low to high, the destination must be a ramp, and your shot must enter in the direction indicated by the arrow on that ramp. You can move along a high plateau normally and descend to a lower tile.
6. Land on the flag exactly (overshooting doesn't count). If you run out of cards, use **UNDO** or **RESTART**.

Successful levels unlock the next one. The app saves current position, cards consumed, undo history, and unlocked progress.

## Controls

- Touch a card to select it; used cards are visibly crossed out.
- Touch any of the four large direction buttons to take a shot.
- **UNDO** restores the previous position **and card**, even after completing a stage.
- **RESTART** retries the current level; previously unlocked levels are retained.
- **?** shows the in-game rule guide, including the elevation and ramp rules introduced later.
- The reader's physical page buttons cycle through unused cards.
- After solving a level, tap **NEXT PUZZLE**. Finishing level 10 permits replay.

Only a valid, complete shot consumes a card. Invalid directions show a message rather than wasting a turn.

## Installing on Licorice

1. Open the [Summit Putt GitHub Actions workflow](https://github.com/BigCatMellow/xteink/actions/workflows/summit-putt.yml).
2. Download the latest successful **summit-putt-xtapp** artifact, unzip, and copy `summit-putt.xtapp` to the microSD root in USB mode.
3. On the device, open **All Files** and tap the `.xtapp` to install.
4. Open **Ink App → Summit Putt**. If Ink App is hidden, open Settings → About and tap Model ten times quickly.

No flashing or firmware replacement is required. Community packaging and device APIs are unofficial; test on a current Licorice build.

## Source

- `app/index.lua`: the full game logic, original levels, renderer, controls, saves.
- `app/manifest.json`: Licorice app metadata.
- `tests/test_game.lua`: separate shortest-solution search for every stage, invalid-move rules, ramp rules, undo, persistence, interaction, and rendering.
- `docs/DEVICE_TESTING.md`: physical-device acceptance checks.
- `.github/workflows/summit-putt.yml` (repo root): tests and packaging.

### Design choices for e-ink

- Static **7 × 7** boards rather than animation or scrolling.
- Monochrome tile borders, raised-edge outlines, simple ramps and a flag.
- Large touch targets and simple numerals suitable for the 480 × 800 panel.
- One screen refresh per decision.
- Progress saved locally with `ctx.storage`.

### Next after the hardware smoke test

Adjust type size/contrast and difficulty based on the actual reader. A more isometric view is possible later, but only if it remains legible and touch-friendly on the small e-ink screen.

### Reference

The inspiration is [Golf Peaks by Afterburn](https://afterburn.games/press/sheet.php?p=golf_peaks). This is an independent, unofficial work.
