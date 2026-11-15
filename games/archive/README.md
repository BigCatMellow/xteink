# Archived XTEINK games — reasoning-depth audit (2026-11-14)

These are complete game projects **moved, not deleted**. Their original app IDs, source, manifests, tests, icons and historical package releases remain available.

| Game | Why archived | What would justify reinstating it |
|---|---|---|
| [line-lift](line-lift/ARCHIVED.md) | The legal next removal is generally visible from the over/under intersections. Repeated safe-next scanning requires limited layered inference. | Introduce coupled, nonlocal constraints and traps that demand planning several removals ahead. |
| [oddity-hunt](oddity-hunt/ARCHIVED.md) | Gameplay is finding named illustrations in a crowded shelf: visual scanning rather than multi-step deduction. | Replace simple object finding with interconnected clues requiring an actual reasoning chain. |
| [word-hunt](word-hunt/ARCHIVED.md) | Word searches and locating one FOX sequence mainly test line scanning, not inference. | Use interdependent word constraints with a verified deduction path. |
| [ten-pairs](ten-pairs/ARCHIVED.md) | Play predominantly repeats matching equal numbers or numbers summing to ten; current puzzles show limited strategic depth. | Design meaningful tradeoffs and constraint-rich sheets; prove difficulty through playtesting. |

**10 games remain active. Seven are archived. Paper Golf remains separately shelved.**

| [link-grid](link-grid/ARCHIVED.md) | All 20 levels collapse under simple local pipe-end constraint propagation, in 1–3 passes; larger boards mostly add the same forced rotations. | Require nonlocal branching or dependencies with meaningful multi-step deductions, not just more tiles. |
| [ink-runes](ink-runes/ARCHIVED.md) | Most puzzles use just 1–6 rune moves; simple random-move simulation wins some advanced boards too often, including 66.7% for level 20. | More interacting rule discovery, fewer interchangeable moves and stronger constraints verified by player trials. |
| [word-bridge](word-bridge/ARCHIVED.md) | Each board is a 12-word set with shortest paths of 3–7 moves; ten of twelve have only one optimal first step. The small bank encourages rapid trial and error. | Larger, nontrivial interlocked word networks needing sustained strategic deduction beyond 4–5 moves. |

The archive is excluded from active discovery, Games Hub, font/theme syncing, active build workflows, and new family releases. Each archived project retains an SVG `icon.svg` and a disabled original `build-workflow.yml`.

**No SD card or installed app was changed.** Existing `XTApps/` player saves have not been erased. Historical installer packages remain under `releases/`. The former 17-game `game-family-latest.json` is stale for the new active family: generate and verify a fresh 13-game family release before any card deployment; do not use stale `--apply-only`.

To reinstate a game, demonstrate real multi-step deduction or consequential planning, human-test difficulty, keep its original app ID/save compatibility, move it back to active, update all registries/icons/workflows/builds and pass normal automated and physical-device checks. This is a quality-priority decision, not a claim that the archived code was defective.

## Parked design prototypes (not previously in active Hub)

- [Margin Codex](prototypes/margin-codex/ARCHIVED.md): original 16-page browser game. Too many one-step ciphers; needs multi-layer deductions.
- [Ink Delve](prototypes/ink-delve/ARCHIVED.md): original six-floor browser game. Dice movement currently dominates consequential strategy.

Both original HTML prototypes, documentation and tests are preserved under
`games/archive/prototypes/`. They are **not** native installable XTEINK games.
