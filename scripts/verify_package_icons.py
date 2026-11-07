#!/usr/bin/env python3
"""Check that an XTApp contains the exact native icon pixels from its source."""
import argparse
from pathlib import Path
import struct

from PIL import Image

from sync_game_ui import ROOT


def verify_icon(package, source):
    raw = package.read_bytes()
    assert len(raw) >= 128 and raw[:4] == b'XTAP', f'{package}: not an XTApp'
    assert struct.unpack_from('<I', raw, 8)[0] == len(raw), f'{package}: container length mismatch'
    offset, length = struct.unpack_from('<II', raw, 0x30)
    assert offset >= 128 and offset % 16 == 0 and length > 0 and offset + length <= len(raw), \
        f'{package}: missing or invalid icons section'
    section = raw[offset:offset + length]
    assert section[:4] == b'XTAB' and struct.unpack_from('<H', section, 4)[0] == 1
    count, table, data_start, total = struct.unpack_from('<IIII', section, 8)
    assert 1 <= count <= 8 and table == 64 and data_start == 64 + count * 40 and total == length
    icons = {}
    for index in range(count):
        entry = 64 + index * 40
        name = section[entry:entry + 24].split(b'\0')[0].decode('ascii')
        position, size, width, height, fmt = struct.unpack_from('<IIHHB', section, entry + 24)
        assert data_start + position + size <= len(section)
        assert name not in icons, f'{package}: duplicate icon entry'
        icons[name] = (section[data_start + position:data_start + position + size], width, height, fmt)
    assert 'app_icon_s' in icons, f'{package}: grid cannot find app_icon_s'
    image, width, height, fmt = icons['app_icon_s']
    assert (width, height, fmt) == (96, 96, 1), f'{package}: wrong icon dimensions or format'
    assert image[:4] == b'XIC\0' and struct.unpack_from('<HHBBB', image, 4) == (96, 96, 1, 1, 1)
    assert image[14:16] == b'\0\0', f'{package}: unexpected alpha mask'
    stride = (width + 7) // 8
    size = stride * height
    assert struct.unpack_from('<I', image, 16)[0] == size and len(image) == 24 + size
    decoded = bytearray([255]) * (width * height)
    for y in range(height):
        for x in range(width):
            if image[24 + y * stride + x // 8] & (128 >> (x % 8)):
                decoded[y * width + x] = 0
    with Image.open(source) as expected:
        assert expected.size == (96, 96) and expected.mode == '1'
        assert bytes(decoded) == expected.convert('L').tobytes(), f'{package}: flipped, missing or inverted icon pixels'
    print(f'{package.name}: native app_icon_s verified, all 9216 pixels match')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('packages', nargs='+', type=Path)
    args = parser.parse_args()
    for package in args.packages:
        verify_icon(package, ROOT / package.stem / 'app/icon.png')


if __name__ == '__main__':
    main()
