#!/usr/bin/env python3
"""Set the Xteink stock wallpaper cache directly from a Pushed Images .xth frame.

Run only while the reader is in USB mode.  This preserves the exact four-level
e-ink bitmap: it does not pass the image through JPEG or the Ink App renderer.
"""

from __future__ import annotations

import argparse
import secrets
from pathlib import Path


WIDTH, HEIGHT = 480, 800
XTH_HEADER, XIC_HEADER = 22, 24
PLANE_BYTES = WIDTH * ((HEIGHT + 7) // 8)


def xth_to_xic(source: Path, cache_header: bytes) -> bytes:
    """Convert an XTH's column-major bitplanes to the stock XIC cache layout."""
    raw = source.read_bytes()
    if len(raw) != XTH_HEADER + PLANE_BYTES * 2 or raw[:4] != b"XTH\0":
        raise ValueError(f"{source.name} is not a 480x800 XTH frame")
    if int.from_bytes(raw[4:6], "little") != WIDTH or int.from_bytes(raw[6:8], "little") != HEIGHT:
        raise ValueError(f"{source.name} has unexpected dimensions")
    if len(cache_header) != XIC_HEADER or cache_header[:4] != b"XIC\0":
        raise ValueError("the existing native wallpaper cache is not an XIC frame")

    output = bytearray(PLANE_BYTES * 2)
    for plane in range(2):
        incoming = raw[XTH_HEADER + plane * PLANE_BYTES:XTH_HEADER + (plane + 1) * PLANE_BYTES]
        outgoing = memoryview(output)[plane * PLANE_BYTES:(plane + 1) * PLANE_BYTES]
        for x in range(WIDTH):
            # XTH stores columns right-to-left, eight vertical pixels per byte.
            column = (WIDTH - 1 - x) * 100
            out_byte, out_mask = x // 8, 0x80 >> (x % 8)
            for y in range(HEIGHT):
                if incoming[column + y // 8] & (0x80 >> (y % 8)):
                    outgoing[y * 60 + out_byte] |= out_mask
    return cache_header + output


def choose_frame(folder: Path, requested: str | None, state: Path) -> Path:
    frames = sorted(folder.glob("*.xth"))
    if not frames:
        raise ValueError(f"no .xth files found in {folder}")
    if requested:
        candidate = folder / requested
        if candidate not in frames:
            raise ValueError(f"{requested!r} is not an XTH frame in {folder}")
        return candidate
    previous = state.read_text().strip() if state.exists() else ""
    choices = [frame for frame in frames if frame.name != previous] or frames
    return secrets.choice(choices)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("sd_root", type=Path, help="mounted reader SD-card root")
    parser.add_argument("--frame", help="specific filename from Pushed Images; default chooses randomly")
    parser.add_argument("--dry-run", action="store_true", help="verify conversion without changing the cache")
    args = parser.parse_args()

    pushed = args.sd_root / "Pushed Images"
    cache_dir = args.sd_root / "XTCache" / "image" / "wallpaper"
    caches = sorted(cache_dir.glob("*.xic"))
    if len(caches) != 1:
        raise SystemExit(f"expected exactly one native wallpaper cache in {cache_dir}, found {len(caches)}")
    cache = caches[0]
    state = cache_dir / ".native-wallpaper-state"
    frame = choose_frame(pushed, args.frame, state)
    converted = xth_to_xic(frame, cache.read_bytes()[:XIC_HEADER])
    if args.dry_run:
        print(f"verified {frame.name} -> {cache.name} ({len(converted)} bytes)")
        return

    temporary = cache.with_suffix(".tmp")
    temporary.write_bytes(converted)
    temporary.replace(cache)
    state.write_text(frame.name + "\n")
    print(f"native wallpaper set from {frame.name}")


if __name__ == "__main__":
    main()
