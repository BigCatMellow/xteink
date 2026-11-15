# XTEINK games — reasoning-first collection

The active family has **10 games**, with an emphasis on linked deduction, constraint solving and meaningful planning rather than rote scanning, obvious actions or luck. All games target a 480×800 monochrome e-ink display. This is a design filter, not a guarantee that every current level is difficult.

## Active games

- [Sudoku](sudoku/README.md) — intersecting row, column and box constraints
- [Nonogram](nonogram/README.md) — intersecting row and column run clues
- [Sum Cross](sum-cross/README.md) — Kakuro's crossing sums
- [Lantern Logic](lantern-logic/README.md) — uniquely solvable light placement
- [Quiet Mines](quiet-mines/README.md) — deduction-only Minesweeper
- [Crown Fields](crown-fields/README.md) — crown-placement region constraints
- [Rectangle Rooms](rectangle-rooms/README.md) — exact-cover rectangle partitions
- [Island Links](island-links/README.md) — Hashi connection constraints
- [Ray Vault](ray-vault/README.md) — deduction from hidden ray outcomes
- [Summit Putt](summit-putt/README.md) — limited-card terrain route planning

[Games Hub](games-hub/README.md) hosts the active collection and reading shell.

## Archived and shelved games

- [Archive index](archive/README.md) — Line Lift, Oddity Hunt, Word Hunt, Ten Pairs, Link Grid, Ink Runes and Word Bridge, including their entire source trees, icons, tests, and reasons.
- [Paper Golf](paper-golf/README.md) remains **shelved separately** and was not changed.

Archiving source does not uninstall already installed games or erase `XTApps/` save data. Historical installers in `releases/` are preserved. A fresh verified release must replace the old 17-game family catalogue before another Games Hub or SD-card deployment. Do not apply the stale `game-family-latest.json` via `--apply-only`.

## Evidence

[Second-pass reasoning audit](REASONING_AUDIT.md) records why each game was retained, measurable puzzle evidence and remaining difficulty risks. Tests can establish uniqueness or a solution path; they cannot establish that the player experience is satisfying.

## Checks and updates

See [AGENTS.md](../AGENTS.md), [game quality](../docs/GAME_QUALITY.md), [game design](../docs/GAME_DESIGN.md), and [game updates](../docs/GAME_UPDATES.md). Run `python3 scripts/check_games.py` from the repository root, then the full build and package flow before any card update.
