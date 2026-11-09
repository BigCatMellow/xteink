#!/usr/bin/env python3
"""Independent exact-constraint validation of all authored Lantern Logic boards.

A bulb is a Boolean per white cell. It must satisfy:
  - at most one per horizontal and vertical unobstructed run,
  - at least one bulb visible from each white cell,
  - exactly the clue's four-way neighboring bulb count.
The solver enumerates at most two solutions; a valid puzzle has exactly one.
"""
from pathlib import Path
import re

src=(Path(__file__).resolve().parents[1]/'app'/'index.lua').read_text(encoding='utf-8')
matches=re.findall(r'\{size=(\d+),rows=\{([^{}]+)\}\}',src)
assert len(matches)==16,f'Expected 16 boards, got {len(matches)}'

def constraints(n,grid):
    cells=[i for i,ch in enumerate(grid) if ch=='.']
    to_var={p:j for j,p in enumerate(cells)}
    horizontals=[]
    verticals=[]
    for y in range(n):
        line=[]
        for x in range(n+1):
            p=y*n+x
            if x<n and p in to_var:line.append(to_var[p])
            elif line:horizontals.append(line);line=[]
    for x in range(n):
        line=[]
        for y in range(n+1):
            p=y*n+x
            if y<n and p in to_var:line.append(to_var[p])
            elif line:verticals.append(line);line=[]
    out=[]
    for group in horizontals+verticals:
        out.append((tuple(group),0,1))
    for j in range(len(cells)):
        h=next(g for g in horizontals if j in g)
        v=next(g for g in verticals if j in g)
        lit=tuple(set(h+v))
        out.append((lit,1,len(lit)))
    for i,ch in enumerate(grid):
        if ch not in '01234':continue
        x,y=i%n,i//n
        adjacent=[]
        for dx,dy in ((1,0),(-1,0),(0,1),(0,-1)):
            nx,ny=x+dx,y+dy
            p=ny*n+nx
            if 0<=nx<n and 0<=ny<n and p in to_var:
                adjacent.append(to_var[p])
        out.append((tuple(adjacent),int(ch),int(ch)))
    return cells,out

def solve(n,grid,limit=2):
    cells,cs=constraints(n,grid)
    var_constraints=[[] for _ in cells]
    for ci,(members,lo,hi) in enumerate(cs):
        for j in members:var_constraints[j].append(ci)
    solutions=[]
    def propagate(state):
        again=True
        while again:
            again=False
            for members,lo,hi in cs:
                ones=sum(state[j]==1 for j in members)
                unk=[j for j in members if state[j]==-1]
                if ones>hi or ones+len(unk)<lo:return False
                force=None
                if ones==hi:force=0
                elif ones+len(unk)==lo:force=1
                if force is not None:
                    for j in unk:state[j]=force;again=True
        return True
    def walk(state):
        if len(solutions)>=limit or not propagate(state):return
        if -1 not in state:
            solutions.append(tuple(cells[i] for i,x in enumerate(state) if x==1))
            return
        candidates=[i for i,v in enumerate(state) if v==-1]
        i=max(candidates,key=lambda j:(len(var_constraints[j]),sum(len(cs[c][0])<5 for c in var_constraints[j])))
        for choice in (0,1):
            nxt=state.copy()
            nxt[i]=choice
            walk(nxt)
            if len(solutions)>=limit:return
    walk([-1]*len(cells))
    return solutions

for i,(size,raw) in enumerate(matches,1):
    n=int(size)
    rows=re.findall(r'"([.#01234]+)"',raw)
    assert n==(5 if i<=5 else 6 if i<=11 else 7)
    assert len(rows)==n and all(len(r)==n for r in rows)
    board=''.join(rows)
    result=solve(n,board,limit=2)
    assert len(result)==1,f'Level {i} must have exactly one bulb configuration; found {len(result)}'
    assert len(result[0])>=n,f'Level {i} has too few bulbs'
    assert sum(ch in '01234' for ch in board)>=2,f'Level {i} has too few clues'
    print(f'Level {i:02}: {n}x{n} — unique, {len(result[0])} bulbs')
print('PASS: all 16 Akari puzzles have exactly one solution')
