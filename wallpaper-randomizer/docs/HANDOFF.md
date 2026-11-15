# Wallpaper handoff — 2026-11-07

## Expanded authentic Tolkien defaults — 2026-11-15

At the user's request to continue, Wallpaper Randomizer 0.6.5 adds eight
more **book-authenticated Tolkien quotations**, for ten total. Attribution
and chapter-by-chapter source URLs are in `docs/QUOTE_SOURCES.md`. Film-only
dialogue, internet misattributions, and invented Tolkien-like lines are
excluded. Every quote is 118 characters or fewer and uses simple ASCII
punctuation for the current stroke font. The test suite checks the full
ten-quote selection cycle, correct author credit and all 480x800 landscape
layouts, in addition to existing sleep/history and custom-file behavior.
No wallpaper images, storage files, rotation state or installed app changed.
Physical reader acceptance remains pending.



## Tolkien-authored default quotes only — 2026-11-15

User clarified that wallpaper quotes should be **Tolkien's own words**,
not newly composed lines in a Lord of the Rings style. Version 0.6.4
removes all 22 invented Middle-earth-themed defaults from v0.6.3,
retaining only two previously used short authentic Tolkien excerpts.
Both are credited to J.R.R. Tolkien. We intentionally avoid expanding
the set with unattributed, invented or film-only dialogue. The trade-off
is a small rotating set until more authentic excerpts are checked.

The custom `quotes.txt` override, quote toggle, landscape orientation,
saved image+quote sleep history, and all original JPEG/XTH files remain
unchanged. Tests explicitly reject the old invented lines, verify the
two Tolkien defaults and their layout, and preserve invalid-file fallback.
Host CI does not prove physical screen quality; no SD card was changed.



## Middle-earth-only built-in quotes — 2026-11-15

At the user's request, the default Wallpaper Randomizer quote collection
now contains only Lord of the Rings-themed wording: 22 newly composed
unattributed lines about journeys, friendship, home, and hope, plus two
short authentic excerpts attributed to J.R.R. Tolkien. Version 0.6.3
replaces the 16 generic original notes and the 8 unrelated literary test
quotes in v0.6.2. The original lines must never be presented as Tolkien
quotations. No app renderer, 480x800 quote geometry, sleep lifecycle,
rotation/save format, or user-provided `quotes.txt` was changed.

Tests enforce default count, correct attribution, all-quote landscape bounds,
custom-file precedence, quote-on/off persistence and rotation. Verify
the physical screen separately; installer is not deployed to the SD card.



## Additional built-in test quotes — 2026-11-15

Version 0.6.2 adds eight built-in sample quotes to the sixteen existing
original statements. Five samples are attributed, verified public-domain
literary excerpts (Austen, Melville, Tennyson, Doyle, Alcott), and three are
new uncredited original phrases. This tests optional author names, short
lines, medium multi-line wraps, and the 0.6.1 landscape polyline renderer.
The samples display automatically when no custom `quotes.txt` is installed;
the user's optional file continues to override the bundled collection.

Tests verify corpus integrity, a full deterministic coverage cycle, all 24
landscape text layouts, existing 100-sleep history behavior, and package
compatibility. No SD file, original JPEG/XTH, or user save was changed.
Physical landscape legibility still requires user acceptance.



## Landscape orientation correction — 2026-11-15

The user provided four actual 480×800 grayscale wallpaper samples: each
displays **clockwise rotated into landscape**, putting the illustrated subject
on the **right** with broad blank white space on the **left**. The earlier
0.6.0 bottom-of-portrait text band was wrong for this use case; it would
appear sideways, obscure negative space, and a solid filled g:rect can
render black (not white) under Licorice.

v0.6.1 draws quote glyphs through small native monochrome polylines with
landscape-to-native coordinate mapping, in the otherwise empty left field
when held sideways. No extra image decode, JPEG edits, wide filled panel,
compositor layer, or loss of per-sleep quote history. Font uses a minimalist
uppercase monoline stroke alphabet at bounded sizes. Host tests assert
all stroke coordinates lie within the raw 480x800 frame and that they stay
in the left area of the rotated landscape image.

**Still needs physical device verification** of polyline text contrast and
clockwise screen orientation, normal sleep/wake, timer redraw, old saves, and
user-provided images. Original uploaded wallpaper examples were used only
for layout inspection; do not add their artwork to the public repo.



## Subsequent quote-overlay candidate — 2026-11-14

At the user's request, v0.6.0 introduces **optional quotes over existing
wallpapers**. No original XTH, JPEG, rotation saves or firmware install was
altered. The new `quotes.lua` draws a white 1-bit band over the existing
one-image JPEG render; no extra bitmap decode, compositor layer or callback.
The original quote set works offline; optional `XTApps/wallrandom/files/quotes.txt`
uses one quote per line, with optional `| Author` attribution. The on/off
setting persists in `quotes-mode.txt` (default ON). New-sleep image and
quote snapshot share the same `rotation.txt` history transaction so timer
redraws reuse both. Older rotation files remain readable.

The existing v0.5.0 physical sleep integration had **no confirmed device
acceptance**. For v0.6.0, check preview and actual sleep text order, white
panel contrast, custom quotes, long lines, timer reuse, storage preservation
and fallback. CI/host checks do not substitute for this hardware test.



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
