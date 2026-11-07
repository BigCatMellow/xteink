#!/usr/bin/env python3
"""Independent BFS verifier of 12 original Word Bridge graphs.

The mobile app contains only banks and move limits, never solution paths. This
validator reconstructs all one-letter edges from scratch, verifies the true
shortest route, and requires enticing first moves that cannot finish in time.
"""
from pathlib import Path
import collections
import re

source=(Path(__file__).resolve().parents[1]/'app'/'levels.lua').read_text()
pattern=re.compile(r'\{title="BRIDGE (\d+)",start="([A-Z]+)",goal="([A-Z]+)",limit=(\d+),words=\{([^{}]+)\}\}')
levels=pattern.findall(source)
assert len(levels)==12,f'Expected 12 authored banks, got {len(levels)}'

def connected(a,b):
    return len(a)==len(b)==4 and sum(x!=y for x,y in zip(a,b))==1

def shortest(bank,start,goal,blocked=frozenset()):
    queue=collections.deque([(start,0)])
    found={start}
    while queue:
        word,dist=queue.popleft()
        if word==goal:return dist
        for nxt in bank:
            if nxt not in found and nxt not in blocked and connected(word,nxt):
                queue.append((nxt,dist+1))
                found.add(nxt)
    return None

seen=set()
for no, (number,start,goal,budget_s,listing) in enumerate(levels,1):
    assert int(number)==no
    budget=int(budget_s)
    bank=re.findall(r'"([A-Z]{4})"',listing)
    assert len(bank)==len(set(bank))==12,f'Level {no}: invalid 12-word bank'
    assert (start,goal) not in seen
    seen.add((start,goal))
    assert start in bank and goal in bank and start!=goal
    distance=shortest(bank,start,goal)
    assert distance==budget, f'Level {no}: optimal {distance}, budget {budget}'
    assert 3<=distance<=7
    neighbors=[w for w in bank if connected(start,w)]
    traps=sum(shortest(bank,w,goal,{start}) is None or
              shortest(bank,w,goal,{start})>distance-1 for w in neighbors)
    assert len(neighbors)>=2 and traps>=1, f'Level {no}: no meaningful wrong first moves'
    print(f'{no:02} {start} -> {goal}  min {distance}  first moves {len(neighbors)}  traps {traps}')
print('PASS: 12 original shortest-route word graphs, every stage has a dead-end opening')
