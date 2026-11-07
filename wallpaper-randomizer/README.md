# Wallpaper Randomizer — XTEINK X4 Pro

An experimental XTOS Licorice app for native **480 × 800 `.xth`** wallpapers. The full renderer failed on the physical reader; automatic rotation is paused while the failure is isolated.

**Status: v0.4.2 diagnostics. This is not a working automatic wallpaper release.** On v0.4.1, preview closed the app and sleep displayed the stock wallpaper. The card recorded `reason=first`, `interval=3600`, and `status=loaded`, with no completed render. The reported interval confirms the firmware clamped the one-year request to one hour; it does not prove the exact wake/power behavior.

## Install

1. Download `wallpaper-randomizer.xtapp` from the [latest successful build](https://github.com/BigCatMellow/xteink/actions/workflows/wallpaper-randomizer.yml). Place it in `SD:/Apps/`, exit USB mode, and install it through **All Files → Apps**. Update over the existing app; do not uninstall first.
2. In USB mode, copy your `.xth` files into **`XTApps/wallrandom/files/`**, creating `files/` if needed. Use flat filenames such as `g10.xth`; no subfolders or spaces. Existing JPEG/PNG files are ignored and can stay during testing.
3. Open **Ink App → Wallpaper Randomizer**. This build clears its custom lock-screen registration so the failed renderer is no longer invoked during sleep.
4. Tap **TEST SMALL PNG** once. This decodes one known-good 32×32 image with four gray bars. Tap the screen to return if it displays.
5. Only if the small test works, tap **TEST TILE** once. This reads one XTH and encodes/decodes just one 480×16 strip, rather than retaining 50 decoded images. **CHECK XTH** only validates the file header and size.
6. Reconnect USB. Inspect `XTApps/wallrandom/files/preview-diagnostics.txt`. A checkpoint is saved before file reading, strip encoding, native decoding and drawing. A hard crash leaves the last completed write, which helps distinguish the failure stages.

Your XTH originals are unchanged. The firmware blocks apps from reading arbitrary SD folders such as `Pushed Images`. Keep originals: uninstalling an app deletes its private files.

## Rendering

`app/xth.lua` validates the XTH header and reads its two bitplanes: columns stored right-to-left, eight vertical pixels per byte. It preserves every source pixel and uses the native shade ordering: white, dark gray, light gray, black.

The app image API does not have a verified direct XTH blit. The renderer bridges those pixels to the available image API using small **480 × 16 lossless grayscale PNG strips in memory**. No PNG files are written to the SD card. There is no JPEG compression, scaling, smoothing, or dithering. Strips avoid passing one full-screen PNG to a decoder that has failed on large PNGs in community tests. Their decoded images stay alive until the session closes, and are reused on redraw.

Host tests reconstruct the strips with Pillow and compare every output pixel against an independent XTH decoder. They do not emulate the reader's native decoder, memory allocator or execution budget. The hardware failure shows why pixel-correct output alone is insufficient. The diagnostic tests verify exactly one decode per probe, crash checkpoints, and that the automatic entry stays disarmed.

## Sleep and battery behavior

The selection algorithm and original strip renderer remain in source for investigation, but v0.4.2 does not enable them as an automatic sleep screen. The app must not be re-enabled until rendering and the user's no-hourly-wake requirement are verified.

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
