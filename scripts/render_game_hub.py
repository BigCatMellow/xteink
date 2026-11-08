#!/usr/bin/env python3
"""Render the actual collection menu and hosted games with shipped bitmap glyphs."""
from PIL import Image, ImageDraw, ImageFont
from render_nonogram import ROOT, FONT, render


def main():
    folder = ROOT / 'docs/design/games-hub'
    folder.mkdir(parents=True, exist_ok=True)
    fixtures = [(f'menu-{page}', '\n'.join("on_input(ctx,{type='pointer',phase='up',gesture='tap',x=390,y=730})" for _ in range(page-1))) for page in range(1,5)]
    fixtures += [('nonogram', 'assert(A.launch(10))\nA.state().engine.api.paint(1,1)'),
                 ('sudoku', 'assert(A.launch(13))')]
    sheet = Image.new('RGB', (3*504, 2*852), '#e9e9e9')
    for i, (name, setup) in enumerate(fixtures):
        fixture = 'dofile(SOURCE)\non_load(ctx)\nlocal A=__TEST.api\n' + setup
        check = "if BITMAP then local s=A.state();assert(s.selected==10 and s.engine.api.typefaces() or require('theme').state()) end"
        shot = render(ROOT/'games-hub/app/index.lua',1,name,bitmap=True,game='games-hub',fixture=fixture,bitmap_check=check)
        shot.save(folder/(name+'.png'))
        x,y=i%3*504+12,i//3*852+38
        sheet.paste(shot.convert('RGB'),(x,y))
        ImageDraw.Draw(sheet).text((x,y-29),name.replace('-',' ').title(),font=ImageFont.truetype(FONT,20),fill='black')
    sheet.save(folder/'overview.png')
    print(f'Games Hub actual bitmap host previews: {folder} (not device screenshots)')


if __name__ == '__main__':
    main()
