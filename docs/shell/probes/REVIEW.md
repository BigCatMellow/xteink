# P2/P3 independent host review

Date: 2026-11-08. Reviewers: Astra high challenger (initial review and
correction readback), then Sol high (fresh final collector review and binding).
Both are independent of this wave's contract, collector and prototype authors.
The coordinator recorded the Sol substitution after the Astra reviewer reached
its usage limit, following the roadmap's capability/substitution rule. Scope:
frozen DP0/DP3 contract, host implementation, negative cases, provenance and
execution boundary. Sol independently closed H-06/H-07 and verified final hashes;
the other correction dispositions retain the earlier Astra review provenance.
The earlier [planning review](../REVIEW.md) is historical; its hashes do not
certify this implementation wave.

**Disposition: HOST PASS for this bounded P2/P3 candidate.** All material
findings below are corrected and read back. This document cannot authorize a
device operation. Physical P4 remains **NOT_READY**;
DP1/DP2 remain **NEEDS_RESEARCH**. A host result cannot establish native Home
escape, startup, wake, return routing, physical rendering or package acceptance.

## Findings and correction evidence

| ID | Severity | Exact owner / finding | Disposition |
| --- | --- | --- | --- |
| H-01 | Medium | [index.lua](../../../shell/probe/src/index.lua), [marker.lua](../../../shell/probe/src/marker.lua): initial marker hardcoded manual-relaunch trial; inventory computed fields that could not be viewed. This prevented faithful capture of the frozen trial/inventory contract. | CLOSED. Builder generates all trial IDs from the contract; Next trial selects and persists them. A second inventory page exposes Lua version, file/byte quotas and raw GC count with unknown units. Lua regression covers selection, Save and reload. |
| H-02 | High for host build completion | [build_shell_probe.py](../../../scripts/build_shell_probe.py) used a nonexistent authority key, so the frozen contract could not build. | CLOSED. Uses `sd_writes_enabled_in_this_wave`; successful candidate/receipt and independent source binding verified. |
| H-03 | Medium | Builder `--check` accepted extra staged files while budgeting only canonical sources, allowing unbudgeted code/assets into the package. | CLOSED. Exact staged filename set and regular-file/non-symlink checks precede packaging. Author reported a negative extra-file check; reviewer inspected the enforcing code. |
| H-04 | Medium | [shell_probe_capture.py](../../../scripts/shell_probe_capture.py) could validate FAILED but its CLI could not record a witnessed failure. | CLOSED. `--outcome failed` requires observation and evidence, retains pending physical status, and has a rejection/success regression. |
| H-05 | Medium | Collector init checked only app ID/version, accepting mismatched API, permissions or lockscreen declarations under the frozen identity. | CLOSED. Entry/API/permissions/no-lockscreen checks now enforce the frozen manifest contract; negative cases cover each mismatch. This is still not code-signature or runnable-package validation. |
| H-06 | Medium | Collector copied evidence before rejecting invalid observation/inventory values, leaving unreferenced files and allowing rejected attempts to bypass the intended disk bound. | CLOSED. Prospective values, report size and evidence hashes are validated before copying; caught write failures remove only newly created files. A regression proves rejected input leaves the report and evidence directory unchanged. |
| H-07 | Medium | Collector accepted serial-bearing model strings under the string-length rule despite the model-family-only contract. | CLOSED. Collector accepts only canonical X4 Pro / X4 / X3 families or null. Serial-suffix rejection has a regression and creates no attachment. |
| H-08 | Low | Probe emitted `thread` outside the system-member enum, accepted zero screen dimensions and could retain old dimensions after a failed size read. | CLOSED. Unsupported types map to `other`; size resets to unknown before each read and zero is rejected. Absent device/API/system and malformed surfaces have focused tests. |

The prototype author also corrected `invalidate` to colon-call convention and
added a fake requiring `self`. No raw storage exception is displayed. Failed
reads and malformed records disable Save; failed writes/readback disable further
Save. Read-only controls preserve the failure status instead of making a blocked
write look safe again.

## Contract compliance and limits

The experimental manifest uses `xteinkshellprobe` 0.1.0, API 2.0, empty
permissions and no lockscreen block. The app reads only its marker and bounded
inventory methods. It inspects navigation-member types without invoking them.
Tests make those methods fail if called. Non-pointer input is not consumed and
`on_leave` performs no storage write: code inspection supports preservation of
the firmware escape, but only a later reader trial can establish its behavior.

