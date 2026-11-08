#!/usr/bin/env python3
"""Run game quality checks; optionally lint and build every active game."""
import argparse
import json
from pathlib import Path
import re
import subprocess
import sys

from sync_game_ui import GAMES, COLLECTIONS, ROOT
from verify_package_icons import verify_icon


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
    assert discovered == set(GAMES + COLLECTIONS), f'Game registry mismatch: {discovered ^ set(GAMES + COLLECTIONS)}'
    run([sys.executable, ROOT / 'scripts/sync_game_ui.py', '--check'])
    run([sys.executable, ROOT / 'scripts/sync_puzzle_store.py', '--check'])
    run([sys.executable, ROOT / 'scripts/sync_game_theme.py', '--check'])
    run([sys.executable, ROOT / 'scripts/make_icons.py', '--check'])
    run([sys.executable, ROOT / 'scripts/build_game_hub.py', '--check'])
    run([sys.executable, ROOT / 'tests/test_hub_migration.py'])
    run([sys.executable, ROOT / 'tests/test_installed_updates.py'])
    run([sys.executable, ROOT / 'tests/test_release_games.py'])
    run(['lua', ROOT / 'tests/test_game_hub.lua'])
    run(['lua', ROOT / 'tests/test_game_ui.lua'])
    run(['lua', ROOT / 'tests/test_puzzle_store.lua'])
    run(['lua', ROOT / 'tests/test_game_theme.lua'])
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
        run(['lua', ROOT/'tests/run_themed_game.lua'], folder)
        run(['lua', ROOT/'tests/run_hub_game.lua'], folder)
        run(['lua', ROOT/'tests/run_hub_game.lua', '--bitmap'], folder)
        if (folder / 'tests/test_fonts.lua').exists():
            run(['lua', 'tests/test_fonts.lua'], folder)
        if (folder / 'tests/validate_fonts.py').exists():
            run([sys.executable, folder / 'tests/validate_fonts.py'])
        for solver in ('validate_levels.py', 'check_levels.py'):
            if (folder / 'tests' / solver).exists():
                run([sys.executable, folder / 'tests' / solver])
        if args.packer:
            output = ROOT / 'dist' / f'{game}.xtapp'
            output.parent.mkdir(exist_ok=True)
            # Use the same environment that passed the Pillow/icon checks.
            # -I suppresses user-site dependencies on GitHub's Python image.
            run([sys.executable, args.packer.resolve(), folder / 'app', '-o', output])
            assert output.read_bytes()[:4] == b'XTAP' and output.stat().st_size > 256
            verify_icon(output, folder / 'app/icon.png')
    for collection in COLLECTIONS:
        app = ROOT / collection / 'app'
        for source in app.glob('*.lua'):
            if args.linter:
                run([sys.executable, args.linter.resolve(), source])
        if args.packer:
            output = ROOT / 'dist' / f'{collection}.xtapp'
            run([sys.executable, args.packer.resolve(), app, '-o', output])
            verify_icon(output, app / 'icon.png')
    print(f'PASS: all {len(GAMES)} active games passed the quality gate')


if __name__ == '__main__':
    main()
