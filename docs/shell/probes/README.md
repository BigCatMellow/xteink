# Shell probe: host preparation

Owner: coordinator. Wave: roadmap P2/P3, 2026-11-08. Device execution remains
pending factual preflight. This package is a small diagnostic for the shell
research, not the proposed final Home interface.

Read [the contract](CONTRACT.md) and [machine contract](contract.json) first.
See the [host validation receipt](HOST-VALIDATION.json) and
[independent review](REVIEW.md) for this preparation wave.
The [device research](../research/device.md) owns the capability claims and
[roadmap](../ROADMAP.md) owns the project sequence. DP0/DP3 are the current
questions; DP1/DP2 navigation stays NEEDS_RESEARCH.

## Reproduce on the host

From the repository root, with Python 3, Lua 5.4, Pillow and the community packer
dependencies installed:

```bash
python3 scripts/build_shell_probe.py \
  --packer /home/mellow/touch-licorice-apps/xtpack.py \
  --linter /home/mellow/touch-licorice-apps/tools/lualint55.py
lua tests/test_shell_probe.lua
python3 tests/test_shell_probe_capture.py
python3 scripts/shell_probe_capture.py init \
  --contract docs/shell/probes/contract.json \
  --package dist/shell-probe/shell-probe.xtapp \
  --output dist/shell-probe/capture
python3 scripts/shell_probe_capture.py validate \
  --report dist/shell-probe/capture/report.json
```

The build writes an experimental package and receipt under ignored `dist/`.
Its source owner is [shell/probe](../../../shell/probe/src/index.lua); the UI
copy is generated from the canonical shared helper. Native fonts are a deliberate
diagnostic baseline; this is not the final Poppins/Inter shell presentation.
CI uses pinned community tools and uploads an artifact labeled **host-only**.
These commands perform no installation or attached-device discovery.

`init` requires a new output directory. Retain earlier captures; use a distinct
directory for each candidate/session. It reads the package header/manifest and
binds identity/version/API/permission declarations and SHA-256 to the contract.
Package execution and firmware acceptance require separate evidence. Use the
builder's checked candidate; capture validation is not a package signature test.

## Record an observation later

After device preflight, the operator supplies sanitized evidence explicitly:

```bash
python3 scripts/shell_probe_capture.py record \
  --report dist/shell-probe/capture/report.json \
  --trial dp0_inventory --outcome observed \
  --observation 'Manually launched; read the displayed inventory' \
  --inventory /path/to/sanitized-inventory.json \
  --values /path/to/structured-observation.json \
  --evidence /path/to/sanitized-photo.png
```

The paths above are placeholders for actual observations, not supplied evidence.
`--observation` is the bounded action text. `--values` supplies allowed fields
such as initial state, observed destination, responsive input and power semantics;
`--inventory` supplies only the contract inventory fields on DP0. Missing fields
remain null. The collector never scans books, saves, firmware or the SD card.

Use `failed` for a witnessed failure, `inconclusive` when evidence cannot answer
the question, and `not_run` for a skipped trial. Preserve an existing observation
instead of replacing it: a repeat belongs in a new capture. Evidence files are
copied and hashed; later tampering or missing files fails integrity validation.
The operator must still judge their relevance, truth and privacy.

The report remains pending for physical acceptance even after observations are
recorded. Neither an OBSERVED result nor a successful `validate` is product PASS,
autostart proof, native navigation support or readiness to change firmware.

## Next device preflight

Establish an accessible reader, exact build, candidate identity, absent disposable
app ID, native escape and a recoverable installation path. An SD mount alone
cannot operate touch, sleep, reset or the screen. Keep the existing apps and
saves outside the probe's write boundary. Record trial-specific power semantics;
retain UNKNOWN for cold boot when a safe supported procedure is unavailable.
The contract describes the allowed future marker path and stop/recovery behavior.
