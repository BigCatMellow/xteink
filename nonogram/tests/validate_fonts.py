#!/usr/bin/env python3
"""Independently inspect font PNGs and compare glyph masks with source fonts."""
import hashlib
from io import BytesIO
import json
from pathlib import Path
import subprocess

from PIL import Image, ImageChops, ImageFont

ROOT = Path(__file__).resolve().parents[2]
FONT_ROOT = ROOT/'assets/fonts/game-ui'
report = json.loads((ROOT/'shared/font-metrics.json').read_text())
for name, digest in report['source_sha256'].items():
    assert hashlib.sha256((FONT_ROOT/name).read_bytes()).hexdigest() == digest

script = r"""
package.path='app/?.lua;'..package.path
local d=require('font_data')
for i,im in ipairs(d.images) do print('I\t'..i..'\t'..im[1]..'\t'..im[2]..'\t'..im[3]) end
for name,role in pairs(d.roles) do
  print('R\t'..name..'\t'..role.line_height)
  for char,glyph in pairs(role.glyphs) do print('G\t'..name..'\t'..char..'\t'..table.concat(glyph,'\t')) end
end
local license=require('font_license')
assert(license:find('SIL OPEN FONT LICENSE Version 1.1',1,true))
assert(license:find('Poppins',1,true) and license:find('Inter',1,true))
"""
output = subprocess.check_output(['lua', '-'], input=script, text=True, cwd=ROOT/'nonogram')
images, roles, glyphs = {}, {}, []
for record in output.splitlines():
    kind, *values = record.split('\t')
    if kind == 'I':
        index, width, height = map(int, values[:3])
        raw = bytes.fromhex(values[3])
        Image.open(BytesIO(raw)).verify()
        image = Image.open(BytesIO(raw))
        image.load()
        assert image.mode == '1' and image.size == (width, height)
        box = ImageChops.invert(image.convert('L')).getbbox()
        assert box == (0, 0, width, height), 'glyph PNG must be tight and nonblank'
        images[index] = image
    elif kind == 'R':
        roles[values[0]] = int(values[1])
    elif kind == 'G':
        glyphs.append((values[0], *map(int, values[1:])))
    else:
        raise AssertionError(kind)

assert len(images) == report['images'] <= 384
assert sum(im.width*im.height for im in images.values()) == report['decoded_pixels']
assert report['decoded_rgb_bytes'] == report['decoded_pixels']*3 <= 256*1024
assert len((ROOT/'shared/font_data.lua').read_bytes()) == report['lua_bytes'] < 128*1024

fonts = {}
for role, metadata in report['roles'].items():
    file = 'Inter.ttf' if metadata['name'] == 'Inter' else metadata['name']+'.ttf'
    font = ImageFont.truetype(str(FONT_ROOT/file), metadata['size'])
    features = ['-kern']
    if file == 'Inter.ttf':
        values = []
        for axis in font.get_variation_axes():
            value = metadata['weight'] if axis['name'] == b'Weight' else metadata['size']
            values.append(max(axis['minimum'], min(axis['maximum'], value)))
        font.set_variation_by_axes(values)
        features.append('tnum')
    fonts[role] = font, features
    assert roles[role] == metadata['line_height']

for role, code, advance, x, y, index in glyphs:
    assert advance > 0 and x >= 0 and y >= 0
    font, features = fonts[role]
    # getmask rasterizes independently of the exporter's baseline/canvas/crop.
    mask = font.getmask(chr(code), mode='L', features=features)
    if mask.size[0] and mask.size[1]:
        reference = Image.frombytes('L', mask.size, bytes(mask))
        reference = reference.point(lambda v: 0 if v >= 128 else 255).convert('1')
        box = ImageChops.invert(reference.convert('L')).getbbox()
    else:
        box = None
    if box is None:
        assert index == 0, 'whitespace needs an advance but no PNG'
    else:
        reference = reference.crop(box)
        packed = images[index]
        assert reference.size == packed.size and reference.tobytes() == packed.tobytes(), \
            f'{role}/{chr(code)}: font shape clipped, inverted or substituted'
        assert x+packed.width <= advance and y+packed.height <= roles[role], \
            f'{role}/{chr(code)}: ink outside measured bounds'
print(f'PASS: {len(glyphs)} glyph records match source-font masks; {len(images)} valid 1-bit PNGs, licenses and bounded cache verified')
