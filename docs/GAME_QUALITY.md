# Game quality and release checks

## Layout

Text must fit a named area on the 480×800 screen. Use real firmware
`font:measure()` and `font.line_height`; do not center by character count or
assume small/medium/large have identical metrics. `UI.text` bounds single-line
labels, `UI.button` adds padding, and `UI.paragraph` wraps instructions. Keep
essential rules readable; shorten the wording or allocate more space instead
of silently truncating them. Explicitly update touch geometry when moving a
control. Mark board extents with `UI.region` so text cannot straddle them.

The canonical helper is `shared/game_ui.lua`. App-local `ui.lua` files are
generated copies because XTApp packages cannot import files outside their own
app. Run `python3 scripts/sync_game_ui.py`; CI rejects drift or raw text calls.

The adopted presentation contract is [GAME_DESIGN.md](GAME_DESIGN.md).
`scripts/sync_game_theme.py` verifies the shared theme, style tokens, bitmap
renderer, glyph data and licenses in all active game packages. The quality gate
also replays each full gameplay suite through `tests/run_themed_game.lua`, using
the actual shipped bitmap metrics, glyph ink bounds and cache lifecycle. The
canonical font sources/export live under `assets/fonts/game-ui/` and `shared/`.

Use crisp lines, understandable symbols, consistent spacing and readable type.
E-ink does not excuse weak presentation. Color or grayscale must not be the
only explanation of a state; avoid gratuitous refreshes and animations.

## Required regressions

Every active app must have a distinct 96×96, 1-bit `app/icon.png`, rendered from
its SVG in `assets/icons/`. Keep important ink at least 6px away from the edges
because the app grid rounds its icon slots. Run `python3 scripts/make_icons.py`
to regenerate or `--check` to compare source/export pixels. `--sheet dist/icons.png`
creates a review sheet at 96px and 64px. No new raster art dependency is needed.
The packer embeds these PNGs as native XTAB/XIC icon data. The quality runner
decodes that data and compares every pixel with the source icon, catching missing
sections, incorrect dimensions, wrong bit order and inverted black/white.

- Exercise all authored boards and solved screens using `tests/game_canvas.lua`.
  The two font profiles have distinct 20/24/30px line heights, variable glyph
  widths and an additional 25% width margin. These are conservative models,
  not extracted firmware font metrics.
- Check help, hints, selection, conflict, stuck and maximum-counter states where
  applicable. Tests must check actual text rectangles, not merely drawing count.
- Reject text/text collisions, text crossing controls or board boundaries,
  off-screen text and overflowing instruction paragraphs. The guard has negative
  self-tests including the old Summit caption/Undo collision.
- Reopen partially completed games, completed games, and correct answers awaiting
  submission. Preserve the current level and global unlocks. Ray Vault's old
  correct-before-CHECK reset is a mandatory regression.
- Visit another unlocked level, close/reopen, and return. Preserve the board and
  undo history. Reset is a separate action. Keep old save formats readable.
- Replay independently specified solutions and validate authored puzzle
  constraints. Keep input release/debounce and static redraw tests.

For features outside a particular game's controls, document why the state is
not applicable; do not invent a blanket exemption.

## Run locally

```bash
python3 scripts/sync_game_ui.py --check
python3 scripts/check_games.py
python3 scripts/check_games.py --packer /path/to/xtpack.py --linter /path/to/lualint55.py
```

Python 3, Lua 5.4 and the packer's crypto prerequisites are used in CI. Existing
games are also compatible with the desktop's Lua 5.1 host tests. Add new games
to the game list in `scripts/sync_game_ui.py`; the runner discovers manifests
and fails if a game is missing from that list. The global workflow runs on pushes
and pull requests, including changes to shared helpers and tests.

## Physical release check

Games Hub is registered under `COLLECTIONS` alongside `GAMES`, with mandatory
checks in the same runner. `build_game_hub.py --check` rejects source drift and
firmware code/file budget overflow. The original gameplay suites run through
every bundled engine and namespaced context, both native and bitmap. Hub tests
check the reserved header menu target, all menu pages, actual game switching,
saved boards/undo, read/write failures, font cleanup and first-launch import
retry/no-overwrite behavior. The USB migration test uses a fake card. No
personal save payload may be checked into `games-hub/app` or public releases.

Install over the previous app without removing its files. Check real font
placement, clear line intersections, touch targets, sleep/resume and existing
save data. Verify all changed screens and record the firmware version and any
failures. Keep a backup before updating the SD card. CI does not establish
physical-device compatibility. Pocket Golf remains excluded while shelved.

The workflow adds a check to pull requests. Requiring that check before merge
also depends on the repository's GitHub branch-protection settings.
