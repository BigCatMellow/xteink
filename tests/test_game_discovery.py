"""Ensure new or misplaced projects cannot silently bypass the game gate."""
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'scripts'))
from check_games import verify_project_layout
from sync_game_ui import GAMES, COLLECTIONS, OTHER_APPS, SHELVED


class Discovery(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        for name in GAMES + COLLECTIONS + SHELVED:
            self.app(Path('games') / name)
        for name in OTHER_APPS:
            self.app(Path(name))

    def app(self, relative):
        path = self.root / relative / 'app/manifest.json'
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text('{}')

    def test_registered_layout_and_shelved_game(self):
        verify_project_layout(self.root)

    def test_new_upstream_game_at_root_is_rejected(self):
        self.app(Path('new-upstream-game'))
        with self.assertRaisesRegex(AssertionError, 'Move games into games/'):
            verify_project_layout(self.root)

    def test_unregistered_game_in_games_is_rejected(self):
        self.app(Path('games/new-upstream-game'))
        with self.assertRaisesRegex(AssertionError, 'Game registry mismatch'):
            verify_project_layout(self.root)

    def test_utility_is_not_silently_exempted_inside_games(self):
        self.app(Path('games') / OTHER_APPS[0])
        with self.assertRaisesRegex(AssertionError, 'Game registry mismatch'):
            verify_project_layout(self.root)

    def test_shelved_game_at_root_is_rejected(self):
        self.app(Path(SHELVED[0]))
        with self.assertRaisesRegex(AssertionError, 'Root app registry mismatch'):
            verify_project_layout(self.root)

    def test_missing_registered_game_is_rejected(self):
        (self.root / 'games' / GAMES[0] / 'app/manifest.json').unlink()
        with self.assertRaisesRegex(AssertionError, 'Game registry mismatch'):
            verify_project_layout(self.root)


if __name__ == '__main__':
    unittest.main()
