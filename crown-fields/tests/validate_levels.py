#!/usr/bin/env python3
"""Count all one-per-row, column, region non-touching crown solutions."""
from pathlib import Path
import re
s=(Path(__file__).resolve().parents[1]/'app'/'levels.lua').read_text()
boards=[re.findall(r'"([A-G]+)"',raw) for raw in re.findall(r'\{rows=\{([^{}]+)\}\}',s)]
assert len(boards)==12, len(boards)
for z,rows in enumerate(boards,1):
 n=len(rows)
 assert n==(5 if z<=4 else 6 if z<=8 else 7)
 assert all(len(r)==n for r in rows)
 assert set(''.join(rows))==set('ABCDEFG'[:n])
 # Every region must be contiguous.
 for label in set(''.join(rows)):
  cells={(x,y) for y,r in enumerate(rows) for x,c in enumerate(r) if c==label}
  reach={next(iter(cells))}
  while True:
   nxt=reach|{(x+dx,y+dy) for x,y in reach for dx,dy in [(0,1),(1,0),(-1,0),(0,-1)]
              if (x+dx,y+dy) in cells}
   if nxt==reach:break
   reach=nxt
  assert reach==cells,(z,label,'disconnected region')
 solutions=[]
 def walk(y,cols,regions,prior,path):
  if len(solutions)>1:return
  if y==n:
   solutions.append(tuple(path));return
  for x in range(n):
   region=ord(rows[y][x])-65
   if (cols>>x)&1 or (regions>>region)&1 or abs(x-prior)==1:continue
   walk(y+1,cols|(1<<x),regions|(1<<region),x,path+[x])
 walk(0,0,0,-9,[])
 assert len(solutions)==1, f'board {z} not unique: {len(solutions)}'
 assert len(set(solutions[0]))==n
 print(f'{z:02} {n}x{n}, unique: {solutions[0]}')
print('PASS: 12 connected-region Crowns boards, 12 unique solutions')
