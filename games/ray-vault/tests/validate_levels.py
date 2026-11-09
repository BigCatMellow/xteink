#!/usr/bin/env python3
"""Independently verify all 12 original Ray Vault secrets.

The public Black Box ray rules are reproduced here without using Lua code.
Each authored layout must have a unique full 24-port signature among all
6x6 arrangements containing the same number of atoms, and require at least
three distinct probe outcomes to identify it by a greedy candidate filter.
"""
import itertools
import re
from pathlib import Path

N=6
source=(Path(__file__).resolve().parents[1]/'app'/'index.lua').read_text()
body=source.split('local LEVELS={',1)[1].split('}',1)[0]
matches=re.findall(r'\{(\d+(?:,\d+)*)\}',source.split('local LEVELS={',1)[1].split('\nlocal C,',1)[0])
boards=[tuple(map(int,b.split(','))) for b in matches]
assert len(boards)==12, f'expected 12 frozen atom layouts, got {len(boards)}'

def origin(port):
    if port<N:return port,-1,0,1
    if port<2*N:return N,port-N,-1,0
    if port<3*N:return port-2*N,N,0,-1
    return -1,port-3*N,1,0

def trace(balls,entry):
    x,y,dx,dy=origin(entry)
    visited=set()
    for _ in range(400):
        state=(x,y,dx,dy)
        if state in visited:return 'LOOP'
        visited.add(state)
        nx,ny=x+dx,y+dy
        if not (0<=nx<N and 0<=ny<N):
            if ny==-1:out=nx
            elif nx==N:out=N+ny
            elif ny==N:out=2*N+nx
            elif nx==-1:out=3*N+ny
            else:raise AssertionError('invalid exit')
            return 'R' if out==entry else out
        if (nx,ny) in balls:return 'H'
        left=(nx-dy,ny+dx) in balls
        right=(nx+dy,ny-dx) in balls
        if (left or right) and not (0<=x<N and 0<=y<N):return 'R'
        if left and right:dx,dy=-dx,-dy
        elif left:dx,dy=dy,-dx
        elif right:dx,dy=-dy,dx
        else:x,y=nx,ny
    return 'LOOP'

def outcomes(locations):
    balls={(i%N,i//N) for i in locations}
    return tuple(trace(balls,p) for p in range(4*N))

def score_min_greedy(secrets,signatures,target):
    candidates=list(range(len(secrets)))
    ports=[]
    while len(candidates)>1:
        options=[]
        for port in range(4*N):
            if port in ports:continue
            survivors=[i for i in candidates if signatures[i][port]==target[port]]
            options.append((len(survivors),port,survivors))
        assert options
        count,port,candidates=min(options)
        ports.append(port)
        assert len(ports)<=24
    return len(ports)

for atoms in (3,4):
    all_secrets=list(itertools.combinations(range(N*N),atoms))
    signatures=[outcomes(b) for b in all_secrets]
    for level,positions in enumerate(boards,1):
        if len(positions)!=atoms:continue
        assert len(set(positions))==atoms and all(0<=p<36 for p in positions)
        signature=outcomes(positions)
        assert 'LOOP' not in signature, f'level {level} ray cycle'
        assert signatures.count(signature)==1, f'level {level} ambiguous atom configuration'
        for p,result in enumerate(signature):
            if isinstance(result,int):
                assert result!=p and signature[result]==p, f'level {level} asymmetric ports'
        assert signature.count('H')>=4 and signature.count('R')>=1
        assert sum(isinstance(p,int) for p in signature)>=4
        needed=score_min_greedy(all_secrets,signatures,signature)
        assert needed>=3, f'level {level} too obvious'
        print(f'Level {level:02}: {atoms} atoms, {needed} probes to isolate by greedy deduction, UNIQUE')
print('PASS: all 12 Ray Vault layouts have unique full-port signatures')
