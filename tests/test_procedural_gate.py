"""Regression for the mandatory generation release guard."""
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'scripts'))
import procedural_gate as gate

class ProceduralGate(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root=Path(self.temp.name)

    def test_new_game_cannot_bypass_procedural_acceptance(self):
        with self.assertRaisesRegex(AssertionError,'procedural acceptance regression missing'):
            gate.verify(('future-game',), self.root)
        # The gate checks coverage, not the content of a test. check_games
        # executes it against standalone and hosted engines.
        path=self.root/'future-game/tests/test_procedural.lua'
        path.parent.mkdir(parents=True)
        path.write_text('assert(true)')
        self.assertEqual(gate.verify(('future-game',),self.root,strict=True),{})

    def test_named_migration_is_not_release_exemption(self):
        self.assertIn('crown-fields',gate.verify(('crown-fields',),self.root))
        with self.assertRaisesRegex(ValueError,'Procedural release gate blocked'):
            gate.verify(('crown-fields',),self.root,strict=True)

    def test_existing_regression_cannot_disappear(self):
        with self.assertRaisesRegex(AssertionError,'missing established generator regression'):
            gate.verify(('nonogram',),self.root,strict=True)

if __name__=='__main__':unittest.main()
