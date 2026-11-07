#!/usr/bin/env python3
"""Independent exhaustive Hashi constraint check for Island Links levels.

Build all geometric neighboring-island links from authored node coordinates.
Enumerate assignments of 0,1,2 bridges; require each numbered island's
degree, no crossing links, and exactly one connected network.
"""
import re
from pathlib import Path

code=(Path(__file__).resolve().parents[1]/'app'/'index.lua').read_text(encoding='utf-8')
body=code.split('local LEVELS={',1)[1].split('\nlocal C,S,ERR',1)[0]
rows=re.findall(r'^\s*\{((?:\{\d+,\d+,\d+\},?)+)\},\s*$',body,re.M)
assert len(rows)==12,f'expected 12 levels, got {len(rows)}'

def candidate_edges(nodes):
    edges=[]
    for i,(x,y,n) in enumerate(nodes):
        for j in range(i+1,len(nodes)):
            a,b,_=nodes[j]
            if x!=a and y!=b:continue
            if any(k not in (i,j) and
                   ((x==a==xx and min(y,b)<yy<max(y,b)) or
                    (y==b==yy and min(x,a)<xx<max(x,a)))
                   for k,(xx,yy,_) in enumerate(nodes)):
                continue
            edges.append((i,j))
    return edges

def crossing(nodes,one,two):
    a,b=[nodes[i] for i in one]
    c,d=[nodes[i] for i in two]
    if a[1]==b[1] and c[0]==d[0]:
        return min(a[0],b[0])<c[0]<max(a[0],b[0]) and min(c[1],d[1])<a[1]<max(c[1],d[1])
    if a[0]==b[0] and c[1]==d[1]:
        return min(c[0],d[0])<a[0]<max(c[0],d[0]) and min(a[1],b[1])<c[1]<max(a[1],b[1])
    return False

def unique_solution(nodes,edges,limit=2):
    n=len(nodes)
    edges_at=[[] for _ in range(n)]
    for i,(a,b) in enumerate(edges):
        edges_at[a].append(i)
        edges_at[b].append(i)
    forbidden={pair for pair in
        ((i,j) for i in range(len(edges)) for j in range(i+1,len(edges)))
        if crossing(nodes,edges[pair[0]],edges[pair[1]])}
    val=[-1]*len(edges)
    found=[]
    def solve():
        if len(found)>=limit:return
        # Each island degree constrains its incident edge total.
        for i,(_,_,required) in enumerate(nodes):
            known=sum(val[k] for k in edges_at[i] if val[k]>=0)
            unknown=sum(val[k]<0 for k in edges_at[i])
            if known>required or known+2*unknown<required:return
        if any(val[i]>0 and val[j]>0 for i,j in forbidden):return
        try:k=val.index(-1)
        except ValueError:
            active=[(a,b) for (a,b),weight in zip(edges,val) if weight>0]
            connected={0}
            changed=True
            while changed:
                changed=False
                for a,b in active:
                    if (a in connected)!=(b in connected):
                        connected.update((a,b));changed=True
            if len(connected)==n:found.append(tuple(val))
            return
        for v in (0,1,2):
            val[k]=v
            solve()
            if len(found)>=limit:break
        val[k]=-1
    solve()
    return found

for level,row in enumerate(rows,1):
    nodes=[tuple(map(int,parts)) for parts in re.findall(r'\{(\d+),(\d+),(\d+)\}',row)]
    assert len(nodes)==(7 if level<=3 else 8 if level<=7 else 9)
    assert len({(x,y) for x,y,_ in nodes})==len(nodes)
    assert all(0<=x<=6 and 0<=y<=6 and 1<=c<=8 for x,y,c in nodes)
    edges=candidate_edges(nodes)
    solutions=unique_solution(nodes,edges)
    assert len(solutions)==1,f'level {level} not uniquely solvable: {len(solutions)}'
    weights=solutions[0]
    assert sum(w==2 for w in weights)>=2, f'level {level} needs double bridges'
    assert sum(w>0 for w in weights)>=len(nodes)-1
    print(f'Level {level:02}: {len(nodes)} islands, {len(edges)} links, unique connected solution')
print('PASS: all 12 Island Links boards have exactly one valid solution')
