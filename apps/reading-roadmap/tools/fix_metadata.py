#!/usr/bin/env python3
"""Give EPUBs with placeholder metadata (title "none", empty author) a real title and author.

  python3 tools/fix_metadata.py --card /media/$USER/CARD            dry run: lists the files
  python3 tools/fix_metadata.py --card /media/$USER/CARD --apply    fix them
  add --all to also fix books that are not on the reading list

The reader shows and reports dc:title, so a book titled "none" cannot be matched by the app (and
looks like every other "none" book on the shelf). The new title is the reading list's title for a
listed file, else the file name before " - Author"; the author comes from the file name. A
placeholder dc:identifier ("none", shared by many files) gets a stable per-file urn:uuid.

Only those OPF elements change; every other byte of every zip member is kept. Originals are
copied to --backup first (default ~/xteink-research/metadata-fix-backup/DATE/), with restore.sh.
"""
import argparse
import datetime
import html
import json
import os
import re
import shutil
import sys
import uuid
import zipfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_catalog as bc  # noqa: E402
import dedupe_card as dc  # noqa: E402

PLACEHOLDER = {'', 'none', 'unknown', 'untitled', 'unknown title'}
DC = r'(?:dc:)?'


def opf_name(z):
    c = z.read('META-INF/container.xml').decode('utf-8', 'replace')
    return re.search(r'full-path="([^"]+)"', c).group(1)


def first(tag, s):
    return re.search(rf'<{DC}{tag}\b([^>]*?)(?:/>|>(.*?)</{DC}{tag}>)', s, re.S)


def needs_fix(s):
    t = first('title', s)
    return t is None or html.unescape((t.group(2) or '')).strip().lower() in PLACEHOLDER


def patch(s, title, author, rel):
    def put(tag, value, s):
        m = first(tag, s)
        esc = html.escape(value, quote=False)
        if m is None:
            meta = re.search(r'<(\w+:)?metadata\b[^>]*>', s)
            return s[:meta.end()] + f'\n    <dc:{tag}>{esc}</dc:{tag}>' + s[meta.end():]
        name = re.match(r'<([\w:]+)', m.group(0)).group(1)
        attrs = m.group(1).rstrip('/')
        attrs = re.sub(r'(opf:file-as=")[^"]*(")', lambda a: a.group(1) + html.escape(value) + a.group(2), attrs)
        return s[:m.start()] + f'<{name}{attrs}>{esc}</{name}>' + s[m.end():]
    s = put('title', title, s)
    m = first('creator', s)
    if author and (m is None or html.unescape(m.group(2) or '').strip().lower() in PLACEHOLDER):
        s = put('creator', author, s)
    m = first('identifier', s)
    if m and html.unescape(m.group(2) or '').strip().lower() in PLACEHOLDER:
        s = put('identifier', 'urn:uuid:' + str(uuid.uuid5(uuid.NAMESPACE_URL, 'xteink-card:' + rel)), s)
    return s


def rewrite(src, dst, opf, new_opf):
    with zipfile.ZipFile(src) as zin, zipfile.ZipFile(dst, 'w') as zout:
        for info in zin.infolist():  # same order (mimetype first, stored), same compression
            data = new_opf if info.filename == opf else zin.read(info.filename)
            zout.writestr(info, data)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--card', required=True)
    ap.add_argument('--apply', action='store_true')
    ap.add_argument('--all', action='store_true', help='also fix books that are not on the reading list')
    ap.add_argument('--backup')
    a = ap.parse_args()
    books = Path(a.card) / 'Books'
    if not books.is_dir():
        sys.exit(f'{books} not found: pass the card root')
    data = json.loads(bc.DATA.read_text(encoding='utf-8'))
    listed = {r['relative_path']: r['title'] for r in data['reading_order']}
    todo = []
    for p in sorted(books.rglob('*')):
        if p.suffix.lower() != '.epub' or p.name.startswith('.') or not p.is_file():
            continue
        rel = p.relative_to(books).as_posix()
        if rel not in listed and not a.all:
            continue
        try:
            with zipfile.ZipFile(p) as z:
                opf = opf_name(z)
                s = z.read(opf).decode('utf-8')
        except Exception:  # noqa: BLE001 - unreadable files are not ours to fix
            continue
        if not needs_fix(s):
            continue
        stem = os.path.splitext(p.name)[0]
        head, _, tail = stem.rpartition(' - ')
        if not head:
            head, tail = stem, ''
        author = '' if tail.strip().lower() in ('unknown author', 'unknown', 'none') else tail.strip()
        title = listed.get(rel) or re.sub(r'^\[[^\]]*\]\s*', '', head).strip()
        todo.append((rel, opf, s, title, author))
    print(f'{len(todo)} EPUBs have a placeholder title')
    for rel, _, _, title, author in todo:
        print(f'   {"LIST" if rel in listed else "    "}  {title!r} / {author!r}   {rel}')
    if not a.apply:
        print('\nDry run. Nothing changed. Re-run with --apply to fix them.')
        return
    backup = Path(a.backup or Path.home() / 'xteink-research' / 'metadata-fix-backup'
                  / datetime.datetime.now().strftime('%Y-%m-%d_%H%M%S'))
    backup.mkdir(parents=True, exist_ok=False)
    for rel, opf, s, title, author in todo:
        src = books / rel
        keep = backup / 'Books' / rel
        keep.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, keep)
        if dc.sha256(keep) != dc.sha256(src):
            sys.exit(f'backup of {rel} does not match; stopped')
        tmp = src.with_name('.fixmeta-' + src.name)
        rewrite(keep, tmp, opf, patch(s, title, author, rel).encode('utf-8'))
        prob = dc.epub_problem(tmp)
        with zipfile.ZipFile(tmp) as z:
            ok = not needs_fix(z.read(opf).decode('utf-8'))
        if prob or not ok:
            tmp.unlink()
            sys.exit(f'{rel}: rewritten file failed checks ({prob or "title still placeholder"}); original untouched')
        os.replace(tmp, src)
        print(f'   fixed {rel}')
    (backup / 'restore.sh').write_text('\n'.join([
        '#!/bin/sh', '# Put the original files back: sh restore.sh /media/$USER/CARD', 'set -e',
        'CARD="${1:?usage: restore.sh CARD_ROOT}"', 'cd "$(dirname "$0")"',
        'find Books -type f | while IFS= read -r f; do cp -p "$f" "$CARD/$f"; done',
        'echo "restore finished"']) + '\n')
    print(f'\nDone: {len(todo)} files fixed; originals in {backup}')
    print('Next: card_from_tree.py ... --titles-json data/reader-titles.json, then build_catalog.py --write')


if __name__ == '__main__':
    main()
