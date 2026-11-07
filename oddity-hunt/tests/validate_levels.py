#!/usr/bin/env python3
"""Independently validate all authored Oddity Hunt scene seeds and touch geometry.

Reproduce the game's deterministic scatter without executing Lua. It checks
42 distinct items, five findable targets with no lookalike duplicates, all
twenty icon types present, artwork within its frame and non-overlapping taps.
"""
import re
from pathlib import Path
SRC=(Path(__file__).resolve().parents[1]/'app'/'scenes.lua').read_text(encoding='utf-8')
ICON=(Path(__file__).resolve().parents[1]/'app'/'art.lua').read_text(encoding='utf-8')
matches=re.findall(r"\{name='([^']+)',targets=\{([^{}]+)\},slots=\{([^{}]+)\},seed=(\d+)\}",SRC)
assert len(matches)==12,f'expected 12 authored scenes, found {len(matches)}'
assert len(re.findall(r'elseif kind==\d+ then|if kind==\d+ then',ICON))==20, 'missing a custom line-art object'
types=re.search(r'M\.KINDS=\{(.*?)\}',SRC,re.S).group(1)
names=re.findall(r"'([A-Z]+)'",types)
assert len(names)==20 and len(set(names))==20, 'twenty unique object names'
seen_seeds=set()
seen_names=set()
for level,(name,t,s,seedstr) in enumerate(matches,1):
    assert name not in seen_names
    seen_names.add(name)
    kinds=list(map(int,t.split(',')))
    targetslots=list(map(int,s.split(',')))
    seed=int(seedstr)
    assert seed not in seen_seeds
    seen_seeds.add(seed)
    assert len(kinds)==len(targetslots)==5
    assert len(set(kinds))==5 and len(set(targetslots))==5
    assert all(1<=k<=20 for k in kinds)
    assert all(1<=p<=42 for p in targetslots)
    reserve=set(kinds)
    filler=[k for k in range(1,21) if k not in reserve]
    value=[seed]
    def draw(n):
        value[0]=(value[0]*48271)%2147483647
        return value[0]%n+1
    pool=[filler[i%len(filler)] for i in range(37)]
    for i in range(37,1,-1):
        j=draw(i)-1
        pool[i-1],pool[j]=pool[j],pool[i-1]
    targets_at={slot:i+1 for i,slot in enumerate(targetslots)}
    objects=[]
    di=0
    for slot in range(1,43):
        col=(slot-1)%7
        row=(slot-1)//7
        jx,jy=draw(15),draw(15)
        tidx=targets_at.get(slot,0)
        kind=kinds[tidx-1] if tidx else pool[di]
        if not tidx:di+=1
        x=50+col*62+jx-8
        y=169+row*70+jy-8
        assert 42<=x<=430 and 161<=y<=527
        # A maximum 23px radius must remain inside the board frame.
        assert 18<=x-23 and x+23<=462, (level,slot,'art x outside frame')
        assert 137<=y-23 and y+23<=551, (level,slot,'art y outside frame')
        objects.append((x,y,kind,tidx))
    assert di==37
    assert len(set(k for x,y,k,t in objects))==20, f'{name} lacks visual variety'
    for idx,(x,y,kind,target) in enumerate(objects):
        if target:
            assert kind==kinds[target-1]
        else:
            assert kind not in reserve,f'{name} duplicates a target visually'
        for xx,yy,_,__ in objects[idx+1:]:
            assert (x-xx)**2+(y-yy)**2>=48**2, f'{name} overlapping touch areas'
    for target in range(1,6):
        assert sum(o[3]==target for o in objects)==1,f'{name} target {target} not unique'
    rows={i//7 for i,obj in enumerate(objects) if obj[3]>0}
    assert len(rows)>=4,f'{name} target concentration too high'
    print(f'{level:02} {name:17} 42 objects; 5 unique targets, {len(rows)} shelf rows, no collisions')
print('PASS: 12 authored illustrations, 504 icons, 60 uniquely identifiable finds')
