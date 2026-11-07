#!/usr/bin/env python3
"""Prepare persistent lossless preview caches while the reader is connected.

Reads XTHs already in XTApps/wallrandom/files. --output-dir can stage the cache
elsewhere for inspection; --check verifies existing caches without writing.
"""
import argparse
from io import BytesIO
from pathlib import Path
import struct

from PIL import Image

from sync_xth_png import decode_xth


def prefix(name):
    key = 0
    for value in name.encode('utf-8'):
        key = (key * 131 + value) % 8388593
    return f'wpc1-32-{key:06x}'


def bundle(image, group):
    entries = []
    for part in range(5):
        y = group * 160 + part * 32
        output = BytesIO()
        image.crop((0, y, 480, y + 32)).save(output, format='PNG', optimize=True)
        entries.append(output.getvalue())
    return (b'WPC1' + struct.pack('<HHHHH', 480, 800, 32, group, 5)
            + struct.pack('<5I', *(len(entry) for entry in entries)) + b''.join(entries))


def unpack_group(data, expected_group):
    if len(data) < 34 or data[:4] != b'WPC1':
        raise ValueError('invalid cache header')
    if struct.unpack_from('<5H', data, 4) != (480, 800, 32, expected_group, 5):
        raise ValueError('invalid cache dimensions/index')
    lengths = struct.unpack_from('<5I', data, 14)
    offset = 34
    entries = []
    for length in lengths:
        if not 57 <= length <= 20000 or offset + length > len(data):
            raise ValueError('invalid cache entry length')
        entries.append(data[offset:offset + length])
        offset += length
    if offset != len(data):
        raise ValueError('trailing cache bytes')
    return entries


def check_cache(source, output):
    raw = source.read_bytes()
    base = prefix(source.name)
    if (output / f'{base}.idx').read_bytes() != raw:
        raise ValueError(f'{source.name}: cache source marker differs')
    expected = decode_xth(source).convert('L')
    for group in range(5):
        entries = unpack_group((output / f'{base}-{group}.bin').read_bytes(), group)
        for part, entry in enumerate(entries):
            with Image.open(BytesIO(entry)) as strip:
                assert strip.size == (480, 32) and strip.mode == 'L'
                y = group * 160 + part * 32
                assert strip.tobytes() == expected.crop((0, y, 480, y + 32)).tobytes()


def prepare(source, output):
    raw = source.read_bytes()
    if len(raw) != 96022 or raw[:4] != b'XTH\0' or struct.unpack_from('<HHBBI', raw, 4) != (480, 800, 0, 0, 96000):
        raise ValueError(f'{source.name}: unsupported XTH format')
    image = decode_xth(source).convert('L')
    base = prefix(source.name)
    output.mkdir(parents=True, exist_ok=True)
    marker = output / f'{base}.idx'
    # Only invalidate our derived cache marker. Source XTHs are never changed.
    marker.unlink(missing_ok=True)
    for group in range(5):
        destination = output / f'{base}-{group}.bin'
        temporary = output / f'{base}-{group}.tmp'
        temporary.write_bytes(bundle(image, group))
        temporary.replace(destination)
    temporary = output / f'{base}.tmp'
    temporary.write_bytes(raw)
    temporary.replace(marker)
    check_cache(source, output)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('sd_root', type=Path)
    parser.add_argument('--output-dir', type=Path)
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    files = args.sd_root / 'XTApps/wallrandom/files'
    frames = sorted(path for path in files.iterdir() if path.suffix.lower() == '.xth')
    if not frames:
        parser.error(f'no XTH files in {files}')
    if len({prefix(frame.name) for frame in frames}) != len(frames):
        parser.error('cache name collision; rename one source before preparing')
    output = args.output_dir or files
    for source in frames:
        (check_cache if args.check else prepare)(source, output)
        print(f'{source.name}: cache ' + ('verified' if args.check else 'prepared and verified'))
    print(f'{len(frames)} images, {len(frames)*6} bounded cache files; XTH originals unchanged')


if __name__ == '__main__':
    main()
