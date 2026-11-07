#!/usr/bin/env python3
"""Prepare maximum-quality grayscale JPEG comparisons without changing XTHs."""
import argparse
from io import BytesIO
from pathlib import Path
import struct

from PIL import Image, ImageChops

from sync_xth_png import decode_xth


def prefix(name):
    key = 0
    for value in name.encode('utf-8'):
        key = (key * 131 + value) % 8388593
    return f'wpj1-{key:06x}'


def verify(source, output):
    base = prefix(source.name)
    assert (output / f'{base}.idx').read_bytes() == source.read_bytes()
    expected = decode_xth(source).convert('L')
    with Image.open(output / f'{base}.jpg') as image:
        assert image.mode == 'L' and image.size == (480, 800) and image.format == 'JPEG'
        assert not image.info.get('progressive')
        # Unit quantization tables establish quality 100 for this encoder.
        assert all(value == 1 for table in image.quantization.values() for value in table)
        actual = image.copy()
    maximum = ImageChops.difference(expected, actual).getextrema()[1]
    a, b = expected.tobytes(), actual.tobytes()
    floor_diff = sum(x // 16 != y // 16 for x, y in zip(a, b))
    nearest_diff = sum(round(x / 17) != round(y / 17) for x, y in zip(a, b))
    return maximum, floor_diff, nearest_diff


def prepare(source, output):
    raw = source.read_bytes()
    if len(raw) != 96022 or raw[:4] != b'XTH\0' or struct.unpack_from('<HHBBI', raw, 4) != (480, 800, 0, 0, 96000):
        raise ValueError(f'{source.name}: unsupported XTH format')
    image = decode_xth(source).convert('L')
    encoded = BytesIO()
    # No resizing, contrast adjustment, dithering or color conversion to RGB.
    image.save(encoded, format='JPEG', quality=100, optimize=True, progressive=False)
    output.mkdir(parents=True, exist_ok=True)
    base = prefix(source.name)
    marker = output / f'{base}.idx'
    marker.unlink(missing_ok=True)
    temporary = output / f'{base}.tmp'
    temporary.write_bytes(encoded.getvalue())
    temporary.replace(output / f'{base}.jpg')
    temporary.write_bytes(raw)
    temporary.replace(marker)
    return verify(source, output)


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
        parser.error('cache name collision; rename one source')
    for source in frames:
        maximum, floor_diff, nearest_diff = (verify if args.check else prepare)(source, args.output_dir or files)
        print(f'{source.name}: max error {maximum}/255; 4-bit differences floor={floor_diff}, nearest={nearest_diff}')
    print(f'{len(frames)} maximum-quality JPEGs verified; XTH originals unchanged')


if __name__ == '__main__':
    main()
