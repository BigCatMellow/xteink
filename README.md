# XTEINK projects

The active games share a Poppins/Inter design, rounded controls and stronger
monochrome graphics. [Game design contract](docs/GAME_DESIGN.md) records the
tokens, per-game exceptions, changes and reasons. [Host preview sheet](docs/design/game-family/first-sheet.png).

Projects and experiments for the XTEINK X4 Pro, primarily running XTOS Licorice.

[Applying game updates from this computer](docs/GAME_UPDATES.md): update existing
installed packages together while preserving saves. Direct replacement has
passed host tests and awaits its first physical reader test.

**Picking this up later?** Start with the [project handoff](docs/HANDOFF.md), then
the [wallpaper handoff](wallpaper-randomizer/docs/HANDOFF.md). The exact
[v0.5.0 wallpaper installer](releases/wallpaper-randomizer-0.5.0.xtapp) is archived in the repo.

## Games

- [Games Hub](games-hub/README.md) — all 13 active games in one installer, with separate progress and a shared game-selection menu. Recommended for updating the collection together.
- [Paper Golf](paper-golf/README.md) — monochrome golf puzzle.
- [Summit Putt](summit-putt/README.md) — card-based golf route puzzles.
- [Line Lift](line-lift/README.md) — zero-animation crossing logic inspired by Hook.
- [Link Grid](link-grid/README.md) — zero-animation tile-rotation network puzzles.
- [Ink Runes](ink-runes/README.md) — original cryptic word-deduction puzzles inspired by LOK.
- [Lantern Logic](lantern-logic/README.md) — classic Akari-style illumination with 16 uniquely solvable boards.
- [Ray Vault](ray-vault/README.md) — Black Box-style hidden-atom deduction with 12 original stages.
- [Island Links](island-links/README.md) — Bridges/Hashi-style single/double-line island logic with 12 unique puzzles.
- [Oddity Hunt](oddity-hunt/README.md) — a no-animation seek-and-find game with 12 crowded shelves and five objects per scene.
- [Word Hunt](word-hunt/README.md) — 8 classic word searches and 8 Find the Fox letter-grid puzzles.
- [Nonogram](nonogram/README.md) — 12 original, uniquely solvable hidden-picture logic puzzles.
- [Sudoku](sudoku/README.md) — generated unique puzzles with notes, undo and saved puzzle history, adapted from the meditation app.
- [Word Bridge](word-bridge/README.md) — 12 shortest-path four-letter word ladders with deceptive branches.
- [Rectangle Rooms](rectangle-rooms/README.md) — 12 unique Shikaku-style rectangle-partition puzzles.
- [Crown Fields](crown-fields/README.md) — 12 original letter-region crown-placement puzzles.
- [Ten Pairs](ten-pairs/README.md) — 12 original Numberama number-clearing sheets.
- [Quiet Mines](quiet-mines/README.md) — 12 deductive Minesweeper grids with a known-safe start.
- [Sum Cross](sum-cross/README.md) — 12 uniquely solvable Kakuro number-crossword grids.

Word Hunt and Nonogram now continue with offline generated puzzles after their original boards. Nonogram's generated continuation uses abstract patterns. Original levels and existing saves are preserved.

## Utilities

- [Wallpaper Randomizer](wallpaper-randomizer/README.md) — reads XTH wallpapers from its own folder and rotates on sleep.

## Builds

Contribution requirements are in [AGENTS.md](AGENTS.md) and
[Game quality](docs/GAME_QUALITY.md). The [game quality gate](.github/workflows/game-quality.yml)
checks measured layouts, save/resume, navigation, puzzle solutions and packages
on pushes and pull requests. Run it locally with `python3 scripts/check_games.py`.

The [Games Hub build](.github/workflows/games-hub.yml) runs the same quality gate
and supplies a single `games-hub.xtapp` artifact for the whole active collection.

Each project has its own installable XTApp build workflow: [Paper Golf](.github/workflows/build.yml), [Summit Putt](.github/workflows/summit-putt.yml), [Line Lift](.github/workflows/line-lift.yml), [Link Grid](.github/workflows/link-grid.yml), [Ink Runes](.github/workflows/ink-runes.yml), [Lantern Logic](.github/workflows/lantern-logic.yml), [Ray Vault](.github/workflows/ray-vault.yml), [Island Links](.github/workflows/island-links.yml), [Oddity Hunt](.github/workflows/oddity-hunt.yml), [Word Hunt](.github/workflows/word-hunt.yml), [Nonogram](.github/workflows/nonogram.yml), [Word Bridge](.github/workflows/word-bridge.yml), [Rectangle Rooms](.github/workflows/rectangle-rooms.yml), [Sudoku](.github/workflows/sudoku.yml), [Crown Fields](.github/workflows/crown-fields.yml), [Ten Pairs](.github/workflows/ten-pairs.yml), [Quiet Mines](.github/workflows/quiet-mines.yml), [Sum Cross](.github/workflows/sum-cross.yml), and [Wallpaper Randomizer](.github/workflows/wallpaper-randomizer.yml).

## Scouting

- [Steam puzzle adaptation candidates](research/steam-puzzle-scouting.md) — ranked references for original zero-animation word, deduction, sorting and placement games on X4 Pro (2026-11-07).

