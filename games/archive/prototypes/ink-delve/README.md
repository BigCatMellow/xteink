# Ink Delve — paper-first dungeon prototype

An original, offline, turn-based solo dungeon drawn as a one-page 9×9 grid. Inspired by the broad **roll-and-write notebook dungeon** format, not a reproduction of *Paper Apps: Dungeon*. It does not copy Gladden Design's authored maps, movement rules, text, artwork, encounter charts, names, or packaged puzzles.

## Current delivery (2026-11-14)

- [Play the HTML prototype](prototype/index.html) in a desktop/mobile browser.
- Six hand-authored 9×9 floors; keys, stairs, coins, healing and sentinel encounters.
- Roll for 1–3-cell stride, choose one orthogonal direction, draw your route. Walls stop movement. Blocked movement does not consume the roll.
- Optional precise 1-cell movement spends focus. Sentinel encounters: fight (HP for coins), evade (focus), or bribe (coins).
- Limited lamp budget per floor, resource carryover, score and best score; auto-save after every action.
- All static 1-bit-friendly graphics, no dragging or animation, no network, no required sound.
- **Not installed on the XTEINK**: this is a browser prototype, not a native XTOS Licorice `.xtapp`.

## 480×800 UX constraints

- Entire 9×9 dungeon in a ~404×404 board without zooming or scrolling.
- Minimum ~50px buttons and large direction controls; direct selection rather than handwriting or swiping.
- Separate encounter/rules/result screens so the map does not shrink for modal overlays.
- Explicit, non-color-only markers (P, K, E, !, $, +), no grayscale-only meaning.
- Short status message and printed legend; no timed redraws.
- Physical page button behavior remains to be designed for the native package.

## Verification

Run the checked-in map regression with `python3 games/ink-delve/tests/check_maps.py` from the repository root. The browser interaction/playthrough check also ran locally with Chromium and Playwright, but is not yet part of repository CI.


- Parsed all six authored maps and confirmed every open cell, key, exit and interactive tile is reachable from the start.
- Tested roll 1–3, blocked movement not consuming the roll, focus spending on precise movement, and local saved-run restoration into a fresh page context.
- Replayed every floor through the game engine via independently planned one-cell paths to key and exit. Reached full-game victory.
- Tested all three sentinel outcomes: fight, evade and bribe.
- Inspected title, gameplay, help, encounter and victory screenshots in a 480×800 Chromium viewport; checked viewport/control bounds.
- This verifies browser behavior only. It **does not** verify e-ink refresh, native glyph metrics, installed saves, physical buttons, or on-device performance.
- The scripted full-run replay forced 1-cell moves to exercise level/transition logic; it does not establish balance or win rate under regular random stride rolls. Real playtesting is required before native release.

## Native XTOS acceptance requirements

1. Preserve `BigCatMellow/xteink` repo rules: read `AGENTS.md`, `docs/HANDOFF.md`, `docs/GAME_QUALITY.md` and `docs/GAME_DESIGN.md` before implementation.
2. Reimplement in Lua using shared `game_ui.lua`, `game_theme.lua`, `game_style.lua` and canonical typefaces. Do not embed a browser in the native app.
3. Register the new game at the end of the stable game order in the central registries, hub catalogue, theme/font syncing, icon tooling, render fixtures, testing and release pipeline. Existing installed apps and saves remain untouched until verified release.
4. Preserve run state and resource choices on leave/relaunch, and ensure accidental updates do not clear the run.
5. Run `python3 scripts/check_games.py`, native compatibility/packing/icon checks, and inspect every screen with normal and enlarged font metrics. Check Hub code limits (previous handoff reported 31/32 files).
6. Device-test text, refresh, physical buttons, save/resume, touch targets, sleep/wake, and difficulty. Never equate browser screenshots or host simulation with device verification.
7. Do not alter shelved Paper Golf or existing player saves. Do not deploy without the SD card and verified release workflow.

## Future quality work

- Balance the six-floor campaign with real rolled stride sequences and playtests; avoid a game whose outcome is mostly luck.
- Tune encounter costs, light/focus economy and score so alternate routes are meaningful.
- Consider seeded daily dungeons only after robust save/seed migration and a uniqueness/reachability validator are in place.
