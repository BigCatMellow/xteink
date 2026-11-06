# Pocket Golf for XTEINK X4 Pro

Offline, roll-and-choose golf for **XTOS Licorice** on the X4 Pro's 480 × 800 monochrome e-ink screen.

**Status: v0.1 prototype.** The source and build can be tested on a computer, but the game has **not yet been verified on a physical X4 Pro**.

Original, unofficial game inspired by paper-based roll-and-write golf. It does **not** reproduce Gladden Design's Paper Apps Golf art, layouts, branding, or proprietary rules. Paper Apps Golf is a separate commercial product: https://gladdendesign.com/products/paper-apps-golf

## How to play

1. Tap **ROLL**. A six-sided die sets your maximum range.
2. Tap a **ringed dot** to take a shot. The ball moves in one of eight straight directions; you may choose a shorter shot.
3. **Fairway** adds 1 to range; **sand** subtracts 1 (minimum 1). You cannot land in water or on trees; trees block shots. Flying over water is allowed.
4. Reach the flag in as few strokes as possible. Complete nine holes and compare your score with par.

No animation, accounts, or online connection. The current course, ball position, rolls, and scorecard save automatically.

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

- ROLL: roll the die and display available destinations.
- Tap any ringed space to shoot.
- NEXT: advance once the ball reaches the hole.
- NEW: confirm before discarding a round.
- The side page buttons also advance from a finished hole.

Uses the host's API 2.9 (manifest requests 2.0), no permissions, no external assets, and original line art. Packaged using MIT-licensed community tools including [kycube/x4pro-emu](https://github.com/kycube/x4pro-emu).

## Next

After an actual-device smoke test, tune legibility, input and game balance before expanding the scope.
