#!/usr/bin/env python3
"""Render the actual shell screens and hosted games with shipped bitmap glyphs."""
from PIL import Image, ImageDraw, ImageFont
from sync_game_ui import project_path
from render_nonogram import ROOT, FONT, render

READER = r'''
ctx.reader={}
function ctx.reader:current() return {title='Alice\226\128\153s Adventures in Wonderland',author='Lewis Carroll',percent=38} end
function ctx.reader:summary() return {streak_days=5,today_sec=1260} end
function ctx.reader:books()
  return {{title="Alice's Adventures in Wonderland",author='Lewis Carroll',percent=38},
    {title='Frankenstein',author='Mary Shelley',percent=0},{title='Pride and Prejudice',author='Jane Austen',finished=true},
    {title='The Time Machine',author='H. G. Wells',percent=12},{title='The Adventures of Sherlock Holmes',author='Arthur Conan Doyle'},
    {title='The Wonderful Wizard of Oz',author='L. Frank Baum'},{title='The Secret Garden',author='Frances Hodgson Burnett'}}
end
ctx.device={firmware='26110201'}
function ctx.device:battery() return {percent=82,charging=false} end
storage['hub.txt']='id=nonogram'
'''
LANDSCAPE = r'''
ctx.screen={width=480,height=800}
function ctx.screen:set_orientation(o)
  if o=='landscape' then self.width,self.height=800,480 else self.width,self.height=480,800 end
end
storage['shell.txt']='screen=home\norient=landscape\n'
'''


def main():
    folder = ROOT / 'docs/design/games-hub'
    folder.mkdir(parents=True, exist_ok=True)
    portrait, landscape = (480, 800), (800, 480)
    fixtures = [('home', READER, '', portrait), ('library', READER, "A.go('library')", portrait),
                ('games', READER, "A.go('games')", portrait), ('settings', READER, "A.go('settings')", portrait),
                ('home-landscape', READER + LANDSCAPE, '', landscape),
                ('library-landscape', READER + LANDSCAPE, "A.go('library')", landscape),
                ('games-landscape', READER + LANDSCAPE, "A.go('games')", landscape),
                ('settings-landscape', READER + LANDSCAPE, "A.go('settings')", landscape),
                ('nonogram', '', 'assert(A.launch(10))\nA.state().engine.api.paint(1,1)', portrait),
                ('sudoku', '', 'assert(A.launch(13))', portrait),
                ('crown-fields', '', 'assert(A.launch(14))', portrait), ('ten-pairs', '', 'assert(A.launch(15))', portrait),
                ('quiet-mines', '', 'assert(A.launch(16))', portrait), ('sum-cross', '', 'assert(A.launch(17))', portrait)]
    cell = 852
    sheet = Image.new('RGB', (3*cell-24, ((len(fixtures)+2)//3)*cell), '#e9e9e9')
    for i, (name, before, setup, canvas) in enumerate(fixtures):
        fixture = before + 'dofile(SOURCE)\non_load(ctx)\nlocal A=__TEST.api\n' + setup
        check = "if BITMAP then local s=A.state();assert(s.selected==10 and s.engine.api.typefaces() or require('theme').state()) end"
        shot = render(project_path('games-hub')/'app/index.lua', 1, name, bitmap=True, game='games-hub',
                      fixture=fixture, bitmap_check=check, canvas=canvas)
        shot.save(folder/(name+'.png'))
        x, y = i % 3*(cell-8)+12, i//3*cell+38
        sheet.paste(shot.convert('RGB'), (x, y))
        ImageDraw.Draw(sheet).text((x, y-29), name.replace('-', ' ').title(), font=ImageFont.truetype(FONT, 20), fill='black')
    sheet.save(folder/'overview.png')
    print(f'Games Hub actual bitmap host previews: {folder} (not device screenshots)')


if __name__ == '__main__':
    main()
