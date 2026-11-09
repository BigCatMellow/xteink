# Xteink shell project

Research and host preparation for a custom primary interface loaded from the
X4 Pro SD card through USB. Licorice remains the host; automatic startup and
native-app return behavior still need device evidence.

- [Shell design: Games Hub 0.4.0](docs/DESIGN.md) — the shipped shell; source in `games/games-hub/src/`
- [Project index and research](docs/README.md)
- [Current state](docs/STATE.md)
- [OS roadmap and model assignments](docs/ROADMAP.md)
- [Probe contract and runbook](docs/probes/README.md)
- [Diagnostic source](probe/README.md)

The project owns its research under `docs/`, diagnostic source under `probe/`,
host tools under `tools/` and focused checks under `tests/`. Canonical UI and
icon helpers remain shared repository infrastructure. Build output stays in
ignored `dist/shell-probe/` at the repository root.

Run from the repository root:

```sh
python3 shell/tools/build_probe.py
lua shell/tests/test_probe.lua
python3 shell/tests/test_capture.py
```

The builder uses the pinned community packer from the sibling
`touch-licorice-apps` checkout by default. See the runbook for explicit paths,
capture commands, limits and factual device preflight. Host results do not
establish physical startup, resume, rendering or package acceptance.
