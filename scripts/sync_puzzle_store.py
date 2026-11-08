#!/usr/bin/env python3
"""Synchronize the numbered-puzzle store into apps that generate puzzles."""
import argparse
from sync_game_ui import ROOT

APPS = ('word-hunt', 'nonogram', 'sudoku')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    canonical = (ROOT / 'shared/puzzle_store.lua').read_bytes()
    for app in APPS:
        target = ROOT / app / 'app/puzzle_store.lua'
        if args.check:
            assert target.read_bytes() == canonical, f'{app}: run scripts/sync_puzzle_store.py'
        else:
            target.write_bytes(canonical)
    print('Puzzle store copies: ' + ('verified' if args.check else 'updated'))


if __name__ == '__main__':
    main()
