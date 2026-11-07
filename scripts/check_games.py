#!/usr/bin/env python3
"""Run game quality checks; optionally lint and build every active game."""
import argparse
import json
from pathlib import Path
import re
import subprocess
import sys

from sync_game_ui import GAMES, ROOT


def run(command, cwd=ROOT):
    subprocess.run([str(item) for item in command], cwd=cwd, check=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--packer', type=Path)
    parser.add_argument('--linter', type=Path)
    args = parser.parse_args()
    discovered = {
        manifest.parents[1].name for manifest in ROOT.glob('*/app/manifest.json')
        if manifest.parents[1].name not in {'wallpaper-randomizer', 'paper-golf'}
    }
    assert discovered == set(GAMES), f'Game registry mismatch: {discovered ^ set(GAMES)}'
    run([sys.executable, ROOT / 'scripts/sync_game_ui.py', '--check'])
    run(['lua', ROOT / 'tests/test_game_ui.lua'])
    for game in GAMES:
        folder = ROOT / game
        manifest = json.loads((folder / 'app/manifest.json').read_text())
        assert manifest['api'] == '2.0'
        for source in (folder / 'app').glob('*.lua'):
            if source.name != 'ui.lua':
                assert not re.search(r'\b\w+:text(?:_box)?\s*\(', source.read_text()), \
                    f'{source}: use the measured UI helper for text'
            if args.linter:
                run([sys.executable, args.linter.resolve(), source])
        print(f'Checking {game}', flush=True)
        run(['lua', 'tests/test_game.lua'], folder)
        for solver in ('validate_levels.py', 'check_levels.py'):
            if (folder / 'tests' / solver).exists():
                run([sys.executable, folder / 'tests' / solver])
        if args.packer:
            output = ROOT / 'dist' / f'{game}.xtapp'
            output.parent.mkdir(exist_ok=True)
            run([sys.executable, '-I', args.packer.resolve(), folder / 'app', '-o', output])
            assert output.read_bytes()[:4] == b'XTAP' and output.stat().st_size > 256
    print(f'PASS: all {len(GAMES)} active games passed the quality gate')


if __name__ == '__main__':
    main()
