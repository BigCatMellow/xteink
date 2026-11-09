# Shell current state

Record: current-state routing summary. Owner: coordinator. Updated 2026-11-09.

**Current (2026-11-09):** the user's X4 Pro is locked, so firmware routes are
rejected. The user reported that sleep, including a long power press, returns
to the open app. D1 is therefore decided: the shell is a stock-hosted app that
stays on screen across sleep, with games bundled inside (route B). I1 has
started as Games Hub 0.4.0. See [shell design](DESIGN.md). Host gate passes. A
one-time firmware install and the device checks listed there are next. The
historical notes below predate this decision.

User authorized autonomous research and THINK/PLAN using helpers for a custom
SD-card shell on X4 Pro. The repo initially contained only a model-routing draft;
earlier chat replies did not complete the research. This is the first substantive
research and planning package.

Canonical [roadmap](ROADMAP.md); [device evidence](research/device.md);
[THINK alternatives](THINK.md); [method research](research/maps-method.md);
[applied protocols](protocols/INDEX.md).

Current scope: research and host probe preparation. Device experiments and full
shell implementation are future tasks. Games Hub provides local evidence for bundled games and a
shared UI, not arbitrary installed-app launch or automatic cold startup.

P2 now has a frozen [probe contract](probes/CONTRACT.md), and P3 has a small
isolated host prototype, package builder and capture tool. See the
[runbook](probes/README.md), [host receipt](probes/HOST-VALIDATION.json) and
[independent probe review](probes/REVIEW.md).
Next work is P4 factual device preflight. Device observations need an accessible
reader, distinct app ID, recovery, matching package and recorded conditions.
An SD mount alone gives no control of boot, touch input, sleep or screen capture.

Preserve existing IDs, saves, unfinished boards and undo. Reuse shared design
owners. Flashing, NVS edits and partition changes remain a contingent decision.
Independent challenge/review and remaining unknowns are recorded in the owning
research artifacts. No physical result is claimed by this delivery.

Planning wave R1/R2/T1/P1 is complete. [Independent review](REVIEW.md) passed for
research/planning: two clarity findings were corrected. That review binds the
historical planning snapshot, not later code. The repository-required 17-game
quality check passed under Lua 5.4 after integration; no app source changed.

The subsequent P2/P3 host wave introduces only the separate diagnostic app.
Its 32 guarded frames pass on Lua 5.1 and 5.4; static Lua 5.5 lint, supported
package budgets and native icon checks pass. The existing 17-game gate also
passes. The probe is 4 Lua files / 15,353 XTCO bytes and is not installed.
Capture integrity never certifies physical acceptance. DP1/DP2 remain blocked
on the exact navigation contract; no autostart or cold-boot result is claimed.
