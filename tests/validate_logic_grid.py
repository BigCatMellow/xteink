#!/usr/bin/env python3
"""Independently validate every authored board and count solutions (up to 2)."""
import re
from pathlib import Path
from itertools import product
from collections import deque

def neigh(n,i,wide=False):
    x,y=i%n,i//n
    return [b*n+a for b in range(max(0,y-1),min(n,y+2)) for a in range(max(0,x-1),min(n,x+2))
            if wide or abs(a-x)+abs(b-y)==1]

def takuzu(n, clues):
    patterns=[p for p in product((0,1),repeat=n) if sum(p)==n//2 and all(not(p[i]==p[i+1]==p[i+2]) for i in range(n-2))]
    axes=[[tuple(r*n+c for c in range(n)) for r in range(n)],[tuple(r*n+c for r in range(n)) for c in range(n)]]
    solutions=[]
    def search(a):
        if len(solutions)>=2:return
        while True:
            changed=False
            for group in axes:
                domains=[[p for p in patterns if all(a[j]==-1 or a[j]==v for j,v in zip(line,p))] for line in group]
                if any(not d for d in domains):return
                fixed=[d[0] for d in domains if len(d)==1]
                if len(set(fixed))!=len(fixed):return
                for line,d in zip(group,domains):
                    if len(d)>1:d=[p for p in d if p not in fixed]
                    if not d:return
                    for k,j in enumerate(line):
                        if a[j]==-1 and len({p[k] for p in d})==1:a[j]=d[0][k];changed=True
            if not changed:break
        if -1 not in a:solutions.append(tuple(a));return
        i=a.index(-1)
        for v in (0,1):
            b=a[:];b[i]=v;search(b)
    search([int(x) if x!='.' else -1 for x in clues])
    return solutions

def connected(n,a):
    remain={i for i,v in enumerate(a) if v!=1}
    if not remain:return False
    seen={next(iter(remain))};q=deque(seen)
    while q:
        for j in neigh(n,q.popleft()):
            if j in remain and j not in seen:seen.add(j);q.append(j)
    return seen==remain

def binary_constraints(n, clues, game):
    if game=='mosaic':
        rules=[(set(neigh(n,i,True)),int(v),int(v)) for i,v in enumerate(clues) if v!='.']
    else:
        rules=[]
        for i in range(n*n):
            for j in range(i+1,n*n):
                if clues[i]==clues[j] and (i//n==j//n or i%n==j%n):rules.append(({i,j},1,2))
            for j in neigh(n,i):
                if i<j:rules.append(({i,j},0,1))
    solutions=[];nodes=0
    def search(a):
        nonlocal nodes
        if len(solutions)>=2:return
        nodes+=1
        assert nodes<=500000, 'solver bound exceeded'
        while True:
            changed=False;pending=[]
            for cells,lo,hi in rules:
                unknown={i for i in cells if a[i]<0}
                known=sum(a[i]==1 for i in cells)
                l=max(0,lo-known);h=min(len(unknown),hi-known)
                if l>h:return
                if unknown and (h==0 or l==len(unknown)):
                    val=int(l==len(unknown))
                    for i in unknown:a[i]=val
                    changed=True
                elif unknown and l==h:pending.append((unknown,l))
            if game=='mosaic' and not changed:
                for A,ca in pending:
                    for B,cb in pending:
                        if A<B:
                            diff=B-A;d=cb-ca
                            if d<0 or d>len(diff):return
                            if d in (0,len(diff)):
                                v=int(d==len(diff))
                                for i in diff:
                                    if a[i]>=0 and a[i]!=v:return
                                    if a[i]<0:a[i]=v;changed=True
            if not changed:break
        if game=='hitori' and not connected(n,a):return
        if -1 not in a:solutions.append(tuple(a));return
        # Most constrained undecided cell first; this is not a human difficulty metric.
        i=max((i for i,v in enumerate(a) if v<0),key=lambda i:sum(i in r[0] for r in rules))
        for v in (0,1):
            b=a[:];b[i]=v;search(b)
    search([-1]*(n*n));return solutions

if __name__=='__main__':
    source=(Path(__file__).resolve().parents[1]/'app/puzzles.lua').read_text()
    game=re.search(r'id="([^"]+)"',source).group(1)
    levels=re.findall(r'\{n=(\d+),clues="([^"]+)",answer="([01]+)"',source)
    assert len(levels)>=12 and len({c for _,c,_ in levels})==len(levels)
    for i,(size,clues,answer) in enumerate(levels,1):
        n=int(size);assert len(clues)==len(answer)==n*n
        expected=tuple(map(int,answer))
        solutions=takuzu(n,clues) if game=='takuzu' else binary_constraints(n,clues,game)
        assert solutions==[expected], (game,i,len(solutions))
    print(f'{game}: {len(levels)} independently verified unique solutions')