Only an explicit Save writes one bounded marker; load, drawing, refresh, trial
selection and leave do not write. Tests reject malformed/oversized/wrong-ID
markers without replacement and exercise read, write and readback failure. The
Save sequence advances only after matching readback. This is not an atomic
storage guarantee: a firmware write failure could still leave damaged bytes.
The contract correctly requires stopping rather than clearing or silently
retrying. The leave counter remains memory-only unless actually captured.

The candidate uses **4 code files and 15,353 XTCO bytes**, within its four-file /
32 KiB contract budget. Generated config and canonical shared UI are included
in that accounting. No games, personal saves, fonts, networking, updater or
startup hooks are added. Package bytes, Lua memory and native-image memory remain
separate concepts; the host tests establish no physical heap/battery allowance.

Collector reads only explicit paths, rejects nonregular/oversized/symlink input,
uses content-addressed evidence names, refuses replacing recorded trials, and
retains `host_template` / `pending` report identity. Unknown inventory starts
null. An OBSERVED or FAILED observation is operator-supplied evidence, not an
automatic physical PASS. Header/manifest checks and a syntactically valid
package hash cannot establish runnable code, truthful evidence or photo privacy.
The package must be matched again at any later authorized staging/test step.

## Independent validation

The earlier Astra review reported staged Lua passes with Lua 5.1.5 and
`/tmp/xteink-lua54/root/usr/bin/lua5.4`, each with **32 guarded frames** plus
persistence/failure/privacy/input checks. Sol independently reran the final
staged suite with `/usr/bin/lua` (Lua 5.1.5): **32 guarded frames PASS**. The
previous Lua 5.4 path was absent at this final pass, so Sol could not repeat
that runtime; its earlier pass remains Astra-reported evidence. No tool
installation or hardware operation was performed. Packaging, compatibility
lint, icon verification and the staged-extra-file rejection are author-reported.

Sol independently compared the local build receipt and every shared field in
HOST-VALIDATION.json, the actual package and contract hashes, every staged source
digest, canonical index/marker/manifest/UI bytes, generated trial configuration,
and the four-file / 15,353-byte XTCO calculation: all match. The candidate was
not rebuilt. Code and CI stay on the host. The workflow builds using pinned
community tools, runs focused suites and uploads host-only artifacts; there is
no deployment step. Upstream source pins and provenance were read in the supplied
research register, without independently refetching every upstream blob.

Sol reran the final **nine Python collector tests: PASS** and inspected
prospective validation before evidence writes. Additional direct failure
injection covered a preexisting report temporary-file collision and an
`os.replace` failure: both preserved the original report and preexisting
evidence, removed only newly created files, and preserved a preexisting
temporary file. These are host fixtures, not hardware evidence. Canonical
hardware families X4 Pro / X4 / X3 or null are the only accepted model values;
serial-suffixed input is rejected before any evidence copy.

A separate final integration used the actual candidate in a temporary host
directory: init and validate succeeded, all **15 trials remained PENDING**,
inventory remained null, and contract/package identities matched the public
host receipt. Temporary fixture outputs were not promoted as hardware evidence.
Full game-family checks in the host receipt are coordinator-reported evidence,
not independently rerun by either reviewer during this final collector pass.
They do not replace these probe-specific checks.

Final routing readback confirms STATE/ROADMAP/HANDOFF point to this bounded
probe wave and retain P4 preflight, DP1/DP2 research and physical unknowns. The
earlier method application and planning review are explicitly historical, with
successor links; their older hashes are not reused for this candidate.

## Remaining readiness

The frozen contract's reference to pending independent review describes its
freeze point; this successor receipt supplies the host review without advancing
physical eligibility. Next is a separate factual preflight: accessible reader, exact build/API, absent
disposable app ID, known native escape, candidate provenance, protected existing
data and recovery. The live-card collision check is deliberately UNKNOWN.
Cold boot remains UNKNOWN without a safe supported procedure; no battery
disassembly, forced discharge or firmware change follows from this review.
P3 prepares a diagnostic, not a working main UI or a general installed-app
launcher. Game-active sleep, timer wake, update/rollback and native navigation
need their later contracts.

## Bound inputs

