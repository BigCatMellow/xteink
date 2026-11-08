# Complete game rollout — 2026-11-08

User authorized a complete pass so individual games do not need repeated design
requests or separate installation. Preserve the established Poppins/Inter family
and rounded controls while applying the space/clarity lessons from Sudoku v0.3.

## Scope

All 17 active games, including four newly fetched games at upstream commit
`2a6af10`: Crown Fields, Ten Pairs, Quiet Mines and Sum Cross. Paper Golf stays
shelved. Dictionary, stock Sudoku and unrelated installed apps remain intact.
Games Hub must include the new games so they are available through one existing
installation. Existing standalone games are updated directly on the mounted card.

## Execution checklist

- [x] Fetch upstream; inventory incoming games and save a complete local-work backup.
- [ ] Merge upstream without losing earlier local presentation, generators or saves.
- [ ] Audit first/dense/help/solved states for every game and record per-game decisions.
- [ ] Improve space use, visual hierarchy, touch geometry and distinguishable icons.
- [ ] Apply canonical fonts/theme to all four new games; integrate them into checks.
- [ ] Rebuild Games Hub with all 17 engines and verify firmware code/file limits.
- [ ] Pass gameplay/save/reload/undo/solution tests, enlarged/native and bitmap layouts.
- [ ] Inspect actual bitmap previews and verify native packaged icons.
- [ ] Archive versioned releases, latest catalogue, design notes and update evidence.
- [ ] Back up the live card; directly update installed games and hub; verify saves.
- [ ] Commit/publish the integrated work, retaining any newer upstream changes.

## Per-game review

| Game | Review focus | Status |
| --- | --- | --- |
| Line Lift | Board prominence, crossing gaps, pair rings, controls | Pending |
| Summit Putt | Terrain/card hierarchy, selected cards, usable controls | Pending |
| Link Grid | Network/grid contrast, anchors and tile targets | Pending |
| Ink Runes | Letter order, connections, selected cells and metadata | Pending |
| Lantern Logic | Walls/clues/light/conflict distinction and grid weight | Pending |
| Ray Vault | Grid/rim port clarity, probe labels and selection | Pending |
| Island Links | Large nodes, bridge separation and centering | Pending |
| Oddity Hunt | Shelf recognition, usable object targets and uncluttered HUD | Pending |
| Word Hunt | Dense letter legibility, found/hint rings and controls | Pending |
| Nonogram | Clue/board centering, semantic grid hierarchy and controls | Pending |
| Word Bridge | Word-card spacing, route and selection hierarchy | Pending |
| Rectangle Rooms | Clear room/cell boundaries and area clues | Pending |
| Sudoku | Preserve v0.3 improvements and verify the shared rollout | Pending |
| Crown Fields | Theme integration, regions/crowns/exclusions and dense boards | Pending |
| Ten Pairs | Theme integration, number emphasis and selection affordances | Pending |
| Quiet Mines | Theme integration, flag/clue states and safe targets | Pending |
| Sum Cross | Theme integration, sum-clue hierarchy and digit pad | Pending |

## Acceptance

Every game receives a documented review and a versioned, tested release; any
already sound geometry is retained for a stated reason. New drawing positions
and hitboxes share a geometry contract. Important rules/labels cannot be hidden
by ellipses. Stable puzzle seeds, app IDs, save records, unfinished answers and
undo survive. Public packages contain no personal save payload. Complete host
checks and direct SD replacement are not recorded as physical reader success.

Local working tree before integration is backed up under
`/home/mellow/Backups/xteink-before-full-rollout-20261108-104801/`.
