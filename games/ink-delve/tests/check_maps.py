#!/usr/bin/env python3
"""Validate that each Ink Delve map fits and exposes every playable tile."""
import ast
from collections import deque
from pathlib import Path
import re

SOURCE = Path(__file__).resolve().parents[1] / 'prototype' / 'index.html'
match = re.search(r'const MAPS=(\[.*?\]);\s*const NAMES=', SOURCE.read_text(), re.S)
assert match, 'Map array missing or renamed'
maps = ast.literal_eval(match.group(1))
assert len(maps) == 6, 'Expected six authored floors'
for number, board in enumerate(maps, 1):
    assert len(board) == 9 and all(len(row) == 9 for row in board), number
    for symbol in ('S', 'K', 'E'):
        assert sum(row.count(symbol) for row in board) == 1, (number, symbol)
    assert all(set(row) <= set('#.SGMKEH') for row in board), number
    start = next((x, y) for y, row in enumerate(board)
                 for x, ch in enumerate(row) if ch == 'S')
    queue = deque([start])
    seen = {start}
    while queue:
        x, y = queue.popleft()
        for dx, dy in ((0, 1), (1, 0), (0, -1), (-1, 0)):
            nx, ny = x + dx, y + dy
            if 0 <= nx < 9 and 0 <= ny < 9 and board[ny][nx] != '#' and (nx, ny) not in seen:
                seen.add((nx, ny))
                queue.append((nx, ny))
    open_tiles = {(x, y) for y, row in enumerate(board)
                  for x, ch in enumerate(row) if ch != '#'}
    assert seen == open_tiles, f'Floor {number} has unreachable tiles: {open_tiles - seen}'
print('PASS: six 9x9 authored floors, valid symbols, reachable key, exit, encounters and loot')
