#!/usr/bin/env python3
"""Convert common image files into 480x800 Xteink X4 Pro XTH frames."""

from __future__ import annotations

import argparse
import struct
from pathlib import Path

from PIL import Image, ImageOps

WIDTH, HEIGHT = 480, 800


def prepare(image: Image.Image) -> Image.Image:
    """Make a portrait, letterboxed X4 Pro frame with a white background."""
    image = Image.alpha_composite(
        Image.new("RGBA", image.size, "white"), image.convert("RGBA")
    ).convert("RGB")
    if image.width > image.height:
        image = image.rotate(90, expand=True)
    image.thumbnail((WIDTH, HEIGHT), Image.Resampling.LANCZOS)
    frame = Image.new("RGB", (WIDTH, HEIGHT), "white")
    frame.paste(image, ((WIDTH - image.width) // 2, (HEIGHT - image.height) // 2))
    return frame


def gray4(image: Image.Image) -> Image.Image:
    """Dither to device Gray4 indices: 0 white, 1 dark, 2 light, 3 black."""
    palette = Image.new("P", (1, 1))
    # Xteink's two middle grayscale values are intentionally reversed.
    palette.putpalette([255, 255, 255, 85, 85, 85, 170, 170, 170, 0, 0, 0] + [0] * 756)
    return image.quantize(palette=palette, dither=Image.Dither.FLOYDSTEINBERG)


def encode_xth(image: Image.Image) -> bytes:
    indexed = gray4(prepare(image))
    col_bytes = (HEIGHT + 7) // 8
    plane_size = WIDTH * col_bytes
    pixels = bytearray(plane_size * 2)
    data = indexed.load()
    for x in range(WIDTH):
        col = WIDTH - 1 - x  # XTH columns are stored right-to-left.
        for y in range(HEIGHT):
            level = data[x, y]
            offset = col * col_bytes + y // 8
            mask = 1 << (7 - y % 8)
            if level & 2:
                pixels[offset] |= mask
            if level & 1:
                pixels[plane_size + offset] |= mask
    # XTH\0, width, height, color mode, compression, data size, reserved checksum.
    header = struct.pack("<4sHHBBIQ", b"XTH\0", WIDTH, HEIGHT, 0, 0, len(pixels), 0)
    return header + pixels


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("input_dir", type=Path)
    parser.add_argument("output_dir", type=Path)
    args = parser.parse_args()
    args.output_dir.mkdir(parents=True, exist_ok=True)
    inputs = [p for p in sorted(args.input_dir.iterdir()) if p.suffix.lower() in {".png", ".jpg", ".jpeg", ".bmp", ".webp"}]
    if not inputs:
        raise SystemExit("No supported image files found.")
    for source in inputs:
        with Image.open(source) as image:
            destination = args.output_dir / f"{source.stem}.xth"
            destination.write_bytes(encode_xth(image))
            print(destination)


if __name__ == "__main__":
    main()
