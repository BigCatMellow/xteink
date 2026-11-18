#!/usr/bin/env python3
"""Render Sudoku's actual Lua frames with shipped glyphs, before and after pilot.

This uses the desktop host renderer, NOT a physical e-ink screen capture.
"""
import argparse
import json
from pathlib import Path
import subprocess
import tempfile

from PIL import Image, ImageDraw, ImageFont
from render_nonogram import FONT, ROOT, render
from sync_game_ui import project_path

BASELINE = "bd733d1b17c70e0745886a1c7b6a0f08e5574197"
APP = project_path("sudoku") / "app/index.lua"
SCENES = {
    "first": "",
    "notes": """
local p=A.puzzle()
for i=1,81 do
 if p.given[i]==0 then
  A.select((i-1)%9+1,math.floor((i-1)/9)+1);break
 end
end
local b=A.controls.notes;A.tap(b[1]+b[3]/2,b[2]+b[4]/2)
A.put(1);A.put(2);A.put(3)
""",
    "feedback": "A.check()",
    "solved": """
local p=A.puzzle()
for i=1,81 do
 if p.given[i]==0 then
  A.select((i-1)%9+1,math.floor((i-1)/9)+1)
  A.put(p.solution[i])
 end
end
A.check()
""",
    "menu": "local b=A.controls.new;A.tap(b[1]+b[3]/2,b[2]+b[4]/2)",
    "help": "local b=A.controls.help;A.tap(b[1]+b[3]/2,b[2]+b[4]/2)",
}


def geometry(text):
    import re
    board = re.search(r"local BOARD=\{x=(\d+),y=(\d+),cell=(\d+),size=(\d+)\}", text)
    keys = re.search(
        r"return 156\+\(n-1\)%3\*106,(\d+)\+math.floor\(\(n-1\)/3\)\*(\d+),98,(\d+)",
        text,
    )
    if not board or not keys:
        raise AssertionError("Sudoku geometry changed: update screenshot measurements")
    x, y, cell, size = map(int, board.groups())
    start, step, height = map(int, keys.groups())
    return {
        "board": [x, y, size, size],
        "cell": cell,
        "number_key": [98, height],
        "number_key_start": start,
        "number_key_step": step,
        "numeric_touch_area": 9 * 98 * height,
    }


def capture(source, scene):
    fixture = """dofile(SOURCE)
on_load(ctx)
local A=__TEST.api
-- Both generations display the same historical board for a fair visual diff.
local G=require('generator')
local Store=require('puzzle_store')
local p=G.generate(1,2)
local zero={}
for i=1,81 do zero[i]=0 end
local data=table.concat({'version=1','difficulty=2',
 'board='..table.concat(p.given),'notes='..table.concat(zero,','),
 'history=','selected=0','noteMode=0','submitted=0'},'\\n')
Store.put(ctx.storage,'sudoku',1,data)
Store.write(ctx.storage,'sudoku.txt','version=1\\nlevel=1\\nunlocked=1')
on_load(ctx)
""" + SCENES[scene]
    return render(source, 1, scene, bitmap=True, game="sudoku", fixture=fixture)


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--out", type=Path, default=ROOT / "dist/sudoku-screen-space")
    args = p.parse_args()
    args.out.mkdir(parents=True, exist_ok=True)
    old_source = subprocess.check_output(
        ["git", "show", f"{BASELINE}:games/sudoku/app/index.lua"], cwd=ROOT
    )
    new_source = APP.read_text()
    before, after = geometry(old_source.decode("utf-8")), geometry(new_source)
    assert before["board"][2] == after["board"][2] == 468
    assert before["numeric_touch_area"] == after["numeric_touch_area"]
    assert before["board"] == after["board"]
    with tempfile.TemporaryDirectory(prefix="xteink-sudoku-") as temp:
        baseline = Path(temp) / "sudoku-before.lua"
        baseline.write_bytes(old_source)
        sheet = Image.new("RGB", (1008, len(SCENES) * 844), "#ededed")
        pen = ImageDraw.Draw(sheet)
        font = ImageFont.truetype(FONT, 18)
        for i, scene in enumerate(SCENES):
            first = capture(baseline, scene)
            last = capture(APP, scene)
            if scene in {"first", "notes", "feedback", "solved"}:
                # The board retains identical geometry, but thicker rules
                # and vector pencil numerals intentionally change its ink.
                before_board = first.crop((6, 100, 474, 568))
                after_board = last.crop((6, 100, 474, 568))
                assert before_board.tobytes() != after_board.tobytes(), (
                    f"{scene}: expected a visually distinct Sudoku style"
                )
            first.save(args.out / f"{scene}-before.png")
            last.save(args.out / f"{scene}-after.png")
            top = i * 844
            sheet.paste(first.convert("RGB"), (8, top + 32))
            sheet.paste(last.convert("RGB"), (512, top + 32))
            pen.text((8, top + 7), f"{scene}: before 0.3.3", font=font, fill=0)
            pen.text((512, top + 7), f"{scene}: after 0.4.0", font=font, fill=0)
        sheet.save(args.out / "before-after.png")
    (args.out / "metrics.json").write_text(
        json.dumps({"baseline": BASELINE, "before": before, "after": after}, indent=2) + "\n"
    )
    print("Baseline:", before)
    print("Updated :", after)
    print("Bitmap-host screenshot and measurement comparison:", args.out)


if __name__ == "__main__":
    main()
