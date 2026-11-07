#!/usr/bin/env python3
"""Independently validate authored Word Hunt boards, not the Lua matcher.

Every target word must have exactly one occurrence in all eight directions.
The F/O/X mode must contain only those letters, and its eight puzzles must
collectively cover every compass direction, as in the supplied example.
"""
import re
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
