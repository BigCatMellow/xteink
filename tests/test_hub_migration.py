"""Check USB snapshots against a fake card; never touches a mounted card."""
import json
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'scripts'))
from install_games_hub import snapshot, encode


class Migration(unittest.TestCase):
    def test_equal_size_saves_cannot_trigger_packer_record_filter(self):
        records = {f'nonogram--board-{i:03}.txt': b'same size' for i in range(100)}
        lines = encode(records).decode().splitlines()
        self.assertEqual(lines[0], 'HUBSAVES1')
        self.assertEqual(len({len(line) for line in lines}), len(lines))
        decoded = {}
        for line in lines[1:]:
            key, count, payload = line.split('\t')
            value = bytes.fromhex(payload)
            self.assertEqual(int(count), len(value))
            decoded[key] = value
        self.assertEqual(decoded, records)

    def test_snapshot_is_strict_and_read_only(self):
        with tempfile.TemporaryDirectory() as temp:
            card = Path(temp)
            (card / 'Apps').mkdir()
            folder = card / 'XTApps/nonogram/files'
            folder.mkdir(parents=True)
            original = b'progress\x00\xff\n'
            (folder / 'nonogram.txt').write_bytes(original)
            unknown = card / 'XTApps/unrelated/files'
            unknown.mkdir(parents=True)
            (unknown / 'secret.txt').write_text('leave alone')
            records, originals = snapshot(card)
            self.assertEqual(records, {'nonogram--nonogram.txt': original})
            self.assertEqual(encode(records), b'HUBSAVES1\nnonogram--nonogram.txt\t11\t70726f677265737300ff0a\n')
            self.assertEqual((folder / 'nonogram.txt').read_bytes(), original)
            self.assertFalse((card / 'XTApps/gameshub').exists())
            (folder / 'nested').mkdir()
            with self.assertRaises(AssertionError):
                snapshot(card)
            (folder / 'nested').rmdir()
            (folder / 'link.txt').symlink_to(folder / 'nonogram.txt')
            with self.assertRaises(AssertionError):
                snapshot(card)


if __name__ == '__main__':
    unittest.main()
