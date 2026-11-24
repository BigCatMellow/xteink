#!/usr/bin/env python3
"""Block UI drift between native Lua and the interactive HTML preview."""
from pathlib import Path
import re

root = Path(__file__).resolve().parents[1]
lua = (root / 'app/index.lua').read_text()
html = (root / 'preview.html').read_text()
def extract(pat, source):
    m = re.search(pat, source, re.S)
    assert m, pat
    return m.group(1).strip().splitlines()

a = extract(r'local RAW\s*=\s*\[=\[(.*?)\]=\]', lua)
b = extract(r'const RAW\s*=\s*`(.*?)`;', html)
assert a == b, 'Book order, titles, paths and notes must match: run tools/build_catalog.py --write'
assert len(a) == 211
assert re.search(r"local V1_KEYS=\{(.*?)\}", lua).group(1).replace('[', '').replace(']', '').replace('=', ':') == \
    re.search(r"const V1_KEYS=\{(.*?)\}", html).group(1), 'v1 save migration table drifted'
assert re.search(r"local CARD_DATE='([^']*)'", lua).group(1) == re.search(r"const CARD_DATE='([^']*)'", html).group(1)
assert '<canvas id="screen" width="480" height="800"' in html
pairs = [
("local y=86+(slot-1)*91", "const y=86+slot*91"),
("g:rect(9,y,W-18,84", "rect(9,y,462,84,3,8)"),
("hit(9,y,58,84", "hit(9,y,58,84"),
("hit(67,y,340,84", "hit(67,y,340,84"),
("hit(408,y,63,84", "hit(408,y,63,84"),
("text(g,416,y+32,'INFO'", "text(416,y+32,'INFO'"),
("draw_head(g,'Book Check'", "drawHead('Book Check'"),
("draw_progress_head(g,'Reading Roadmap')", "drawProgressHead('Reading Roadmap')"),
("g:rect(14,52,452,14,{line_width=2,radius=7})", "rect(14,52,452,14,2,7)"),
("checkbox(g,20,y+22,st)", "checkbox(20,y+22,st)"),
]
buttons=[
(12,652,118,54,"< PREV"),(349,652,119,54,"NEXT >"),
(8,725,148,58,"PATH"),(166,725,148,58,"DONE"),(324,725,148,58,"CHECK"),
(15,584,146,55,"TO READ"),(167,584,146,55,"READING"),
(319,584,146,55,"FINISHED"),(15,650,218,55,"LINK BOOK"),
(247,650,218,55,"OPEN BOOK"),(15,723,450,59,"BACK TO LIST"),
(15,725,450,56,"BACK")
]
for x,y,w,h,label in buttons:
    pairs.append((f"button(g,{x},{y},{w},{h},'{label}'",f"button({x},{y},{w},{h},'{label}'"))
for native,web in pairs:
    assert native in lua, f"Native UI changed: {native}"
    assert web in html, f"Preview UI changed: {web}"
assert "const DEFAULTS={small:20,medium:24,large:30,stroke:1}" in html
assert "preview_only:changed" in html
assert "string.format('%02d',b.id)" in lua
assert "String(b.id).padStart(2,'0')" in html
assert "WHY THIS BOOK" in lua and "WHY THIS BOOK" in html
assert "Up next" in lua and "Up next" in html
assert "toggle_done(b)" in lua and "toggleDone(b)" in html
assert "control_radius=9" not in lua  # standalone app uses explicit shared-family 9px radius
assert "radius=9" in lua and "rect(x,y,w,h,3,9)" in html
assert "button(g,15,650,450,55,'LINK BOOK'" in lua and "button(15,650,450,55,'LINK BOOK'" in html
assert "LINK AN EPUB" not in lua + html  # 54 listed books are MOBI
assert "'Optional reread'" in lua and "'Optional reread'" in html
assert "path_page()" in lua and "pathPage()" in html
assert "{'WHY THIS BOOK',b.note,3},{'HEADS-UP',b.warning,2},{'VISUAL REFERENCE',b.anchor,2}" in lua
assert "[['WHY THIS BOOK',b.note,3],['HEADS-UP',b.warning,2],['VISUAL REFERENCE',b.anchor,2]]" in html
assert "local LIMIT,CARD_H=572,83" in lua and "const LIMIT=572,CARD_H=83" in html
assert "if page>1 then button" in lua and "page>1&&button" in html
assert "open_or_link(b)" in lua and "openOrLink(b)" in html
assert "begin_pick(b)" in lua and "beginPick(b)" in html
assert "leave_pick()" in lua and "leavePick()" in html
assert "try_open(books[chosen])" in lua and "openBook(books[chosen-1])" in html
assert "hit(9,y,W-18,84" not in lua, 'Full row must not accidentally claim Info tap'
assert "if(view==='check')hit(9,y,462,84" in html, 'Issue rows need full-width review tap'
assert "hit(408,y,63,84" in html, 'Reading rows must keep INFO separate'
assert "scan.issues" in lua and "scan.issues" in html
assert "scan.found" in lua and "scan.found" in html
assert "NOT INDEXED" in lua and "NOT INDEXED" in html
assert "MULTIPLE" in lua and "MULTIPLE" in html
assert "LINK CHANGED" in lua and "LINK CHANGED" in html
assert "CHECK TITLE" in lua and "CHECK TITLE" in html
assert "Opened books only; SD not scanned" in lua
assert "Opened books only; SD not scanned" in html
assert "text(g,67,y+58,b.reason" in lua and "text(67,y+58,b.reason" in html
assert "local function refresh_library()" in lua and "function scanLibrary()" in html
assert lua.count("local function draw_list(g)") == 1, 'Duplicate Lua view: source corrupted'
assert lua.count("local function detail(b)") == 1, 'Duplicate Lua detail: source corrupted'
assert "back_from_detail()" in lua and "backFromDetail()" in html
assert "version 0.1.0" not in html

for code in ('NOT OPENED YET', 'NOT ON CARD'):
    assert code in lua and code in html, code
assert "local function classify(" in lua and "function classify(" in html
print("PASS: 211-book catalog, migration table, hierarchy, corners and touch geometries match")
