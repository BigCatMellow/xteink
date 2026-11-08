# Card-loaded shell: independent architecture challenge

Date: 2026-11-08. Status: research and design reasoning only. No shell implementation,
SD writes, app replacement, firmware patch, flash, commit or publication is implied.
Read with [ROADMAP.md](ROADMAP.md), the capability research and the staged plan.
This document owns the concept comparison; firmware discoveries must update its
assumptions before implementation.

## Decision to make

The intended outcome is a custom **main UI**, delivered to the Xteink X4 Pro's
card through USB, while retaining Licorice where possible. A particular PocketOS
appearance is not a requirement. There are three separate claims to prove:

1. **Delivery:** a card file can be installed or updated through the existing
   workflow, with a recoverable previous version.
2. **Capability:** the UI can perform the reading, game and system actions it
   presents, and preserve progress while moving between them.
3. **Ownership:** the UI appears at the required entry points and receives a
   useful return path after reading, other apps, Home, sleep and power cycling.

An attractive application proves none of the third claim. Automatic restoration
after sleep would not prove cold-boot startup. Opening a native reader would not
prove launching arbitrary installed XTApps, nor returning to the shell when that
reader closes. These are independent gates, not successive interpretations of one
successful demonstration.

**Working recommendation:** keep a minimal XTApp shell as the lowest-cost
capability and visual prototype, with bundled engines as one optional route.
Adopt it as the main UI only if entry/return behavior passes the main-UI gate.
Keep firmware integration as a contingent route, and report a failure of that
gate plainly if a stock-firmware solution cannot provide the requested ownership.
Do not silently redefine the request as “another app to open.”

## Evidence read for this challenge

These are source observations or existing records, not new device results.

| Evidence | What it establishes | What it does not establish |
| --- | --- | --- |
| [Hub navigation](../../games-hub/src/index.lua) | `launch()` loads a generated `game_<id>` module in the current application; leaving saves via a namespace and releases theme images. | Installed-app discovery, native launching, shell startup or a global Home interception. |
| [Hub storage namespace](../../games-hub/src/namespace.lua) | Game IDs prefix save names inside one root storage object. Storage usage delegates to that root. Read failures inhibit writes. | Separate firmware sandboxes or independent per-game quotas. |
| [Hub importer](../../games-hub/src/importer.lua) | Optional packaged saves are imported only when absent, read back, then receipted. | Live access to standalone saves or two-way synchronization. |
| [Hub UI adapter](../../games-hub/src/ui.lua) | Existing engines receive an in-app return control and a small header adaptation. | A general layout contract for unrelated third-party apps. |
| [Hub builder](../../scripts/build_game_hub.py) | Canonical engines are generated into one package, with checks for 32 code files and 524,288 container bytes. | Native runtime memory, startup latency or an extensible plug-in loader. |
| [Current handoff](../HANDOFF.md) | Current recorded hub is 30/32 code files and 383,525 bytes; direct card replacements preserve recorded data hashes. Physical launch checks remain pending. | A demonstrated post-update reader launch or memory/refresh behavior. Older sections are historical. |
| [Update procedure](../GAME_UPDATES.md) | The host updater replaces existing `app.xtapp` files with backups and verification; changed permissions/API declarations require installation. | Registration of a new shell, an on-device installer API, or refresh of cached firmware metadata. |
| [Shared archive store](../../shared/puzzle_store.lua) | Up to 64 shard filenames per archive prefix; records are retained and whole shards are read/rewritten. | Unlimited history capacity or constant cost as a shard grows. |

