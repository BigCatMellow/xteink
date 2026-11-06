# Physical X4 Pro test plan

The checks below require the actual reader; Lua and packaging CI cannot reproduce wake/sleep behavior.

1. Check **Settings → About** confirms X4 Pro running XTOS Licorice.
2. Install the built `wallpaper-randomizer.xtapp` from **All Files**; confirm it appears in **Ink App**.
3. With no images, app says `0 JPG images ready`; empty lock-screen fallback should remain readable.
4. In USB mode, add three portrait 480×800 baseline JPEGs to `XTApps/wallrandom/files/`. Return, tap **RESCAN**, confirm the count is three.
5. Tap **PREVIEW**; image fills the screen and closes on a tap. No crash or spurious stretching.
6. Choose **Settings → Display → Off wallpaper → Default**, then tap **ENABLE LOCK SCREEN**, approve the system prompt.
7. Lock and wake the reader at least six times in succession. Photograph or write down the image order. No image should repeat immediately (assuming 2+ usable images). If it does, note whether the lock entry is being reused rather than reloaded.
8. Leave the reader locked for over an hour: the image should remain stable during timer-driven redraws. If it changes, investigate the firmware's lock-screen lifecycle.
9. Reboot the device and lock twice. The first image after restart must not be the immediately previous one when 2+ JPEGs exist.
10. Remove one JPEG; ensure the selection logic handles the new list and does not crash. With only one JPEG, repetition is expected.
11. Try a malformed JPG and an oversized JPG; confirm graceful fallback. Do not ship if decode crashes.
12. Reinstall an updated `.xtapp` **over** the current install (never uninstall first); verify image files and rotation history survive.

Collect Licorice build number, install result, and any failed step. The app cannot be called device-verified until these checks pass.
