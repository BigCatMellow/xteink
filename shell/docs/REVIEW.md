# Independent planning review

Historical planning snapshot: commit `a2e69a8`. Input hashes below bind that
planning wave; later probe preparation is reviewed separately under
[`probes/REVIEW.md`](probes/REVIEW.md). They are not hashes of all future revisions.

Date: 2026-11-08. Reviewer: Astra high challenger, separate from the coordinator
who authored the integrated roadmap. Scope: documentation correctness, evidence
boundaries, method traceability and readiness to define the next task. This is
**not product acceptance, device verification or implementation authorization**.
The reviewer authored THINK; that file is contextual input and is not being
self-certified as an independently reviewed design.

**Disposition: PASS for the research/planning package, conditional on future
execution readiness gates.** No critical or high-severity finding was identified.
Both medium clarity findings below were corrected and read back before final
binding. P2 contract drafting is the appropriate next work; device execution is
not ready merely because this review passes. Upstream pins/provenance were inspected in the supplied research
packet; this review did not independently refetch every upstream source blob.

## Findings and disposition requirements

| ID | Severity | Finding / evidence | Suggested correction |
| --- | --- | --- | --- |
| R-01 | Medium | Task IDs collide across owners: roadmap P2 means contract drafting, while device-research P2 means an actual controlled `system:open` transition. P1/P3/P4 also have different meanings. A traversal from STATE into research can therefore change the apparent next action. | Rename research probe IDs DP0–DP4 and all its internal references, or consistently qualify them. Keep roadmap P2 as contract drafting and link it to the research sequence. |
| R-02 | Medium | Roadmap's “separate Licorice shell app” is followed by “Keep the existing gameshub app identity.” This could mean preserve the installed Hub or use that identity for the prototype; THINK explicitly warns against the latter during exploration. | State that the existing gameshub ID/package/saves remain unchanged and the experimental shell uses a distinct ID. Leave any future migration a separate explicit decision. |
| R-03 | Low / next-task requirement | P2 is appropriately a contract task, but P3/P4 are still phase descriptions: exact outputs, selected app ID, write boundary, expected callback sequence and recovery artifact are not frozen. The method index requires these before executable device work. | P2 must produce the complete bounded contract and readiness disposition. Do not infer READY for P3/P4 from a planning PASS. This is expected future elaboration, not missing implementation in the present research deliverable. |

**Correction readback:** R-01 is CLOSED: device research uses DP0–DP4 throughout,
including its ranked-question references, while roadmap P2 remains contract
drafting. R-02 is CLOSED: roadmap now explicitly leaves the existing `gameshub`
ID, package and saves unchanged and selects a distinct experimental shell ID.
R-03 remains a next-task constraint, not a blocker to this planning handoff.

Cold-boot and return criteria are substantively consistent. Roadmap separates
ordinary power-button trials, warm resets and true cold boot; inability to create
safe cold-boot conditions leaves evidence incomplete. Native Home, reader close,
other-app exit and USB-mode exit are separate observations. Neither research nor
plan treats `can_open/open` member presence, RTC flags, retained e-ink pixels or
an NVS key name as a functioning startup/launcher contract.

The 512 KiB nuance is reconciled: research distinguishes the reversed unexercised
streaming path from the supported packer/builder gate; roadmap retains that gate
and does not mislabel it a heap limit. Both preserve the distinction between
host-verified replacement and a physically observed reader launch.

## Fresh integration traversal

Starting at the [root README](../../README.md), the shell link reaches
[shell README](README.md), which routes to [STATE](STATE.md), current device
evidence, THINK and the canonical roadmap. The independent
[handoff entry](../../docs/HANDOFF.md) reaches the same index/state rather than another
plan. This traversal recovered the objective, owner, current scope and next task.

One claim was traced end to end:

1. **Cause / user need:** a custom primary interface needs useful native/app
   navigation and return, not only an attractive foreground menu.
2. **Evidence:** [device research](research/device.md), “Stock screen navigation”
   and “Arbitrary installed-app launch,” points to E3 member-presence evidence
   and E1's native dispatcher. [Source register](research/sources.json) identifies
   exact revisions/blob IDs and expressly limits those claims.
