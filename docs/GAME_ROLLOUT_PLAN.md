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
- [x] Merge upstream without losing earlier local presentation, generators or saves.
- [x] Audit first/dense/help/solved states for every game and record per-game decisions.
- [x] Improve space use, visual hierarchy, touch geometry and distinguishable icons.
- [x] Apply canonical fonts/theme to all four new games; integrate them into checks.
- [x] Rebuild Games Hub with all 17 engines and verify firmware code/file limits.
- [x] Pass gameplay/save/reload/undo/solution tests, enlarged/native and bitmap layouts.
- [x] Inspect actual bitmap previews and verify native packaged icons.
- [x] Archive versioned releases, latest catalogue, design notes and update evidence.
- [x] Back up the live card; directly update installed games and hub; verify saves.
- [x] Commit/publish the integrated work, retaining newer upstream changes (see Git history).

## Per-game review

| Game | Review focus | Status |
| --- | --- | --- |
| Line Lift | Solid rods preserve crossing gaps; quieter header; distinct ring icon | Reviewed / implemented |
| Summit Putt | 424px terrain composition; larger Undo/Restart targets below cards; bold distances | Reviewed / implemented |
| Link Grid | 448px board; solid network strokes and fine cells; explicit anchors/rules | Reviewed / implemented |
| Ink Runes | 448px logical board and stronger letter tiles; preserve void geometry/order | Reviewed / implemented |
| Lantern Logic | 448px play band; fine grid distinct from clue walls and bulbs | Reviewed / implemented |
| Ray Vault | 434px rim composition; stronger frame; preserve port geometry | Reviewed / implemented |
| Island Links | 416px network composition; evenly spread nodes and separated double bridges | Reviewed / implemented |
| Oddity Hunt | Retain already full shelf/object hitboxes; quieter metadata and clearer icon | Reviewed / implemented |
| Word Hunt | Larger 8×8 and 13×13 grids; centered glyphs and readable target list | Reviewed / implemented |
| Nonogram | Retain approved measured clue centering; solid grid strokes; readable picture icon | Reviewed / implemented |
| Word Bridge | Larger word cards and compact goal/current band; preserve route meanings | Reviewed / implemented |
| Rectangle Rooms | 448px play band; bold area clues; fine grid distinct from rooms | Reviewed / implemented |
| Sudoku | Retain v0.3 density; reuse canonical solid grid; retain reviewed icon | Reviewed / implemented |
| Crown Fields | Shared fonts; large board; letter regions and solid 5px boundaries | Reviewed / implemented |
| Ten Pairs | Full-width responsive number sheet; row height adapts to 4–11 rows | Reviewed / implemented |
| Quiet Mines | Large field; separate closed/open/flag states and visible active mode | Reviewed / implemented |
| Sum Cross | Larger clue grid; solid inactive blocks; correct diagonal between across/down clues and keypad | Reviewed / implemented |

## Acceptance

Every game receives a documented review and a versioned, tested release; any
already sound geometry is retained for a stated reason. New drawing positions
and hitboxes share a geometry contract. Important rules/labels cannot be hidden
by ellipses. Stable puzzle seeds, app IDs, save records, unfinished answers and
undo survive. Public packages contain no personal save payload. Complete host
checks and direct SD replacement are not recorded as physical reader success.

Local working tree before integration is backed up under
`/home/mellow/Backups/xteink-before-full-rollout-20261108-104801/`.

## Completion evidence

Both forms of all 17 gameplay suites passed: 3,904 audited bitmap frames, peak 589 commands, no font image leaks. Hub navigation covers 165 further frames. Independent level/generator solvers, save/undo/error cases, Lua compatibility and packaged icons pass. Games Hub uses 30/32 code files and 383,525/524,288 container bytes.

The final complete gate ran under Lua 5.4, matching CI. A pencil-note save
encoding fix also passes Lua 5.1 and recovers legacy decimal masks and undo.
Sudoku 0.3.2 / Hub 0.3.3 were applied directly in the final SD correction;
all existing app data remains unchanged from the pre-rollout inventory.

Live deployment updated all 13 existing standalone games and the installed Hub. All 326 app-data files stayed byte-identical; all 346 installed files were verified. The four new games are available in Hub, with optional standalone recovery packages. All 18 recovery installers were verified. Reader startup/touch/refresh checks remain physical checks, not inferred successes.

Backups: `/home/mellow/Backups/xteink-family-update-20261108-112417/` and final corrections `/home/mellow/Backups/xteink-family-update-20261108-113525/`. See dated SD receipts in releases/ and the [visual review](design/full-rollout-2026-11-08/README.md).
