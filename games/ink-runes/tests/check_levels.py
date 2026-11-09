#!/usr/bin/env python3
"""Independent exact-state solver of the 20 frozen original Ink Runes boards."""
from functools import lru_cache
from pathlib import Path
import re
SRC=Path(__file__).resolve().parents[1]/'app'/'index.lua'
PAT=re.compile(r'\{name="GLYPH (\d+)",n=(\d+),rows=\{([^{}]+)\}\}')
DIRS=((0,-1),(1,0),(0,1),(-1,0))
WORDS={'MIR','VAS','DOK'}

def neighbors(n,i):
    x,y=i%n,i//n
    for dx,dy in DIRS:
        nx,ny=x+dx,y+dy
        if 0<=nx<n and 0<=ny<n:yield ny*n+nx

def analyze(n,board):
    actions=[]
    for i,c in enumerate(board):
        if c not in 'MVD':continue
        for j in neighbors(n,i):
            for k in neighbors(n,j):
                if k==i:continue
                word=board[i]+board[j]+board[k]
                if word not in WORDS:continue
                need=(1<<i)|(1<<j)|(1<<k)
                effect=need
                if word=='VAS':
                    for q in neighbors(n,k):effect|=1<<q
                if word=='DOK':
                    for q in range(k%n,n*n,n):effect|=1<<q
                actions.append((need,effect,word))
    original=sum(1<<i for i,c in enumerate(board) if c!='.')
    @lru_cache(None)
    def search(mask):
        if not mask:return 1,0
        ways=0
        shortest=None
        for needed,effect,_ in actions:
            if (mask&needed)!=needed:continue
            count,steps=search(mask&~effect)
            if count:
                ways+=count
                newlen=steps+1
                shortest=newlen if shortest is None else min(shortest,newlen)
        return ways,shortest
    count,shortest=search(original)
    options=[(need,effect) for need,effect,_ in actions if original&need==need]
    traps=sum(search(original&~effect)[0]==0 for _,effect in options)
    return count,shortest,len(options),traps

def main():
    found=PAT.findall(SRC.read_text(encoding='utf-8'))
    assert len(found)==20,f'Expected 20 authored puzzles; found {len(found)}'
    bad=0
    for i,(serial,n,raw) in enumerate(found,1):
        n=int(n)
        assert int(serial)==i
        assert n==(4 if i<=6 else 5 if i<=13 else 6)
        rows=re.findall(r'"([.MIRVASDOK]+)"',raw)
        assert len(rows)==n and all(len(row)==n for row in rows)
        full=''.join(rows)
        assert set(full)<=set('.MIRVASDOK')
        count,steps,options,traps=analyze(n,full)
        required=1 if i<=2 else 2 if i<=6 else 3 if i<=10 else 4 if i<=13 else 5 if i<=16 else 6
        assert count>0 and steps>=required,f'Level {i} not solvable to depth {required}'
        assert options>0
        if i>=3:
            assert traps>=1,f'Level {i} lacks a meaningful first-move trap'
            bad+=1
        print(f'{i:02} {n}x{n}: minimum {steps} words, {options} first moves, {traps} traps')
    assert bad==18
    print('PASS: all 20 solvable; 18 have meaningful dead-end openings')

if __name__=='__main__':main()
