# Inactive projects and next puzzle family — 2026-11-24

These six complete projects are parked by user direction, not deleted and not newly judged shallow. Their app IDs, source and historical releases are preserved. Original workflows are kept here disabled. Paper Golf remains separately shelved. The four active games are unchanged.

| Project | Disposition |
|---|---|
| [summit-putt](summit-putt/) | Parked |
| [ray-vault](ray-vault/) | Parked |
| [island-links](island-links/) | Parked |
| [rectangle-rooms](rectangle-rooms/) | Parked |
| [sum-cross](sum-cross/) | Parked |
| [ten-pairs](ten-pairs/) | Parked |

## Candidate family: implementation acceptance

Akari and Crown Fields have been restored to their original project paths on the candidate branch, with existing app IDs. Takuzu, Mosaic and Hitori are new projects.

| Candidate | Rule and device design | Challenge and correctness |
|---|---|---|
| Takuzu | Blank / 0 / 1, explicit two-mode controls, fixed givens, 6×6/8×8/10×10, no color | Equal counts, no triple, unique rows/columns; independently count solutions and demonstrate deductions |
| Mosaic | Fill / X, digits count black cells in clipped 3×3 neighborhood including clue cell; clue digits remain readable on shaded cells | Generated or authored unique boards; overlapping clue and subset deductions, no guess-only tiers |
| Akari (Lantern Logic) | Bulb / X, outlined bulb, small light indicators and numbered walls; preserve app ID | Preserve old 16 boards; add harder validated boards, verify conflict visibility and no-guess depth |
| Hitori | Shade / keep, numbers stay readable and fixed; no drag | Distinct numbers in each unshaded row/column, no adjacent black squares, connected white area; unique solutions |
| Crown Fields | Strong region outlines, remove repetitive letters only if borders alone are unambiguous; direct Crown / X modes, compact status, larger boards | Preserve first 12 layouts and v1 saves; add harder unique connected-region boards and evaluate deduction depth |

For every candidate: native Lua, 480×800, monochrome, static redraw, no network or mandatory gesture; use canonical UI/theme/fonts; target near-full-width grids with readable cells; no permanent duplicate instructions. Add deterministic generation or a substantial verified authored bank, independent solver, input and save regressions, distinct icon, versioning, hub entry, and actual bitmap renders. Review empty, in-progress, dense, solved, error and help frames at standard and enlarged metrics. No candidate is released before the quality gate and visual review; device checks are separate.

No SD card access or physical verification has occurred. The previous family release is stale; do not apply it.
