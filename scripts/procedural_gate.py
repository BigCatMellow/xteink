"""Procedural acceptance coverage and strict family release guard.

The small migration list is intentionally explicit and closed to new games.
It permits development checks only, not releases.
"""
from pathlib import Path

from sync_game_ui import GAMES, ROOT, project_path

# Existing end-to-end generator/save regressions run in test_game.lua and
# have independent generator evidence documented in REASONING_AUDIT.md.
ESTABLISHED = frozenset(('nonogram', 'sudoku', 'quiet-mines'))

MIGRATION_GAPS = {
}

def verify(games=GAMES, root=ROOT, strict=False):
    """Require explicit coverage, reject pending migration for releases."""
    root=Path(root)
    assert not (set(ESTABLISHED) & set(MIGRATION_GAPS)), 'Conflicting procedural states'
    pending={}
    for game in games:
        folder=project_path(game, root)
        if game in MIGRATION_GAPS:
            pending[game]=MIGRATION_GAPS[game]
        elif game in ESTABLISHED:
            assert (folder/'tests/test_game.lua').is_file(), f'{game}: missing established generator regression'
        else:
            assert (folder/'tests/test_procedural.lua').is_file(), (
                f'{game}: procedural acceptance regression missing; add tests/test_procedural.lua'
            )
    if pending:
        report='; '.join(f'{game}: {reason}' for game,reason in pending.items())
        if strict:
            raise ValueError('Procedural release gate blocked: '+report)
        print('PROCEDURAL RELEASE BLOCKED (development only): '+report, flush=True)
    else:
        print('Procedural acceptance coverage: complete', flush=True)
    return pending
