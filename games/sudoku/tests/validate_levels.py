#!/usr/bin/env python3
"""Validate generated Lua puzzles with a separate Python constraint solver."""
from pathlib import Path
import subprocess


def count_solutions(text):
    board = [int(c) for c in text]
    units = [[r*9+c for c in range(9)] for r in range(9)]
    units += [[r*9+c for r in range(9)] for c in range(9)]
    units += [[(br+r)*9+bc+c for r in range(3) for c in range(3)]
              for br in (0, 3, 6) for bc in (0, 3, 6)]
    for unit in units:
        filled = [board[i] for i in unit if board[i]]
        if len(filled) != len(set(filled)):
            return 0
    peers = [set().union(*(set(u) for u in units if i in u)) - {i} for i in range(81)]
    answers = []

    def search():
        if len(answers) >= 2:
            return
        best = None
        choices = set(range(1, 10))
        for i, val in enumerate(board):
            if val:
                continue
            available = set(range(1, 10)) - {board[j] for j in peers[i]}
            if not available:
                return
            if best is None or len(available) < len(choices):
                best, choices = i, available
        if best is None:
            answers.append(''.join(map(str, board)))
            return
        for value in choices:
            board[best] = value
            search()
            board[best] = 0
            if len(answers) >= 2:
                return
    search()
    return answers


script = r"""
package.path='app/?.lua;'..package.path
local G=require('generator')
local blank={};for i=1,81 do blank[i]=0 end
for i=1,8 do blank[i]=i end;blank[18]=9
assert(G.count(blank)==0,'a dead cell is a contradiction, not a solution')
blank[1]=9;blank[2]=9;assert(G.count(blank)==0,'duplicate givens rejected')
for i=1,81 do blank[i]=0 end
assert(G.count(blank,1)==-1,'budget exhaustion is not uniqueness')
for d=1,3 do
  for seed=1,24 do
    local p=G.generate(seed,d)
    local again=G.generate(seed,d)
    assert(table.concat(p.given)==table.concat(again.given),'stable seed')
    print(d..'\t'..seed..'\t'..table.concat(p.given)..'\t'..table.concat(p.solution))
  end
  local p=G.generate(999999999,d)
  print(d..'\t999999999\t'..table.concat(p.given)..'\t'..table.concat(p.solution))
end
"""
output = subprocess.check_output(['lua', '-'], input=script, text=True,
    cwd=Path(__file__).resolve().parents[1])
seen = set()
for line in output.splitlines():
    difficulty, seed, given, solution = line.split('\t')
    assert len(given) == len(solution) == 81
    assert given not in seen, 'duplicate grid within sample'
    seen.add(given)
    clues = sum(c != '0' for c in given)
    assert (45, 36, 30)[int(difficulty)-1] <= clues < 60
    assert count_solutions(given) == [solution], (difficulty, seed, 'not uniquely solvable')
    assert all(g == '0' or g == s for g, s in zip(given, solution))
print('PASS: 75 generated Sudoku puzzles independently solved; stable seeds, unique solutions, valid givens')
