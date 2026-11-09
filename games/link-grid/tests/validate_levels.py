#!/usr/bin/env python3
"""Independent consistency/uniqueness test for frozen Link Grid puzzles.

Read only index.lua's puzzle data, reconstruct the puzzle rules with a small
constraint solver, and count solutions up to two. No Lua fixture answers used.
"""
from __future__ import annotations
import re
from collections import deque
from pathlib import Path

SCRIPT=Path(__file__).resolve().parents[1]/"app"/"index.lua"
SRC=SCRIPT.read_text(encoding="utf-8")
PATTERN=re.compile(r'\{name="([^"]+)",size=(\d+),rows=\{([^{}]+)\},fixed=\{([^{}]+)\}\}')
DIR=((0,-1),(1,0),(0,1),(-1,0))
BITS=(1,2,4,8)
OPP=(4,8,1,2)

def variants(mask:int) -> list[int]:
    out=[]
    for _ in range(4):
        if mask not in out:out.append(mask)
        mask=((mask*2)%16)+(mask//8)
    return out

def solve(w:int,base:list[int],fixed:set[int],limit:int=2):
    occ={i for i,m in enumerate(base) if m}
    nb={}
    domains={}
    for i in occ:
        x,y=i%w,i//w
        neighbors=[]
        for dx,dy in DIR:
            xx,yy=x+dx,y+dy
            j=yy*w+xx if 0<=xx<w and 0<=yy<w else -1
            neighbors.append(j if j in occ else -1)
        nb[i]=neighbors
        domains[i]=[
            m for m in variants(base[i]) if
            (i not in fixed or m==base[i]) and
            all((m&BITS[d])==0 for d,j in enumerate(neighbors) if j<0)
        ]
        if not domains[i]:return []

    def reduce(d):
        changed=True
        while changed:
            changed=False
            for i in occ:
                valid=[
                    mask for mask in d[i] if all(
                        j<0 or any(bool(mask&BITS[k])==bool(v&OPP[k]) for v in d[j])
                        for k,j in enumerate(nb[i])
                    )
                ]
                if not valid:return False
                if len(valid)<len(d[i]):d[i]=valid;changed=True
        return True

    def connected(assignment):
        start=next(iter(occ))
        seen={start}
        queue=deque([start])
        while queue:
            i=queue.popleft()
            for d,j in enumerate(nb[i]):
                if j>=0 and (assignment[i]&BITS[d]) and j not in seen:
                    seen.add(j);queue.append(j)
        return len(seen)==len(occ)

    solutions=[]
    def search(d):
        if len(solutions)>=limit or not reduce(d):return
        undecided=[i for i in occ if len(d[i])>1]
        if not undecided:
            assignment={i:d[i][0] for i in occ}
            if connected(assignment):solutions.append(assignment)
            return
        i=min(undecided,key=lambda k:(len(d[k]),-sum(j>=0 for j in nb[k])))
        for m in d[i]:
            nd={k:v[:] for k,v in d.items()}
            nd[i]=[m]
            search(nd)
            if len(solutions)>=limit:return
    search(domains)
    return solutions

def network_is_complete(w,board):
    active={i for i,m in enumerate(board) if m}
    if len(active)<2:return False
    for i,mask in enumerate(board):
        x,y=i%w,i//w
        for d,(dx,dy) in enumerate(DIR):
            xx,yy=x+dx,y+dy
            j=yy*w+xx if 0<=xx<w and 0<=yy<w else -1
            neighbor=board[j] if j>=0 else 0
            if bool(mask&BITS[d])!=bool(neighbor&OPP[d]):
                return False
    start=next(iter(active))
    seen={start};queue=[start]
    for i in queue:
        x,y=i%w,i//w
        for d,(dx,dy) in enumerate(DIR):
            if board[i]&BITS[d]:
                j=(y+dy)*w+x+dx
                if j not in seen:seen.add(j);queue.append(j)
    return seen==active

def main():
    blocks=PATTERN.findall(SRC)
    assert len(blocks)==20,f"expected 20 frozen boards; found {len(blocks)}"
    names=set()
    total=0
    for no,(name,w_str,row_chunk,fixed_chunk) in enumerate(blocks,1):
        w=int(w_str)
        assert w==(4 if no<=10 else 5),f"{no} wrong size"
        assert name not in names,f"duplicate level {name}"
        names.add(name)
        rows=re.findall(r'"([0-9A-F]+)"',row_chunk)
        anchors=re.findall(r'"([.X]+)"',fixed_chunk)
        assert len(rows)==len(anchors)==w
        assert all(len(row)==w for row in rows+anchors)
        board=[int(c,16) for row in rows for c in row]
        locked={i for i,v in enumerate(''.join(anchors)) if v=='X'}
        assert len(locked)>=2 and all(board[i] for i in locked)
        assert not network_is_complete(w,board),f"level {no} already solved"
        results=solve(w,board,locked,limit=2)
        assert len(results)==1, f"{no} {name}: {len(results)} valid solutions (expected exactly one)"
        result=[results[0].get(i,0) for i in range(w*w)]
        assert network_is_complete(w,result),f"{no} solution disconnected"
        changes=sum(a!=b for a,b in zip(board,result))
        assert changes>=4,f"{no} requires only {changes} tile changes"
        for i in locked:
            assert board[i]==result[i],f"{no} fixed tile changed"
        for i,mask in enumerate(board):
            assert result[i] in variants(mask),f"{no} solution changed tile shape"
        total+=changes
        print(f"{no:02} {name:18} {w}x{w}: {len([a for a in board if a])} tiles, {len(locked)} anchors, {changes} changes, UNIQUE")
    print(f"PASS: 20 distinct uniquely solvable connected-network puzzles ({total} required corrections)")
if __name__=="__main__":main()
