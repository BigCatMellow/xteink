#!/usr/bin/env python3
"""Prepare personal wallpapers for the XTEINK X4 Pro Licorice randomizer.

Example:
  python tools/prepare_images.py ~/Pictures/wallpapers --output prepared

Then copy the *contents* of prepared/ to SD:/XTApps/wallrandom/files/.
Requires: pip install Pillow
"""
import argparse
from pathlib import Path
from PIL import Image, ImageOps, ImageEnhance

W, H = 480, 800
SUPPORTED = {".png", ".jpg", ".jpeg", ".webp", ".bmp", ".gif", ".tif", ".tiff"}

def convert(src: Path, dest: Path, contrast: float = 1.08) -> None:
    with Image.open(src) as im:
        image = ImageOps.exif_transpose(im)
        frame = ImageOps.fit(image.convert("RGB"), (W,H), method=Image.Resampling.LANCZOS)
        gray = ImageEnhance.Contrast(ImageOps.autocontrast(frame.convert("L"))).enhance(contrast)
        # Keep the output compact and avoid heavy black fills where possible.
        gray.save(dest, format="JPEG", quality=88, optimize=True, progressive=False)
    with Image.open(dest) as check:
        assert check.size == (W,H) and check.format == "JPEG"

def main() -> None:
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument("source", type=Path, help="folder of JPG/PNG/BMP/etc images")
    p.add_argument("--output",type=Path,default=Path("prepared"))
    p.add_argument("--contrast",type=float,default=1.08)
    a=p.parse_args()
    if not a.source.is_dir():
        p.error(f"not a directory: {a.source}")
    candidates=sorted(f for f in a.source.iterdir() if f.is_file() and f.suffix.lower() in SUPPORTED)
    if not candidates:
        p.error("no supported images found")
    a.output.mkdir(parents=True,exist_ok=True)
    for i,source in enumerate(candidates,1):
        dest=a.output/f"wall{i:03d}.jpg"
        convert(source,dest,a.contrast)
        print(f"{source.name} -> {dest.name}")
    print(f"Converted {len(candidates)} image(s). Copy JPGs into XTApps/wallrandom/files.")

if __name__=="__main__":
    main()
