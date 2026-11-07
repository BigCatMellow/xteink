#!/usr/bin/env python3
"""Losslessly mirror reader ``Pushed Images/*.xth`` into the lock-screen app.

Licorice lock-screen apps run every time the reader locks, but are deliberately
sandboxed: they cannot read ``Pushed Images`` directly.  This tool is the
one-time-per-USB-session bridge.  It converts every native 480x800 XTH frame
to a palette PNG with the same four grey levels and copies it to the private
folder read by the Wallpaper Randomizer app.

Usage while the reader is mounted in USB mode:
  python sync_xth_png.py /media/mellow/READER_LABEL
"""

from __future__ import annotations

import argparse
import hashlib
from pathlib import Path

from PIL import Image

WIDTH, HEIGHT = 480, 800
HEADER_BYTES = 22
PLANE_BYTES = WIDTH * ((HEIGHT + 7) // 8)


def decode_xth(path: Path) -> Image.Image:
    """Decode an Xteink 480x800 two-plane image into a 4-colour PNG image."""
    raw = path.read_bytes()
    if len(raw) != HEADER_BYTES + 2 * PLANE_BYTES or raw[:4] != b"XTH\0":
        raise ValueError(f"{path.name}: not a 480x800 XTH frame")
    if int.from_bytes(raw[4:6], "little") != WIDTH or int.from_bytes(raw[6:8], "little") != HEIGHT:
        raise ValueError(f"{path.name}: unexpected dimensions")

    first = raw[HEADER_BYTES:HEADER_BYTES + PLANE_BYTES]
    second = raw[HEADER_BYTES + PLANE_BYTES:]
    pixels = bytearray(WIDTH * HEIGHT)
    for x in range(WIDTH):
        column = (WIDTH - 1 - x) * 100
        for y in range(HEIGHT):
            mask = 0x80 >> (y % 8)
            value = ((first[column + y // 8] & mask) != 0) | (((second[column + y // 8] & mask) != 0) << 1)
            # XTH level 0 is white and level 3 is black.
            pixels[y * WIDTH + x] = value

    image = Image.frombytes("P", (WIDTH, HEIGHT), bytes(pixels))
    palette = []
    for level in range(4):
        shade = (3 - level) * 85
        palette.extend((shade, shade, shade))
    palette.extend((255, 255, 255) * (256 - 4))
    image.putpalette(palette)
    return image


def same_contents(source: Path, destination: Path) -> bool:
    return destination.exists() and hashlib.sha256(source.read_bytes()).digest() == hashlib.sha256(destination.read_bytes()).digest()


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("sd_root", type=Path, help="mounted reader SD-card root")
    parser.add_argument("--dry-run", action="store_true", help="validate and list output without writing")
    args = parser.parse_args()

    source = args.sd_root / "Pushed Images"
    destination = args.sd_root / "XTApps" / "wallrandom" / "files"
    frames = sorted(source.glob("*.xth"))
    if not frames:
        raise SystemExit(f"no .xth frames found in {source}")
    if not args.dry_run:
        destination.mkdir(parents=True, exist_ok=True)

    for frame in frames:
        target = destination / f"{frame.stem}.png"
        image = decode_xth(frame)
        if args.dry_run:
            print(f"would write {target.name} ({image.mode}, {image.size[0]}x{image.size[1]})")
            continue
        temporary = target.with_suffix(".tmp")
        image.save(temporary, format="PNG", optimize=True, bits=2)
        if same_contents(temporary, target):
            temporary.unlink()
            print(f"unchanged {target.name}")
        else:
            temporary.replace(target)
            print(f"synced {frame.name} -> {target.name}")


if __name__ == "__main__":
    main()