The locally read upstream companion repository was commit
[`3f810cf11c29792fad03d58c04b65368b01ed4e5`](https://github.com/omer-faruq-xteink/touch-licorice-apps/tree/3f810cf11c29792fad03d58c04b65368b01ed4e5).
Its [firmware notes](https://github.com/omer-faruq-xteink/touch-licorice-apps/blob/3f810cf11c29792fad03d58c04b65368b01ed4e5/docs/firmware-notes.md)
report API 2.9 device probes exposing `system.can_open` / `system.open`, reader
statistics with permission, plain-name sandbox storage and a quota of 512 files /
134,217,728 bytes. They do not document an arbitrary-app target contract in the
section inspected. Its [installation instructions](https://github.com/omer-faruq-xteink/touch-licorice-apps/blob/3f810cf11c29792fad03d58c04b65368b01ed4e5/README.md#install)
describe opening apps from Ink App and a Home-pad leave confirmation. Its reported
lockscreen callback is a lockscreen capability, not evidence for a replacement
awake home screen. Treat these as build-specific observations from another device;
the current research and this user's firmware must establish applicability.
Our repo's `SD:/Apps/` installer convention takes precedence over that README's
card-root suggestion.

## Competing routes

| Route | Why choose it | Missing proof / limitation | Decision |
| --- | --- | --- | --- |
| A. Minimal standalone shell XTApp | Smallest reversible way to validate navigation, drawing, input and available native actions. Maintains a distinct experimental app identity. | It is initially an ordinary app. A native-reader shortcut cannot be promised from a method name alone. | Preferred first prototype after research, not yet a main-UI solution. |
| B. Shell with bundled engines | Reuses the real Hub's navigation, canonical engines and save isolation; internal game-to-shell return is under our control. No external launcher API is needed for those engines. | Shared resource quotas, independent histories from standalone apps, package growth and no control over firmware Home. | Strong fallback for owned content; add only after baseline fit/resource checks. |
| C. Launcher of installed apps | Could preserve each app's own identity, saves and update independence; potentially scales beyond our games. | Needs exact target syntax, authorization, success semantics, app discovery or a maintained catalogue, and return behavior. `can_open` alone is insufficient. | Conditional. Do not build navigation around guessed app IDs, filesystem paths or URI schemes. |
| D. Supported firmware setting or hook | Could supply default entry/return ownership while retaining a card-hosted UI and stock firmware services. | No supported hook is established here. A sleep/resume setting is narrower than startup or Home routing. | Investigate before considering a patch. Require exact-build documentation and recovery behavior. |
| E. Minimal firmware patch plus card UI | Could bridge a narrowly proven entry/return gap without moving the whole UI into firmware. | Requires compatible firmware, validated patch point, safe fallback without a card, and recovery independent of the UI. Updates may invalidate it. | Separate research branch only if stock hooks fail and the user chooses this scope. |
| F. Custom firmware | Potential control over startup, Home and lifecycle; may remove stock API constraints. | Requires demonstrated X4 Pro hardware support, touch/e-ink/power/storage/USB support, reading parity, migration and recovery. Support for a different Xteink model is not transferable evidence. | Contingency, not a drop-in extension of an XTApp. No compatibility claim in this document. |

Combining A/B with selectively proven native actions is a useful hybrid. Combining
them with unproven external launching does not remove that dependency. A visually
complete home mockup with dead Reading or Settings controls is not a capability
prototype and should not be described as a functioning shell.

## Decision criteria and falsifiers

Use gates before weighted preferences: a beautiful UI cannot compensate for lost
saves or an unrecoverable boot route. Once gates pass, compare daily steps to
reading/playing, legibility, refresh behavior, maintenance effort and update cost.

| Gate or premise | Smallest discriminating evidence | Falsifier and consequence |
| --- | --- | --- |
| Stock firmware can host our main UI | Separate records for first launch, cold boot, wake, native-reader exit, Home, app exit and USB exit on the exact firmware. | If a required transition always returns to stock UI and no supported hook exists, call this an app front end; do not declare full main-UI success. |
| `system.open` can reach required native destinations | Source-backed accepted targets followed by an authorized minimal invocation and observed destination; record errors and return behavior. | Missing target or one-way handoff removes that shortcut or limits its claim. Never fill the gap with guessed paths. |
| Installed XTApps can be launched | A specific registered app target, preserved standalone progress, repeated launch and return, and documented behavior for absent apps. | If only native destinations work, C is rejected while A/B remain viable. |
| USB updates are effective on the reader | Replaced existing app opens with an unmistakable new version marker and old saves; recovery copy also launches. | Failure or stale version means fix the delivery route before treating host replacement as deployment success. First registration remains separate. |
| A bundled shell fits | Package count/bytes, all-game storage bounds, and physical startup/switching/refresh observations on a representative long session. | A single successful first screen cannot justify the bundle. Exceeding budget requires consolidation or a smaller bundle with explicit scope, not weakened checks. |
| Saves remain trustworthy | Failure injection for read/write/full storage and import; controlled migration with old/new inventories and resumable recovery. | If leaving drops unpersisted state or retry overwrites good state, stop that route until corrected. |
| A boot hook is recoverable | Known behavior with missing/corrupt card content and a recovery path that works before the shell starts. | Recovery depending on a Settings control inside a broken shell is circular; reject the hook design. |

These are proposed probes, not authorization to run device operations during this
research-only task. Record firmware/build, exact package hash, starting state,
action and visible result. Keep sleep, cold boot and lockscreen observations in
separate rows; repeated observations should test interruption and failure, not
just repeat the happy path.

## Resource and lifecycle challenge

**The existing Hub is already a substantial bundle.** Its recorded headroom is
two code files and 140,763 container bytes (about 26.8% of the checked ceiling).
A shell with reading metadata, settings, catalogue, icons and lifecycle adapters
can consume this without adding a game. Combining source modules into fewer
files can address the file count, but does not raise the byte, heap or execution
limits. Do not choose package architecture solely from compressed installer size.

**Per-game names do not create per-game budgets.** Current inspected sharded
archives can use 256 files: 64 for Nonogram, 64 for Sudoku, and 128 for Word Hunt's
two modes, before fixed saves, shell settings and import receipts. This is not
evidence that the current bundle is over quota. It is evidence that every added
archive namespace must enter a whole-application file/byte budget. Eight fully
populated 64-file namespaces alone would consume 512 files, leaving no metadata
capacity. Reducing shard counts later is a save migration, not a cosmetic refactor.
Sources: [Nonogram](../../nonogram/app/index.lua),
[Sudoku](../../sudoku/app/index.lua), [Word Hunt](../../word-hunt/app/index.lua),
[store](../../shared/puzzle_store.lua), [namespace](../../games-hub/src/namespace.lua).

**Image release is necessary but insufficient for memory evidence.** The current
navigation releases theme images and discards the active instance. Native module
caching, compiled engine factories, decoding overhead and garbage-collection
timing still need measurement. Host allocation counts do not establish the
firmware's heap watermark, latency or fragmentation after visiting every engine.
Budget a shell's own icons and covers alongside fonts. A text-first shell is a
useful diagnostic baseline, not a mandatory final visual style.

**Save failure is a transition failure.** The Hub checks its namespace error before
an internal return, but an external firmware transition may ignore an application
exception. Prove the lifecycle ordering of a native launch and Home action. Save
the selected game/book and navigation state before handing off; an application's
`on_leave` hook alone is not a proven veto over firmware navigation. Recovery must
leave valid old data usable after an interrupted update or partial import.

**No hidden background-service assumption.** A foreground shell can redraw after
an event without implying that it runs while a book or other app is active.
Battery/statistics displayed on it need freshness rules. Avoid persistent timers
or animation until their wake, power and refresh behavior is justified. E-ink
ghosting, partial/full refresh and touch handling are device acceptance criteria,
not properties proved by a screenshot.

## Data ownership and update boundary

A separate experimental app ID isolates a trial from the currently installed Hub.
It also gives it a separate sandbox. The existing first-launch importer copies
missing records; it does not merge later progress. Do not call such a copy shared
storage or promise seamless switching between old Hub, standalone apps and a new
shell. Select one authoritative progression location before real migration.

If the eventual shell becomes an in-place evolution of `gameshub`, preserve that
ID, its namespaced keys, importer receipts, stable game IDs, legacy numeric resume
compatibility and public/private package separation. Make that identity decision
explicit after capability acceptance. Reusing the production identity during
exploration risks turning a disposable UI experiment into a migration.

If the eventual shell launches standalone apps, leave their saves in their own
sandboxes and store only shell preferences and validated route identifiers.
Catalogue data may be prepared on the computer, but a catalogue entry is not
proof an app remains installed after USB disconnect or another update.

The existing direct updater is a host delivery component, not a runtime shell
service. Its current safety checks deliberately reject permission/API changes.
Adding reader permission may therefore require a normal firmware installation
step even if later package updates can be applied by USB. Neither the shell nor
this plan should conceal that boundary from the user.

## Premise challenge

“Loaded from the SD card through USB” specifies a delivery preference; it does
not itself require direct execution of a loose Lua file, zero initial
registration, an installer-free system, or firmware stored on the card. Keep
these interpretations separate until research confirms the feasible one.

“Main UI” should be assessed through the paths the user takes every day. It may
be possible to achieve most desired use through a resumed full-screen app, but
that is a narrower result if Home or cold boot consistently bypasses it. Preserve
that distinction even if the visual prototype is convincing. Likewise, extending
the existing Games Hub is convenient evidence reuse; it is not automatically the
best architecture for reading-first use.

Do not clone a desktop's taskbar, draggable windows or dense settings tree just
because the interface is called a shell. The relevant design opportunities are
legible choices, a short path back to an unfinished activity, and predictable
touch targets within 480×800. Stock firmware services can remain useful where a
verified handoff exists. Rebuilding a book reader or settings service would be a
new capability project, not an implied part of skinning a home screen.

## Emergence ideas — candidates, not adopted design

| Candidate | Why it might help | Experiment or rejection rule |
| --- | --- | --- |
| Activity-oriented home: Continue reading, Continue puzzle, Library, Games | Expresses the user's intent with fewer steps than a universal app drawer. | Test representative journeys using only proven routes. Reject labels implying unsupported resume behavior. |
| Capability-aware catalogue generated on the computer | USB delivery could carry known app metadata and art without requiring sandbox escape or runtime filesystem scanning. | Compare recorded catalogue against installed state during an authorized host update; handle stale/missing entries safely. It does not solve launch APIs. |
| Small native-action adapter separated from presentation | A later verified firmware hook could change routing while retaining the UI and save model. | Host mock adapters must be visibly test-only; require real evidence before enabling an on-device route. |
| “Return to desk” within bundled activities | Gives our games a consistent internal destination independent of firmware Home. | Keep wording and hitboxes consistent; do not claim it intercepts the physical Home action. |
| Conservative new-shell recovery screen | A bad optional catalogue or preference could fall back to a minimal known UI. | Deliberately corrupt optional data in host tests. A firmware-level startup hook still needs recovery outside the shell. |
| Separate presentation pack | Fonts/icons and navigation could evolve without forking engines. | Only adopt if actual package-loading rules and budgets support it; arbitrary asset/code loading from SD is presently a hypothesis. |

The strongest early result is a small evidence-backed capability map, a concrete
main-UI acceptance matrix, and a reversible design whose UI does not depend on an
invented startup hook. Visual exploration can then proceed without locking the
project into a launcher or firmware route before its decisive premise is known.
