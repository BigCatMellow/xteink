#!/usr/bin/env python3
"""Bake the reading list (data/quality-first-211.json) into the app and the HTML preview.

  python3 tools/build_catalog.py                       check only (exit 1 if the baked copy is stale)
  python3 tools/build_catalog.py --write               rewrite the CATALOG block in index.lua + preview.html
  python3 tools/build_catalog.py --tree TREE.md        also require every path to exist in a card tree

Each book's progress is saved under a stable title key (not its position), so reordering or
replacing the list never moves progress onto another book. V1_KEYS maps the 33-book list's
positional IDs (save format #roadmap1) onto the books that carried over.
"""
import argparse
import json
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import card_from_tree as ct  # noqa: E402  (shared title rules: norm/title_forms/classify)

APP = Path(__file__).resolve().parents[1]
DATA = APP / 'data' / 'quality-first-211.json'
TITLES = APP / 'data' / 'reader-titles.json'
INDEX = APP / 'app' / 'index.lua'
PREVIEW = APP / 'preview.html'

# The 0.4/0.5 catalogue (save format #roadmap1 used these positions as IDs). Frozen history.
V1_TITLES = [
    ('A Knight of the Seven Kingdoms', 'George R. R. Martin'), ('All Systems Red', 'Martha Wells'),
    ('The Thin Man', 'Dashiell Hammett'), ("Penric's Demon", 'Lois McMaster Bujold'),
    ('The Blacktongue Thief', 'Christopher Buehlman'), ('True Grit', 'Charles Portis'),
    ('Guards! Guards!', 'Terry Pratchett'), ('Slow Horses', 'Mick Herron'),
    ('The Blade Itself', 'Joe Abercrombie'), ('The Martian', 'Andy Weir'),
    ('We Are Legion (We Are Bob)', 'Dennis E. Taylor'), ('The Long Way to a Small, Angry Planet', 'Becky Chambers'),
    ('I Am Legend', 'Richard Matheson'), ('The Last Wish', 'Andrzej Sapkowski'),
    ('The Princess Bride', 'William Goldman'), ('Kings of the Wyld', 'Nicholas Eames'),
    ('The Tainted Cup', 'Robert Jackson Bennett'), ('Theft of Swords', 'Michael J. Sullivan'),
    ('The Black Company', 'Glen Cook'), ('The Curse of Chalion', 'Lois McMaster Bujold'),
    ('The Lies of Locke Lamora', 'Scott Lynch'), ('The Hobbit', 'J. R. R. Tolkien'),
    ('The Lord of the Rings', 'J. R. R. Tolkien'), ('We Have Always Lived in the Castle', 'Shirley Jackson'),
    ('The Sisters Brothers', 'Patrick deWitt'), ('The Last Policeman', 'Ben H. Winters'),
    ('The Friends of Eddie Coyle', 'George V. Higgins'), ('The Stepford Wives', 'Ira Levin'),
    ("The Queen's Gambit", 'Walter Tevis'), ('A Walk in the Woods', 'Bill Bryson'),
    ('Smoke Gets in Your Eyes', 'Caitlin Doughty'), ('The Disaster Artist', 'Greg Sestero and Tom Bissell'),
    ('The Big Year', 'Mark Obmascik'),
]


def author_of(filename):
    stem = re.sub(r'\.[A-Za-z0-9]+$', '', filename)
    m = re.match(r'^.*?\s+-\s+(.+)$', stem)
    a = m.group(1).strip() if m else ''
    return '' if a.lower() in ('unknown author', 'unknown', 'none') else a


def clean(s):
    s = re.sub(r'\s+', ' ', str(s or '')).strip()
    if '|' in s or '`' in s or '${' in s or ']=]' in s:
        sys.exit(f'unsafe character in catalogue text: {s!r}')
    return s


def aliases(data, titles):
    """Expected reader title per listed file, where plain title matching would miss it.
    Only titles unique on the card qualify ('none' or 'CHAPTER ONE' would link the wrong book)."""
    by_path = {t['path']: t for t in titles}
    out, manual = {}, []
    for r in data['reading_order']:
        t = by_path.get(r['relative_path'])
        if not t or ct.classify(r['title'], author_of(r['filename']), t['title'], t['author']) == 'exact':
            continue
        k = ct.norm(t['title'])
        # A shared title is fine only when every other file with it is this same work.
        others = [u for u in titles if ct.norm(u['title']) == k and u is not t]
        if len(k) >= 4 and all(ct.classify(r['title'], author_of(r['filename']), u['path'].rsplit('/', 1)[-1])
                               for u in others):
            out[r['relative_path']] = clean(t['title'])
        else:
            manual.append((r['order'], r['title'], t['title']))
    return out, manual


