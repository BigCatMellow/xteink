#!/usr/bin/env python3
"""Independently verify 12 Kakuro grids have one cross-sums solution.

Every playable cell belongs to one across and one down run. Each numbered
entry is 2+ digits, sums exactly its black-cell clue, and uses distinct 1..9.
Constraint propagation enumerates up to two solutions per grid.
"""
from pathlib import Path
import itertools,re
from functools import lru_cache
s=(Path(__file__).resolve().parents[1]/'app'/'puzzles.lua').read_text()
found=re.findall(r'\{rows=\{([^{}]+)\},across=\{([^{}]*)\},down=\{([^{}]*)\}\}',s)
assert len(found)==12, len(found)
@lru_cache(None)
def choices(length,total):
 return tuple(seq for seq in itertools.permutations(range(1,10),length) if sum(seq)==total)
for level,(layout,across_raw,down_raw) in enumerate(found,1):
 rows=re.findall(r'"([.#]+)"',layout)
 n=len(rows)
 assert n==(5 if level<=4 else 6 if level<=8 else 7)
 assert all(len(row)==n for row in rows)
 white={y*n+x+1 for y in range(n) for x in range(n) if rows[y][x]=='.'}
 assert len(white)>=8
 across={int(i):int(v) for i,v in re.findall(r'\[(\d+)\]=(\d+)',across_raw)}
 down={int(i):int(v) for i,v in re.findall(r'\[(\d+)\]=(\d+)',down_raw)}
 assert across and down
 runs=[]
 for kind,clues in [('A',across),('D',down)]:
  for entry,total in clues.items():
   assert entry not in white
   x,y=(entry-1)%n,(entry-1)//n
   cells=[]
   while True:
    x+=kind=='A';y+=kind=='D'
    if x>=n or y>=n or y*n+x+1 not in white:break
    cells.append(y*n+x+1)
   assert 2<=len(cells)<=9
   assert min(range(len(cells)))==0
   assert choices(len(cells),total)
   runs.append((tuple(cells),total))
 membership={cell:[] for cell in white}
 for j,(cells,total) in enumerate(runs):
  for k,c in enumerate(cells):
   assert c in membership
   membership[c].append((j,k))
 assert all(len(x)==2 for x in membership.values()),f'Level {level}: missing across/down run'
 domains=[choices(len(c),t) for c,t in runs]
 solutions=[]
 def propagate(pools):
  more=True
  while more:
   more=False
   for cell,links in membership.items():
    allowed=set.intersection(*(set(vec[k] for vec in pools[j]) for j,k in links))
    if not allowed:return None
    for j,k in links:
     subset=tuple(vec for vec in pools[j] if vec[k] in allowed)
     if not subset:return None
     if len(subset)<len(pools[j]):pools[j]=subset;more=True
  return pools
 def search(pools):
  if len(solutions)>=2:return
  pools=propagate(pools)
  if pools is None:return
  varied=[(len(v),i) for i,v in enumerate(pools) if len(v)>1]
  if not varied:
   numbers={}
   for j,(cells,total) in enumerate(runs):
    for c,val in zip(cells,pools[j][0]):numbers[c]=val
   solutions.append(numbers)
   return
  _,j=min(varied)
  for option in pools[j]:
   new=list(pools);new[j]=(option,)
   search(new)
   if len(solutions)>=2:return
 search(list(domains))
 assert len(solutions)==1,f'Level {level}: {len(solutions)} valid solutions'
 assert set(solutions[0])==white
 print(f'{level:02} {n}x{n} {len(white)} white cells, {len(runs)} runs, UNIQUE')
print('PASS: 12 Sum Cross grids, exactly one valid digit filling each')
