# Wallpaper Randomizer — XTEINK X4 Pro

An offline XTOS Licorice Ink App that reads native **480 × 800 `.xth`** wallpapers from its own folder and chooses a new one when its custom sleep screen starts. With two or more pictures it avoids consecutive repeats.

**Status: v0.4 prototype, tested on the host; XTH rendering, runtime limits, and sleep lifecycle still need verification on the physical reader.** A passing build does not establish device compatibility or battery usage.

## Install

1. Download `wallpaper-randomizer.xtapp` from the [latest successful build](https://github.com/BigCatMellow/xteink/actions/workflows/wallpaper-randomizer.yml). Place it at the SD-card root, exit USB mode, and install it through **All Files**. Update over the existing app; do not uninstall first.
2. In USB mode, copy your `.xth` files into **`XTApps/wallrandom/files/`**, creating `files/` if needed. Use flat filenames such as `g10.xth`; no subfolders or spaces. Existing JPEG/PNG files are ignored and can stay during testing.
3. Set **Settings → Display → Off wallpaper → Default**.
4. Open **Ink App → Wallpaper Randomizer**, tap **RESCAN**, and check the count. Try **PREVIEW** first; tap to close it.
5. Tap **ENABLE LOCK SCREEN**, approve the system prompt, then sleep and wake the reader several times.

You can add XTHs straight to this folder. No image conversion or computer sync tool is required. The firmware blocks apps from reading arbitrary SD folders such as `Pushed Images`; copy files from there into the app folder once if you want to reuse them. Keep originals: uninstalling an app deletes its private files.

## Rendering

`app/xth.lua` validates the XTH header and reads its two bitplanes: columns stored right-to-left, eight vertical pixels per byte. It preserves every source pixel and uses the native shade ordering: white, dark gray, light gray, black.

The app image API does not have a verified direct XTH blit. The renderer bridges those pixels to the available image API using small **480 × 16 lossless grayscale PNG strips in memory**. No PNG files are written to the SD card. There is no JPEG compression, scaling, smoothing, or dithering. Strips avoid passing one full-screen PNG to a decoder that has failed on large PNGs in community tests. Their decoded images stay alive until the session closes, and are reused on redraw.

Host tests reconstruct the strips with Pillow and compare every output pixel against an independent XTH decoder. They also exercise malformed headers, partial decoder failure, redraw reuse and resource release. Firmware memory/instruction limits, decoder behavior and visible rendering speed remain device tests.

## Sleep and battery behavior

The app chooses an image on a new lock-screen session, records it in `rotation.txt`, and keeps it through redraws and ticks. If the host reports `ctx.lock.reason == 'timer'`, it reuses the previous image rather than rotating while asleep.

The manifest and `set_interval` request a one-year interval. **Whether the firmware accepts that interval or clamps it is unverified.** We cannot yet claim periodic wakes are disabled. `diagnostics.txt` records the host's reason, reported interval, selected frame and render status for the physical-device check. Stable wallpaper alone is not proof that the reader did not wake or refresh.

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
