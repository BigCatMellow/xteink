# Xteink projects

Apps and experiments for the Xteink X4 Pro running XTOS Licorice.

- [Shell / OS project](shell/README.md) — the card-loaded shell (Games Hub 0.4.0: Home, reading progress, Library, Games, landscape), plus research, roadmap and diagnostics.
- [Games](games/README.md) — all 17 active games, Games Hub and the shelved Paper Golf source.
- [Wallpaper Randomizer](wallpaper-randomizer/README.md) — sleep wallpaper utility.

## Shared infrastructure

`shared/` and `assets/` own common UI, fonts and icons. `scripts/` and `tests/`
maintain the game collection and utilities. `releases/` keeps immutable installers
and catalogues. Local build artifacts belong in ignored `dist/`.

Run commands from the repository root:

```sh
python3 scripts/check_games.py
python3 scripts/release_games.py --card /media/mellow/4A21-0000
python3 shell/tools/build_probe.py
```

The release helper checks/builds the games, archives packages and directly
updates existing installed games/Hub with backups and save verification.
The shell probe command prepares a host candidate; it does not install it.

[Repository rules](AGENTS.md) · [Handoff](docs/HANDOFF.md) ·
[Game design](docs/GAME_DESIGN.md) · [Game updates](docs/GAME_UPDATES.md) ·
[Shell roadmap](shell/docs/ROADMAP.md)
