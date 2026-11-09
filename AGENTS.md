# XTEINK repository rules

Game projects, including Games Hub and shelved Paper Golf, live in `games/`.
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
gate. Append to the existing game order so legacy numeric hub resumes stay
valid; current resumes use stable app IDs. Keep code/file budgets enforced.

Use `python3 scripts/release_games.py --card <mount>` for the complete verified
build/archive/direct-update workflow. `--apply-only` deploys an already verified
latest catalogue and rejects stale source. Do not overwrite an archived version
with changed source; bump its version. Keep the rollout plan/design decisions
and deployment receipt current, and publish the integrated tested repo changes.
New standalone registrations are optional when the updated Hub contains them.
