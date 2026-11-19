#!/usr/bin/env python3
"""Independent proof of the new 10x10 and 12x12 subset-deduction fields.

Only numbers visible after opening S are used for inference. The hidden mine
map is used solely to verify the deductions are sound, never to choose them.
"""
from pathlib import Path
import re

text=(Path(__file__).resolve().parents[1]/'app'/'legacy_levels.lua').read_text()
raw=re.findall(r'\{title="FIELD (\d+)",n=(\d+),mines=\{([0-9,]+)\}\}',text)
assert len(raw)==24, 'Expected original twelve and twelve advanced fields'

def neighbors(n,p):
    x,y=p%n,p//n
    return {yy*n+xx for yy in range(max(0,y-1),min(n,y+2))
            for xx in range(max(0,x-1),min(n,x+2)) if (xx,yy)!=(x,y)}

def verify(n,mines):
    adj=[neighbors(n,i) for i in range(n*n)]
    assert not mines & ({0}|adj[0]), 'Start S must have zero adjacent mines'
    clue=[len(a&mines) for a in adj]
    revealed=set()
    flags=set()
    passes=0
    subset_moves=0
    def reveal(p):
        queue=[p]
        while queue:
            j=queue.pop()
            if j in revealed or j in flags:continue
            assert j not in mines,'An inferred safe move is a mine'
            revealed.add(j)
            if clue[j]==0:queue.extend(adj[j]-revealed)
    reveal(0)
    opening=len(revealed)
    while True:
        constraints=[]
        for i in sorted(revealed):
            hidden=adj[i]-flags-revealed
            need=clue[i]-len(adj[i]&flags)
            assert 0<=need<=len(hidden)
            if hidden:constraints.append((hidden,need))
        safe=set()
        marked=set()
        for hidden,need in constraints:
            if need==0:safe.update(hidden)
            if need==len(hidden):marked.update(hidden)
        subset=False
        if not safe and not marked:
            for small,a in constraints:
                for large,b in constraints:
                    if len(small)<len(large) and small.issubset(large):
                        extra=large-small
                        diff=b-a
                        if diff==0:safe.update(extra);subset=True
                        elif diff==len(extra):marked.update(extra);subset=True
        if not safe and not marked:break
        assert not safe&mines and not marked-mines,'Incorrect logical inference'
        previous=len(flags)+len(revealed)
        flags.update(marked)
        for j in safe:reveal(j)
        if previous==len(flags)+len(revealed):break
        passes+=1
        if subset:subset_moves+=len(safe)+len(marked)
        assert passes<500,'Solver failed to converge'
    assert len(revealed)==n*n-len(mines),'A guess was required'
    return opening,passes,subset_moves

for level,(name,ns,positions) in enumerate(raw[12:],13):
    assert int(name)==level
    n=int(ns)
    assert n==(10 if level<=20 else 12)
    mines={int(x)-1 for x in positions.split(',')}
    assert len(mines)==(18 if n==10 else 27)
    opening,passes,subset=verify(n,mines)
    assert passes>=4 and subset>=2 and opening<n*n*.5, \
        f'{level}: not enough deduction depth'
    print(f'{level:02} {n}x{n}: opening={opening}, passes={passes}, subset={subset}')
print('PASS: twelve advanced fields require no guesses and include subset deductions')
