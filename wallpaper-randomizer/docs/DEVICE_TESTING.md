# XTH wallpaper physical-device checks

**v0.4.5 is a cached manual preview test only.** v0.4.1 failed on the reader (preview crashed,
stock sleep screen shown). Its log stopped at `status=loaded` and reported
`interval=3600`. Preserve that evidence before updating.

v0.4.2's small PNG and single XTH strip were confirmed visible on the reader.
v0.4.3's complete image was confirmed visible, taking 30–60 seconds. v0.4.4
measured 10.167 seconds, including 8.025 seconds encoding. Install v0.4.5 over
it and tap FULL PREVIEW. A prepared image should report 25 cached strips;
close/reopen the app and repeat to test persistence. Compare elapsed build
times and read `preview-timing.txt` after reconnecting. Expect `cache_hits=25`,
`encoded_strips=0` and `encode_ms=0` for both prepared runs. Do not assume
desktop-compressed PNG decoding or card I/O is device-verified yet. Verify a complete,
unscaled image with accurate gray levels, no seams, and no overlaid text. Check
that it displays without 50 intermediate screen refreshes. Close during a build
and switch diagnostic tests to check cancellation. Reconnect and read
`preview-diagnostics.txt` if anything fails. The tests below are
the future acceptance criteria, not claims that the current build passes them.

Before enabling automatic mode, also test a new image with no prepared cache:
the first successful preview should encode 25 strips and commit its cache;
after closing/reopening, the next preview should encode none. On a backed-up
test collection, replace an XTH with another valid image under the same name;
ensure the old cache is rejected and the new image is shown. Never delete or
replace the user's originals to conduct this check.

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
