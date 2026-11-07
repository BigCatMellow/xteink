# Preserved experiments

These are historical snapshots for resuming the investigation, not active runtime code.

- `compact-png-cache.patch.gz`: an optional ten-strip, 80-row, 2-bit grayscale PNG cache. Preserved from the working tree based on `f99535fa9e1df7f3d481dc3e8cfc628e9aaa34c`. Host tests passed for source pixels, resource cleanup and fallback, but native decoding and speed were never checked. It was not copied to the card or merged; the successful direct quality-100 JPEG route superseded it. Inspect with `gzip -dc compact-png-cache.patch.gz`; apply only in an isolated checkout of that base if needed.
- `convert_xteink_xth.py`: exact snapshot of `/home/mellow/convert_xteink_xth.py`, the earlier standalone desktop converter. It rotates landscape images, letterboxes/resizes and dithers to four gray levels before encoding XTH. Do not mistake this historical conversion behavior for the current JPEG preparation, which decodes existing XTH pixels without those changes.

Current code is in `../../app/`; current preparation is `../../tools/prepare_jpeg.py`. The exact v0.5.0 installer is archived under the root `releases/` folder.
