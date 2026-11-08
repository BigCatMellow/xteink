#!/usr/bin/env python3
"""Render the actual themed Lua games with their packaged bitmap glyphs."""
import argparse
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

from render_nonogram import ROOT, FONT, render
from sync_game_ui import GAMES

FIXTURES={
 'line-lift': ('A.fresh(LEVEL,#A.raw)',12,'A.tap(415,40)'),
 'summit-putt': ('A.start(LEVEL,#A.levels)',10,'A.touch(420,32)'),
 'link-grid': ('A.start(LEVEL,#A.levels)',20,None),
 'ink-runes': ("A.start(LEVEL,#A.levels,'')",20,'A.tap(412,32)'),
 'lantern-logic': ('A.start(LEVEL,#A.levels)',16,None),
 'ray-vault': ('A.start(LEVEL,#A.levels)',12,'A.tap(420,32)'),
 'island-links': ('A.start(LEVEL,#A.levels)',12,None),
 'oddity-hunt': ('A.state().unlocked=#A.levels;A.visit(LEVEL);A.hint()',12,'A.tap(426,32)'),
 'word-hunt': ("local s=A.state();s.unlocked={999999999,999999999};if LEVEL>8 then A.mode(2) end;A.visit(LEVEL);A.hint()",15,'A.tap(440,32)'),
 'word-bridge': ('A.state().unlocked=#A.levels;A.visit(LEVEL);A.hint()',12,'A.tap(440,32)'),
 'rectangle-rooms': ('A.state().unlocked=#A.puzzles;A.visit(LEVEL)',12,'A.tap(440,32)'),
 'sudoku': ("if LEVEL>1 then A.new(3) end;local p=A.puzzle();for i=1,81 do if p.given[i]==0 then A.select((i-1)%9+1,math.floor((i-1)/9)+1);break end end;local b=A.controls.notes;A.tap(b[1]+b[3]/2,b[2]+b[4]/2);A.put(1);A.put(2);A.put(3)",2,'A.tap(448,36)'),
}


def shot(game,level,scene):
    if game=='nonogram':
        return render(ROOT/game/'app/index.lua',level,scene,bitmap=True)
    setup,_,help_action=FIXTURES[game]
    fixture='dofile(SOURCE)\non_load(ctx)\nlocal A=__TEST.api\n'+setup+'\n'
    if scene=='help' and help_action:
        fixture+=help_action+'\n'
    return render(ROOT/game/'app/index.lua',level,scene,bitmap=True,game=game,fixture=fixture)


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--out',type=Path,default=ROOT/'docs/design/game-family')
    parser.add_argument('--game',choices=GAMES)
    args=parser.parse_args()
    args.out.mkdir(parents=True,exist_ok=True)
    names=(args.game,) if args.game else GAMES
    label=ImageFont.truetype(FONT,20)
    for scene in ('first','dense','help'):
        shots=[]
        for game in names:
            level=1 if scene!='dense' else (15 if game=='nonogram' else FIXTURES[game][1])
            if scene=='help' and game!='nonogram' and not FIXTURES[game][2]:
                continue
            image=shot(game,level,'partial' if scene!='help' else 'help')
            image.save(args.out/f'{game}-{scene}.png')
            shots.append((game,image))
        columns=min(4,len(shots))
        rows=(len(shots)+columns-1)//columns
        sheet=Image.new('RGB',(columns*504,rows*852),'#e9e9e9')
        for i,(game,image) in enumerate(shots):
            x,y=i%columns*504+12,i//columns*852+38
            sheet.paste(image.convert('RGB'),(x,y))
            ImageDraw.Draw(sheet).text((x,y-29),game.replace('-',' ').title(),font=label,fill='black')
        sheet.save(args.out/f'{scene}-sheet.png')
    print(f'Actual game-family host previews: {args.out}')


if __name__=='__main__':
    main()
