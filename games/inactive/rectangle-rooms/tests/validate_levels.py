#!/usr/bin/env python3
"""Independent exact-cover solver for twelve original Rectangle Rooms boards.

Each valid rectangle has a single numbered clue and an area equal to that
clue. Solutions must partition every cell with no overlap. Reject zero or
multiple solutions; also require multiple plausible shapes at some clues.
"""
from pathlib import Path
import re

source=(Path(__file__).resolve().parents[1]/'app'/'puzzles.lua').read_text()
pattern=re.compile(r'\{name="([A-Z ]+)",rows=\{([^{}]+)\}\}')
puzzles=pattern.findall(source)
assert len(puzzles)==12, f'Expected 12 puzzles, found {len(puzzles)}'

def solve(rows,cap=2):
    n=len(rows)
    numbers={(x,y):int(rows[y][x],36) for y in range(n)
             for x in range(n) if rows[y][x]!='.'}
    choices=[]
    options=[[] for _ in range(n*n)]
    for index,((cx,cy),area) in enumerate(numbers.items()):
        matches=[]
        for width in range(1,n+1):
            if area%width:continue
            height=area//width
            if height>n:continue
            for x in range(max(0,cx-width+1),min(cx,n-width)+1):
                for y in range(max(0,cy-height+1),min(cy,n-height)+1):
                    if any((x<=other_x<x+width and y<=other_y<y+height)
                           for (other_x,other_y) in numbers if (other_x,other_y)!=(cx,cy)):
                        continue
                    mask=sum(1<<(j*n+i) for j in range(y,y+height) for i in range(x,x+width))
                    matches.append((index,mask,(x,y,width,height)))
        if not matches:return [],0
        choices.append(matches)
        for item in matches:
            for cell in range(n*n):
                if (item[1]>>cell)&1:options[cell].append(item)
    answers=[]
    universe=(1<<(n*n))-1
    def search(occupied,clues_used,solution):
        if len(answers)>=cap:return
        if occupied==universe:
            if len(clues_used)==len(numbers):answers.append(list(solution))
            return
        best=None
        for cell in range(n*n):
            if occupied>>cell&1:continue
            available=[option for option in options[cell]
                       if option[0] not in clues_used and not option[1]&occupied]
            if not available:return
            if best is None or len(available)<len(best):
                best=available
                if len(available)==1:break
        for number,mask,rect in best:
            search(occupied|mask,clues_used|{number},solution+[rect])
            if len(answers)>=cap:return
    search(0,set(),[])
    ambiguous=sum(len(choices[i])>1 for i in range(len(choices)))
    return answers,ambiguous

names=set()
for level,(name,raw) in enumerate(puzzles,1):
    rows=re.findall(r'"([.0-9A-Z]+)"',raw)
    size=5 if level<=4 else 6 if level<=8 else 7
    assert len(rows)==size and all(len(row)==size for row in rows)
    assert name not in names
    names.add(name)
    numbers=[int(ch,36) for row in rows for ch in row if ch!='.']
    assert 5<=len(numbers)<=11 and sum(numbers)==size*size
    assert all(2<=v<=size*size for v in numbers)
    answers,ambiguous=solve(rows,cap=2)
    assert len(answers)==1, f'Level {level} has {len(answers)} valid partitions, expected 1'
    assert ambiguous>=3, f'Level {level} lacks meaningful geometric choices'
    print(f'{level:02} {name:14} {size}x{size}: {len(numbers)} clues, {ambiguous} ambiguous areas, UNIQUE')
print('PASS: all 12 Rectangle Rooms puzzles have exactly one partition')
