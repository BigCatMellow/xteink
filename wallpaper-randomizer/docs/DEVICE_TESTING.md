# Wallpaper Randomizer v0.6.1 landscape quote-overlay device checks

The quality-100 JPEG quick preview is confirmed on X4 Pro Licorice **26110201**: `total_ms=583`, `decode_ms=237`, `cache_ms=346`, `stage=draw-ok`. The user accepted the appearance. The elapsed time excludes physical screen refresh. The prior lossless strip preview measured 2347 ms.

**The v0.6.1 landscape-oriented quote overlay is host-tested and still needs first physical sleep/wake verification.** The earlier v0.5.0 sleep integration also has no confirmed device result. Do not describe it as device-verified merely because CI passes. Preserve images, history and existing logs before updating.

1. Install from **All Files → Apps** over the existing app. Do not uninstall.
2. Set **Settings → Display → Off wallpaper → Default**. Open Wallpaper Randomizer and confirm **15 images prepared** on the current card.
3. With **QUOTES: ON**, tap **Preview Next**. Hold the X4 Pro sideways, with the sample drawing upright on the RIGHT. Check that the quote reads left-to-right on the blank LEFT, and no filled rectangle obscures the art. Inspect thin stroke clarity and legibility. Check long quotes and optional author lines. Switch **QUOTES: OFF**, preview again, and confirm the image is unaltered. Then check crisp lettering and gray levels, tap to return, and repeat with another image. Include the largest JPEG (currently g3) when checking the full collection. Confirm no crash, scaling or unintended overlays.
4. Tap **Enable**, approve the firmware's **Set as lock screen** dialog, and confirm **Sleep rotation: ON**. Cancelling the dialog must leave it off.
5. Close the app. Use a brief power-button press to sleep. Check a complete wallpaper. Wake and sleep at least three times; adjacent sleeps should show different usable images.
6. Reopen the app: it must remain enabled. Close it and repeat sleep. Check after a reboot too; distinguish ordinary sleep from full shutdown.
7. While asleep, leave it past an hour. Verify the quote text and wallpaper BOTH remain identical; neither advances on a timer redraw. Inspect `rotation.txt` for the single committed quote snapshot.
8. For custom quotes, add two short entries to `XTApps/wallrandom/files/quotes.txt`, confirm Preview Next can show them, and sleep again. Verify unchanged original XTH/JPEG bytes. A timer redraw must retain the same quote and frame; check `diagnostics.txt` for `reason=timer`, unchanged selection and `interval=3600`. This is not a no-wake/no-battery-use claim.
9. Tap **Disable**, close the app and sleep. The firmware's default wallpaper should return. Reopen/reinstall over the app and check images/history survive.

The normal first sleep should log `status=rendered` and the correct frame/interval. A default wallpaper, blank frame, crash or `load-error`/`draw-error` requires inspecting `diagnostics.txt`; host drawing success alone is insufficient evidence of physical output.

On a backed-up test collection, verify one/no images, stale source markers, missing/corrupt JPEGs, failed history writes and removed saved timer images. New sleeps should skip bad alternatives; timer sessions must never choose a different frame. Errors should be readable, and originals must not be deleted to conduct checks.

Host checks cover the corresponding selection, storage, controls and measured layout states. Real font rendering, native full-image decoding, sleep lifecycle, actual timer behavior and power use remain hardware checks.
