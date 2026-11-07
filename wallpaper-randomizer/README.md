# Wallpaper Randomizer — XTEINK X4 Pro

Continuing previous work: see the [saved handoff](docs/HANDOFF.md) for the exact
installer, device evidence, backups and next physical check.

**v0.5.0: a random high-quality wallpaper each time you enter sleep**, with Enable/Disable, Preview Next, Rescan and Help controls. A wallpaper stays selected throughout that sleep, including firmware timer wakes. With at least two usable images, consecutive sleeps avoid an immediate repeat.

The quality-100 grayscale JPEG renderer worked on X4 Pro Licorice **26110201**: v0.4.6 measured **583 ms** to read/validate/decode an image, including 237 ms native decoding, and the user reported the preview worked well. Physical screen refresh is additional. The new sleep integration and settings have host coverage; the first real sleep/wake check for v0.5.0 is still needed.

## Install and enable

1. Place `wallpaper-randomizer.xtapp` in **SD:/Apps/**. Exit USB mode and install through **All Files → Apps**. Update over the existing app; do not uninstall.
2. In **Settings → Display**, set **Off wallpaper → Default**.
3. Open **Ink App → Wallpaper Randomizer**. Check the prepared-image count; the current card has 15.
4. **Preview Next** displays a prepared wallpaper full-screen. Tap it to return. Repeated previews visit other images without changing sleep history.
5. Tap **Enable** and approve the reader's **Set as lock screen** prompt. The status should say **Sleep rotation: ON**.
6. Close the app. Press power briefly to enter sleep. Wake and sleep again for another image.

Opening or reopening the app preserves the firmware's enabled setting. **Disable** removes this app as the default sleep screen without deleting images or history. **Rescan** finds newly prepared images. **How to Use** repeats setup instructions on the reader.

**Firmware limitation:** the host may still wake and redraw an app sleep screen hourly. This app requests 3600 seconds, the longest supported interval, and does not select a different image on timer wakes. It cannot promise zero hourly wakes or battery use. The Notes app's [measurements on the same firmware](https://github.com/omer-faruq-xteink/touch-licorice-apps/blob/main/apps/notes/lockscreen.lua#L134) report that zero and values above 3600 are refused. Sleep-only selection is separate from the host's timer. Full shutdown may behave differently from ordinary sleep.

## Images and preparation

Prepared images live in **SD:/XTApps/wallrandom/files/**. The firmware blocks apps from reading arbitrary SD folders such as Pushed Images. Keep originals backed up: installing over an app preserves its files, but uninstalling deletes its private folder.

Each prepared wallpaper has three files:

- Its original uncompressed 480×800 `.xth`.
- A `wpj1-*.jpg` containing the full-resolution grayscale image at quality 100.
- A matching `wpj1-*.idx` containing the exact source bytes as a commit marker.

The app lists complete sets and checks the marker against the source before decoding. Replacing an XTH under the same name requires preparing its JPEG again. Unrelated older JPEGs, PNGs and lossless strip caches are ignored and may remain.

While connected to the computer:

```bash
python3 wallpaper-randomizer/tools/prepare_jpeg.py /path/to/SD
python3 wallpaper-randomizer/tools/prepare_jpeg.py /path/to/SD --check
```

Use `--output-dir /path/to/staging` to prepare or check a separate staging directory. The tool reads originals already in the app folder, writes only derived JPEG/marker files, commits markers last and verifies the results. Fifteen images use 30 derived files; account for originals, old caches and other app files against the 512-file/128 MiB storage quota.

JPEG is technically lossy. There is no resizing, contrast adjustment, RGB conversion, color subsampling or dithering. All 15 current images showed maximum decoded error **1/255** on the desktop, with no changed pixels under either tested 4-bit mapping (floor `/16` or nearest `/17`). Those models do not prove firmware quantization, but the actual preview's appearance was accepted by the user. Original XTHs remain unchanged.

## Rendering and sleep history

The app uses the same one-image JPEG decoder and draw path as the successful quick preview. It retains at most one native image, without a compositor layer or strip callbacks. Preview timings go to `preview-timing.txt`; they exclude final drawing and physical e-ink refresh.

A new `reason=first` sleep chooses another prepared image. If an alternative is corrupt or stale, the loader tries the remaining alternatives before reusing the previous usable image. A successful draw commits `rotation.txt` once. Failed loads/draws do not advance history. Repeated draws and ticks reuse the decoded image. Timer sessions, and other non-first sessions with existing history, reload that saved image without advancing the sequence. A timer without valid saved history reports an error rather than selecting a new wallpaper.

Selection arithmetic stays below signed 32-bit limits. The old `sequence`/`last` save format remains readable. Storage failures are recorded without discarding originals.

`diagnostics.txt` records the sleep reason, actual interval, selected frame, status, load time and any failure. `status=rendered` means the draw API returned successfully; it does not by itself establish physical refresh, wake timing or battery behavior.

## Build and verify

```bash
python3 scripts/sync_game_ui.py --check
cd wallpaper-randomizer
lua tests/test_wallpaper.lua
python3 tests/test_jpeg.py
python3 tests/test_cache.py
python3 tests/test_xth.py
python3 /path/to/touch-licorice-apps/tools/lualint55.py app/*.lua
python3 /path/to/touch-licorice-apps/xtpack.py app -o wallpaper-randomizer.xtapp
```

The settings use the canonical measured UI helper, synchronized by `scripts/sync_game_ui.py`. Host checks cover 100 new sleeps, no immediate repeats, fixed timer frames, redraws/ticks, transactional history, image/storage failures, enable confirmation/cancellation, relaunch persistence and text/control bounds with two font profiles. JPEG tests compare every pixel and enforce one decode with no layer/callbacks. The earlier lossless PNG renderer/cache remains covered by its independent pixel and lifecycle tests, though it is no longer exposed in the everyday menu.

Host tests do not emulate firmware scheduling, native memory limits or physical rendering. See [device checks](docs/DEVICE_TESTING.md) for the remaining hardware checks.

## Earlier tools

`tools/prepare_cache.py` and `app/xth.lua` retain the slower lossless PNG-strip prototype. `tools/native_xth_wallpaper.py` changes the stock cached wallpaper while connected; it does not randomize on sleep. `tools/prepare_images.py` is the older quality-88 converter and is not used by this release.

Firmware/API findings and packaging tools: [touch-licorice-apps](https://github.com/omer-faruq-xteink/touch-licorice-apps).
