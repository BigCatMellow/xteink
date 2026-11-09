#!/usr/bin/env python3
"""Render real Nonogram draw commands with a host font, not firmware emulation.

Pillow supplies measured DejaVu Sans glyph widths to the Lua app. Geometry,
labels and states come from on_draw itself. Native font/corner rendering and
physical e-ink refresh behavior still require the reader.
"""
import argparse
from io import BytesIO
import json
from pathlib import Path
from sync_game_ui import project_path
import subprocess

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
FONT = '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'

HARNESS = r'''
package.path='app/?.lua;'..TEST_ROOT..'/?.lua;'..package.path
__TEST={}
local storage={}
local fonts={}
for name,size in pairs({small=20,medium=24,large=30}) do
  local f={line_height=size}
  function f:measure(s)
    local width=0
    for i=1,#s do width=width+(METRICS[size][s:byte(i)] or size*.55) end
    return math.ceil(width)
  end
  fonts[name]=f
end
local ctx={fonts=fonts,
  storage={read=function(_,n) return storage[n] end,write=function(_,n,v) storage[n]=v end},
  invalidate=function() end}
if BITMAP then
  ctx.image={decode=function(_,raw)
    local function u32(i)
      local a,b,c,d=raw:byte(i,i+3);return ((a*256+b)*256+c)*256+d
    end
    local im={width=u32(17),height=u32(21),raw=raw}
    function im:release() self.released=true end
    return im
  end}
end
dofile(SOURCE)
on_load(ctx)
local A=__TEST.api
local s=A.state()
s.unlocked=999999999
A.visit(LEVEL)
local p=A.shape(LEVEL)
if SCENE~='blank' then
  for y=1,p.n do for x=1,p.n do
    local value=0
    if SCENE=='solved' or y<=math.floor(p.n/2) then
      value=p.rows[y]:sub(x,x)=='#' and 1 or (SCENE=='solved' and 0 or 2)
    elseif (x+y*3)%11==0 then value=2 end
    for i=1,value do A.paint(x,y) end
  end end
end
if SCENE=='solved' then A.check() end
if SCENE=='help' then A.tap(443,34) end
if SCENE=='wrong' then A.check() end
local function emit(kind,...)
  local values={kind}
  for _,v in ipairs({...}) do values[#values+1]=tostring(v) end
  print(table.concat(values,'\t'))
end
local g={}
function g:clear() emit('clear') end
function g:rect(x,y,w,h,o)
  o=o or {};emit('rect',x,y,w,h,o.line_width or 1,o.fill and 1 or 0,o.radius or 0)
end
function g:line(x,y,xx,yy,o) emit('line',x,y,xx,yy,(o or {}).line_width or 1) end
function g:circle(x,y,r,o) o=o or {};emit('circle',x,y,r,o.line_width or 1,o.fill and 1 or 0) end
function g:text(x,y,s,o) emit('text',x,y,o.font.line_height,s) end
if BITMAP then
  function g:image(im,x,y)
    assert(not im.released)
    local hex=im.raw:gsub('.',function(c) return string.format('%02x',c:byte()) end)
    emit('image',x,y,hex)
  end
end
on_draw(ctx,g)
if BITMAP then assert(A.typefaces(),'bitmap fonts unexpectedly fell back') end
'''


