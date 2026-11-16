#!/usr/bin/env python3
"""Build an SD-card-ready, uncompressed StarDict English Wiktionary package.

Source is the XTEINK-targeted Wiktionary StarDict build from sd-plugins.
The source checksums are pinned to its 2026-11-01 release assets so updates
cannot silently substitute a different index for its dictionary payload.
"""
from __future__ import annotations

import argparse
import gzip
import hashlib
import shutil
import struct
import tempfile
import zipfile
from pathlib import Path

SOURCES = {
    "english.ifo": "5f3f992face79ad1a90793a219ac7a15040da592843a0451ec8dd838e5761c1d",
    "english.idx": "b72e56b0fcb52c338efe9e8fcf49271b9ddc33befc8ca4120a4eb405a75049ec",
    "english.dict.dz": "9177af23eaa354d1fb258c4832127070b2bf7a6adabb5d1bb9863900148b76f3",
}
SOURCE_URL = "https://github.com/itsthisjustin/sd-plugins/releases/tag/dictionaries"
LICENSE_NOTE = """ENGLISH WIKTIONARY — attribution and licensing

Dictionary content derives from the English Wiktionary community:
https://en.wiktionary.org/
Machine-readable extraction: https://kaikki.org/dictionary/English/
StarDict transformation/distribution: https://github.com/itsthisjustin/sd-plugins
Source release: https://github.com/itsthisjustin/sd-plugins/releases/tag/dictionaries

English Wiktionary text is available under CC BY-SA and the GNU Free
Documentation License. The source project's Wiktionary mirror is dual-licensed.
Consult the licensing notices of Wiktionary and the source distribution:
https://creativecommons.org/licenses/by-sa/4.0/
https://www.gnu.org/licenses/fdl-1.3.en.html
https://en.wiktionary.org/wiki/Wiktionary:Copyrights

This repackage changes only the compression/container of the StarDict data:
its original .ifo and .idx are retained, and .dict.dz is decompressed to .dict.
No definitions, entry offsets, or headwords are intentionally altered.
"""


def digest(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            h.update(block)
    return h.hexdigest()


def read_metadata(path: Path) -> dict[str, str]:
    info = {}
    data = path.read_text(encoding="utf-8-sig")
    assert data.startswith("StarDict's dict ifo file"), "Missing StarDict IFO header"
    for line in data.splitlines()[1:]:
        if "=" in line:
            k, v = line.split("=", 1)
            info[k] = v
    if info.get("idxoffsetbits", "32") != "32":
        raise ValueError("XTEINK requires 32-bit StarDict index offsets")
    return info


def validate_idx(path: Path, dict_size: int, metadata: dict[str, str]) -> tuple[int, set[str]]:
    buf = path.read_bytes()
    if int(metadata.get("idxfilesize", len(buf))) != len(buf):
        raise ValueError("StarDict IFO idxfilesize does not match index")
    pos = 0
    count = 0
    seen = set()
    sample_words = {"book", "read", "water", "serendipity"}
    while pos < len(buf):
        end = buf.find(b"\0", pos)
        if end < 0 or end + 9 > len(buf):
            raise ValueError(f"Truncated StarDict index entry at offset {pos}")
        word = buf[pos:end].decode("utf-8")
        if not word:
            raise ValueError("Empty StarDict headword")
        offset, length = struct.unpack_from(">II", buf, end + 1)
        if length == 0 or offset + length > dict_size:
            raise ValueError(f"Invalid definition offset/size at {word!r}")
        if word.casefold() in sample_words:
            seen.add(word.casefold())
        pos = end + 9
        count += 1
    if int(metadata.get("wordcount", count)) != count:
        raise ValueError(f"IFO wordcount mismatch: {metadata['wordcount']} != {count}")
    if count < 1:
        raise ValueError("StarDict index contains no entries")
    return count, seen


def build(source_dir: Path, output: Path, skip_checksums: bool = False) -> tuple[int, int]:
    for filename, expected in SOURCES.items():
        src = source_dir / filename
        if not src.is_file():
            raise FileNotFoundError(src)
        if not skip_checksums and digest(src) != expected:
            raise ValueError(f"Source checksum mismatch: {filename}; obtain matching assets from {SOURCE_URL}")
    metadata = read_metadata(source_dir / "english.ifo")
    output.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp:
        raw_dict = Path(tmp) / "english.dict"
        with gzip.open(source_dir / "english.dict.dz", "rb") as src, raw_dict.open("wb") as dst:
            shutil.copyfileobj(src, dst, 1024 * 1024)
        dict_size = raw_dict.stat().st_size
        count, samples = validate_idx(source_dir / "english.idx", dict_size, metadata)
        if not skip_checksums and not {"book", "read", "water"}.issubset(samples):
            raise ValueError(f"Expected English lookup samples are missing: {samples}")
        root = "dictionaries/wiktionary-en/"
        with zipfile.ZipFile(output, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=6, allowZip64=True) as z:
            z.write(source_dir / "english.ifo", root + "english.ifo")
            z.write(source_dir / "english.idx", root + "english.idx")
            z.write(raw_dict, root + "english.dict")
            z.writestr(root + "ATTRIBUTION.txt", LICENSE_NOTE)
        with zipfile.ZipFile(output) as z:
            for name in ("english.ifo", "english.idx", "english.dict", "ATTRIBUTION.txt"):
                expected_path = root + name
                assert z.getinfo(expected_path).file_size > 0, expected_path
            bad = z.testzip()
            if bad:
                raise ValueError(f"Corrupt ZIP entry: {bad}")
    print(f"Validated {count:,} entries, {dict_size:,} definition bytes; ZIP: {output} ({output.stat().st_size:,} bytes)")
    print(f"Present example headwords: {', '.join(sorted(samples))}")
    print(f"SHA256 ZIP: {digest(output)}")
    return count, dict_size


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, required=True, help="Folder with english.ifo, english.idx, english.dict.dz")
    parser.add_argument("--output", type=Path, default=Path("dist/wiktionary-en-xteink.zip"))
    parser.add_argument("--skip-checksums", action="store_true", help="For unit-test fixtures only")
    args = parser.parse_args()
    build(args.source, args.output, skip_checksums=args.skip_checksums)


if __name__ == "__main__":
    main()