3. **Decision:** [THINK](THINK.md) makes installed-app launching conditional;
   [roadmap](ROADMAP.md) requires enumeration, launch and return evidence and
   retains a separate shell/bundled-engine route.
4. **Successor:** STATE selects roadmap P2 to freeze a probe contract, with
   documented targets required before any real transition. R-01 captures the
   naming collision found along this route and its verified correction.

This is a bounded semantic traversal, not a claim to have run upstream Spiderweb
or a complete knowledge-graph audit. Structural validation resolved **144 local
Markdown link targets with no missing files** across the reviewed inputs and
parsed the source register's **13 records**. Fragment-anchor and remote-link
reachability checks were not part of that count.

## Method and model traceability

[Method research](research/maps-method.md) records the pinned MAPS revision,
retrieval, blob identities and the limits of its coverage. [Protocol index](protocols/INDEX.md)
maps THINK/PLAN to current owners without inventing active upstream acronyms,
keeps target authority above imported methods, and distinguishes HPOM routing
from historical model tiers. [Application receipt](protocols/APPLICATION.md)
captures a concrete insight and an incubating wake idea. Roadmap explicitly
adopts the entry/recovery recommendation while preserving that idea's status.

The Sol high coordinator/research, Astra high challenge/review and Terra medium
bounded implementation assignments match the requested routing. Luna is reserved
for clerical work; using Sol for the authority-sensitive protocol discovery is
explained. Model choices remain dispatch defaults, not capability guarantees.
Read-only parallel research and distinct file ownership are explicit. Independence
is valid for this review of the parent plan, subject to the THINK authorship
limitation stated above.

Final bounded refresh inspected the shell README review link, STATE completion/
review receipt and coordinator-reported Lua 5.4 game-check result, and APPLICATION
integration disposition. They preserve the reviewed scope and next-task gates;
the earlier UNKNOWN traversal is explicitly superseded. The quality-run outcome
is a coordinator report, not a test independently rerun by this reviewer. All
other input hashes remained unchanged. The table and link count below/above
reflect this final receipt integration.

## Reviewed input identity

SHA-256 values below bind this review to the inspected contents. Material edits
need a bounded re-review; a link to this review does not transfer its verdict to
different substantive content. REVIEW itself is excluded to avoid a circular hash.

| Input relative to repository | SHA-256 |
| --- | --- |
| `README.md` | `9c8ee57d7233b82bd488765a5e4a9477704ac0bcefb49277efee124299a12f7e` |
| `docs/HANDOFF.md` | `8f30bfb58fc415b021c6be4d2fcc1dc6e6ba12adeb8b27fe82cb3a0dd13f1c7c` |
| `AGENTS.md` | `49dad6ce455580f99b3eb790081fd6352b25c3fac5e80b51a06f9d4c3ad09b99` |
| `docs/shell/README.md` | `52ddd6b452b20de6961aab8b6ea8fe9d46755f3fd77436e5bfcf63ccdf773d78` |
| `docs/shell/ROADMAP.md` | `3e0ad6adb9038df2c50ac21f8bb0ad259aea92b0b9bd65d8e495a35e67665b10` |
| `docs/shell/STATE.md` | `6cd2a887104bd276a5c89ea3f4e85d17e6baaeab7062107153d5f3d3332100f4` |
| `docs/shell/research/device.md` | `322e0e63b5a687e9d63c2853ae832ae12d537900b8c5fa7f21c87b64bbf91a3a` |
| `docs/shell/research/sources.json` | `e2fa247857afeddc5f81c8d97e4335ba374f16d7d2b1d081477a2066b8ef08ff` |
| `docs/shell/protocols/INDEX.md` | `16de9d0c4181b32c5e98e0e8b1b51ec270c0354d31c8aede974bd1f52040345c` |
| `docs/shell/protocols/APPLICATION.md` | `abc36cd784f5f1beb25b3a9c2055e9ca52c4d31613d2b796aa046bfd07ad78bd` |
| `docs/shell/research/maps-method.md` | `2aa7137a63f5572c4d853f8ec1ce3fa027a713b91062e3a8fc701651337ddcfb` |
| `docs/shell/THINK.md` | `fe90d13eb124904205709d7f2f988d9b0adcb7fcc5457cb6bc3e726a927de908` |
