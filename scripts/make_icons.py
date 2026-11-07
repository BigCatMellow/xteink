#!/usr/bin/env python3
"""Rasterize the repository's vector icons into native 96px 1-bit app icons.

Uses only Pillow. The supported SVG subset is deliberately small: rect, circle,
polyline, polygon, and absolute M/L/H/V paths. Unknown elements fail the build.
Run --check to compare pixels without writing; --sheet writes a review contact
sheet at 96px and 64px. Artwork remains editable as SVG in assets/icons/.
"""
import argparse
from io import BytesIO
from pathlib import Path
import re
import xml.etree.ElementTree as ET

from PIL import Image, ImageDraw, ImageFont, ImageOps

from sync_game_ui import GAMES, ROOT

APPS = (*GAMES, 'wallpaper-randomizer')
SIZE, SCALE = 96, 4


def path_lines(value):
    tokens = re.findall(r'[A-Za-z]|-?\d+(?:\.\d+)?', value)
    lines, points = [], []
    index, x, y, command = 0, 0, 0, None
    while index < len(tokens):
        if tokens[index].isalpha():
            command = tokens[index]
            index += 1
        if command not in ('M', 'L', 'H', 'V'):
            raise ValueError(f'unsupported SVG path command {command}')
        if command in ('M', 'L'):
            x, y = map(float, tokens[index:index + 2])
            index += 2
            if command == 'M':
                if points:
                    lines.append(points)
                points = []
                command = 'L'
        elif command == 'H':
            x = float(tokens[index])
            index += 1
        else:
            y = float(tokens[index])
            index += 1
        points.append((x, y))
    if points:
        lines.append(points)
    return lines


def render(source):
    svg = ET.parse(source).getroot()
    assert svg.get('viewBox') == '0 0 96 96', source
    canvas = Image.new('L', (SIZE * SCALE, SIZE * SCALE), 255)
    pen = ImageDraw.Draw(canvas)

    def color(value):
        if value == 'none':
            return None
        if value in ('black', '#000', '#000000'):
            return 0
        if value in ('white', '#fff', '#ffffff'):
            return 255
        raise ValueError(f'icons must be black and white: {value}')

    for shape in svg:
        kind = shape.tag.split('}')[-1]
        stroke = color(shape.get('stroke', svg.get('stroke', 'black')))
        fill = color(shape.get('fill', svg.get('fill', 'none')))
        width = max(1, round(float(shape.get('stroke-width', svg.get('stroke-width', '3'))) * SCALE))
        def number(key, default='0'):
            return float(shape.get(key, default)) * SCALE
        if kind == 'circle':
            x, y, r = number('cx'), number('cy'), number('r')
            # SVG strokes are centered on the contour; Pillow draws inward.
            if stroke is not None:
                half = width / 2
                pen.ellipse((x-r-half, y-r-half, x+r+half, y+r+half), fill=stroke)
                pen.ellipse((x-r+half, y-r+half, x+r-half, y+r-half), fill=fill if fill is not None else 255)
            elif fill is not None:
                pen.ellipse((x-r, y-r, x+r, y+r), fill=fill)
        elif kind == 'rect':
            x, y, w, h = number('x'), number('y'), number('width'), number('height')
            radius = number('rx')
            pen.rounded_rectangle((x, y, x+w, y+h), radius=radius, fill=fill, outline=stroke, width=width)
        elif kind in ('polyline', 'polygon', 'path'):
            if kind == 'path':
                paths = path_lines(shape.get('d'))
            else:
                values = list(map(float, re.findall(r'-?\d+(?:\.\d+)?', shape.get('points'))))
                paths = [list(zip(values[::2], values[1::2]))]
            for points in paths:
                scaled = [(x*SCALE, y*SCALE) for x, y in points]
                if kind == 'polygon':
                    pen.polygon(scaled, fill=fill)
                    scaled.append(scaled[0])
                if stroke is not None:
                    pen.line(scaled, fill=stroke, width=width, joint='curve')
                    if shape.get('stroke-linecap', svg.get('stroke-linecap')) == 'round':
                        half = width / 2
                        for x, y in (scaled[0], scaled[-1]):
                            pen.ellipse((x-half, y-half, x+half, y+half), fill=stroke)
        else:
            raise ValueError(f'unsupported SVG element {kind} in {source}')
    return canvas.resize((SIZE, SIZE), Image.Resampling.LANCZOS).point(lambda v: 0 if v < 128 else 255).convert('1')


def validate(image, name):
    assert image.mode == '1' and image.size == (SIZE, SIZE), f'{name}: expected 96x96 1-bit PNG'
    ink = ImageOps.invert(image.convert('L'))
    box = ink.getbbox()
    assert box and min(box[:2]) >= 6 and max(box[2:]) <= 90, f'{name}: ink reaches clipped margins: {box}'
    black = image.histogram()[0]
    assert 0.025 < black/(SIZE*SIZE) < 0.55, f'{name}: empty or overly dense icon'


def contact_sheet(images, destination):
    sheet = Image.new('RGB', (800, 380), 'white')
    pen = ImageDraw.Draw(sheet)
    try:
        font = ImageFont.truetype('DejaVuSans.ttf', 14)
    except OSError:
        font = ImageFont.load_default()
    for i, (app, image) in enumerate(images.items()):
        x, y = (i % 4) * 200, (i // 4) * 190
        sheet.paste(image.convert('RGB'), (x+16, y+16))
        small = image.resize((64, 64), Image.Resampling.LANCZOS).point(lambda v: 0 if v < 128 else 255)
        sheet.paste(small.convert('RGB'), (x+120, y+32))
        title = app.replace('-', ' ').title()
        if app == 'wallpaper-randomizer':
            title = 'Wallpaper Randomizer'
        pen.text((x+100, y+130), title, fill='black', font=font, anchor='mt')
        pen.text((x+100, y+154), '96px / 64px', fill='black', font=font, anchor='mt')
    destination.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(destination)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true')
    parser.add_argument('--sheet', type=Path)
    args = parser.parse_args()
    images, signatures = {}, set()
    for app in APPS:
        expected = render(ROOT / 'assets/icons' / f'{app}.svg')
        validate(expected, app)
        assert expected.tobytes() not in signatures, f'{app}: duplicates another icon'
        signatures.add(expected.tobytes())
        target = ROOT / app / 'app/icon.png'
        if args.check:
            with Image.open(target) as actual:
                validate(actual, app)
                assert actual.tobytes() == expected.tobytes(), f'{app}: regenerate icon from SVG'
        else:
            expected.save(target, optimize=True)
        images[app] = expected
    if args.sheet:
        contact_sheet(images, args.sheet)
    print(f'{len(images)} unique 96px monochrome app icons ' + ('verified' if args.check else 'generated'))


if __name__ == '__main__':
    main()
