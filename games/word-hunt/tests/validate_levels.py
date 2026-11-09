#!/usr/bin/env python3
"""Independently validate authored Word Hunt boards, not the Lua matcher.

Every target word must have exactly one occurrence in all eight directions.
The F/O/X mode must contain only those letters, and its eight puzzles must
collectively cover every compass direction, as in the supplied example.
"""
import re
import subprocess
from pathlib import Path

SOURCE=(Path(__file__).resolve().parents[1]/'app'/'puzzles.lua').read_text(encoding='utf-8')
P=re.compile(r'\{title="([^"]+)",n=(\d+),rows=\{([^{}]*)\},words=\{([^{}]*)\},paths=\{((?:\{[-\d,]+\},?)+)\}\}')
games=P.findall(SOURCE)
assert len(games)==16,f'Expected 16 authored games, got {len(games)}'
DIRECTIONS={(dx,dy) for dx in (-1,0,1) for dy in (-1,0,1) if dx or dy}
fox_dirs=set()
titles=set()

for i,(name,size,rows_literal,words_literal,paths_literal) in enumerate(games,1):
    n=int(size)
    rows=re.findall(r'"([A-Z]+)"',rows_literal)
    words=re.findall(r'"([A-Z]+)"',words_literal)
    coords=[tuple(map(int,v.split(','))) for v in re.findall(r'\{([-\d,]+)\}',paths_literal)]
    assert len(rows)==n and all(len(row)==n for row in rows),f'Level {i} invalid size'
    assert len(coords)==len(words)==(4 if i<=8 else 1)
    assert len(set(words))==len(words)
    assert name=='FIND THE FOX' or name not in titles
    titles.add(name)
    if i<=8:assert n==8
    else:
        assert n==13
        assert words==['FOX']
        assert set(''.join(rows))==set('FOX')
    for word,(sx,sy,dx,dy) in zip(words,coords):
        assert (dx,dy) in DIRECTIONS
        ending_x=sx+(len(word)-1)*dx
        ending_y=sy+(len(word)-1)*dy
        assert 1<=sx<=n and 1<=sy<=n and 1<=ending_x<=n and 1<=ending_y<=n
        spelled=''.join(rows[sy-1+j*dy][sx-1+j*dx] for j in range(len(word)))
        assert spelled==word,f'Level {i}: authored path spells {spelled}, not {word}'
        matches=[]
        for y in range(1,n+1):
            for x in range(1,n+1):
                for vx,vy in DIRECTIONS:
                    if not (1<=x+(len(word)-1)*vx<=n and 1<=y+(len(word)-1)*vy<=n):continue
                    trial=''.join(rows[y-1+j*vy][x-1+j*vx] for j in range(len(word)))
                    if trial==word:matches.append((x,y,vx,vy))
        assert matches==[(sx,sy,dx,dy)],f'Level {i} {word}: {matches}'
        if i>8:fox_dirs.add((dx,dy))
    print(f'{i:02}: {name:15} {n}x{n} {", ".join(words)} - unique, 8-way scan')
assert fox_dirs==DIRECTIONS,f'Expected all eight FOX directions, found {fox_dirs}'
print('PASS: 8 classic and 8 FOX searches, every word unique, all eight FOX directions')

# Scan generated grids independently of the generator's own uniqueness check.
script = r"""
package.path='app/?.lua;'..package.path
local G=require('generator')
local function emit(mode,seed,p,kind)
  local paths={}
  for i,a in ipairs(p.paths) do paths[i]=table.concat(a,',') end
  print(table.concat({kind,mode,seed,table.concat(p.rows,','),table.concat(p.words,','),table.concat(paths,';')},'\t'))
end
for mode=1,2 do
  for seed=9,108 do emit(mode,seed,G.generate(mode,seed),'normal') end
  for _,seed in ipairs({999999998,999999999}) do emit(mode,seed,G.generate(mode,seed),'normal') end
end
-- Exercise guaranteed constructions, not just the usually accepted candidates.
local file=assert(io.open('app/generator.lua'));local source=file:read('*a');file:close()
source=source:gsub('for attempt=1,64 do','for attempt=1,0 do'):gsub('for repair=1,2048 do','for repair=1,0 do')
local fallback=assert((loadstring or load)(source))()
for mode=1,2 do for seed=1,32 do emit(mode,seed,fallback.generate(mode,seed),'fallback') end end
"""
output = subprocess.check_output(['lua', '-'], input=script, text=True,
    cwd=Path(__file__).resolve().parents[1])
seen = {1: set(), 2: set()}
for record in output.splitlines():
    kind, mode, seed, raw_rows, raw_words, raw_paths = record.split('\t')
    mode, seed = int(mode), int(seed)
    rows, words = raw_rows.split(','), raw_words.split(',')
    paths = [tuple(map(int, path.split(','))) for path in raw_paths.split(';')]
    n = 8 if mode == 1 else 13
    assert len(rows) == n and all(len(row) == n for row in rows)
    assert len(words) == len(paths) == (4 if mode == 1 else 1)
    assert len(set(words)) == len(words)
    if mode == 2:
        assert set(''.join(rows)) == set('FOX') and words == ['FOX']
    if kind == 'normal':
        assert tuple(rows) not in seen[mode], 'repeated board within sample'
        seen[mode].add(tuple(rows))
    for word, path in zip(words, paths):
        occurrences = []
        for y in range(n):
            for x in range(n):
                for dx, dy in DIRECTIONS:
                    ex, ey = x + (len(word)-1)*dx, y + (len(word)-1)*dy
                    if not (0 <= ex < n and 0 <= ey < n):
                        continue
                    if ''.join(rows[y+j*dy][x+j*dx] for j in range(len(word))) == word:
                        occurrences.append((x+1, y+1, dx, dy))
        assert occurrences == [path], (kind, mode, seed, word, occurrences, path)
print('PASS: 204 generated grids + 64 forced fallbacks independently scanned in all eight directions')
