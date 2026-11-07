# XTEINK repository rules

Read [docs/GAME_QUALITY.md](docs/GAME_QUALITY.md) before changing a game.

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
- Update the manifest version for changed installable apps. Install over existing
  apps; do not uninstall or discard saves to test an update.
- Host font models do not prove physical rendering. State device checks still
  needed; never call a package device-tested because CI passes.

These rules and the quality workflow apply to future game contributions as well
as current games. Do not weaken tests just to accommodate a failing layout.