def render(source, level, scene, fonts=None, bitmap=False, game='nonogram', fixture=None, bitmap_check=None, canvas=(480, 800)):
    fonts = fonts or {size: ImageFont.truetype(FONT, size) for size in (20, 24, 30)}
    tables = []
    for size, font in fonts.items():
        glyphs = ','.join(f'[{code}]={font.getlength(chr(code), features=["-kern"]):.5f}'
                          for code in range(32, 127))
        tables.append(f'[{size}]={{{glyphs}}}')
    setup = 'METRICS={' + ','.join(tables) + '}\n'
    setup += f'TEST_ROOT={json.dumps(str(ROOT / "tests"))}\n'
    setup += f'SOURCE={json.dumps(str(source))}\nLEVEL={level}\nSCENE={json.dumps(scene)}\nBITMAP={str(bitmap).lower()}\n'
    program=HARNESS
    if fixture is not None:
        start=program.index('dofile(SOURCE)')
        end=program.index('local function emit',start)
        program=program[:start]+fixture+'\n'+program[end:]
        program=program.replace("if BITMAP then assert(A.typefaces(),'bitmap fonts unexpectedly fell back') end",
          bitmap_check or "if BITMAP then assert(require('theme').state(),'bitmap theme unexpectedly fell back') end")
    output = subprocess.check_output(['lua', '-'], input=setup + program, text=True,
                                     cwd=Path(game) if Path(game).is_absolute() else project_path(game))
    image = Image.new('L', canvas, 255)
    draw = ImageDraw.Draw(image)
    for record in output.splitlines():
        kind, *values = record.split('\t')
        if kind == 'clear':
            draw.rectangle((0, 0, canvas[0]-1, canvas[1]-1), fill=255)
        elif kind == 'text':
            x, y, size = map(float, values[:3])
            label = values[3]
            assert 'ERROR' not in label, label
            draw.text((round(x), round(y)), label, font=fonts[int(size)], fill=0,
                      anchor='lt', features=['-kern'])
        elif kind == 'rect':
            x, y, w, h, width, filled, radius = map(float, values)
            # Pillow includes its far endpoint. A filled w×h canvas command
            # must occupy exactly w×h pixels, especially 1px/4px grid bars.
            edge = 1 if filled else 0
            draw.rounded_rectangle((round(x), round(y), round(x+w-edge), round(y+h-edge)),
                                   radius=round(radius), fill=0 if filled else None,
                                   outline=0, width=round(width))
        elif kind == 'line':
            x, y, xx, yy, width = map(float, values)
            draw.line((round(x), round(y), round(xx), round(yy)), fill=0, width=round(width))
        elif kind == 'circle':
            x, y, r, width, filled = map(float, values)
            draw.ellipse((round(x-r), round(y-r), round(x+r), round(y+r)),
                         outline=0, fill=0 if filled else None, width=round(width))
        elif kind == 'image':
            x, y = map(float, values[:2])
            glyph = Image.open(BytesIO(bytes.fromhex(values[2]))).convert('L')
            image.paste(glyph, (round(x), round(y)))
        else:
            raise AssertionError(f'Unsupported draw command {kind}')
    return image.point(lambda value: 0 if value < 128 else 255).convert('1')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--baseline', type=Path)
    parser.add_argument('--bitmap', action='store_true', help='Use the packaged font glyphs')
    parser.add_argument('--out', type=Path, default=project_path('nonogram') / 'docs/design')
    args = parser.parse_args()
    args.out.mkdir(parents=True, exist_ok=True)
    source = project_path('nonogram') / 'app/index.lua'
    scenes = [('5x5', 1, 'partial'), ('7x7', 5, 'partial'), ('8x8', 9, 'partial'),
              ('generated', 15, 'partial'), ('solved', 9, 'solved'),
              ('help', 1, 'help'), ('wrong', 9, 'wrong')]
    previews = []
    for name, level, scene in scenes:
        shot = render(source, level, scene, bitmap=args.bitmap)
        shot.save(args.out / f'{name}.png')
        previews.append((name, shot))
    label_font = ImageFont.truetype(FONT, 20)
    sheet = Image.new('RGB', (4*504, 2*852), '#e9e9e9')
    for index, (name, shot) in enumerate(previews):
        x, y = index % 4 * 504 + 12, index // 4 * 852 + 38
        sheet.paste(shot.convert('RGB'), (x, y))
        ImageDraw.Draw(sheet).text((x, y-29), name, font=label_font, fill='black')
    sheet.save(args.out / 'states.png')
    if args.baseline:
        before = render(args.baseline.resolve(), 9, 'partial')
        before.save(args.out / 'before.png')
        compare = Image.new('RGB', (1008, 852), '#e9e9e9')
        compare.paste(before.convert('RGB'), (12, 38))
        compare.paste(previews[2][1].convert('RGB'), (516, 38))
        pen = ImageDraw.Draw(compare)
        pen.text((12, 9), 'Before / v0.2.0', font=label_font, fill='black')
        pen.text((516, 9), 'After / v0.4.0' if args.bitmap else 'After / v0.3.0', font=label_font, fill='black')
        compare.save(args.out / 'before-after.png')
    if args.bitmap:
        compare = Image.new('RGB', (1008, 852), '#e9e9e9')
        compare.paste(render(source, 9, 'partial').convert('RGB'), (12, 38))
        compare.paste(previews[2][1].convert('RGB'), (516, 38))
        pen = ImageDraw.Draw(compare)
        pen.text((12, 9), 'Native layout / desktop font stand-in', font=label_font, fill='black')
        pen.text((516, 9), 'Packaged Poppins + Inter glyphs', font=label_font, fill='black')
        compare.save(args.out / 'native-vs-bitmap.png')
    print(f'Nonogram host previews: {args.out} (packaged glyphs={args.bitmap}; not device screenshots)')


if __name__ == '__main__':
    main()
