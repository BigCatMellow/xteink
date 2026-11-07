# XTH wallpaper physical-device checks

**v0.4.2 is diagnostic only.** v0.4.1 failed on the reader (preview crashed,
stock sleep screen shown). Its log stopped at `status=loaded` and reported
`interval=3600`. Preserve that evidence before updating.

Install v0.4.2 over the existing app, open it to clear the failed custom sleep
screen, then test the small PNG first. If that displays, test one XTH tile.
Reconnect and read `preview-diagnostics.txt`; do not repeat full-screen tests
until the decoder/encoding/draw failure has been isolated. The tests below are
the future acceptance criteria, not claims that the current build passes them.

Host tests verify pixels and selection logic; these steps verify the reader itself.

1. Record the X4 Pro Licorice firmware build. Update over the installed app without uninstalling it. Confirm v0.4 installed from All Files and appears in Ink App.
2. Put at least three uncompressed 480×800 XTH files in `XTApps/wallrandom/files/`. Rescan and confirm the count; JPEG/PNG files should not count.
3. Preview each image. Check sharp text/line art, orientation, lack of seams, and both middle grays against the stock XTH viewer. Record visible load delay. Failure or a crash blocks deployment.
4. Set Off wallpaper to Default, enable the app and approve the system prompt. Lock/wake six times. Each new sleep should select a different image from the preceding one.
5. Check `XTApps/wallrandom/files/diagnostics.txt` over USB. Confirm `status=rendered`; record `reason` and the actual `interval`. If the host reports 3600 or another clamp, the no-periodic-wake battery requirement remains unmet.
6. Leave the reader asleep past any reported interval and observe display refreshes; inspect available logs/power measurements for timer wakes. Merely displaying the same image does not prove no wake occurred. Timer wakes must not advance `rotation.txt` or choose a different image.
7. Repeat using your usual short/long power-button action. Distinguish ordinary sleep from full shutdown. Test after a reboot as well.
8. Test one image and no images; test malformed/unsupported XTH headers. Expect readable fallback instead of a crash. Remove the bad frame afterwards.
9. Reinstall over the current app and verify XTHs/history survive. Preserve old JPEG files until the XTH path is verified; originals should remain on the computer or in Pushed Images.

Do not call this device-verified until image output, speed, memory usage, lifecycle and actual timer behavior have been checked.
