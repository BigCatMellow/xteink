#!/usr/bin/env python3
"""Review actual Sudoku Lua/bitmap frames and pixel-check its 3x3 grid."""
from PIL import Image, ImageDraw, ImageFont
from render_nonogram import ROOT, FONT, render


def main():
    folder = ROOT/'docs/design/sudoku-2026-11-08'
    folder.mkdir(parents=True,exist_ok=True)
    select = 'local p=A.puzzle();local first;for i=1,81 do if p.given[i]==0 then first=i;break end end;A.select((first-1)%9+1,math.floor((first-1)/9)+1)\n'
    frames = {
        'normal': '',
        'notes': select+"local b=A.controls.notes;A.tap(b[1]+10,b[2]+10);A.put(1);A.put(2);A.put(3)",
        'entry': select+'A.put(p.solution[first])',
        'clash': select+"for _,i in ipairs(require('generator').peers[first]) do if p.given[i]>0 then A.put(p.given[i]);break end end;A.check()",
        'menu': 'local b=A.controls.new;A.tap(b[1]+10,b[2]+10)',
        'help': 'local b=A.controls.help;A.tap(b[1]+10,b[2]+10)',
        'solved': 'local p=A.puzzle();for i=1,81 do if p.given[i]==0 then A.select((i-1)%9+1,math.floor((i-1)/9)+1);A.put(p.solution[i]) end end;A.check()',
        'largest': 'A.state().level=999999999;A.state().unlocked=999999999',
    }
    shots = {}
    for name, setup in frames.items():
        fixture = 'dofile(SOURCE)\non_load(ctx)\nlocal A=__TEST.api\n'+setup
        shot = render(ROOT/'sudoku/app/index.lua',1,name,bitmap=True,game='sudoku',fixture=fixture)
        shot.save(folder/(name+'.png'))
        shots[name]=shot
    # The real raster output must have four solid pixels across each box bar.
    # Adjacent cell lines are only one pixel wide; typography is tested separately.
    plain=shots['normal']
    for offset in (162,318):
        for delta in range(-2,2):
            assert all(plain.getpixel((offset+delta,y))==0 for y in range(108,576))
    for offset in (264,420):
        for delta in range(-2,2):
            assert all(plain.getpixel((x,offset+delta))==0 for x in range(6,474))
    assert plain.getpixel((159,150))==255 and plain.getpixel((164,150))==255, 'box boundary must be exactly 4px, not a fat cell outline'
    assert plain.getpixel((57,150))==255 and plain.getpixel((58,150))==0 and plain.getpixel((59,150))==255, 'fine grid must be exactly 1px'
    font=ImageFont.truetype(FONT,20)
    sheet=Image.new('RGB',(4*504,2*852),'#e9e9e9')
    for i,(name,shot) in enumerate(shots.items()):
        x,y=i%4*504+12,i//4*852+38
        sheet.paste(shot.convert('RGB'),(x,y))
        ImageDraw.Draw(sheet).text((x,y-29),name.title(),font=font,fill='black')
    sheet.save(folder/'states.png')
    if (folder/'before.png').exists():
        compare=Image.new('RGB',(1008,852),'#e9e9e9')
        compare.paste(Image.open(folder/'before.png').convert('RGB'),(12,38))
        compare.paste(shots['notes'].convert('RGB'),(516,38))
        pen=ImageDraw.Draw(compare)
        pen.text((12,9),'Before / v0.2.0',font=font,fill='black')
        pen.text((516,9),'After / v0.3.0',font=font,fill='black')
        compare.save(folder/'before-after.png')
    if (folder/'icon-before.png').exists():
        icons=Image.new('RGB',(504,190),'#e9e9e9')
        pen=ImageDraw.Draw(icons)
        for i,(label,source) in enumerate((('Previous',folder/'icon-before.png'),('Updated',ROOT/'sudoku/app/icon.png'))):
            icon=Image.open(source).convert('L')
            icons.paste(icon.convert('RGB'),(i*252+18,42))
            small=icon.resize((64,64),Image.Resampling.LANCZOS).point(lambda value: 0 if value<128 else 255)
            icons.paste(small.convert('RGB'),(i*252+140,58))
            pen.text((i*252+18,12),label,font=font,fill='black')
            pen.text((i*252+18,152),'96px / 64px',font=font,fill='black')
        icons.save(folder/'icons.png')
    print('Sudoku actual bitmap previews and solid box-bar pixel checks PASS: '+str(folder))


if __name__ == '__main__':
    main()
