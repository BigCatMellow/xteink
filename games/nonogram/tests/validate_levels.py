#!/usr/bin/env python3
"""Independent nonogram solver: ensure every authored picture is uniquely implied
by the visible row and column run clues, never merely checked against its image.
"""
import re
import subprocess
from pathlib import Path

SRC=(Path(__file__).resolve().parents[1]/'app'/'pictures.lua').read_text(encoding='utf-8')
puzzles=re.findall(r'\{name="([A-Z]+)",rows=\{([^{}]+)\}\}',SRC)
assert len(puzzles)==12,f'Expected 12 puzzles, found {len(puzzles)}'

def clue(row):
    runs=[]
    current=0
    for ch in row:
        if ch=='#':current+=1
        elif current:runs.append(current);current=0
    if current:runs.append(current)
    return tuple(runs or [0])

def solutions(rows,limit=2):
    n=len(rows)
    row_clues=[clue(row) for row in rows]
    col_clues=[clue(''.join(rows[y][x] for y in range(n))) for x in range(n)]
    assert max(map(len,row_clues+col_clues))<=3,'clues would not fit the display'
    row_choices=[]
    for target in row_clues:
        row_choices.append([
            tuple((mask>>i)&1 for i in range(n))
            for mask in range(1<<n)
            if clue(''.join('#' if (mask>>i)&1 else '.' for i in range(n)))==target
        ])
    column_choices=[]
    for target in col_clues:
        column_choices.append([
            tuple((mask>>i)&1 for i in range(n))
            for mask in range(1<<n)
            if clue(''.join('#' if (mask>>i)&1 else '.' for i in range(n)))==target
        ])
    found=[]
    def search(y,chosen,available):
        if len(found)>=limit:return
        if y==n:
            found.append([''.join('#' if v else '.' for v in row) for row in chosen])
            return
        for row in row_choices[y]:
            choices=[[v for v in available[x] if v[y]==row[x]] for x in range(n)]
            if all(choices):
                search(y+1,chosen+[row],choices)
                if len(found)>=limit:return
    search(0,[],column_choices)
    return found,row_clues,col_clues

names=set()
for i,(name,raw) in enumerate(puzzles,1):
    rows=re.findall(r'"([.#]+)"',raw)
    n=5 if i<=4 else 7 if i<=8 else 8
    assert name not in names
    names.add(name)
    assert len(rows)==n and all(len(row)==n for row in rows)
    assert all(set(row)<={'#','.'} for row in rows)
    black=sum(row.count('#') for row in rows)
    assert n*n*.20<=black<=n*n*.85,f'{name}: bad ink density'
    found,rc,cc=solutions(rows)
    assert len(found)==1,f'{name} has {len(found)} solutions'
    assert found[0]==rows, f'{name}: solution does not match authored image'
    print(f'{i:02} {name:12} {n}x{n}, {black} filled cells, UNIQUE')
print('PASS: 12 original nonograms, each with one exact solution')

script = r"""
package.path='app/?.lua;'..package.path
local G=require('generator')
for seed=13,112 do print('normal\t'..seed..'\t'..table.concat(G.generate(seed).rows,',')) end
for _,seed in ipairs({999999998,999999999}) do print('normal\t'..seed..'\t'..table.concat(G.generate(seed).rows,',')) end
-- Exhaustion must not be mistaken for a unique solution.
assert(G.count({'#....','.#...','..#..','...#.','....#'})==2)
assert(G.count({'#####','#####','#####','#####','#####'},1)==-1)
G.count=function() return -1 end
for seed=1,32 do print('fallback\t'..seed..'\t'..table.concat(G.generate(seed).rows,',')) end
"""
output = subprocess.check_output(['lua', '-'], input=script, text=True,
    cwd=Path(__file__).resolve().parents[1])
seen = set()
for record in output.splitlines():
    kind, seed, raw = record.split('\t')
    rows = raw.split(',')
    assert len(rows) in (5, 7, 8) and all(len(row) == len(rows) for row in rows)
    assert .25 <= sum(row.count('#') for row in rows) / len(rows)**2 <= .8
    found, _, _ = solutions(rows)
    assert found == [rows], (kind, seed, 'not uniquely reconstructable')
    if kind == 'normal':
        assert tuple(rows) not in seen, 'duplicate generated board within sample'
        seen.add(tuple(rows))
print('PASS: 102 generated patterns + 32 forced fallbacks independently solved; unique, bounded clues')
