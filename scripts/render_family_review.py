#!/usr/bin/env python3
"""Compare actual first frames/icons with a preserved Git baseline."""
import argparse
from io import BytesIO
import json
from pathlib import Path
import subprocess
import tempfile

from PIL import Image,ImageDraw,ImageFont
from render_nonogram import ROOT,FONT,render
from render_games import FIXTURES,shot
from sync_game_ui import GAMES, project_path
from make_icons import APPS,contact_sheet


def git(ref,path):
    return subprocess.check_output(['git','show',ref+':'+path],cwd=ROOT)


def baseline_project(ref, name):
    """Resolve either historical flat layout or the current games layout."""
    candidates = ['games/' + name, name] if name in GAMES or name == 'games-hub' else [name]
    for candidate in candidates:
        result = subprocess.run(['git', 'cat-file', '-e', ref + ':' + candidate + '/app/manifest.json'],
                                cwd=ROOT, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        if result.returncode == 0:
            return candidate
    raise ValueError('No project in baseline: ' + name)


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--baseline-ref',default='db9c26b')
    parser.add_argument('--out',type=Path,default=ROOT/'docs/design/full-rollout-2026-11-08')
    args=parser.parse_args();args.out.mkdir(parents=True,exist_ok=True)
    label=ImageFont.truetype(FONT,20)
    sheet=Image.new('RGB',(4*504,((len(GAMES)+3)//4)*452),'#e9e9e9')
    links=[]
    with tempfile.TemporaryDirectory(prefix='xteink-review-baseline-') as temp:
        for i,game in enumerate(GAMES):
            baseline=baseline_project(args.baseline_ref,game)
            paths=subprocess.check_output(['git','ls-tree','-r','--name-only',args.baseline_ref,baseline+'/app'],cwd=ROOT,text=True).splitlines()
            for name in paths:
                target=Path(temp)/game/Path(name).relative_to(baseline);target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(git(args.baseline_ref,name))
            folder=Path(temp)/game
            bitmap=(folder/'app/font_data.lua').exists()
            fixture=None if game=='nonogram' else 'dofile(SOURCE)\non_load(ctx)\nlocal A=__TEST.api\n'+FIXTURES[game][0]
            before=render(folder/'app/index.lua',1,'partial',bitmap=bitmap,game=folder,fixture=fixture)
            after=shot(game,1,'first')
            old=json.loads((folder/'app/manifest.json').read_text())['version']
            current=json.loads((project_path(game) /'app/manifest.json').read_text())['version']
            compare=Image.new('RGB',(1008,852),'#e9e9e9')
            compare.paste(before.convert('RGB'),(12,38));compare.paste(after.convert('RGB'),(516,38))
            pen=ImageDraw.Draw(compare)
            pen.text((12,9),'Before '+old+(' / native font stand-in' if not bitmap else ''),font=label,fill='black')
            pen.text((516,9),'After '+current,font=label,fill='black')
            compare.save(args.out/(game+'.png'))
            x,y=i%4*504,i//4*452
            sheet.paste(compare.resize((504,426),Image.Resampling.LANCZOS),(x,y+26))
            ImageDraw.Draw(sheet).text((x+12,y+3),game.replace('-',' ').title(),font=label,fill='black')
            links.append(f'| {game.replace("-"," ").title()} | {old} → {current} | [Before / after]({game}.png) |')
    sheet.save(args.out/'all-games.png')
    previous={}
    current={}
    for game in APPS:
        previous[game]=Image.open(BytesIO(git(args.baseline_ref,baseline_project(args.baseline_ref,game)+'/app/icon.png'))).copy()
        current[game]=Image.open(project_path(game) /'app/icon.png').copy()
    contact_sheet(previous,args.out/'icons-before.png');contact_sheet(current,args.out/'icons-after.png')
    report='# Full game-family visual review\n\n'
    report+='All frames replay actual Lua drawing commands. Current frames use the shipped bitmap glyphs. The four newly imported games had native fonts at the baseline, so their before frames use a labeled host-font stand-in. These are host previews, not reader photographs. All fixtures use fresh mock saves.\n\n'
    report+='Baseline Git commit: `'+args.baseline_ref+'`. Reproduce with `python3 scripts/render_family_review.py --baseline-ref '+args.baseline_ref+'`.\n\n'
    report+='[All games](all-games.png) · [Previous icons](icons-before.png) · [Updated icons](icons-after.png)\n\n'
    report+='| Game | Version | Review |\n| --- | --- | --- |\n'+'\n'.join(links)+'\n'
    (args.out/'README.md').write_text(report)
    print('Complete '+str(len(GAMES))+'-game comparison: '+str(args.out))


if __name__=='__main__':
    main()
