# Reasoning-depth audit — 2026-11-14

**Purpose:** Retain only games with evidence of multi-step deduction, cross-constraint reasoning, or consequential route planning. These are source-level assessments, **not human playtest scores**. A unique solution or a passing test proves correctness, not difficulty.

## Retained: 12 games

| Game | Evidence from the actual game/tests | Known difficulty risk | Decision |
|---|---|---|---|
| Sudoku | 9×9 row/column/box intersections; 75 generated boards independently checked for uniqueness; player notes and undo. | Easy/Medium/Hard selects clue counts (45/36/30) rather than logical technique tiers; actual difficulty can vary. | **Keep**, improve calibrated ratings. |
| Nonogram | 12 authored clue-unique picture boards, plus new 7x7, 8x8 and 10x10 continuation patterns that an independent Python line-pattern solver proves uniquely solvable without guessing. Hint uses current clues and player marks, not a solution peek. | Number of deduction passes is a difficulty proxy, not a human rating. Random patterns may lack recognizable pictures; 10x10 has compact 35px touch targets. Old saved v1 patterns use their original generation. | **Keep**; review physical readability and human difficulty. |
| Sum Cross (Kakuro) | 12 grids, 5×5–7×7, uniquely solved from intersecting nonrepeating sums with every white square in two runs. | Small boards may be easier than magazine-grade hard Kakuro. | **Keep**, assess forced deductions and harder stages. |
| Lantern Logic (Akari) | 16 unique 5×5–7×7 grids; simultaneously enforce illumination, no bulb visibility, and wall-number constraints. | Uniqueness does not measure techniques needed. | **Keep**, human test advanced boards. |
| Crown Fields | 12 connected-region 5×5–7×7 boards, with exactly one one-per-row/column/region non-touching crown arrangement. | Compact boards and region outlines may create quick forced moves. | **Keep**, review late-stage difficulty. |
| Rectangle Rooms (Shikaku) | 12 exact-cover grids, 5×5–7×7; every board has multiple plausible local rectangles but one full partition. | Many shapes may resolve by local area arithmetic. | **Keep**, require more interconnected eliminations. |
| Island Links (Hashi) | 12 unique noncrossing connected bridge networks with 7–9 islands, including double-bridge constraints. | Sparse 7–9-island layouts may be shallow. | **Keep**, test reasoning beyond corner-island forcing. |
| Quiet Mines | New sessions now use bounded seeded random placements in three 8×8/10×10/12×12 tiers. Only candidates completely solved by number/subset deductions from S are accepted; independent samples are re-solved in Python. The 24 old authored boards remain archived in place for existing saves. Hints use visible clues and player flags. | Rejection sampling can fail for a seed rather than publishing an unchecked fallback. Solver passes do not prove human challenge; the 12×12 38px targets and device generation latency need physical review. | **Keep**; playtest tier depth, generation latency and save storage. |
| Ray Vault (Black Box) | 12 6×6 hidden-atom cases with 3–4 atoms; full beam signatures unique and at least three informative probes needed in greedy filtering. | Unlimited probing may eventually trivialize the board; count of probes is not difficulty of inference. | **Keep**, test deliberate probe-choice challenges. |
| Lights Out | Random boards built from random presses (always solvable), four sizes from 5×5 to 7×10; par is the exact minimum from a light-chasing solver that tries every first-row press set. Boards need at least 4 presses. | Light chasing is a known mechanical method, so larger boards reward persistence more than insight; hints and the solution overlay can trivialise a board. | **Keep at user request** (ported from the user's HTML prototype, PR #29); assess challenge through playtesting. |
| Ten Pairs | 12 original 8-column, 32-digit starting sheets; an independent interval-matching solver verifies a full 16-pair clearing sequence for each. Pair order matters and the ADD mechanic extends the search space. | The solver demonstrates solvability, not difficulty; some pair matches may be routine. Restored at the user's explicit request rather than on a claim of Sudoku-equivalent complexity. | **Keep at user request**, assess challenge through playtesting. |
| Summit Putt | Ten 7×7 finite-card routing boards, 3–5 shot cards; wrong sequences become dead ends. Level four, for example, has 12 winning action sequences versus thousands of dead-end action sequences under exhaustive action enumeration. | Five-shot ceiling and ten boards limit sustained challenge; brute-force retries are possible. | **Keep provisionally** for consequential planning, review before calling it premium. |

## Archived in this second pass

| Game | Concrete concern | Re-entry requirement |
|---|---|---|
| Link Grid | All 20 boards reduce to a complete solution with simple local edge-consistency propagation in 1–3 sweeps (calculated from authored rotations/fixed anchors). This is an objective shallow-depth proxy, not a human difficulty score. | Nonlocal dependencies, genuine alternate hypotheses and multiple rounds of reasoning. |
| Word Bridge | Twelve words per level and 3–7 shortest moves (mean 4.42); ten of twelve boards have one optimal first step. Choices are small and often resolved by short trial-and-error. | Larger intertwined word graph and substantive route planning; preserve 480×800 legibility. |
| Ink Runes | Twenty puzzles with minimum 1–6 rune moves; for the final seven boards, a simulated uniformly random legal-move strategy wins ~32.5% on average, and 66.7% on level 20. This is a model, **not** a player win rate. | Fewer independent interchangeable moves, stronger cause-and-effect combinations, more multi-stage discoveries, real playtest evidence. |

The earlier archive decisions for Line Lift, Oddity Hunt and Word Hunt remain in [the archive](archive/README.md). Margin Codex and Ink Delve are parked HTML prototypes, not native apps. Paper Golf remains separately shelved. Ten Pairs was reinstated to the active lineup at the user's request without changing gameplay.

## Acceptance standard for future games

A candidate should explain at least two logically linked deductions or a genuinely consequential multi-step plan, with authored puzzle examples and validator evidence. The reviewer should check whether obvious local propagation or uniform random legal play largely solves its advanced levels. Board validity, uniqueness and solvability are necessary but not sufficient. Keep 480×800 monochrome text/graphics readable, touch targets large, no animation, no mandatory online resources, and preserve progress.

**Unverified:** No independent human difficulty ratings or physical XTEINK testing were performed in this audit. Active inclusion is a reasoned shortlist, not a declaration that every board is excellent. No physical card/install/uninstall/save operation occurred.
