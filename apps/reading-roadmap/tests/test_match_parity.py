#!/usr/bin/env python3
"""The title matcher exists three times (app Lua, preview JS, card tool Python). Run one case
table through all three real implementations and require identical, expected answers."""
import json
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

root = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(root / 'tools'))
import card_from_tree as py  # noqa: E402

CASES = [  # catalogue title, catalogue author, reader title, reader author, expected[, alias]
    ('The Martian', 'Andy Weir', 'The Martian: A Novel', '', 'exact'),
    ('The Martian', 'Andy Weir', 'The Martian Chronicles', 'Ray Bradbury', None),
    ('The Martian', 'Andy Weir', 'The Martian Extended Edition', '', 'similar'),
    ('All Systems Red', 'Martha Wells', '[Murderbot Diaries 01] All Systems Red', '', 'exact'),
    ('The Hobbit', 'J. R. R. Tolkien', 'The Hobbit: Or There and Back Again', 'J. R. R. Tolkien', 'exact'),
    ('The Hobbit', 'J. R. R. Tolkien', '[LOTR 00] The Hobbit Or There and Back Again - J. R. R Tolkien.epub', '', 'similar'),
    ('The Princess Bride', 'William Goldman', 'Princess Bride S. Morgenstern The - William Goldman', '', 'similar'),
    ('The Princess Bride', 'William Goldman', "The Princess Bride: S. Morgenstern's Classic Tale", 'William Goldman', 'exact'),
    ('A Walk in the Woods', 'Bill Bryson', 'In the Woods', 'Tana French', None),
    ('A Walk in the Woods', 'Bill Bryson', 'In the Woods', '', None),
    ('We Are Legion (We Are Bob)', 'Dennis E. Taylor', 'We Are Legion', '', 'exact'),
    ('The Lord of the Rings', 'J. R. R. Tolkien', 'The Lord of the Rings', 'JRR Tolkien', 'exact'),
    ('The Disaster Artist', 'Greg Sestero and Tom Bissell', 'The Disaster Artist', 'Tom Bissell', 'exact'),
    ('True Grit', 'Charles Portis', 'True Grit - Charles Portis.epub', '', 'exact'),
    ('True Grit', 'Charles Portis', 'True Grit', 'Unknown Author', 'exact'),
    ('Guards! Guards!', 'Terry Pratchett', 'Guards! Guards!', 'Terry Pratchett', 'exact'),
    ('The Thin Man', 'Dashiell Hammett', 'The Maltese Falcon', 'Dashiell Hammett', None),
    # Junk metadata on the user's card
    ('The Rum Diary', 'Hunter S. Thompson', 'Thompson, Hunter S', 'The Rum Diary', 'exact'),
    ('The Curse of Lono', 'Hunter S. Thompson', 'Thompson, Hunter S', 'The Rum Diary', None),
    ('Rebecca', 'Daphne du Maurier', 'Microsoft Word - Daphne Du Maurier   Rebecca', '', 'exact',
     'Microsoft Word - Daphne Du Maurier   Rebecca'),
    ('Brideshead Revisited', 'Evelyn Waugh', 'Microsoft Word - Daphne Du Maurier   Rebecca', '', None,
     'Microsoft Word - Waugh, Evelyn - Brideshead Revisited.doc'),
    ('Holes', 'Louis Sachar', 'none', '', None),
]


def alias(c):
    return c[5] if len(c) > 5 else ''


def run_py():
    return [py.classify(c[0], c[1], c[2], c[3], alias(c)) for c in CASES]


def run_lua():
    lua_bin = shutil.which('lua5.4') or shutil.which('lua5.1') or shutil.which('lua')
    src = (root / 'app/index.lua').read_text()
    block = 'local books={}\n' + re.search(r'(local function safe_text\(s\).*?\nend\n)', src, re.S).group(1)
    block += re.search(r'(local function norm\(s\).*?)local ISSUE_ORDER', src, re.S).group(1)
    rows = ',\n'.join('{%s}' % ','.join(json.dumps(v) for v in (*c[:4], alias(c))) for c in CASES)
    prog = block + 'for _,c in ipairs({' + rows + '}) do\n' \
        '  print(classify({title=c[1],author=c[2],alias=c[5]},c[3],c[4]) or "nil")\nend\n'
    with tempfile.NamedTemporaryFile('w', suffix='.lua', delete=False) as f:
        f.write(prog)
    out = subprocess.run([lua_bin, f.name], capture_output=True, text=True, check=True).stdout.split()
    return [None if o == 'nil' else o for o in out]


def run_js():
    html = (root / 'preview.html').read_text()
    block = re.search(r'(// Title matching\..*?)const ISSUE_ORDER', html, re.S).group(1)
    prog = "function safe(s){return String(s??'');}\n" + block + \
        f'for(const c of {json.dumps([[*c[:4], alias(c)] for c in CASES])})console.log(classify({{title:c[0],author:c[1],alias:c[4]}},c[2],c[3])??"nil");\n'
    out = subprocess.run(['node', '-e', prog], capture_output=True, text=True, check=True).stdout.split()
    return [None if o == 'nil' else o for o in out]


expected = [c[4] for c in CASES]
results = {'python': run_py(), 'lua': run_lua(), 'js': run_js()}
bad = False
for name, got in results.items():
    for c, g, e in zip(CASES, got, expected):
        if g != e:
            bad = True
            print(f'FAIL {name}: {c[0]!r} vs {c[2]!r} ({c[3]!r}) -> {g}, expected {e}')
assert not bad, 'matcher implementations disagree'
print(f'PASS: {len(CASES)} title-matching cases agree across Lua, JS and Python')
