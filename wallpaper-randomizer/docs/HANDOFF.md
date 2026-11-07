# Wallpaper handoff — 2026-11-07

## Where we stopped

The user asked to save everything to resume later after v0.5.0 was staged. **Code and CI are complete; the next task is the reader's first v0.5.0 sleep/wake test.** No successful sleep-screen result has been reported for this version yet. Do not restart the previous rendering experiments unless that test identifies a failure.

- Repo: `/home/mellow/xteink`, GitHub `BigCatMellow/xteink`, branch `main`.
- Last functional commit: `981d182224d63b56c867201cee90f21940490a7a`.
- Version **0.5.0**, app ID **wallrandom**; update over the existing app, never uninstall to test.
- Device: **X4 Pro**, **XT Licorice 26110201**, Lua **32-bit integers** (`math.maxinteger=2147483647`).
- Exact saved installer: [releases/wallpaper-randomizer-0.5.0.xtapp](../../releases/wallpaper-randomizer-0.5.0.xtapp), **36,576 bytes**.
- Installer SHA-256: `c4decd7ee8ca7ee84ac199831e476660d541f554961f243863e884e1ede7f1d5`.
- Local build copy: `/home/mellow/xteink/dist/wallpaper-randomizer.xtapp`.
- Copied to **SD:/Apps/wallpaper-randomizer.xtapp**. All **156 installed app/data files** were compared with the backup and unchanged during staging. Installing is a separate action on the reader.

The last verified installed version before staging was **0.4.6**. Do not assume the user has since installed 0.5.0. The SD card was no longer accessible at `/media/mellow/4A21-0000` when these handoff notes were written.

## Next device steps

1. Install **All Files → Apps → wallpaper-randomizer.xtapp** over the current app.
2. Set **Settings → Display → Off wallpaper → Default**.
3. Open **Wallpaper Randomizer**; expect **15 images prepared**. Preview Next should show full-screen images; tap to return.
4. Tap **Enable**, approve **Set as lock screen**, and check **Sleep rotation: ON**.
5. Close the app. Briefly press power to sleep. Wake and sleep again for a different wallpaper.

Opening the app must preserve enablement; Disable should restore the stock sleep screen. Ordinary sleep and full shutdown are different cases. More complete acceptance checks are in [DEVICE_TESTING.md](DEVICE_TESTING.md).

If a sleep fails, reconnect and read **XTApps/wallrandom/files/diagnostics.txt** before changing code. It records reason, actual interval, frame, status, load time, firmware/model and a bounded error. Expected after a successful draw: `status=rendered`. A host draw return is not by itself proof of physical display or battery behavior.

## User requirements and the firmware limit

Choose another random image **once per new sleep**. Keep it fixed through that sleep. No hourly wallpaper changes. The user values crisp text/line art and wanted the image load under one second; the tested JPEG path achieved that load/decode target.

The firmware can still wake/redraw an app sleep screen hourly. The old one-year interval request was clamped to 3600. Upstream Notes measurements on the same firmware report that `ctx.lock:set_interval(0)` and values above 3600 are refused. v0.5.0 requests the supported maximum **3600** and displays this limitation in settings/help. Timer sessions keep the same image and never advance history. **Do not claim zero hourly wakes, refreshes or battery use.** No such hardware/power test was completed.

