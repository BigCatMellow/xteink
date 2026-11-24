# XTEINK repository rules

Active games, Games Hub, and separately shelved Paper Golf live in `games/`.
User-parked games live in `games/inactive/`; they retain source, IDs and saves,
but must not enter active builds, registries or releases until explicitly restored.
The current active baseline is Nonogram, Sudoku, Quiet Mines and Lights Out.
See `games/inactive/README.md` for the planned new game family.
Archived reasoning-light games live in `games/archive/` with original sources,
IDs, tests, icons, and workflow definitions preserved. Do not accidentally
restore them to active registries, the Hub, or new release catalogues. Preserve
installed saves and the original 17-slot numeric Hub resume mapping.
Every active game's reasoning-depth evidence and known difficulty gaps must be documented
in `games/REASONING_AUDIT.md`; solver uniqueness alone does not establish challenge.
Keep registry/release keys stable and use `scripts/sync_game_ui.py`'s
`project_path()` to resolve source locations. The shell project owns its docs,
tools and focused tests under `shell/`; use `shell/README.md` as its entry point.
Shared UI/assets and collection-wide scripts/tests remain at the repo root.

Read [docs/HANDOFF.md](docs/HANDOFF.md) for the saved project state and next
device check before resuming earlier work. Wallpaper-specific evidence and
backups are linked there. Do not treat a passing preview as a verified sleep screen.

Read [docs/GAME_QUALITY.md](docs/GAME_QUALITY.md) before changing a game.
Read [docs/GAME_DESIGN.md](docs/GAME_DESIGN.md) for the adopted shared visual
contract, per-game exceptions, change reasons and required visual evidence.

- Fix the behavior and add a regression that fails without the fix. Passing
  command-count or solution tests alone does not establish layout quality.
- Use `shared/game_ui.lua` for measured text, padded buttons and bounded
  paragraphs. Sync its app copies with `python3 scripts/sync_game_ui.py`.
  Do not bypass it with raw canvas text calls in games.
- Keep drawing geometry and touch hitboxes synchronized. Reserve explicit board,
  header, status and control space within 480×800. Verify every level, help and
  solved screen with distinct font sizes and enlarged glyph-width metrics.
- Design for **purposeful full-screen use** on the 480×800 reader. Give the
  puzzle/clues the largest *usable* play region, collapse repetitive header
  and instruction text, and keep controls close to gameplay. Do not leave
  unexplained empty bands merely because a phone-style layout has fixed rows.
  Do not distort square boards, reduce touch targets, or add decorative filler.
  Follow the screen-space contract in `docs/GAME_DESIGN.md` and the required
  visual review in `docs/GAME_QUALITY.md` before adding or substantially
  redesigning a game.
- Preserve valid saves, app IDs, unlocked progress, unfinished boards and undo
  history through update, relaunch and level visits. Only explicit reset clears
  a board. A correct but unsubmitted answer is a valid in-progress save.
- Add new games to `scripts/sync_game_ui.py` and the quality runner. Do not
  silently exempt them from checks. Pocket Golf (`paper-golf`) is shelved:
  leave it unchanged and off the SD card unless the user requests it.
- Run `python3 scripts/check_games.py` before handoff. Also run Lua compatibility
  checks and build packages when code changes; the quality workflow does both.
- Use `shared/game_style.lua` and `shared/game_theme.lua` for game presentation.
  Rebuild fonts with `scripts/make_game_fonts.py`, then sync with
  `scripts/sync_game_theme.py`. Do not fork app-local fonts or style constants.
  Run the bitmap gameplay suites and inspect `scripts/render_games.py` previews.
  Record design changes and their reasons in `docs/GAME_DESIGN.md`.
- Update the manifest version for changed installable apps. Install over existing
  apps; do not uninstall or discard saves to test an update.
- **Procedural generation is mandatory for every active puzzle game.** Fresh
  installs and New must generate original offline puzzles, not select a fixed
  bank or merely transform an authored board. Validate solutions, bound work,
  offer retry without losing progress, and prove seed replay, variety, and
  save compatibility. Fixed boards are permitted only as legacy-save records
  or test fixtures, never as the default or a fallback. Difficulty must be
  based on reasoning evidence, not just board size. Register generation
  evidence in the procedural acceptance gate; no new game may enter without
  gameplay-level generation tests. Existing named migration gaps block family
  release until resolved. See [procedural contract](docs/PROCEDURAL_PUZZLES.md).
- Generated puzzle seeds are a save format: keep v1 boards stable or migrate
  them explicitly. Sync `shared/puzzle_store.lua` with
  `python3 scripts/sync_puzzle_store.py`. Numbered puzzle history must stay below
  Licorice's 512-file quota without evicting valid saves.
- Every active app needs a distinct native icon. Keep editable vectors in
  `assets/icons/`, generate `app/icon.png` with `scripts/make_icons.py`, and
  verify the packaged XTAB/XIC section with `scripts/verify_package_icons.py`.
- Deliver all our `.xtapp` installers in `SD:/Apps/`, not the card root. Preserve
  `XTApps/` as the firmware-managed location for installed apps and save data.
- The user expects updates applied to existing installed games when we load
  updates onto the SD card, without manually installing each package. See
  `docs/GAME_UPDATES.md` and use `scripts/update_installed_games.py` with the
  current tested release catalogue, host backups and verified save preservation.
  Staging installers in Apps/ alone does not satisfy that request. Direct package
  replacement still needs a physical check; do not claim it verified prematurely.
- Host font models do not prove physical rendering. State device checks still
  needed; never call a package device-tested because CI passes.

These rules and the quality workflow apply to future game contributions as well
as current games. Do not weaken tests just to accommodate a failing layout.

The user requested a complete family workflow, without repeated per-game design
approval or manual package installation. Before a family pass, fetch origin and
integrate new active games while preserving local work. Register every new game
in GAMES, theme/font syncing, hub descriptions, render fixtures and the quality
gate. Keep the retained relative order, and append new games so legacy numeric hub resumes stay
valid; current resumes use stable app IDs. Keep code/file budgets enforced.

Use `python3 scripts/release_games.py --card <mount>` for the complete verified
build/archive/direct-update workflow. `--apply-only` deploys an already verified
latest catalogue and rejects stale source. Do not overwrite an archived version
with changed source; bump its version. Keep the rollout plan/design decisions
and deployment receipt current, and publish the integrated tested repo changes.
New standalone registrations are optional when the updated Hub contains them.
