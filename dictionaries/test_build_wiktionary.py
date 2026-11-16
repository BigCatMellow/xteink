import gzip
import struct
import tempfile
import unittest
import zipfile
from pathlib import Path

from build_wiktionary import build


class StarDictBuildTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        entries = [("book", b"a printed work"), ("read", b"to understand text"), ("water", b"a liquid")]
        data, idx = bytearray(), bytearray()
        for word, definition in entries:
            idx += word.encode("utf-8") + b"\x00" + struct.pack(">II", len(data), len(definition))
            data += definition
        self.data = bytes(data)
        self.idx = bytes(idx)
        self.source = self.root / "sources"
        self.source.mkdir()
        (self.source / "english.idx").write_bytes(self.idx)
        (self.source / "english.dict.dz").write_bytes(gzip.compress(self.data))
        (self.source / "english.ifo").write_text(
            "StarDict's dict ifo file\nversion=2.4.2\nwordcount=3\nidxfilesize=" + str(len(idx)) + "\nsametypesequence=m\n"
        )

    def test_package_structure_and_entries(self):
        zip_path = self.root / "wiktionary.zip"
        count, size = build(self.source, zip_path, skip_checksums=True)
        self.assertEqual((count, size), (3, len(self.data)))
        with zipfile.ZipFile(zip_path) as z:
            root = "dictionaries/wiktionary-en/"
            self.assertEqual(z.read(root + "english.dict"), self.data)
            self.assertEqual(z.read(root + "english.idx"), self.idx)
            self.assertIn("Wiktionary", z.read(root + "ATTRIBUTION.txt").decode())
            self.assertIsNone(z.testzip())

    def test_bad_index_offset_rejected(self):
        idx = bytearray(self.idx)
        idx[5:9] = struct.pack(">I", 99_999)
        (self.source / "english.idx").write_bytes(idx)
        with self.assertRaisesRegex(ValueError, "Invalid definition offset"):
            build(self.source, self.root / "bad.zip", skip_checksums=True)

    def test_bad_wordcount_rejected(self):
        path = self.source / "english.ifo"
        path.write_text(path.read_text().replace("wordcount=3", "wordcount=7"))
        with self.assertRaisesRegex(ValueError, "wordcount mismatch"):
            build(self.source, self.root / "bad.zip", skip_checksums=True)

    def test_64_bit_index_rejected(self):
        path = self.source / "english.ifo"
        path.write_text(path.read_text() + "idxoffsetbits=64\n")
        with self.assertRaisesRegex(ValueError, "32-bit"):
            build(self.source, self.root / "bad.zip", skip_checksums=True)

    def test_source_checksum_verification(self):
        with self.assertRaisesRegex(ValueError, "Source checksum mismatch"):
            build(self.source, self.root / "bad.zip", skip_checksums=False)


if __name__ == "__main__":
    unittest.main()
