# Pocket Golf for XTEINK X4 Pro

Offline, exact-distance puzzle golf for **XTOS Licorice** on the X4 Pro's 480 × 800 monochrome e-ink screen.

**Status: v0.3 monochrome strategy prototype.** The source and build can be tested on a computer, but the game has **not yet been verified on a physical X4 Pro**.

Original, unofficial game inspired by paper-based roll-and-write golf. It does **not** reproduce Gladden Design's Paper Apps Golf art, layouts, branding, or proprietary rules. Paper Apps Golf is a separate commercial product: https://gladdendesign.com/products/paper-apps-golf

## Visual design (v0.2)

The course artwork now follows a **minimal top-down paper-grid aesthetic** rather than the earlier scattered-symbol layout. Because the X4 Pro screen is monochrome, meaning replaces color:

- **Fairway and putting green:** continuous, stepped outlines with tiny sparse marks; no large black fills.
- **Water:** grouped, outlined blocks containing repeating small waves.
- **Sand:** clustered, outlined blocks with stippled dots.
- **Trees:** solid small triangles; rough remains mostly empty dotted paper.
- **Ball:** double outline ring. **Cup:** black dot and a small outlined flag.
- **Available shots:** thin circles appear on reachable grid positions after a roll.

The 9×12 course now takes most of the portrait screen. A compact header, a small NEW button, and three large club selectors preserve e-ink-friendly touch controls. The app draws all graphics in black on white and doesn't rely on colored shades. This intentionally follows the *visual structure* of the supplied reference, without copying a specific course.

**Compatibility:** This revision changes procedural layouts; an unfinished round saved by the previous version may look different after updating. The device still needs a physical smoke test.

## How to play

This is now a **deterministic shot-planning puzzle, not a luck-based dice game**. The course is generated once per hole, then stays fixed. Every valid shot is predictable.

1. Select a club: **PUTT = exactly 1** grid square, **CHIP = exactly 2**, **DRIVE = exactly 4**. Shots travel in one of eight straight directions.
2. The game shows **ringed landing spaces** for that club. Tap any ring to take the shot.
3. A **tree blocks a flight path**. You can fly **over water**, but cannot land in it. Sand permits only a putt to escape; rough permits putts and chips but not a drive.
4. Reach the hole using as few shots as possible. Each hole's **TARGET** is calculated by a shortest-path search over the same rules the player uses, so matching it is always theoretically possible.
5. Finish nine holes and compare your total strokes with the total optimum.

The important decision is how to position the ball for the **next** shot: taking a longer club now may land in rough, cost a recovery shot, or leave no good line to the flag. No randomness enters shot selection, power, or hazard outcomes.

No animation, accounts, or online connection. Course seed, current ball, chosen club, stroke count, and scorecard are saved automatically.

### Save compatibility

Version 0.3 introduces a new save format. An unfinished round from the old **dice-based** build resets when this version first runs; older saves are not reinterpreted as club-based rounds.

## Project files

- app/index.lua — game, drawing, touch controls, save/load
- app/manifest.json — Licorice package metadata
- tests/test_game.lua — rules tests (Lua 5.4)
- ../.github/workflows/build.yml — root workflow that tests and packages a downloadable XTApp artifact
- docs/TESTING.md — hardware acceptance tests

## Install

The [GitHub Actions build](https://github.com/BigCatMellow/xteink/actions/workflows/build.yml) produces a **pocket-golf.xtapp** downloadable workflow artifact when CI passes. Download the artifact and unzip it.

With an X4 Pro running XTOS Licorice, enter reader USB mode, copy the XTApp onto the microSD root, exit USB mode, then open **All Files**, tap the package, and confirm install. If the **Ink App** menu is missing, go to **Settings → About** and tap **Model** ten times rapidly; open **Ink App** from the side drawer.

This procedure does not replace firmware. Package signing is unofficial, so installability may depend on your Licorice version.

For local builds: use Python 3.10+, install the cryptography package, and run **python xtpack.py APP_DIR -o OUTPUT** with this repository's app folder, from a checkout of [omer-faruq-xteink/touch-licorice-apps](https://github.com/omer-faruq-xteink/touch-licorice-apps). See the CI workflow for the pinned packer commit.

## Controls

- Tap **PUTT 1**, **CHIP 2**, or **DRIVE 4** to choose the exact shot distance.
- Tap any ringed square to shoot. Water is not a valid landing; trees block the shot.
- **NEXT HOLE**: advance once the ball reaches the hole.
- **NEW**: top-right button confirms before discarding the current round.
- Side page buttons cycle clubs, or advance from a completed hole.

Uses the host's API 2.9 (manifest requests 2.0), no permissions, no external assets, and original line art. Packaged using MIT-licensed community tools including [kycube/x4pro-emu](https://github.com/kycube/x4pro-emu).

## Next

After an actual-device smoke test, tune legibility, input and puzzle difficulty before expanding the scope.
