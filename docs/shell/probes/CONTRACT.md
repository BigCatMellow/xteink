# DP0 / DP3 minimal probe contract

Contract **xteink-shell-probe-v1**, 2026-11-08. Accountable owner: coordinator.
Machine authority: [contract.json](contract.json). Planning task: roadmap **P2**;
device questions: research **DP0/DP3**. Inputs:
[ROADMAP](../ROADMAP.md), [STATE](../STATE.md), [planning review](../REVIEW.md),
[device research](../research/device.md), [pinned sources](../research/sources.json).

**Disposition: frozen for host implementation and review; physical execution is
NOT_READY.** DP1 and DP2 are **NEEDS_RESEARCH**. Their exact `system:open` target
contract was not found. This contract permits no guessed route calls and makes
no cold-boot/autostart claim. The planning PASS is not device acceptance.

## Authority and write boundaries

Current work covers host documentation, a capture harness and a minimal host
prototype. **No SD/card writes, installations, serial/USB device commands,
reader operation, firmware/NVS/partition/efuse edits or lock-screen registration
are enabled in this bounded host wave.** Existing autonomy already covers
reversible host preparation; this contract creates no repeat user-approval gate.
All observations initialized by host tooling
are pending/unknown, never physical PASS. A collector may read a specifically
provided host package and copy explicitly provided sanitized host evidence into
its report directory; it must not discover attached devices or crawl backups.

Future device execution, once inherited scope and factual readiness hold, may
write only the disposable probe's own
marker, after the preflight below. Existing `gameshub`, standalones, unrelated
apps, saves, wallpaper registration and startup settings stay outside its write
boundary. An SD mount alone does not provide device-control or permission.

## Identity, package and authoritative inputs

The proposed all-letter app ID is **xteinkshellprobe**, version **0.1.0**,
manifest API **2.0**, permissions **[]**, no lock-screen block. Local source and
known upstream probe-manifest inspection found no ID collision on 2026-11-08.
**Installed-card uniqueness remains UNKNOWN** until a later authorized preflight;
stop if that app ID already exists rather than overwriting it.

P3 produces an isolated host diagnostic under `shell/probe/`, a build script,
host checks and a package candidate. Its target is at most four code files /
32 KiB XTCO, within the existing supported 32-file / 524,288-byte gates. It has
one readable Home diagnostic, one tappable counter, explicit Save/readback and
the native Home-pad exit. No games, network, personal data, package updater,
startup changes, borrowed saves or large font pack belong in this experiment.

Capture the exact contract SHA-256, candidate package SHA-256, app ID and version
in the host report. Record hardware model **family only**, firmware/build,
runtime API major/minor, Lua version, screen size and the allowlisted inventory
fields. Preserve null for absent/unreadable counters. Strip serial-like suffixes
from model strings. The host hash binds the package staged in a future test;
the app cannot embed a hash of its own completed package without circularity.
Later staging must separately prove that tested bytes match this candidate.

## Frozen inventory and marker surface

The exhaustive field/type/length allowlist is
`contract.json → capture.inventory_fields`. It includes model/build/runtime,
screen dimensions, types of `system.can_open/open`, four storage counters and a
raw GC counter with explicit units or `unknown`. Probe only established read
methods; inspect navigation member **types without calling them**. Do not infer
native-image allocation from a Lua GC count. Probe absence is a result.

No MAC, serial, device/app identifier, credentials, books/titles, SD inventory,
other saves, firmware image, unrestricted ctx dump, raw exception or unrestricted
log is captured. Use bounded fixed error codes and unknown values. Human photos
must be reviewed for private content before attaching; integrity checking cannot
certify image privacy automatically.

The only future device file is
`XTApps/xteinkshellprobe/files/shell-probe-marker.json`, at most **2,048 bytes**.
Its complete field list and enums are in the machine contract. It holds numeric
load/tap/leave counts, a sequence, selected trial and fixed last-event/write-status
enums. **Only an explicit Save writes it**, with immediate readback. Callback
counters stay in memory until Save; `on_load`/`on_leave` must not write storage.
A missing marker means a new sandbox. A malformed marker or read failure is
visible, disables replacement and requires disposition; never silently reset it.
No per-event files. No private payload. A persisted leave count remains unknown
if callback exit could not be captured.

Expected host callback behavior: `on_load` reads/validates marker and inventory;
`on_draw` displays bounded values without writes; `on_input` changes a counter or
selects a trial and writes only on explicit Save; native Home invokes the
firmware confirmation/escape. Record the actual callback sequence on hardware
later; do not assume `on_leave` runs before every reset or sleep.

