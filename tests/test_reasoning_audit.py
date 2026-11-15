#!/usr/bin/env python3
"""Prevent undocumented low-depth games from returning to the active family.

This is *audit coverage*, not a human difficulty certification.
"""
from pathlib import Path
import json
import re
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
from sync_game_ui import GAMES, ARCHIVED, project_path


class ChallengeAudit(unittest.TestCase):
    def test_all_active_games_have_difficulty_audit(self):
        doc = (ROOT / "games/REASONING_AUDIT.md").read_text()
        self.assertIn(f"## Retained: {len(GAMES)} games", doc)
        for slug in GAMES:
            meta = json.loads((project_path(slug) / "app/manifest.json").read_text())
            title = meta["display_name"]
            row = re.search(r"^\|\s*" + re.escape(title) + r"\s*(?:\([^|]*\))?\s*\|", doc, re.M)
            self.assertIsNotNone(row, f"Active game lacks evidence row: {slug} ({title})")

    def test_all_archives_are_preserved_with_reasons(self):
        for slug in ARCHIVED:
            folder = ROOT / "games/archive" / slug
            self.assertTrue((folder / "app/manifest.json").is_file(), slug)
            self.assertTrue((folder / "icon.svg").is_file(), slug)
            self.assertTrue((folder / "build-workflow.yml").is_file(), slug)
            note = (folder / "ARCHIVED.md").read_text()
            self.assertGreater(len(note), 200, slug)
            self.assertFalse((ROOT / "games" / slug / "app/manifest.json").exists(), slug)

    def test_hub_only_lists_active_games(self):
        text = (ROOT / "games/games-hub/app/catalogue.lua").read_text()
        app_ids = re.findall(r'\{id="([a-z]+)"', text)
        expected = [
            json.loads((project_path(slug) / "app/manifest.json").read_text())["app_id"]
            for slug in GAMES
        ]
        self.assertEqual(app_ids, expected)
        for slug in ARCHIVED:
            meta = json.loads((project_path(slug) / "app/manifest.json").read_text())
            self.assertNotIn(meta["app_id"], app_ids)


if __name__ == "__main__":
    unittest.main()
