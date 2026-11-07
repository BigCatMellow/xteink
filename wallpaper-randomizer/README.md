# Wallpaper Randomizer — XTEINK X4 Pro

An experimental XTOS Licorice app for native **480 × 800 `.xth`** wallpapers. Full preview works on the reader. Automatic rotation remains paused while performance and the sleep timer are investigated.

**Status: v0.4.5 persistent preview cache; cached device speed test pending. This is not a working automatic wallpaper release.** v0.4.1 crashed; v0.4.3 displayed the complete image in 30–60 seconds. The reader measured v0.4.4 at 10.167 seconds, including 8.025 seconds of encoding and 1.731 seconds of native decoding. v0.4.5 saves the encoded strips for reuse after closing/reopening the app. The reader is X4 Pro, Licorice 26110201, with 32-bit Lua integers. It also reported `interval=3600` despite a one-year request, so the no-hourly-wake requirement remains unresolved.

## Install

1. Download `wallpaper-randomizer.xtapp` from the [latest successful build](https://github.com/BigCatMellow/xteink/actions/workflows/wallpaper-randomizer.yml). Place it in `SD:/Apps/`, exit USB mode, and install it through **All Files → Apps**. Update over the existing app; do not uninstall first.
2. In USB mode, copy your `.xth` files into **`XTApps/wallrandom/files/`**, creating `files/` if needed. Use flat filenames such as `g10.xth`; no subfolders or spaces. Existing JPEG/PNG files are ignored and can stay during testing.
3. Open **Ink App → Wallpaper Randomizer**. This build clears its custom lock-screen registration so the failed renderer is no longer invoked during sleep.
4. Tap **FULL PREVIEW**. The app builds one off-screen layer in short callbacks, using prepared strips when available. Missing caches are encoded and saved once while the app is open. The menu shows a static waiting message while work runs; it does not redraw the screen for each strip. Tap the image to return. A valid prepared image should report **25 cached strips**; close/reopen the app and repeat to check persistence.
5. **TEST PNG** and **TEST TILE** retain the two smaller diagnostic tests. A PNG's fourth bar is white and blends with the background.
6. Tap the image to return and read the elapsed build time. Reconnect USB to inspect `XTApps/wallrandom/files/preview-timing.txt`: `total_ms`, `layer_ms`, `encode_ms`, `decode_ms`, `copy_ms`, `queue_ms`, `cache_ms`, `cache_hits`, `encoded_strips`, and `strips`. A warm cache should show `cache_hits=25`, `encoded_strips=0`, and `encode_ms=0`. These measure build operations, not physical e-ink refresh time. `preview-diagnostics.txt` keeps sparse recovery checkpoints and errors.

Your XTH originals are unchanged. The firmware blocks apps from reading arbitrary SD folders such as `Pushed Images`. Keep originals: uninstalling an app deletes its private files.

## Rendering

`app/xth.lua` validates the XTH header and reads its two bitplanes: columns stored right-to-left, eight vertical pixels per byte. It preserves every source pixel and uses the native shade ordering: white, dark gray, light gray, black.

The app image API does not have a verified direct XTH blit. The renderer bridges those pixels to the available image API using small **480 × 32 lossless grayscale PNG strips**. The single-strip diagnostic still uses 480×16. There is no JPEG compression, scaling, smoothing, or dithering.

`app/cache.lua` stores five bounded bundles per image plus an exact-source marker, named `wpc1-32-*.bin` and `.idx`. Each bundle holds five encoded strips; only one bundle and one decoded strip are live at a time. Comparing the marker with the complete XTH detects replacement even with the same filename and size. The marker is committed only after all bundles have been checked. Interrupted builds, missing bundles and malformed headers trigger rebuilding; write failures produce a readable error. Original XTHs are never overwritten. Fifteen images use 90 derived cache files, within the current 512-file app quota; larger collections need to account for originals and other app files too.

While connected, prepare caches on the computer to avoid even the first reader-side encoding pass:

```bash
python3 wallpaper-randomizer/tools/prepare_cache.py /path/to/SD
python3 wallpaper-randomizer/tools/prepare_cache.py /path/to/SD --check
```

The tool reads XTHs already in `XTApps/wallrandom/files/`, creates only derived cache files there, and verifies every decoded pixel. `--output-dir /path/to/staging` prepares or checks a separate staging directory. Pillow is required. Prepared strips preserve all four native shades; loading, decoding and e-ink refresh still take time.

v0.4.1 processed all 50 strips in one callback and retained all 50 decoded image objects. v0.4.3 fixed that with one off-screen layer and one live strip. v0.4.4 keeps that resource limit and doubles the strip height, halving image callbacks. It replaces three card writes per strip with five recovery writes per frame, plus startup/completion/error logs. The encoder transposes eight source pixels per pair of XTH bytes using a bounded 256-entry cache, and combines Adler sums once per row rather than twice per pixel. Integer intermediates remain safe on 32-bit Lua.

After completion the app retains only the layer; redraws do not re-decode the image. Closing or switching tests cancels queued work. The next hardware timing log must confirm the cached path and its remaining storage, decoding and callback costs.

Host tests reconstruct all strips with Pillow and compare every output pixel against an independent XTH decoder. They also assert at most one decoded strip is retained, at most one strip is processed per callback, and cancellation, decoder failure and scheduler failure release resources. Cache regressions cover desktop/reader interoperability, persistent reuse without encoding or cache writes, source replacement, damaged bundles, interrupted builds, quota failures and decoder failures. They do not emulate the reader's native decoder, allocator, layer format or execution budget. The automatic entry stays disarmed.

## Sleep and battery behavior

The selection algorithm remains in source for investigation, but v0.4.5 does not enable automatic sleep rotation. The app must not be re-enabled until performance and the user's no-hourly-wake requirement are verified.

The prior build requested a one-year interval; the device reported 3600 seconds. Further lifecycle investigation is needed before making battery claims. Stable wallpaper alone is not proof that the reader did not wake or refresh.

Custom sleep screens are firmware-specific and require **Off wallpaper → Default**. This app does not change the stock Custom wallpaper cache. Full shutdown may behave differently from sleep; test the exact power-button action you use.

## Build and verify

```bash
cd wallpaper-randomizer
lua5.4 tests/test_wallpaper.lua
python3 tests/test_xth.py
python3 tests/test_cache.py
python3 /path/to/touch-licorice-apps/xtpack.py app -o wallpaper-randomizer.xtapp
```

Python renderer tests require Pillow. To check your own art, append XTH paths to `tests/test_xth.py`. The packer includes all app Lua modules, including `cache.lua`.

See [physical-device checks](docs/DEVICE_TESTING.md) before calling this release device-verified.

## Earlier desktop tools

`tools/native_xth_wallpaper.py` changes the stock cached wallpaper while connected to the computer. It does not randomize on sleep. `tools/prepare_images.py` and `tools/sync_xth_png.py` belong to previous JPEG/PNG prototypes; the v0.4 app reads XTHs instead.

## Sources

- [Community firmware/API findings](https://github.com/omer-faruq-xteink/touch-licorice-apps/blob/main/docs/firmware-notes.md)
- [Lock-screen lifecycle probe](https://github.com/omer-faruq-xteink/touch-licorice-apps/tree/main/tools/lockprobe)
- [App packaging tool](https://github.com/omer-faruq-xteink/touch-licorice-apps)
