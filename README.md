# XTEINK projects

Projects and experiments for the XTEINK X4 Pro, primarily running XTOS Licorice.

## Games

- [Paper Golf](paper-golf/README.md) — monochrome golf puzzle.
- [Summit Putt](summit-putt/README.md) — card-based golf route puzzles.
- [Line Lift](line-lift/README.md) — zero-animation crossing logic inspired by Hook.
- [Link Grid](link-grid/README.md) — zero-animation tile-rotation network puzzles.
- [Ink Runes](ink-runes/README.md) — original cryptic word-deduction puzzles inspired by LOK.
- [Lantern Logic](lantern-logic/README.md) — classic Akari-style illumination with 16 uniquely solvable boards.
- [Ray Vault](ray-vault/README.md) — Black Box-style hidden-atom deduction with 12 original stages.
- [Island Links](island-links/README.md) — Bridges/Hashi-style single/double-line island logic with 12 unique puzzles.

## Utilities

- [Wallpaper Randomizer](wallpaper-randomizer/README.md) — reads XTH wallpapers from its own folder and rotates on sleep.

## Builds

Contribution requirements are in [AGENTS.md](AGENTS.md) and
[Game quality](docs/GAME_QUALITY.md). The [game quality gate](.github/workflows/game-quality.yml)
checks measured layouts, save/resume, navigation, puzzle solutions and packages
on pushes and pull requests. Run it locally with `python3 scripts/check_games.py`.

Each project has its own installable XTApp build workflow: [Paper Golf](.github/workflows/build.yml), [Summit Putt](.github/workflows/summit-putt.yml), [Line Lift](.github/workflows/line-lift.yml), [Link Grid](.github/workflows/link-grid.yml), [Ink Runes](.github/workflows/ink-runes.yml), [Lantern Logic](.github/workflows/lantern-logic.yml), [Ray Vault](.github/workflows/ray-vault.yml), [Island Links](.github/workflows/island-links.yml), and [Wallpaper Randomizer](.github/workflows/wallpaper-randomizer.yml).
