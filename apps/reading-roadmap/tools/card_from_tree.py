#!/usr/bin/env python3
"""Check the roadmap's books against an SD-card directory tree, and read reader titles.

  python3 card_from_tree.py TREE.md                     every listed file present? (near matches if not)
  python3 card_from_tree.py TREE.md --card /media/…/CARD --titles-json data/reader-titles.json
                                                        read each EPUB/MOBI's metadata title (what the
                                                        stock reader reports), for build_catalog.py
  python3 card_from_tree.py TREE.md --card … --predict OUT.lua     fixture for tests/predict.lua

TREE.md is the markdown tree written at the card's Books/ root (``Books/`` then ├──/└── lines).
The reader API cannot list SD files, so the baked paths are how the app knows "on the card,
not opened yet" (and where). Re-run after adding, moving or de-duplicating books.
"""
import argparse
import json
import os
import re
import struct
import sys
import zipfile
import xml.etree.ElementTree as ET
from pathlib import Path

APP = Path(__file__).resolve().parents[1]
INDEX = APP / 'app' / 'index.lua'
PREVIEW = APP / 'preview.html'
BOOK_EXT = ('.epub', '.mobi', '.azw3', '.txt', '.pdf', '.prc', '.fb2')
READER_EXT = ('.epub', '.mobi', '.azw3', '.txt', '.pdf')  # what Licorice's reader lists


# ---- matching rules: keep identical to title_forms()/author_ok() in index.lua -------------
def norm(s):
    return re.sub(rb'[^a-z0-9]+', b'', s.lower().encode('utf-8')).decode()


def words(s):
    return re.sub(rb'[^a-z0-9]+', b' ', s.lower().encode('utf-8')).decode().split()


def title_forms(t):
    """(full, main, author_tail, cleaned_title) for a reader title or file name."""
    s = t.lower().strip()
    s = re.sub(r'\.(epub|mobi|azw3|txt|pdf|prc|fb2)$', '', s)
    s = re.sub(r'^\s*\[[^\]]*\]\s*', '', s)                 # "[Murderbot Diaries 01] "
    tail = ''
    m = re.match(r'^(.*?)\s+-\s+(.+)$', s)                  # "Title - Author" (file-name fallback)
    if m:
        s, tail = m.group(1), m.group(2)
    m = re.match(r'^(.*\S)\s+(the|a|an)$', s)               # "Princess Bride … The" (mangled name)
    if m:
        s = m.group(2) + ' ' + m.group(1)
    main = re.sub(r'\s*[:;].*$', '', s)                     # subtitle
    main = re.sub(r'\s*\([^)]*\)\s*$', '', main)            # "(alternate edition)"
    return norm(s), norm(main), tail, s


def surnames(author):
    out = []
    for part in re.split(r'\s+and\s+|&|,', author):
        w = words(part)
        if w:
            out.append(w[-1])
    return out


def author_ok(cat_author, reader_author):
    rw = set(words(reader_author or ''))
    if not rw or rw & {'unknown', 'author', 'none'} == rw:
        return True                                         # nothing to veto with
    return any(s in rw or s in norm(reader_author) for s in surnames(cat_author))


def classify(cat_title, cat_author, reader_title, reader_author='', alias=''):
    """'exact' | 'similar' | None. alias: the title the listed file's own metadata gives."""
    key, keymain, _, ctitle = title_forms(cat_title)
    full, main, tail, rtitle = title_forms(reader_title)
    if alias and norm(reader_title) == norm(alias):          # whole title, as the file reports it
        return 'exact'
    if reader_author and norm(reader_author) in (key, keymain):
        return 'exact'                                      # title/author swapped in the metadata
    if not author_ok(cat_author, reader_author or tail):
        return None
    if full in (key, keymain) or (main and main in (key, keymain)):
        return 'exact'
    a, b = words(ctitle), words(rtitle)
    if len(key) >= 8 and len(full) >= 8 and min(len(a), len(b)) >= 2 and (a[:len(b)] == b or b[:len(a)] == a):
        return 'similar'
    return None


# ---- inputs ---------------------------------------------------------------------------------
def catalogue():
    """(title, author, path under Books/) as baked into index.lua by build_catalog.py."""
    raw = re.search(r'local RAW\s*=\s*\[=\[(.*?)\]=\]', INDEX.read_text(), re.S).group(1)
    return [(f[0], f[1], f[5]) for f in (l.split('|') for l in raw.strip().splitlines())]


