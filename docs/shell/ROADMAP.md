# PLAN — X4 Pro shell roadmap

Record: ROADMAP / task context. Owner: coordinator. Updated 2026-11-08.
Authority: human request to research and plan autonomously using helpers in
Xteink. Parent: [index](README.md). Inputs: [device research](research/device.md),
[THINK](THINK.md), [methods](protocols/INDEX.md).

## Objective and DONE

Provide a custom primary interface whose code lives on SD and is updated
through USB, using stock hardware services where practical. Planning DONE:
sourced capabilities, compared alternatives, executable next tasks, measurable
gates, recovery, independent challenge and model routing. Product DONE later:
reliable startup entry, useful navigation and return, preserved data, recovery,
acceptable e-ink/battery behavior and repeatable updates on the target build.

## Working decision

Adopt the startup and recovery acceptance recommendation from
[the method application](protocols/APPLICATION.md). The separate wake-to-shell
idea remains incubating pending lifecycle evidence; it is not a proven hook.

Investigate a separate Licorice shell app first. Reuse canonical fonts/UI and
game adapters after measuring package and save budgets. Manual launch is the
baseline experiment; automatic startup remains a separate required question.
Installed-app enumeration/launch, global browsing, settings actions and package
installation each require evidence. Leave the existing `gameshub` ID, package and saves unchanged; use a distinct
experimental shell ID.

If stock startup cannot deliver the desired experience, return to THINK with a
concrete firmware-hook proposal and recovery evidence. Research and planning
scope does not include flashing, NVS/partition edits or bypassing recovery.
Source inspection and a host prototype can proceed without those changes.

## Task sequence

| ID | Work / accountable role | Depends on | Exit evidence | Failure route |
| --- | --- | --- | --- | --- |
| R1 | Canonical methods / protocol helper | None | Pinned sources and applied HPOM, indexing, spiderweb, emergence/insight coverage | Preserve UNKNOWN where sources are missing |
| R2 | Runtime research / device helper | None | Capability matrix distinguishes source reports, local implementation and physical observations | Reconcile API/build conflicts |
| T1 | THINK / challenger | R2 preliminary | Alternatives, failure modes and falsifiers | Retain competing hypotheses where unresolved |
| P1 | PLAN / coordinator | R1, R2, T1 | Roadmap and independent challenge reconciled | Repair disputed claims |
| P2 | Minimal probe contract / research helper | P1 | Frozen inputs, expected outputs, capture format, stop conditions and recovery | Return to R2 for missing signatures |
| P3 | Host prototype / implementation helper | P2 | Separate app skeleton, minimal Home, owned state and native escape | Reduce features to proven APIs |
| P4 | Device probes / coordinator | P2, P3, accessible reader and recovery | Build-scoped evidence for scenarios below | Stop affected probe on crash/data failure |
| D1 | Architecture disposition / coordinator | P4 | Adopt/narrow/reject startup, navigation and update routes separately | Reopen THINK if stock cannot meet startup goal |
| I1 | Usable shell / implementation helper | D1 supports chosen features | Feature contracts, package budgets, save preservation and bounded errors | Feature fallback; preserve valid data |
| V1 | Independent review and acceptance / reviewer + coordinator | I1 | Revision-bound review and physical acceptance | Correct and re-review material changes |
| L1 | Release / coordinator | V1 | Immutable package, USB update/rollback evidence and runbook | Restore previous package; retain diagnostic data |

R1/R2/T1/P1 completed the initial planning wave. P2 is now frozen in the
[probe contract](probes/CONTRACT.md); P3 has an isolated host prototype and
[validation receipt](probes/HOST-VALIDATION.json), subject to its
[independent review](probes/REVIEW.md). P4 remains NOT_READY pending factual
device preflight; DP1/DP2 navigation remains NEEDS_RESEARCH. Later tasks are
future work, not claims of completed device experiments. Select one eligible bounded
next task, reconcile evidence, then continue. Material contrary evidence can
reopen a decision without restarting the entire plan.

## Probe contract for P2/P4

Each record includes hardware model, firmware/build, API/permissions, package
hash, initial state, action, expected/observed outcome and evidence path.

