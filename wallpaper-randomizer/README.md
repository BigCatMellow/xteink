# Wallpaper Randomizer — XTEINK X4 Pro

An experimental XTOS Licorice app for native **480 × 800 `.xth`** wallpapers. Full preview works on the reader with v0.4.3, but took 30–60 seconds. Automatic rotation remains paused while performance and the sleep timer are investigated.

**Status: v0.4.4 optimized manual preview; device speed test pending. This is not a working automatic wallpaper release.** v0.4.1 crashed. Small PNG and XTH-strip tests worked, and v0.4.3 successfully displayed the complete image. The reader is X4 Pro, Licorice 26110201, with 32-bit Lua integers. The device also reported `interval=3600` despite a one-year request, so the no-hourly-wake requirement remains unresolved.

## Install

1. Download `wallpaper-randomizer.xtapp` from the [latest successful build](https://github.com/BigCatMellow/xteink/actions/workflows/wallpaper-randomizer.yml). Place it in `SD:/Apps/`, exit USB mode, and install it through **All Files → Apps**. Update over the existing app; do not uninstall first.
2. In USB mode, copy your `.xth` files into **`XTApps/wallrandom/files/`**, creating `files/` if needed. Use flat filenames such as `g10.xth`; no subfolders or spaces. Existing JPEG/PNG files are ignored and can stay during testing.
3. Open **Ink App → Wallpaper Randomizer**. This build clears its custom lock-screen registration so the failed renderer is no longer invoked during sleep.
4. Tap **FULL PREVIEW** once. The app builds one off-screen layer in short callbacks, then displays it after completion. The menu shows a static waiting message while work runs; it does not redraw the screen for each strip. Tap the image to return.
5. **TEST PNG** and **TEST TILE** retain the two smaller diagnostic tests. A PNG's fourth bar is white and blends with the background.
6. Tap the image to return and read the elapsed build time. Reconnect USB to inspect `XTApps/wallrandom/files/preview-timing.txt`: `total_ms`, `layer_ms`, `encode_ms`, `decode_ms`, `copy_ms`, `queue_ms`, and `strips`. These measure build operations, not physical e-ink refresh time. `preview-diagnostics.txt` keeps sparse recovery checkpoints and errors.

Your XTH originals are unchanged. The firmware blocks apps from reading arbitrary SD folders such as `Pushed Images`. Keep originals: uninstalling an app deletes its private files.

## Rendering

`app/xth.lua` validates the XTH header and reads its two bitplanes: columns stored right-to-left, eight vertical pixels per byte. It preserves every source pixel and uses the native shade ordering: white, dark gray, light gray, black.

The app image API does not have a verified direct XTH blit. The renderer bridges those pixels to the available image API using small **480 × 32 lossless grayscale PNG strips in memory**. The single-strip diagnostic still uses 480×16. No PNG files are written to the SD card. There is no JPEG compression, scaling, smoothing, or dithering.

v0.4.1 processed all 50 strips in one callback and retained all 50 decoded image objects. v0.4.3 fixed that with one off-screen layer and one live strip. v0.4.4 keeps that resource limit and doubles the strip height, halving image callbacks. It replaces three card writes per strip with five recovery writes per frame, plus startup/completion/error logs. The encoder transposes eight source pixels per pair of XTH bytes using a bounded 256-entry cache, and combines Adler sums once per row rather than twice per pixel. Integer intermediates remain safe on 32-bit Lua.

After completion the app retains only the layer; redraws do not re-decode the image. Closing or switching tests cancels queued work. A desktop encoder comparison on g19 measured roughly 1.9× faster encoding; this is not a device-speed claim. The next hardware timing log will show the actual contribution of storage, native decoding and callback waits.

Host tests reconstruct all strips with Pillow and compare every output pixel against an independent XTH decoder. They also assert at most one decoded strip is retained, at most one strip is processed per callback, and cancellation, decoder failure and scheduler failure release resources. They do not emulate the reader's native decoder, allocator, layer format or execution budget. The automatic entry stays disarmed.

## Sleep and battery behavior

The selection algorithm remains in source for investigation, but v0.4.4 does not enable automatic sleep rotation. The app must not be re-enabled until performance and the user's no-hourly-wake requirement are verified.

The prior build requested a one-year interval; the device reported 3600 seconds. Further lifecycle investigation is needed before making battery claims. Stable wallpaper alone is not proof that the reader did not wake or refresh.

Custom sleep screens are firmware-specific and require **Off wallpaper → Default**. This app does not change the stock Custom wallpaper cache. Full shutdown may behave differently from sleep; test the exact power-button action you use.

## Build and verify

```bash
cd wallpaper-randomizer
lua5.4 tests/test_wallpaper.lua
python3 tests/test_xth.py
python3 /path/to/touch-licorice-apps/xtpack.py app -o wallpaper-randomizer.xtapp
```

Python renderer tests require Pillow. To check your own art, append XTH paths to `tests/test_xth.py`. The packer includes `index.lua`, `lockscreen.lua` and `xth.lua` in the app.

See [physical-device checks](docs/DEVICE_TESTING.md) before calling this release device-verified.

## Earlier desktop tools

`tools/native_xth_wallpaper.py` changes the stock cached wallpaper while connected to the computer. It does not randomize on sleep. `tools/prepare_images.py` and `tools/sync_xth_png.py` belong to previous JPEG/PNG prototypes; the v0.4 app reads XTHs instead.

## Sources

- [Community firmware/API findings](https://github.com/omer-faruq-xteink/touch-licorice-apps/blob/main/docs/firmware-notes.md)
- [Lock-screen lifecycle probe](https://github.com/omer-faruq-xteink/touch-licorice-apps/tree/main/tools/lockprobe)
- [App packaging tool](https://github.com/omer-faruq-xteink/touch-licorice-apps)
