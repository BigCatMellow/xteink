#!/usr/bin/env python3
"""Independent verification of Lua-generated puzzles, not the generator's proof."""
import subprocess
import sys
from pathlib import Path
from itertools import product
from collections import deque, Counter

ROOT=Path(__file__).resolve().parents[1]

def near(n,i,wide=False):
    x,y=i%n,i//n
    return [b*n+a for a in range(max(0,x-1),min(n,x+2))
            for b in range(max(0,y-1),min(n,y+2))
            if wide or abs(a-x)+abs(b-y)==1]

def connected(n,cells):
    if not cells:return False
    seen={next(iter(cells))}
    q=deque(seen)
    while q:
        for j in near(n,q.popleft()):
            if j in cells and j not in seen:
                seen.add(j);q.append(j)
    return seen==cells

def takuzu(n,clues):
    valid=[p for p in product((0,1),repeat=n)
           if sum(p)==n//2 and all(len(set(p[i:i+3]))>1 for i in range(n-2))]
    domains=[[p for p in valid if all(c=='.' or int(c)==v for c,v in zip(clues[r*n:(r+1)*n],p))]
             for r in range(n)]
    solutions=[]
    def search(rows):
        if len(solutions)>1:return
        if len(rows)==n:
            cols=list(zip(*rows))
            if len(set(cols))==n and all(c in valid for c in cols):
                solutions.append(tuple(v for row in rows for v in row))
            return
        for p in domains[len(rows)]:
            if p in rows:continue
            nxt=rows+[p]
            if all(any(candidate[:len(nxt)]==tuple(c) for candidate in valid)
                   for c in zip(*nxt)):
                search(nxt)
    search([])
    return solutions

def cardinality(size,rules,connect=None):
    answers=[]
    degree=Counter(i for cells,_,_ in rules for i in cells)
    nodes=0
    def search(a):
        nonlocal nodes
        if len(answers)>1:return
        nodes+=1
        assert nodes<=1000000,'independent search budget exceeded'
        while True:
            changed=False
            for ids,lo,hi in rules:
                known=sum(a[i]==1 for i in ids)
                unknown=[i for i in ids if a[i]<0]
                if known>hi or known+len(unknown)<lo:return
                if unknown and (known==hi or known+len(unknown)==lo):
                    bit=int(known+len(unknown)==lo)
                    for i in unknown:a[i]=bit
                    changed=True
            if not changed:break
        if connect is not None and not connected(connect,{i for i,v in enumerate(a) if v!=1}):return
        undecided=[i for i,v in enumerate(a) if v<0]
        if not undecided:answers.append(tuple(a));return
        i=max(undecided,key=lambda j:degree[j])
        for bit in (0,1):
            b=a[:];b[i]=bit;search(b)
    search([-1]*size)
    return answers

def mosaic(n,c):
    return cardinality(n*n,[(near(n,i,True),int(v),int(v)) for i,v in enumerate(c) if v!='.'])

def hitori(n,c):
    rules=[]
    for i in range(n*n):
        for j in range(i+1,n*n):
            if c[i]==c[j] and (i%n==j%n or i//n==j//n):
                rules.append(([i,j],1,2))
        for j in near(n,i):
            if j>i:rules.append(([i,j],0,1))
    return cardinality(n*n,rules,n)

def akari(n,c):
    cells=[i for i,v in enumerate(c) if v=='.']
    white=set(cells);ids={p:i for i,p in enumerate(cells)}
    runs=[]
    for axis in (0,1):
        for line in range(n):
            run=[]
            for k in range(n+1):
                i=line*n+k if axis==0 else k*n+line
                if k<n and i in white:run.append(ids[i])
                elif run:runs.append(tuple(run));run=[]
    rules=[(run,0,1) for run in runs]
    for j in range(len(cells)):
        lit=set(i for run in runs if j in run for i in run)
        rules.append((lit,1,len(lit)))
    for i,v in enumerate(c):
        if v.isdigit():rules.append(([ids[j] for j in near(n,i) if j in white],int(v),int(v)))
    result=[]
    for a in cardinality(len(cells),rules):
        b=[0]*(n*n)
        for i,j in enumerate(cells):b[j]=a[i]
        result.append(tuple(b))
    return result

def crowns(n,c):
    assert set(c)==set('ABCDEFGHI'[:n])
    for label in set(c):
        cells={i for i,v in enumerate(c) if v==label}
        assert len(cells)>=2 and connected(n,cells)
    answers=[]
    def search(y,cols,regions,prior,path):
        if len(answers)>1:return
        if y==n:
            b=[0]*(n*n)
            for i in path:b[i]=1
            answers.append(tuple(b));return
        for x in range(n):
            i=y*n+x
            if x in cols or c[i] in regions or abs(x-prior)<=1:continue
            search(y+1,cols|{x},regions|{c[i]},x,path+[i])
    search(0,set(),set(),-2,[])
    return answers

if __name__=='__main__':
    solvers={'takuzu':takuzu,'mosaic':mosaic,'hitori':hitori,'akari':akari,'crowns':crowns}
    result=subprocess.run(['lua','tests/generate_procedural_samples.lua'],cwd=ROOT,check=True,
                          capture_output=True,text=True,timeout=240)
    if result.stderr:print(result.stderr,file=sys.stderr,end='')
    counts=Counter();maxwork=Counter()
    for line in result.stdout.splitlines():
        kind,n,seed,c,a,proof,work=line.split('\t')
        n=int(n);work=int(work)
        expected=tuple(map(int,a))
        assert len(c)==len(a)==n*n
        assert solvers[kind](n,c)==[expected],(kind,n,seed,'not uniquely solvable')
        counts[kind,n]+=1
        maxwork[kind,n]=max(maxwork[kind,n],work)
    assert len(counts)==21
    for key in sorted(counts):
        assert counts[key]>=4
        print(f'{key[0]} {key[1]}x{key[1]}: {counts[key]} unique generated boards, max work {maxwork[key]}')
    print(f'PASS: independently verified {sum(counts.values())} procedural boards')
