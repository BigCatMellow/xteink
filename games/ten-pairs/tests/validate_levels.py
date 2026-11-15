#!/usr/bin/env python3
"""Exact DP: each 32-digit starting grid has a complete pair-removal route.

Noncrossing matching orders represent sequentially clearing inner digits first;
when an outer pair is reached, intermediate positions are blank, making the
pair legal in the game's reading-order rule. No solution fixture is in the app.
"""
import re
from functools import lru_cache
from pathlib import Path
s=(Path(__file__).resolve().parents[1]/'app'/'boards.lua').read_text()
boards=re.findall(r'digits="([1-9]+)"',s)
assert len(boards)==12
for level,digits in enumerate(boards,1):
 assert len(digits)==32
 @lru_cache(None)
 def clear(a,b):
  if a>b:return ()
  for j in range(a+1,b+1,2):
   x,y=int(digits[a]),int(digits[j])
   if x!=y and x+y!=10:continue
   inside=clear(a+1,j-1)
   outside=clear(j+1,b)
   if inside is not None and outside is not None:
    return inside+((a,j),)+outside
  return None
 sequence=clear(0,31)
 assert sequence is not None and len(sequence)==16, f'Level {level}: no complete sequence'
 live=set(range(32))
 for a,b in sequence:
  assert a in live and b in live
  assert all(p not in live for p in range(a+1,b)),f'Level {level}: witness violates reading-order rule'
  live.remove(a);live.remove(b)
 assert not live
 assert sum(b==a+1 for a,b in sequence)>=3
 print(f'{level:02}: 32 digits / 16 removable pairs, exact DP clearable')
print('PASS: all 12 Ten Pairs sheets clear completely without ADD')
