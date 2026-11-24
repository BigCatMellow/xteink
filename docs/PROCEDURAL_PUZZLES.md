# Procedural puzzle family — 2026-11-24

## Parent outcome
Every game in the nine-game current/candidate family offers fresh original puzzles
on-device, without a fixed finite campaign as the default. Existing progress,
app IDs, levels, historic installers and old seed algorithms remain readable.
Inactive/archived games and firmware are outside scope.

## Current evidence
Nonogram, Sudoku and Quiet Mines already generate new seeds; Quiet Mines
enforces no-guess deduction. Lights Out generates from press sets but has a
deterministic scatter fallback, which should be removed or replaced with an
explicit retry. The five candidate apps still play finite banks. Keep those
boards only as legacy-save compatibility, not the default for new installs.

## First implementation
`shared/procedural_puzzles.lua` is a host-testable, unintegrated v1 backend for
Takuzu, Mosaic, Hitori, Akari and Crown Fields. No bank or symmetry of an authored
puzzle is used. It returns exact clues, the solution for independent validation,
kind, size, seed, generator version and work count; exhaustion returns nil and
a reason, never a fixed substitute.

| Game | Construction | Acceptance |
|---|---|---|
| Takuzu | Random valid complete binary grid, then remove givens | Full row/column domain deductions reconstruct original |
| Mosaic | Random binary pattern, clipped 3×3 clue counts, remove clues | Cardinality and subset deductions reconstruct original |
| Akari | Random wall topology and maximal non-conflicting bulb layout | Forced segment/lighting/number deductions reconstruct original |
| Hitori | Random Latin grid with independently placed shaded cells and duplicate numbers | Exact solution count equals one; connected white cells |
| Crown Fields | Random non-touching row/column crown permutation, connected region growth | Each growth preserves uniqueness; all regions contain at least two cells |

The first three proof methods are deterministic deduction, not human difficulty
ratings. Exact uniqueness for Hitori and Crowns is not evidence of a guess-free
human solving path. Difficulty calibration and device latency remain unverified.
The work counter is a finite deterministic bound, not milliseconds.

## Required integration (not yet done)
- Wire the generator to an explicit New action and default new-install flow;
  choose size/difficulty; do not recycle the frozen bank.
- Use the existing sharded puzzle store and durable exact clues/seed/version,
  current marks and undo. Save the successful new record before switching the
  active pointer. Read old saves without overwriting them. Resume uses the exact
  original puzzle even if a later generator changes. Preserve older numbered
  sessions and stable Hub resume IDs.
- Failed generation must preserve the current session and offer a retry with a
  fresh seed; no unbounded draw loop, no predetermined fallback. Measure
  generation on actual Licorice firmware and constrain work to a responsive
  limit (host work counts are only a proxy).
- Extend layout/input/save/restore/next/restart and Hub regression suites, verify
  package/file limits, increment changed manifests, render actual bitmap
  previews, and independently verify generated samples from every size.
- Check no-guess evidence and challenge: avoid trivial symmetry variants,
  oversized clue counts, singleton regions and repetitive boards. Human
  playtesting is separate. Do not remove a working release until replacement
  passes the quality gate and the physical check.

The added Python test invokes Lua for multiple seeds at every size and solves
the results independently; it also checks deterministic seed replay, diversity,
bounded exhaustion and minimum successful seed count. No runtime or installed
data was modified by this backend-only step.


## Verified host evidence

The backend quality gate at commit d30a8c173606846528d2f9338555a6ade5596576
passed: [run 45469559990](https://github.com/BigCatMellow/xteink/actions/runs/45469559990).
All 126 sampled puzzles (six seeds for each of 21 game/size combinations)
were independently verified unique, with seed replay and diversity checks.
Largest observed work counts included 5,013,014 for Crowns 9x9 and 3,372,126
for Mosaic 10x10. These are operation counts, not physical-device timing.

## Mandatory policy and mechanical safeguard

Procedural generation is a release requirement, not a stretch goal.
The explicit migration registry in `scripts/procedural_gate.py` records the
existing exceptions as blockers, not permissions to ship. New games without
an acceptance test fail the ordinary quality gate; a family release fails
while any named migration gap remains. Passing the backend sample solver
does not establish gameplay integration. Keep the existing four games and
historic packages intact while resolving the gaps.
