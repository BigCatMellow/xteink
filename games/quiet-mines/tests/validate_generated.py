#!/usr/bin/env python3
"""Independent check of the native randomized Minesweeper generator.

The Lua generator constructs candidate boards and checks no-guess inference.
Python receives only the published mine positions and independently replays
the complete solution from S, including subset differences, to prevent a
generator regression from marking a guess-requiring board as verified.
"""
from pathlib import Path
import subprocess
import runpy

folder=Path(__file__).resolve().parents[1]
independent=runpy.run_path(str(Path(__file__).with_name('validate_advanced.py')))
verify=independent['verify']
script=r"""
package.path='app/?.lua;'..package.path
local G=require('generator')
for d=1,3 do
  for seed=1,8 do
    local p,why=G.generate(seed*131+20261118,d)
    assert(p,why or 'no verified generated board')
    local repeatBoard=G.generate(seed*131+20261118,d)
    assert(table.concat(p.mines,',')==table.concat(repeatBoard.mines,','),'unstable generated seed')
    print(d..'\t'..seed..'\t'..p.n..'\t'..table.concat(p.mines,',')..
      '\t'..p.metrics.passes..'\t'..p.metrics.subsetMoves)
  end
end
"""
lines=subprocess.check_output(['lua','-'],cwd=folder,input=script,text=True).splitlines()
assert len(lines)==24
seen=set()
for line in lines:
    d,seed,n,positions,passes,subsets=line.split('\t')
    d,seed,n,passes,subsets=map(int,(d,seed,n,passes,subsets))
    mines={int(p)-1 for p in positions.split(',')}
    assert n==({1:8,2:10,3:12}[d])
    assert len(mines)==({1:10,2:18,3:27}[d])
    assert (n,tuple(sorted(mines))) not in seen,'Repeated generated board'
    seen.add((n,tuple(sorted(mines))))
    opening,iterations,inferred_subsets=verify(n,mines)
    assert iterations>=({1:2,2:3,3:4}[d])
    assert inferred_subsets>=({1:0,2:1,3:2}[d])
    assert passes>=iterations or passes>0
print('PASS: 24 procedurally generated Mines fields independently solved without guessing')
