#!/usr/bin/env python3
"""Copy the canonical UI into each participating app, or --check for drift."""
import argparse
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GAMES = ('line-lift', 'summit-putt', 'link-grid', 'ink-runes',
         'lantern-logic', 'ray-vault', 'island-links', 'oddity-hunt', 'word-hunt', 'nonogram', 'word-bridge', 'rectangle-rooms', 'sudoku',
         'crown-fields', 'ten-pairs', 'quiet-mines', 'sum-cross')
OTHER_APPS = ('wallpaper-randomizer',)
COLLECTIONS = ('games-hub',)  # Generated from GAMES; audited by check_games.py.
SHELVED = ('paper-golf',)


def project_path(name, root=ROOT):
    """Locate sources without changing stable release/game keys."""
    root = Path(root)
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
    if bad:
        raise SystemExit('UI copies differ; run scripts/sync_game_ui.py: ' + ', '.join(bad))
    print('Shared UI copies: ' + ('verified' if args.check else 'updated'))


if __name__ == '__main__':
    main()