| Question | Smallest experiment | Interpretation / pass |
| --- | --- | --- |
| Can shell run? | Manually launch a separate minimal app, save a marker, exit through native Home | Drawing, taps and owned state work; native escape remains available |
| Sleep/wake | Five cycles from shell Home and from a game | State and screen return; distinguish sleep from reset |
| Reset resume | Supported normal reset from app, then stock Home | Destination and state recorded; RTC resume proves only that reset class |
| Startup | Five normal power-button off/on cycles; determine actual power semantics | Repeatable entry; a deep-sleep cycle cannot establish true cold boot |
| Cold boot | Inspect code; use an existing safe supported full-power-loss procedure only if available | Otherwise UNKNOWN; no battery disassembly or forced discharge |
| Books/settings/apps | Documented can_open checks for exact supported targets, then one open at a time | Target-specific success and return path; no guessed URI scan |
| Failed save | Disposable fixture with failed write and interrupted ordinary save | Previous valid record survives; visible bounded retry |
| USB update | Back up, update one version through safe storage exposure, flush/readback, reopen | Code changes, data survives, prior package restores; no concurrent device/host writes |
| Native ownership | Exercise Home, native reader close, other-app exit and USB-mode exit separately | Record destination each time; stock fallback is explicit, not automatic shell ownership |

Do not hide the native escape before recovery is proven. If safe cold-boot
conditions cannot be established, report incomplete evidence rather than pass.

## Feature gates

| Area | Initial scope | Evidence before expansion |
| --- | --- | --- |
| Home | Static monochrome navigation, Resume and native exit | Touch geometry, readability and real refresh |
| Games | Existing adapters in an isolated fixture | Code/file/heap/image budgets; aggregate save growth; canonical sources retained |
| Reading | Supported native reader shortcut | Exact route, book identity and return path |
| Settings | Supported status and documented actions | Permission/capability checks |
| Other installed apps | Conditional | Enumeration, launch and return each proven |
| Startup | Investigate native resume/start behavior | Known reset/cold semantics and recovery |
| Updates | Host USB updater with backup/readback | Stable shell ID, preserved data and interrupted-update recovery |

Games Hub currently uses 30/32 code files and 383,525/524,288 container bytes:
two files and 140,763 code bytes remain under the current supported builder gate.
An upstream streaming path is reported but untested; it does not justify raising
that gate. This is not a heap budget. Namespaced
games share the app storage quota; forecast worst-case shard growth before
adding features and never evict valid records. Measure peak drawing, loaded
images, long-session memory and battery against a stock baseline on the reader.

## Model and effort routing / HPOM application

These are project dispatch defaults using available tools, not benchmark claims
or guaranteed account availability. Check actual capability at dispatch and
record substitutions. [Canonical method application](protocols/INDEX.md).

| Role / task | Model | Effort | Escalation / completion condition |
| --- | --- | --- | --- |
| Coordinator / reconciliation and roadmap | GPT-6.1 Sol | high | xhigh for contradictory startup evidence or consequential boot decisions |
| Clerical indexing after source selection | GPT-6 Luna | medium; low for mechanical updates | Source authority ambiguity goes to Sol high |
| Device research and probe contracts | GPT-6.1 Sol | high | Exact build/revision and observed evidence required |
| THINK alternatives/challenge | GPT-6 Astra | high | Independent critique; coordinator disposes findings |
| PLAN tasks/dependencies | GPT-6.1 Sol | high | Listing work does not imply it has run |
| Bounded prototype/implementation | GPT-6.1 Terra | medium | high for material save/recovery or cross-module complexity |
| Device operation/reconciliation | GPT-6.1 Sol | high | Accessible hardware and recorded observations required |
| Consequential independent review | GPT-6 Astra | high | Review exact revision; author cannot self-certify independence |

Actual planning dispatch: Sol high coordinator, Sol high protocol helper, Sol
high device helper, Astra high challenger. Sol handles source indexing here
because canonical protocol authority is ambiguous. Read-only research can run
in parallel; writable helpers own distinct files. Coordinator retains scope,
decisions, reconciliation and publishing responsibility.

## Recovery and release acceptance

Startup failure: retain manual native launch/exit and stock recovery. Unsupported
routes: narrow features. Save quota: budget and report while retaining records.
Package update: verified host backup before replacing code. Firmware/API drift:
recheck affected observations. Public evidence: exclude private books/saves and
firmware images.

Product acceptance requires supported startup classes, native exit/recovery,
repeated navigation round trips, unfinished boards/undo, sleep/wake, failed
writes, update/rollback, readable layouts and bounded resource use. Physical
battery/refresh evidence remains required. Unsupported cases narrow claims;
emulator output alone cannot satisfy reader acceptance.

After each task, reconcile evidence into its owning document and update
[STATE](STATE.md). Capture ideas in THINK before promotion. Repair stale links
and contradictory claims through the spiderweb procedure. Next: establish the
P4 factual preflight and record only eligible DP0/DP3 observations using the
[probe runbook](probes/README.md). Preserve UNKNOWN for inaccessible or unsupported
device cases. Broad launcher features still depend on their navigation contracts.
