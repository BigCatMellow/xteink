#!/usr/bin/env python3
"""Ship the canonical theme and licensed font pack in every active game."""
import argparse
from sync_game_ui import GAMES, ROOT, project_path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    sources = {
        'theme.lua': ROOT/'shared/game_theme.lua',
        'game_style.lua': ROOT/'shared/game_style.lua',
        'typefaces.lua': ROOT/'shared/typefaces.lua',
        'font_data.lua': ROOT/'shared/font_data.lua',
        'font_license.lua': ROOT/'shared/font_license.lua',
    }
    for game in GAMES:
        for name, source in sources.items():
            target = project_path(game) /'app'/name
            if target == source:
                continue
            if args.check:
                assert target.read_bytes() == source.read_bytes(), f'{game}/{name}: sync_game_theme.py'
            else:
                target.write_bytes(source.read_bytes())
    print('Shared game theme and font copies: ' + ('verified' if args.check else 'updated'))


if __name__ == '__main__':
    main()
