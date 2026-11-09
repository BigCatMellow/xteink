# Shell Probe (host preparation)

Minimal diagnostic app for the [frozen probe contract](../../docs/shell/probes/contract.json).
It is distinct from the proposed shell and all installed apps: app ID
`xteinkshellprobe`, version `0.1.0`, API `2.0`, no permissions or lockscreen.
This work has performed no SD, USB/serial, firmware or device operation.

The source uses canonical `shared/game_ui.lua`, copied only into ignored staging
at build time. Native fonts are the diagnostic baseline, **not the final shell
theme**. The editable icon lives in `src/icon.svg`; its native PNG is generated
with the repository's Pillow icon renderer and checked against packaged pixels.

## Rebuild and verify

From the repository root, install Python 3 dependencies `Pillow==10.2.0` and
`cryptography`, plus Lua 5.4 and Lua 5.1. Obtain the community packer repository
at commit `3d7e6225efc9b18d2b4aeed324a32b2e352d1f0d`; no firmware dump or
credential is needed. The build checks exact packer, vendor and linter bytes
against that Git commit, even if the checkout HEAD is newer.

```sh
python3 scripts/build_shell_probe.py --packer ../touch-licorice-apps/xtpack.py
lua5.4 tests/test_shell_probe.lua
lua5.1 tests/test_shell_probe.lua
python3 scripts/build_shell_probe.py --check --packer ../touch-licorice-apps/xtpack.py
```

`--linter /path/to/tools/lualint55.py` overrides the linter location, which must
remain inside the packer checkout and match the same pin. Default paths use the
sibling `touch-licorice-apps` checkout. `--check` rejects stale or extra staged
sources/assets, then rebuilds the package. Encryption makes package hashes vary
on rebuild; each receipt binds that exact output to the contract and source.

Outputs are ignored host artifacts in `dist/shell-probe/`: staged `app/`,
`shell-probe.xtapp`, and `receipt.json` with contract/package/source hashes,
manifest identity, tool pin and code budgets. They are not public releases.
The target is at most four Lua files and 32 KiB XTCO, tighter than the supported
32-file/512 KiB ceiling. The build also checks distinct ID/icon, manifest and
all 9,216 native icon pixels. Lua 5.5 lint is static compatibility evidence,
not execution on device Lua 5.5.

## Intended diagnostic behavior

The future screen has two inventory pages, Page and Next trial controls,
read-only Refresh inventory, and explicit Save marker. Every control accepts
only pointer-up tap gestures in its drawn rectangle. No timer or recurring
redraw is installed. `system.can_open` and `system.open` are inspected by type
only and are never called. No arbitrary context, IDs, book data, device logs
or raw error strings are captured. Unrecognized model/firmware formats display
unknown; GC's numeric counter is shown without asserting its unit.

Next trial cycles the contract's trial IDs as labels; selecting one never
performs that procedure. The screen instructs the native Home pad for escape.
All counters are memory-only until Save. `on_load` reads a marker but never
writes; `on_leave` never writes. Therefore a persisted leave count cannot prove
that an exit callback ran; physical observations must retain UNKNOWN as needed.

Save overwrites only `shell-probe-marker.json`, a strict bounded JSON record
under the app's own sandbox, then reads it back byte-for-byte and validates it.
Only verified success advances the in-memory saved sequence. A missing file is
accepted only with documented `not_found`; other read failures or malformed
records block writes. Write/readback failure disables further Save until app
reload. No automatic retry, reset, deletion or raw-error display occurs.
A failed/partial storage write can leave the marker unreadable; the app reports
failure rather than pretending the old marker was preserved. It never creates
extra backup or per-event files.

Host tests cover marker reload, selecting/reloading trial labels, no automatic
writes, thrown/returned read and write failures, readback mismatch, malformed
and oversized data, blocked retry, navigation methods never invoked, privacy,
tap boundaries and both inventory pages with native/enlarged glyph metrics.
Physical font, input, native Home, sleep/resume and launch checks remain unrun.
Follow the contract's factual device/preflight conditions before any later
hardware work; host results establish no autostart or resume claim.