The stock app sandbox cannot read **Pushed Images** directly. Runtime files are in **XTApps/wallrandom/files/**. The current approach needs no firmware flashing. USB disk mode is not proof of serial/bootloader access; a flashing route was not established for this unit. Keep using stock XTOS mini apps unless explicitly changing that scope.

## What worked on the reader

| Version/path | Evidence |
| --- | --- |
| v0.4.1 full XTH/PNG preview | Crashed; stock sleep wallpaper shown. |
| v0.4.2 small PNG + single XTH strip | Visible; an all-white fourth bar blended with the background. |
| v0.4.3 one layer + sequential small strips | Full image visible, user estimated 30–60 seconds. |
| v0.4.4 optimized lossless strips | 10,167 ms total; 8,025 ms encoding and 1,731 ms decoding. |
| v0.4.5 prepared lossless PNG strips | 2,347 ms total; 25 cached strips, zero encoding; 1,676 ms decoding. |
| v0.4.6 direct quality-100 grayscale JPEG | **583 ms total**, 346 ms read/validation/setup, **237 ms decode**, one image, no layer or callback queue. User: “that quick preview worked great.” |
| v0.5.0 sleep integration and everyday UI | Implemented and host/CI-tested; **physical sleep/wake result pending**. |

Saved raw timing logs and the successful JPEG diagnostic are in [evidence/](evidence/). These durations exclude physical screen refresh. Do not conflate preview timing with total button-to-visible-sleep delay or claim all 15 JPEGs were physically checked.

JPEG is technically lossy. All 15 prepared images were checked on the desktop: maximum brightness error **1/255**, with no changed samples under the two tested 4-bit mappings. There is no resizing, contrast adjustment or dithering in JPEG preparation. The older quality-88 converter altered contrast; do not use it as the current pipeline. Original XTHs and old lossless caches remain intact.

## Implementation map

- `app/index.lua`: measured settings UI; Enable/Disable, Preview Next, Rescan, Help. Queries actual firmware enablement; opening/relaunching never clears it. Preflight decodes an image before the firmware enable prompt. Previews do not update sleep history.
- `app/wallpaper.lua`: catalogue, source/marker checks through the shared JPEG path, bounded selection arithmetic, history transaction, diagnostics. Avoids the preceding usable image; skips corrupt/stale alternatives. Direct existence/size checks cover derived files omitted from capped directory listings.
- `app/lockscreen.lua`: loads one JPEG synchronously. New sleeps choose a candidate; timer/non-first sessions with saved history reuse it. Only the first successful draw commits history. Redraws/ticks never select or decode another frame. Failures do not deliberately advance history.
- `app/probe.lua`: the device-confirmed JPEG decode/draw path, now with a quiet option for normal use. Retains the historical renderer probes for their existing tests. Sleep mode does not write verbose preview checkpoints.
- `app/ui.lua`: generated from `shared/game_ui.lua`; update with `scripts/sync_game_ui.py`.
- `app/xth.lua`, `app/cache.lua`: retained slower lossless PNG prototype; still covered by independent tests but not exposed in the everyday menu.
- `tools/prepare_jpeg.py`: current preparation and verification. Each XTH has a `wpj1-*.jpg` plus an exact-source `wpj1-*.idx` commit marker. Markers are committed last; replacing an original invalidates its prepared JPEG.

XTH format: 480×800, uncompressed, 22-byte header, two 48,000-byte bitplanes; columns right-to-left, eight vertical pixels per byte. First plane supplies bit 1, second bit 0; native levels are 0=white/255, 1=dark/85, 2=light/170, 3=black/0. Preserve this unusual middle-gray ordering. Selection intermediates must stay below signed 32-bit limits.

The 15 current originals are g10, g11, g13–g20, g3, g7, g9, ignatius2 and wave, all `.xth`. They and their prepared JPEGs were checked before staging. The largest JPEG is g3 (260,123 bytes), worth including in the hardware image/memory check.

## Resume development

```bash
cd /home/mellow/xteink
git status --short
git fetch origin main
python3 scripts/sync_game_ui.py --check
python3 scripts/check_games.py
cd wallpaper-randomizer
lua tests/test_wallpaper.lua
python3 tests/test_jpeg.py
python3 tests/test_cache.py
python3 tests/test_xth.py
python3 /home/mellow/touch-licorice-apps/tools/lualint55.py app/*.lua
python3 /home/mellow/touch-licorice-apps/xtpack.py app -o ../dist/wallpaper-randomizer.xtapp
```

Python tests require Pillow. Renderer tests use Lua 5.4/5.3, or the installed Lua 5.4 shared library when the desktop's `lua` points to 5.1. The lifecycle/layout test supports the desktop's Lua 5.1. CI installs Lua 5.4. The workflow pins packer commit `3d7e6225efc9b18d2b4aeed324a32b2e352d1f0d`. Rebuilds use fresh encryption material; the archived checksum identifies the exact staged installer, not every rebuild's bytes.

For new XTHs already copied into the app folder:

```bash
python3 wallpaper-randomizer/tools/prepare_jpeg.py /path/to/SD
python3 wallpaper-randomizer/tools/prepare_jpeg.py /path/to/SD --check
```

Use `--output-dir` to stage first. Read [AGENTS.md](../../AGENTS.md) and the root [project handoff](../../docs/HANDOFF.md) before touching games or SD layout. Preserve unrelated new game commits when fetching/pushing.

Tests cover 100 new sleeps, no immediate repeats, fixed timer frames, redraw/tick behavior, source invalidation, bad alternatives, storage/draw failures, enable approval/cancellation, relaunch, capped listings, resource release and two measured font profiles. The [wallpaper CI](https://github.com/BigCatMellow/xteink/actions/runs/42410216245) and [12-game quality gate](https://github.com/BigCatMellow/xteink/actions/runs/42410216255) passed for `981d182`.

## Local backups and preserved experiments

These remain on the machine, not in the public code repo:

- **Before v0.5.0 staging:** `/home/mellow/xteink-backups/wallpaper-before-sleep-release-6ztqm_69/`. Installed v0.4.6, all app files/history/logs, prior installer, and `preserved-sha256.json` for all 156 installed files.
- Before v0.4.6/JPEG update: `/home/mellow/xteink-backups/wallpaper-before-fast-cache-1oj3d9dp/`.
- Before persistent PNG cache: `/home/mellow/xteink-backups/wallpaper-before-cache-nplgrg87/`.
- Older backups: `/home/mellow/xteink-backups/wallpaper-before-fast-preview-jU7ZX1QX/`, `wallpaper-before-layer-preview-JiADt9hq/`, `wallpaper-before-xth-d46gRKRX/`, `wallpaper-device-failure-8KLgRhOm/`.
- Original desktop image folder from the initial request: `/home/mellow/Pictures/drive-download-20261107T021743Z-1-001/`. Reader originals also existed in Pushed Images. Recheck availability before using either.

[experiments/](experiments/) preserves the unused compact-PNG patch and the original desktop XTH conversion script. The compact-PNG alternative passed host checks but was never deployed or device-tested; the direct JPEG route superseded it. Do not apply the old patch on top of current main. It belongs to base `f99535fa9e1df7f3d481dc3e8cfc628e9aaa34c` and should only be examined in an isolated checkout.
