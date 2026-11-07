# Wallpaper Randomizer — XTEINK X4 Pro

A small, offline **XTOS Licorice Ink App** that cycles through your own 480 × 800 **JPEG** wallpapers whenever its custom lock screen starts. It remembers the last displayed image, and never picks that same image on the next activation if there are at least two.

**Status:** v0.2 prototype. This is an app-based *lock screen*, not a patch to the stock **Off wallpaper → Custom** option. It selects the next wallpaper when the reader enters sleep, then remains static while asleep. Firmware lifecycle behavior can still differ by version.

## How it works

- The user copies pictures into the app's private folder: `XTApps/wallrandom/files/` on the microSD card.
- `lockscreen.lua` lists JPEG files, sorts them, and randomly picks from every file **except the last displayed**. It saves the filename and a counter in `rotation.txt`, so reboots don't cause consecutive repeats.
- The image is decoded once per lock-screen session, not every screen redraw. The idle refresh interval is one year, so it does not perform hourly redraws or consume power while asleep.
- **One picture:** displays that picture every time. **No pictures:** displays an instruction instead of crashing.
- No network access, cloud sync, or changes to the device firmware are required.

The included `tools/prepare_images.py` crops and converts ordinary PNG/JPG/WebP/BMP pictures into properly sized grayscale JPEGs. The images themselves are **not committed** and are **not embedded into the `.xtapp` package**.

## Install on Licorice

1. Open the [Wallpaper Randomizer build](https://github.com/BigCatMellow/xteink/actions/workflows/wallpaper-randomizer.yml). Download the latest successful **wallpaper-randomizer-xtapp** artifact and extract `wallpaper-randomizer.xtapp`.
2. Put the `.xtapp` at the root of the reader's microSD card using USB mode. In **All Files**, tap it and confirm installation.
3. Go back to USB mode. Open `XTApps/wallrandom/files/` on the microSD card, **creating the `files` directory if needed**. Copy at least **two** JPEG images there, preferably portrait **480 × 800**. Use simple ASCII names such as `01.jpg`, `02.jpg`, etc. Avoid nested folders.
4. In **Settings → Display**, select **Default** for **Off wallpaper** (not Custom, Cover, or Desk).
5. Open **Ink App → Wallpaper Randomizer**. If Ink App is hidden, go to **Settings → About** and tap **Model** ten times quickly.
6. Tap **RESCAN** to count photos, then **ENABLE LOCK SCREEN**, and approve Licorice's system confirmation.
7. Lock/sleep the reader, wake it, and lock it again. Confirm images rotate.

You can use **PREVIEW** in the app to confirm a JPEG decodes on the device. Tap the screen again to leave preview. Only tap **ENABLE** when you're ready to make it the active lock screen.

### Converting a folder of images

Install Python 3 and Pillow (`python -m pip install Pillow`), then run from this project folder:

```bash
python tools/prepare_images.py /path/to/pictures --output prepared
```

The `prepared/` directory will contain `wall001.jpg`, `wall002.jpg`, and so on. Copy those JPEGs to `XTApps/wallrandom/files/` on your SD card.

Original PNG/BMP images won't be recognized directly by this v0.1 app; convert them first. The device's image decoder has been confirmed for JPEG, whereas PNG support has varied by firmware build.

**Important:** Reinstalling the app *over* an existing install generally preserves its files. **Uninstalling** the app deletes its app-private storage, including your pictures and rotation history. Keep originals on your computer.

## Limitations / verification

- **Live lock-screen support is firmware-specific.** The official API is not public; community tests establish `lockscreen.lua` plus `ctx.lockscreen:set_default()`. The app chooses only when a lock-screen session starts, and uses a one-year idle-refresh interval to avoid periodic redraws.
- **This cannot change the normal stock “Custom” wallpaper directly.** Attempts to use `ctx.lockscreen:set_wallpaper()` have not produced a working off-wallpaper on tested Licorice versions.
- **A small app sandbox only.** Licorice mini-apps cannot scan arbitrary SD folders like CrossPoint's `/.sleep/`. Images must be in the app's private `files/` folder.
- **Do not uninstall to update.** Uninstall removes app data.
- The prototype uses JPEGs to limit decoding failures, and does not currently include a device-side file picker.
- A custom lock-screen app may override the usual book-cover/Desk off-wallpaper behavior while enabled.
- Installation/build success does **not** prove correct real-device lock lifecycle.

## Project structure

- `app/index.lua`: Enable, rescan, and preview management UI.
- `app/lockscreen.lua`: Lock entry, persistent no-repeat image selection, JPEG renderer.
- `app/manifest.json`: Licorice app manifest with lock-screen entry point.
- `tools/prepare_images.py`: JPEG conversion tool.
- `tests/test_wallpaper.lua`: Simulated host tests.
- `docs/DEVICE_TESTING.md`: Physical-device acceptance checks.
- `.github/workflows/wallpaper-randomizer.yml` (repo root): build and package workflow.

## Sources

- [Community Licorice API findings](https://github.com/omer-faruq-xteink/touch-licorice-apps/blob/main/docs/firmware-notes.md)
- [Working Notes lock-screen example](https://github.com/omer-faruq-xteink/touch-licorice-apps/tree/main/apps/notes)
- [Community .xtapp packaging tool](https://github.com/omer-faruq-xteink/touch-licorice-apps)
