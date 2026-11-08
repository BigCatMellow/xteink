# Applying updates on the mounted SD card

The user's intended workflow is: **when we put an update on the SD card, apply
it to the installed game too**. They should not have to tap Install separately
for every updated game. Games Hub v0.1.0 reduced package count, but its original
manual-install instructions did not fulfill this requirement.

`scripts/update_installed_games.py` is a computer-side updater for existing
installed games. It replaces only `XTApps/<app_id>/app.xtapp`. It leaves game
identity, registration directories, saves and all other files in place.
No on-reader updater app or persistent desktop service is installed.

## One-command family release

The current family contains **17 games**, including Crown Fields, Ten Pairs,
Quiet Mines and Sum Cross. After integrating upstream games and making changes:

```bash
python3 scripts/release_games.py --card /media/mellow/4A21-0000
```

This exports canonical assets, synchronizes helpers, builds the complete hub,
runs the full quality gate, archives immutable versioned packages and a recovery
ZIP, updates the latest catalogue, backs up the live card, applies installed
game/hub updates, refreshes recovery installers and verifies all app data.
Use `--packer` and `--linter` when the pinned tools are elsewhere. Omit `--card`
to prepare a release without touching the SD card, then deploy it with:

```bash
python3 scripts/release_games.py --apply-only --card /media/mellow/4A21-0000
```

Apply-only requires the source to match its verified fingerprints. The complete
hub makes newly added games available without individually registering their
standalone packages. First-time standalone registration remains optional.
The low-level updater procedure below is retained for targeted deployments.

## Developer update procedure

1. Make the changes, bump versions, complete the quality gate and package the
   release. Maintain a release catalogue with file, app ID, version, byte length
   and SHA-256 (the existing family release JSON is an example).
2. Read the updater's plan using the actual mounted card and current catalogue.
3. Apply the plan with a backup on this computer. Verify the receipt. Keep
   recovery installers under `SD:/Apps/`, but do not count that copy as applying
   an update. Tell the user exactly which installed games were updated.
4. Safely eject and test opening the existing game on the reader. It may need
   its app list refreshed/reopened. Do not claim physical success from a host
   package replacement alone.

```bash
python3 scripts/update_installed_games.py --card /media/mellow/4A21-0000 \
  --catalogue releases/game-family-latest.json
python3 scripts/update_installed_games.py --card /media/mellow/4A21-0000 \
  --catalogue releases/game-family-latest.json --apply
```

For an already installed Games Hub, use its release metadata instead:
`--catalogue releases/games-hub-0.3.3.json`. This updates the bundle in place;
individual game packages do not update engines embedded in an older hub.
An uninitialized hub is skipped until its first-launch import is complete.
The default family catalogue points to `game-family-latest.json`; update that
index whenever archiving a tested release, so normal deployments include the
current Sudoku version instead of using an older dated family manifest.

The updater validates package headers, IDs, versions and catalogue checksums
before writing. It skips current/newer versions and absent apps, and rejects
changed permissions/API/lockscreen setup requiring firmware installation.
All selected app directories are backed up and verified before replacement.
Each new package is written to an exclusive temporary file, flushed, verified
and renamed. All other file hashes must remain unchanged. Failures attempt
to restore changed packages from backup; a disconnected/unavailable card may
need recovery after reconnection. Backups and plan/receipt remain on the host.
It does not create installed-app directories or silently register new games.

## Evidence and current limit

The user's real installed-app backup contains only `app.xtapp` plus `files/`.
Ten archived installed packages were updated to the current family releases on
a fake card; all 18 save files stayed byte-identical, the three absent games
were skipped, and a second run had no updates. Regressions cover corrupt
releases, changed permission declarations, downgrade prevention, symlinks,
stale plans, collection metadata/import guard and rollback after a failed write.
These tests run in the game quality gate.

**Direct replacement still needs its first physical reader test.** The firmware
may cache installation metadata not represented in the backup. Do not promise
it works on-device until an existing game launches the newer version after
replacement. On 2026-11-08, the mounted card received its first direct update:
Sudoku 0.2.0 → 0.3.0 and Games Hub 0.1.0 → 0.2.0. Both installed packages and
their recovery installers were flushed and checksum-verified. All 326 app-data
files and all other installed files stayed unchanged. The other 12 standalone
games were already current. Backup/receipt paths are recorded in
[HANDOFF.md](HANDOFF.md); a reader-launch result is still pending.

The documented [runtime sandbox](https://github.com/omer-faruq-xteink/touch-licorice-apps/blob/main/docs/firmware-notes.md)
restricts apps to their own save directories and exposes no verified package
installer API. This host-side route avoids depending on an invented native
installer call. Source changes remain local until explicitly published.
