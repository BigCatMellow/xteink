# Games Hub

All 17 active games in one offline XTApp. Install one package to update the
whole collection. It shares the family Poppins/Inter fonts, rounded controls,
strong monochrome strokes and each game's existing rules and puzzle generator.

Open a game from the list, or Resume the last game. Tap the nine-dot button at
the top left of a game to save and return to the list. The reader's Home action
exits the hub. Games retain separate progress, unfinished boards and undo.

## Install and update

The user's preferred update workflow is now to apply updates from this computer
while the SD card is mounted. See [direct updates](../../docs/GAME_UPDATES.md).
That updater supports the installed hub, so future bundle updates need not
involve another manual Install action if the physical replacement test succeeds.
The first installation and recovery procedure below remains available.

Copy `games-hub.xtapp` to **SD:/Apps/**. On the reader, use All Files to open
`Apps/games-hub.xtapp`, accept installation, then open **Games Hub** in the app
drawer. Future collection updates use the same package and app ID (`gameshub`):
install over the current hub to keep its saves. Installation still requires
the reader's confirmation; this app is a collection, not a background updater.

To carry over standalone-game progress with the mounted SD card:

```bash
python3 scripts/install_games_hub.py --card /media/mellow/4A21-0000 \
  --packer /path/to/touch-licorice-apps/xtpack.py
```

Run from the repo root. The helper backs up available saves and the previous
hub installer under `~/Backups/`, builds a private installer under ignored
`dist/`, copies it to `Apps/games-hub.xtapp` and verifies its checksum. Use
`--prepare-only` to inspect the package before staging. It only reads original
installed games; it never changes their firmware registration or save files.

The private package imports missing save records on first launch. Existing
hub progress takes precedence, partial imports can retry, and an import failure
blocks game launch until resolved. Later standalone play and hub play are
separate histories; updates never merge over existing hub records. Keep the
standalone apps until you've checked the imported progress on the reader.
Treat private installers as personal save backups and keep them out of releases.

## Build and maintain

```bash
python3 scripts/build_game_hub.py
python3 scripts/check_games.py --packer /path/to/xtpack.py \
  --linter /path/to/tools/lualint55.py
python3 scripts/render_game_hub.py
```

Edit each original game's source, then rebuild. `app/game_*.lua` and the shared
copies are generated; `src/` owns the hub menu, header adapter, save namespace
and importer. The builder combines each game's private modules into one module
and keeps mutable game instances separate. The catalogue records source versions
and fingerprints. CI rejects stale generated code, verifies all 17 engines
through the adapter, tests collection navigation/imports and packages the icon.

v0.3.2 includes all 17 revised games, including Crown Fields, Ten Pairs, Quiet
Mines and Sum Cross. Five game rows per page keep the list compact with large
touch targets. Resume now stores a stable game ID while reading older numeric
saves. The collection has 30/32 code files and roughly 383 KB including the XTCO table, below
the firmware's 512 KiB code ceiling. Fonts are opened for the current screen
and released when changing games. This is a host-tested release; physical
startup, repeated switching, import, sleep/resume and memory behavior still
need checking. [Actual bitmap host previews](../../docs/design/games-hub/overview.png).

The public release has **no personal save data**. Paper Golf remains shelved
and excluded. See the [design contract](../../docs/GAME_DESIGN.md) and
[quality requirements](../../docs/GAME_QUALITY.md).
