# Project handoff — 2026-11-07

Start here when resuming this work. Repository: **BigCatMellow/xteink**, branch **main**. Last functional wallpaper change: [`981d182`](https://github.com/BigCatMellow/xteink/commit/981d182224d63b56c867201cee90f21940490a7a).

## Next action

**Wallpaper Randomizer v0.5.0 is implemented, built, tested and staged on the SD card. Its new sleep integration still needs its first physical test.** The user has not yet reported installing/enabling v0.5.0 or seeing a wallpaper during sleep. Do not confuse the successful v0.4.6 quick preview with a completed sleep/wake test.

Follow the [wallpaper handoff](../wallpaper-randomizer/docs/HANDOFF.md). It includes the exact installer, device evidence, install steps, limitations, backups and developer commands. The user wants a new random wallpaper **only when entering sleep**, held unchanged throughout that sleep. They do not want an hourly wallpaper changer.

## Saved deliverables

- [Exact v0.5.0 installer](../releases/wallpaper-randomizer-0.5.0.xtapp), with [SHA-256 checksum](../releases/SHA256SUMS). This is the same package copied to the card, archived here independently of expiring CI artifacts.
- [Wallpaper implementation and usage](../wallpaper-randomizer/README.md), [device checks](../wallpaper-randomizer/docs/DEVICE_TESTING.md), preserved preview logs and the unshipped compact-PNG experiment linked from the handoff.
- Existing source, quality rules, tests, native icons and per-app build workflows are committed. Personal wallpapers, card backups and game save data remain on the local machine/card.

The SD card was mounted at `/media/mellow/4A21-0000` while staging. It was **not accessible at that path when this handoff was written**. Reconnect/remount before inspecting logs or copying anything. Do not infer a new device result from the old backup logs.

## Games and repository conventions

There are 12 active games in `scripts/sync_game_ui.py`. Current manifests at handoff:

| Project | Version |
| --- | --- |
| Line Lift | 0.4.1 |
| Summit Putt | 0.4.1 |
| Link Grid | 0.2.1 |
| Ink Runes | 0.2.1 |
| Lantern Logic | 0.2.1 |
| Ray Vault | 0.2.1 |
| Island Links | 0.2.1 |
| Oddity Hunt | 0.1.1 |
| Word Hunt | 0.1.1 |
| Nonogram | 0.1.1 |
| Word Bridge | 0.1.0 |
| Rectangle Rooms | 0.1.0 |

Pocket Golf / Paper Golf (`paper-golf`, app ID `pocketgolf`) is **shelved and must stay off the SD card**. Its source is preserved; do not reinstall it with the active games.

All our `.xtapp` installers belong in **SD:/Apps/**. **XTApps/** is firmware-managed installed app/save storage; do not move or replace it to organize installers. Install updates over existing apps and preserve progress, undo history and unfinished boards. Verify the SD inventory before assuming every newer repo game has already been copied/installed; this final work only staged the wallpaper update.

The user expects crisp, premium e-ink presentation. Text overlapping boards/controls was a recurring issue. Read [AGENTS.md](../AGENTS.md) and [GAME_QUALITY.md](GAME_QUALITY.md). Games use `shared/game_ui.lua` for measured text, padded controls and wrapping, with layout regressions using distinct font heights and wider glyph metrics. The wallpaper settings now use the same synchronized helper, listed under `OTHER_APPS` rather than `GAMES`.

Native icons are required for every active app. Editable SVGs are in `assets/icons/`; `scripts/make_icons.py` produces the app PNGs, and `scripts/verify_package_icons.py` checks the native packaged icon section. Host checks do not prove the real reader's typography or touch behavior.

## Last verification

Both checks passed for functional commit `981d182`:

- [Wallpaper build, renderer/cache/rotation tests, Lua compatibility and native icon](https://github.com/BigCatMellow/xteink/actions/runs/42410216245).
- [Game quality gate](https://github.com/BigCatMellow/xteink/actions/runs/42410216255), including all 12 active games.

Locally: `python3 scripts/check_games.py` passed. Wallpaper tests covered 100 new sleeps, fixed timer frames, history transactions, failures, controls and measured layouts; independent JPEG and lossless PNG/cache checks passed. **Only the JPEG preview, not the new v0.5.0 sleep integration, was physically confirmed.**

The repo has received new game commits concurrently. Fetch before publishing and preserve/rebase over unrelated changes rather than overwriting them.
