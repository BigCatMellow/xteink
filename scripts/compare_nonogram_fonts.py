#!/usr/bin/env python3
"""Compare actual Inter/Poppins in the Lua layout; this does not embed app fonts."""
import argparse
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

from render_nonogram import ROOT, FONT, render


def inter(path, size, weight):
    font = ImageFont.truetype(str(path), size)
    values = []
    for axis in font.get_variation_axes():
        value = weight if axis['name'] == b'Weight' else size
        values.append(max(axis['minimum'], min(axis['maximum'], value)))
    font.set_variation_by_axes(values)
    return font


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--fonts', type=Path, default=Path.home()/'.cache/xteink-font-review')
    parser.add_argument('--out', type=Path, default=ROOT/'nonogram/docs/design')
    args = parser.parse_args()
    args.out.mkdir(parents=True, exist_ok=True)
    ui = {size: inter(args.fonts/'Inter.ttf', size, 600 if size == 30 else 500)
          for size in (20, 24, 30)}
    friendly = {size: ImageFont.truetype(str(args.fonts/
                ('Poppins-SemiBold.ttf' if size == 30 else 'Poppins-Medium.ttf')), size)
                for size in (20, 24, 30)}
    mixed = {20: ui[20], 24: friendly[24], 30: friendly[30]}
    profiles = [('Inter', 'Inter throughout', ui),
                ('Poppins', 'Poppins throughout', friendly),
                ('Poppins + Inter', 'Poppins title/buttons, Inter clues', mixed)]
    sheet = Image.new('RGB', (1512, 1000), '#e9e9e9')
    pen = ImageDraw.Draw(sheet)
    title = ImageFont.truetype(FONT, 23)
    caption = ImageFont.truetype(FONT, 17)
    for i, (name, label, fonts) in enumerate(profiles):
        shot = render(ROOT/'nonogram/app/index.lua', 9, 'partial', fonts)
        shot.save(args.out/('font-'+name.lower().replace(' + ', '-').replace(' ', '-')+'.png'))
        x = i*504+12
        pen.text((x, 9), name, font=title, fill='black')
        pen.text((x, 39), label, font=caption, fill='black')
        sheet.paste(shot.convert('RGB'), (x, 70))
        specimen = Image.new('L', (480, 74), 255)
        specimen_pen = ImageDraw.Draw(specimen)
        specimen_pen.text((12, 8), '0123456789   1 2 1   3 3', font=fonts[20], fill=0,
                          anchor='lt', features=['-kern'])
        specimen_pen.text((12, 39), 'Check   Next   Undo   Reset', font=fonts[24], fill=0,
                          anchor='lt', features=['-kern'])
        specimen = specimen.point(lambda v: 0 if v < 128 else 255).convert('1')
        sheet.paste(specimen.convert('RGB'), (x, 882))
    pen.text((12, 971), 'Typography study: 1-bit host rendering. Custom fonts are not embedded in the current XTApp.',
             font=caption, fill='black')
    target = args.out/'font-comparison.png'
    sheet.save(target)
    print(target)


if __name__ == '__main__':
    main()