def tree_paths(tree):
    stack, out = [], []
    for ln in Path(tree).read_text(encoding='utf-8').splitlines():
        m = re.match(r'^((?:│   |    )*)(?:├── |└── )(.*)$', ln)
        if not m:
            continue
        depth, name = len(m.group(1)) // 4, m.group(2)
        stack = stack[:depth]
        if name.endswith('/'):
            stack.append(name[:-1])
        elif name.lower().endswith(BOOK_EXT):
            out.append(stack + [name])
    return out


def reader_title(root, rel):
    """Title the stock reader shows: EPUB dc:title / MOBI EXTH 503, else the file name."""
    p = os.path.join(root, 'Books', *rel)
    stem = os.path.splitext(rel[-1])[0]
    try:
        if p.lower().endswith('.epub'):
            z = zipfile.ZipFile(p)
            opf = ET.fromstring(z.read('META-INF/container.xml')).find('.//{*}rootfile').get('full-path')
            o = ET.fromstring(z.read(opf))
            t = o.find('.//{http://purl.org/dc/elements/1.1/}title')
            a = o.find('.//{http://purl.org/dc/elements/1.1/}creator')
            return ((t.text or '').strip() if t is not None else '') or stem, (a.text or '').strip() if a is not None else ''
        if p.lower().endswith(('.mobi', '.azw3')):
            d = open(p, 'rb').read()
            r0 = d[struct.unpack('>I', d[78:82])[0]:]
            mobi = r0[16:]
            hl = struct.unpack('>I', mobi[4:8])[0]
            ex = {}
            if struct.unpack('>I', mobi[112:116])[0] & 0x40:
                e = mobi[hl:]
                n, q = struct.unpack('>I', e[8:12])[0], 12
                for _ in range(n):
                    t, l = struct.unpack('>II', e[q:q + 8])
                    ex.setdefault(t, e[q + 8:q + l].decode('utf-8', 'replace'))
                    q += l
            fo, fl = struct.unpack('>II', mobi[68:76])
            return ex.get(503) or r0[fo:fo + fl].decode('utf-8', 'replace') or stem, ex.get(100, '')
    except Exception:
        pass
    return stem, ''


# ---- output ---------------------------------------------------------------------------------
def lua_str(s):
    return "'" + s.replace('\\', '\\\\').replace("'", "\\'") + "'"


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('tree')
    ap.add_argument('--card', help='mounted card root, to read metadata titles')
    ap.add_argument('--predict', help='write reader-index fixture for tests/predict.lua (needs --card)')
    ap.add_argument('--titles-json', help='write data/reader-titles.json for build_catalog.py (needs --card)')
    a = ap.parse_args()

    cat = catalogue()
    files = tree_paths(a.tree)
    have = {'/'.join(f) for f in files}
    print(f'{len(files)} book files in tree, {len(cat)} roadmap titles\n')
    missing = 0
    for i, (title, author, path) in enumerate(cat, 1):
        if path in have:
            continue
        missing += 1
        near = [f for f in files if classify(title, author, f[-1])]
        print(f'{i:3} MISSING  {title} — {author}\n      listed: {path}')
        for f in near:
            print(f'      maybe:  {"/".join(f)}')
    print(f'\n{len(cat) - missing} / {len(cat)} listed files present, {missing} missing')

    if a.card:
        idx = []
        for f in files:
            if f[-1].lower().endswith(READER_EXT):
                t, au = reader_title(a.card, f)
                idx.append((t, au, '/'.join(f)))
        if a.predict:
            with open(a.predict, 'w') as out:
                out.write('-- generated by card_from_tree.py: what the reader would list if every book were opened once\nreturn {\n')
                for n, (t, au, p) in enumerate(idx, 1):
                    out.write(f'{{id={lua_str("card%03d" % n)},title={lua_str(t)},author={lua_str(au)},path={lua_str(p)}}},\n')
                out.write('}\n')
            print(f'wrote {len(idx)} reader-title records to {a.predict}')
        if a.titles_json:
            Path(a.titles_json).write_text(json.dumps(
                [{'path': p, 'title': t, 'author': au} for t, au, p in idx], indent=1, ensure_ascii=False) + '\n')
            print(f'wrote {len(idx)} reader titles to {a.titles_json}; now run build_catalog.py --write')


if __name__ == '__main__':
    main()
