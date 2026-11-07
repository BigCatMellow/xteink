# Wallpaper Randomizer v0.5.0 device checks

The quality-100 JPEG quick preview is confirmed on X4 Pro Licorice **26110201**: `total_ms=583`, `decode_ms=237`, `cache_ms=346`, `stage=draw-ok`. The user accepted the appearance. The elapsed time excludes physical screen refresh. The prior lossless strip preview measured 2347 ms.

**The v0.5.0 sleep integration is host-tested and awaits the first physical sleep/wake check.** Do not describe it as device-verified merely because CI passes. Preserve images, history and existing logs before updating.

1. Install from **All Files → Apps** over the existing app. Do not uninstall.
2. Set **Settings → Display → Off wallpaper → Default**. Open Wallpaper Randomizer and confirm **15 images prepared** on the current card.
3. Tap **Preview Next**, check crisp lettering and gray levels, tap to return, and repeat with another image. Include the largest JPEG (currently g3) when checking the full collection. Confirm no crash, scaling or overlaid text.
4. Tap **Enable**, approve the firmware's **Set as lock screen** dialog, and confirm **Sleep rotation: ON**. Cancelling the dialog must leave it off.
5. Close the app. Use a brief power-button press to sleep. Check a complete wallpaper. Wake and sleep at least three times; adjacent sleeps should show different usable images.
6. Reopen the app: it must remain enabled. Close it and repeat sleep. Check after a reboot too; distinguish ordinary sleep from full shutdown.
7. While asleep, leave it past an hour. The firmware may wake/redraw, but the selected frame and `rotation.txt` sequence must remain unchanged. Inspect `diagnostics.txt` for `reason=timer`, the same frame and `interval=3600`. This is not a no-wake/no-battery-use claim.
8. Tap **Disable**, close the app and sleep. The firmware's default wallpaper should return. Reopen/reinstall over the app and check images/history survive.

The normal first sleep should log `status=rendered` and the correct frame/interval. A default wallpaper, blank frame, crash or `load-error`/`draw-error` requires inspecting `diagnostics.txt`; host drawing success alone is insufficient evidence of physical output.

On a backed-up test collection, verify one/no images, stale source markers, missing/corrupt JPEGs, failed history writes and removed saved timer images. New sleeps should skip bad alternatives; timer sessions must never choose a different frame. Errors should be readable, and originals must not be deleted to conduct checks.

Host checks cover the corresponding selection, storage, controls and measured layout states. Real font rendering, native full-image decoding, sleep lifecycle, actual timer behavior and power use remain hardware checks.
