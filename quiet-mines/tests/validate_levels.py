#!/usr/bin/env python3
"""Independent no-guess Minesweeper verifier from the marked safe start.

Repeatedly reveal zero regions, then use local clue arithmetic to deduce
every forced safe square and forced mine. Reject maps requiring a guess.
"""
from pathlib import Path
import re
text=(Path(__file__).resolve().parents[1]/'app'/'levels.lua').read_text()
raw=re.findall(r'\{title="FIELD (\d+)",n=(\d+),mines=\{([0-9,]+)\}\}',text)
assert len(raw)==12
def neighbors(n,p):
 x,y=divmod(p,n)[1],p//n
 return {yy*n+xx for yy in range(max(0,y-1),min(n,y+2))
         for xx in range(max(0,x-1),min(n,x+2)) if (xx,yy)!=(x,y)}
for level,(name,ns,positions) in enumerate(raw,1):
 assert int(name)==level
 n=int(ns)
 assert n==(6 if level<=4 else 7 if level<=8 else 8)
 mines={int(p)-1 for p in positions.split(',')}
 assert len(mines)==(6 if n==6 else 8 if n==7 else 10)
 assert not mines & ({0}|neighbors(n,0))
 adj={i:len(neighbors(n,i)&mines) for i in range(n*n) if i not in mines}
 revealed=set()
 def reveal(start):
  stack=[start]
  while stack:
   p=stack.pop()
   if p in revealed:continue
   assert p not in mines
   revealed.add(p)
   if adj[p]==0:stack.extend(neighbors(n,p)-revealed)
 reveal(0)
 known=set()
 iterations=0
 changed=True
 while changed:
  changed=False;iterations+=1
  for p in list(revealed):
   possible=neighbors(n,p)-revealed-known
   remaining=adj[p]-len(neighbors(n,p)&known)
   assert 0<=remaining<=len(possible)
   if remaining==0 and possible:
    assert not possible & mines, f'{level}: unsafe deduction'
    for safe in possible:reveal(safe)
    changed=True
   elif remaining==len(possible) and possible:
    assert possible<=mines, f'{level}: incorrect mine inference'
    known.update(possible)
    changed=True
 assert len(revealed)==n*n-len(mines), f'{level}: requires guessing ({len(revealed)} safe revealed)'
 print(f'{level:02} {n}x{n}, {len(mines)} mines, {iterations} deduction sweeps, no guessing')
print('PASS: all 12 Quiet Mines fields solve by arithmetic from START')
