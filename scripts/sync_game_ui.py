#!/usr/bin/env python3
"""Copy the canonical UI into each participating app, or --check for drift."""
import argparse
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GAMES = ('nonogram', 'sudoku', 'quiet-mines', 'lights-out', 'takuzu', 'mosaic', 'hitori', 'lantern-logic', 'crown-fields')
INACTIVE = ('summit-putt', 'ray-vault', 'island-links', 'rectangle-rooms', 'sum-cross', 'ten-pairs')
OTHER_APPS = ('wallpaper-randomizer',)
COLLECTIONS = ('games-hub',)  # Generated from GAMES; audited by check_games.py.
SHELVED = ('paper-golf',)
ARCHIVED = ('line-lift', 'oddity-hunt', 'word-hunt',
            'link-grid', 'ink-runes', 'word-bridge')  # Retired, not released.


def project_path(name, root=ROOT):
    """Locate sources without changing stable release/game keys."""
    root = Path(root)
    if name in INACTIVE:
        return root / 'games' / 'inactive' / name
    if name in ARCHIVED:
        return root / 'games' / 'archive' / name
    return root / 'games' / name if name in GAMES + COLLECTIONS + SHELVED else root / name


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    canonical = (ROOT / 'shared/game_ui.lua').read_bytes()
    bad = []
    for game in GAMES + OTHER_APPS:
        target = project_path(game) / 'app/ui.lua'
        if args.check:
            if not target.exists() or target.read_bytes() != canonical:
                bad.append(str(target.relative_to(ROOT)))
        else:
            target.write_bytes(canonical)
    # Shared engine and host checks for the three binary-mark puzzle apps.
    for game in ('takuzu', 'mosaic', 'hitori'):
        for source, dest in (
            ('shared/logic_grid.lua', 'app/index.lua'),
            ('tests/logic_grid_game.lua', 'tests/test_game.lua'),
            ('tests/validate_logic_grid.py', 'tests/validate_levels.py'),
            ('shared/procedural_puzzles.lua', 'app/procedural_puzzles.lua'),
            ('tests/logic_grid_procedural.lua', 'tests/test_procedural.lua'),
        ):
            target = project_path(game) / dest
            data = (ROOT / source).read_bytes()
            if args.check:
                if not target.exists() or target.read_bytes() != data:
                    bad.append(str(target.relative_to(ROOT)))
            else:
                target.write_bytes(data)
    if bad:
        raise SystemExit('UI copies differ; run scripts/sync_game_ui.py: ' + ', '.join(bad))
    print('Shared UI copies: ' + ('verified' if args.check else 'updated'))


if __name__ == '__main__':
    main()