SHA-256 bindings below identify the inspected substantive inputs and selected
shared test/runtime dependencies. REVIEW is excluded from its own hash list.
Any regenerated encrypted package has its own digest and receipt; a matching
app ID/version alone does not transfer this candidate's identity. This binding
does not authenticate an operator observation or replace later staging checks.


| Input relative to repository | SHA-256 |
| --- | --- |
| `docs/shell/probes/CONTRACT.md` | `2266974cd5d3b4fbff8e60bbed9a9297bc1601e9dae0bd34d1648bc919fda32f` |
| `docs/shell/probes/contract.json` | `54952881a2c8328666a3210cf188bb91667df9a3bb6a7f4e6e608417bb58288a` |
| `docs/shell/probes/README.md` | `5e967e2a898bf3d29d4bca390513088b9cc11f82ee5a621bf6b3f178a3994ff2` |
| `docs/shell/probes/HOST-VALIDATION.json` | `5b0cf18a2d341780e414c539e845662c38111d11ec0e6dd3437f2ae15c393eae` |
| `shell/probe/src/index.lua` | `582e80406fec28bb5c4c1be60535908ef419aeaea023b6cb02a936059466c6b5` |
| `shell/probe/src/marker.lua` | `a6a8049ff38d0aea80185d6b27e437a4557b5fc046f70265323397dbad639b14` |
| `shell/probe/src/manifest.json` | `702e1a69942bcf945e8aabf5dfe0132ded42cb2a0248ab7a3f872bc6bf0f8c70` |
| `shell/probe/src/icon.svg` | `6ea3068ccd9452e2229e585f5edd3150d67e3c538c27e41109867c2a5993b0c9` |
| `scripts/build_shell_probe.py` | `6e2fc47b3ea11fd0d9f2bd93411453125823165a021f673e6f5251f80004f7d5` |
| `scripts/shell_probe_capture.py` | `a96ea0f932ece1f1dc35c7a8a5972f132f4f81388a327c7f7537c6baa41d50ad` |
| `tests/test_shell_probe.lua` | `4c2037bdb4d27d40c7ee0467214ef4f018c851d780ceb8685e0a25a3eaa333c6` |
| `tests/test_shell_probe_capture.py` | `b6681ff8dd7424da37b69d001f646eda1200e68ee6c42c4aea749ec622d0ca9e` |
| `.github/workflows/shell-probe.yml` | `94b64b4f7f0fc8fae962a202bdd8d21cd850ce675dbf3601191c6a77e3f3a59b` |
| `shared/game_ui.lua` | `da2eb581ca1f701fdad733558acc4aeb18a51ff00b379712b9ac1a1779866357` |
| `tests/game_canvas.lua` | `797889973e6b30c747313641de22c4fc7c96266b5b215fd5ec63bbbc8ba28b55` |
| `docs/shell/ROADMAP.md` | `33be827614a13ebe1ba6bbc149114cd4018a23cdee070989fb0f042505ced5b5` |
| `docs/shell/STATE.md` | `db452615c947d775baab26a01dbfcd8334fe1942aa44ebb80fbc57c6aa53eea5` |
| `docs/shell/README.md` | `85ea61a86a3e7090d9466491a6eedbdeb7a0248155dec55e7c10040b1e69b557` |
| `docs/HANDOFF.md` | `e7cc2d4222d86bbf538c65ff030b54eb7b9d769a935bc1b4e62f82081e8afb98` |
| `docs/shell/protocols/APPLICATION.md` | `6b749dd65aaf950a805c7d9614dd9b64723e608a1dd3dd9332ab1ec21126232c` |
| `shell/probe/README.md` | `45cd9bd6a1d1366950258e469bbb40918585321587bed167dd121924a0b1ac3c` |
| `docs/shell/REVIEW.md` | `192a1d4540c5b12d020ebda686a9c56788bf96bca1240ef9c7c345bdcfd442f7` |
| `docs/shell/research/sources.json` | `e2fa247857afeddc5f81c8d97e4335ba374f16d7d2b1d081477a2066b8ef08ff` |
| `docs/shell/research/device.md` | `322e0e63b5a687e9d63c2853ae832ae12d537900b8c5fa7f21c87b64bbf91a3a` |

Local candidate: `dist/shell-probe/shell-probe.xtapp`, SHA-256
`3ac52e3682fa261842180a7c2d7aaaac500b6fc1bb82dc6c997fa16ff28e56b2`.
Generated staged files are individually bound in [HOST-VALIDATION.json](HOST-VALIDATION.json).