## Task sequence and capture

1. **P3 host prototype:** implement the minimal diagnostic and meaningful host
   checks for absent capabilities, marker roundtrip/readback failure, malformed
   marker preservation, bounded display/hitboxes and package budgets. Bind the
   resulting artifact hash. No SD deployment occurs.
2. **Host collector:** `init` creates a pending report bound to copied contract
   and package hashes; `record` associates supplied observations/evidence with
   the frozen trial IDs; `validate` checks structure, bounds and hashes. Coordinate
   exact CLI flags with the capture-harness owner rather than inventing commands.
   The collector has no device discovery and never converts integrity into
   physical PASS. Unknown inventory starts null. Host fixture examples must be
   unmistakably synthetic and cannot be cited as hardware evidence.
3. **Separate hardware preflight:** coordinator confirms inherited device scope,
   safe stock escape, accessible reader, exact build, ID noncollision, package
   provenance and recovery artifacts. Review the host candidate independently.
   Back up any exact paths that an authorized installation could change before
   proceeding; preserve unrelated data. This is a factual readiness check, not
   a requirement to ask the user again. If these facts are absent, P4 stays
   NOT_READY. Do not create cold-boot conditions through battery disassembly,
   forced discharge, flashing or undocumented resets.
4. **Eligible P4 portions only:** perform the fixed trials below, recording
   preconditions/action/destination, responsive fresh input and marker readback.
   Attach supplied sanitized photographs or notes, with host hashes. A missing
   observation remains UNKNOWN/SKIPPED; no absence-to-success inference.

| Frozen trial IDs | Future operation | Evidence needed / claim limit |
| --- | --- | --- |
| `dp0_inventory` | Manually open probe and read inventory | Exact build/API, visible interactive screen, supported/absent members; no route invocations. |
| `dp3_manual_relaunch` | Tap, Save/readback, native Home leave, manually reopen | Marker retained, fresh counter response and stock escape. This establishes manual entry only. |
| `dp3_sleep_01` … `05` | Five normal sleep/wake cycles from probe Home | Per-cycle visible destination, fresh input and marker. Record power mode UNKNOWN unless independently established. |
| `dp3_power_01` … `05` | Five supported normal power-button off/on cycles | Record actual semantics; off/on is unclassified if RTC/deep sleep cannot be excluded. |
| `dp3_warm_reset` | Conditional supported ordinary reset | Only a safe documented procedure; otherwise UNKNOWN/SKIPPED. It proves only that reset class. |
| `dp3_cold_boot` | Conditional existing safe full-power-loss procedure | Otherwise UNKNOWN. Retained pixels, power-button labeling and RTC resume do not prove cold boot. |
| `dp3_usb_exit` | Conditional normal USB-mode entry/exit after backup/quiescence review | Explicitly capture destination; no host/device concurrent writes. Not permission to stage an update in this wave. |

These are a bounded first wave. Game-active sleep, timer wakes, update/rollback,
failed/interrupted ordinary save, arbitrary native navigation and DP4 integrated
resource tests remain later contracts. Never activate a new lock-screen timer
to generate a missing observation. Do not present first-wave success as full
product DONE or completion of the roadmap's game/timer/update criteria.

## Stop, recovery and disposition

Stop on missing native escape, crash/restart, unresponsive fresh input, marker
read/write failure, unexplained state loss, cross-app change, unsafe/unknown power
procedure or build drift. Save the bounded evidence; do not retry destructively
or clear data to make a result pass. Use the already established normal stock
Home/power recovery only. If recovery is not established beforehand, no test.

Preflight recovery artifact: host candidate package/hash, exact test-path backup
if anything preexists, version/contract record, normal stock escape instructions
and a manifest of intended writes. Because the ID must be absent, normal future
cleanup removes only that disposable app after capturing its marker and evidence.
Uninstall deletes its sandbox; it must never target a production app.

Readiness checks: owner and inputs are named; output/capture format and write
boundary are fixed; inherited authority is host-only; host proof and failure
signals are specified; independent review is pending; physical prerequisites and
recovery are pending. Therefore P3 is eligible for bounded host preparation
within existing autonomy, **P4 is NOT_READY**, and **DP1/DP2 remain NEEDS_RESEARCH**.
Next: parent reconciles this P2 contract, then P3 host evidence, then a separate
device preflight. A report validator cannot advance any of those authority gates.