def rows(data, alias=None):
    alias = alias or {}
    out = []
    for r in sorted(data['reading_order'], key=lambda r: r['order']):
        out.append('|'.join([
            clean(r['title']), clean(author_of(r['filename'])), clean(r['section']), str(r['stage']),
            '1' if r['reread_option'] else '0', clean(r['relative_path']), clean(r['reader_fit']),
            clean(r['visual_reference']), clean(r['warning']), alias.get(r['relative_path'], ''),
        ]))
    return out


def v1_keys(books):
    keys = {}
    for i, (t, a) in enumerate(V1_TITLES, 1):
        hit = [b for b in books if ct.classify(t, a, b[0], b[1]) == 'exact']
        if len(hit) == 1:
            keys[i] = ct.norm(hit[0][0])
    return keys


def blocks(data, alias=None):
    lines = rows(data, alias)
    books = [l.split('|') for l in lines]
    keys = [ct.norm(b[0]) for b in books]
    dupes = {k for k in keys if keys.count(k) > 1}
    if dupes:
        sys.exit(f'title keys must be unique: {sorted(dupes)}')
    date = data.get('date_updated', '')
    mig = v1_keys(books)
    src = 'data/' + DATA.name
    lua = [f'-- CATALOG:BEGIN generated by tools/build_catalog.py from {src}; do not edit',
           f"local CARD_DATE='{date}'",
           '-- title|author|section|stage|reread|path under Books/|why|visual reference|heads-up|reader title',
           'local RAW = [=[', *lines, ']=]',
           '-- 0.4/0.5 progress IDs (#roadmap1) of books that carried over, by title key',
           'local V1_KEYS={' + ','.join(f"[{i}]='{k}'" for i, k in mig.items()) + '}',
           '-- CATALOG:END']
    js = [f'// CATALOG:BEGIN generated by tools/build_catalog.py from {src}; do not edit',
          f"const CARD_DATE='{date}';",
          '// title|author|section|stage|reread|path under Books/|why|visual reference|heads-up|reader title',
          'const RAW=`' + '\n'.join(lines) + '`;',
          'const V1_KEYS={' + ','.join(f"{i}:'{k}'" for i, k in mig.items()) + '};',
          '// CATALOG:END']
    return '\n'.join(lua), '\n'.join(js), len(lines), mig


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--json', default=str(DATA))
    ap.add_argument('--write', action='store_true')
    ap.add_argument('--tree', help='directory-tree.md of the card; every path must exist in it')
    ap.add_argument('--titles', default=str(TITLES),
                    help='reader titles per file (card_from_tree.py --card ... --titles-json)')
    a = ap.parse_args()
    data = json.loads(Path(a.json).read_text(encoding='utf-8'))
    alias, manual = {}, []
    if Path(a.titles).exists():
        alias, manual = aliases(data, json.loads(Path(a.titles).read_text(encoding='utf-8')))
        print(f'{len(alias)} books get their file\'s own metadata title as a match alias')
        for o, t, rt in manual:
            print(f'  needs LINK BOOK once: {o:3} {t}  (reader title {rt!r} is not unique)')
    lua, js, n, mig = blocks(data, alias)
    print(f'{n} books; carried over from the 33-book list: {sorted(mig)}')
    if a.tree:
        have = {'/'.join(p) for p in ct.tree_paths(a.tree)}
        missing = [r['relative_path'] for r in data['reading_order'] if r['relative_path'] not in have]
        for p in missing:
            print('  NOT IN TREE', p)
        if missing:
            sys.exit(f'{len(missing)} listed files are not in {a.tree}')
        print(f'all {n} paths present in {a.tree}')
    stale = False
    for path, block, pat in ((INDEX, lua, r'-- CATALOG:BEGIN.*?-- CATALOG:END'),
                             (PREVIEW, js, r'// CATALOG:BEGIN.*?// CATALOG:END')):
        src = path.read_text(encoding='utf-8')
        found = re.findall(pat, src, re.S)
        if len(found) != 1:
            sys.exit(f'{path.name}: CATALOG markers not found exactly once')
        if found[0] != block:
            stale = True
            if a.write:
                path.write_text(src.replace(found[0], block), encoding='utf-8')
                print(f'updated {path.relative_to(APP)}')
            else:
                print(f'STALE {path.relative_to(APP)}: run with --write')
    if stale and not a.write:
        sys.exit(1)


if __name__ == '__main__':
    main()
