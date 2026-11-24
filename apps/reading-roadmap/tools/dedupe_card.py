#!/usr/bin/env python3
"""Remove duplicate copies of books from the SD card: keep one EPUB, take the rest off.

  python3 tools/dedupe_card.py --card /media/$USER/CARD            dry run: prints the plan
  python3 tools/dedupe_card.py --card /media/$USER/CARD --apply    do it

Rules, per group in data/duplicate-audit.json:
  * Keep exactly one EPUB. Duplicate MOBIs go, and so do extra EPUBs.
  * A file the reading list uses (data/quality-first-211.json, incl. EPUB optional continuations)
    is never removed; it is the keeper.
  * Otherwise the keeper is the audit's preferred EPUB, or else the largest one, and it must be a
    readable, DRM-free EPUB (zip, container.xml, OPF, no encryption). If none is, the group is skipped.
  * Groups without an EPUB (MOBI+MOBI, MOBI+PDF) are skipped: nothing to prefer.
  * "verify manually" groups go ahead only if each file's own metadata title names the same book.
  * Omnibus/collection overlaps are reported, never touched.

Nothing is deleted outright. Each removed file is first copied to --backup (default
~/xteink-research/card-dedupe-backup/DATE/), verified by SHA-256, and only then deleted from the
card. The backup folder gets manifest.json, restore.sh, and a fresh directory-tree.md of the card.
"""
import argparse
import datetime
import hashlib
import json
import os
import shutil
import sys
import zipfile
import xml.etree.ElementTree as ET
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import card_from_tree as ct  # noqa: E402

APP = Path(__file__).resolve().parents[1]
AUDIT = APP / 'data' / 'duplicate-audit.json'
LIST = APP / 'data' / 'quality-first-211.json'
FONT_OBFUSCATION = {'http://www.idpf.org/2008/embedding', 'http://ns.adobe.com/pdf/enc#RC'}


def epub_problem(path):
    """None if the EPUB looks readable and DRM-free, else a short reason."""
    try:
        with zipfile.ZipFile(path) as z:
            names = set(z.namelist())
            if 'META-INF/container.xml' not in names:
                return 'no container.xml'
            opf = ET.fromstring(z.read('META-INF/container.xml')).find('.//{*}rootfile').get('full-path')
            if opf not in names:
                return 'OPF missing'
            ET.fromstring(z.read(opf))
            if 'META-INF/rights.xml' in names:
                return 'DRM (rights.xml)'
            if 'META-INF/encryption.xml' in names:
                enc = ET.fromstring(z.read('META-INF/encryption.xml'))
                algs = {m.get('Algorithm') for m in enc.iter() if m.tag.endswith('EncryptionMethod')}
                if algs - FONT_OBFUSCATION:
                    return 'DRM (encrypted content)'
            bad = z.testzip()
            if bad:
                return f'corrupt member {bad}'
    except Exception as e:  # noqa: BLE001 - any failure means "do not rely on this file"
        return f'unreadable ({type(e).__name__})'
    return None


def sha256(path):
    h = hashlib.sha256()
    with open(path, 'rb') as f:
        for chunk in iter(lambda: f.read(1 << 20), b''):
            h.update(chunk)
    return h.hexdigest()


def plan(card, audit, used):
    books = Path(card) / 'Books'
    actions, skipped = [], []
    for g in audit['duplicate_groups']:
        work = g['work']
        files = [f['path'] for f in g['files']]
        present = [p for p in files if (books / p).is_file()]
        gone = [p for p in files if p not in present]
        if len(present) < 2:
            skipped.append((work, 'already single on the card' if present else 'no copies found', gone))
            continue
        epubs = [p for p in present if p.lower().endswith('.epub')]
        if not epubs:
            skipped.append((work, 'no EPUB in this group (rule only prefers EPUB)', present))
            continue
        protected = [p for p in present if p in used]
        if g.get('confidence') == 'verify manually':
            titles = {p: ct.reader_title(card, p.split('/'))[0] for p in present}
            name = work.replace('(probable)', '').replace('(possible edition match)', '').strip()
            if not all(ct.classify(name, '', t) for t in titles.values()):
                skipped.append((work, 'uncertain group; metadata titles differ: '
                                + '; '.join(f'{t!r}' for t in titles.values()), present))
                continue
        problems = {p: epub_problem(books / p) for p in epubs}
        if protected:
            keep = protected
        else:
            pref = g.get('preferred_file_for_epub_reader')
            good = [p for p in epubs if not problems[p]]
            if pref in good:
                keep = [pref]
            elif good:
                keep = [max(good, key=lambda p: (books / p).stat().st_size)]
            else:
                skipped.append((work, 'no readable DRM-free EPUB: '
                                + '; '.join(f'{p.rsplit("/", 1)[-1]}: {problems[p]}' for p in epubs), present))
                continue
        bad_keep = [p for p in keep if p.lower().endswith('.epub') and problems.get(p)]
        if bad_keep:
            skipped.append((work, f'reading-list copy has a problem ({problems[bad_keep[0]]}); check by hand', present))
            continue
        if not any(p.lower().endswith('.epub') for p in keep):
            # The list uses a MOBI: keep it and the best EPUB, remove nothing else blindly.
            skipped.append((work, 'reading list uses the MOBI; switch the list to the EPUB first', present))
            continue
        remove = [p for p in present if p not in keep]
        actions.append({'work': work, 'keep': keep, 'remove': remove, 'missing': gone})
    return actions, skipped


def write_tree(card, out):
    root = Path(card) / 'Books'
    lines = ['Books/']

    def walk(d, prefix):
        entries = sorted(d.iterdir(), key=lambda e: (not e.is_dir(), e.name.lower()))
        entries = [e for e in entries if not e.name.startswith('.')]
        for i, e in enumerate(entries):
            last = i == len(entries) - 1
            lines.append(prefix + ('└── ' if last else '├── ') + e.name + ('/' if e.is_dir() else ''))
            if e.is_dir():
                walk(e, prefix + ('    ' if last else '│   '))
    walk(root, '')
    Path(out).write_text('\n'.join(lines) + '\n', encoding='utf-8')


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--card', required=True, help='mounted card root (the folder that contains Books/)')
    ap.add_argument('--apply', action='store_true', help='move the duplicates off the card (default: dry run)')
    ap.add_argument('--backup', help='where removed files go (default ~/xteink-research/card-dedupe-backup/DATE)')
    a = ap.parse_args()
    card = os.path.abspath(a.card)
    if not (Path(card) / 'Books').is_dir():
        sys.exit(f'{card}/Books not found: pass the card root')
    audit = json.loads(AUDIT.read_text(encoding='utf-8'))
    data = json.loads(LIST.read_text(encoding='utf-8'))
    used = {r['relative_path'] for r in data['reading_order']}
    # Optional series continuations are protected too, except a MOBI the user's rule replaces.
    later = {r['relative_path']: r['title'] for r in data.get('optional_continuations', [])}
    used |= {p for p in later if p.lower().endswith('.epub')}
    actions, skipped = plan(card, audit, used)

    n = sum(len(x['remove']) for x in actions)
    size = sum((Path(card) / 'Books' / p).stat().st_size for x in actions for p in x['remove'])
    print(f'{len(actions)} groups to clean, {n} files to take off the card ({size / 1e6:.1f} MB)\n')
    for x in actions:
        print(f"{x['work']}")
        for p in x['keep']:
            print(f'   KEEP    {p}' + ('   (reading list)' if p in used else ''))
        for p in x['remove']:
            print(f'   REMOVE  {p}')
            if p in later:
                print(f'           note: optional continuation "{later[p]}" points here; read the kept EPUB instead')
    if skipped:
        print(f'\nLeft alone ({len(skipped)} groups):')
        for work, why, _ in skipped:
            print(f'   {work}: {why}')
    print('\nNever touched (collections that overlap single books):')
    for w in audit.get('collection_overlap_warnings', []):
        print(f"   {w['title']}")

    if not a.apply:
        print('\nDry run. Nothing changed. Re-run with --apply to do it.')
        return
    backup = Path(a.backup or Path.home() / 'xteink-research' / 'card-dedupe-backup'
                  / datetime.datetime.now().strftime('%Y-%m-%d_%H%M%S'))
    backup.mkdir(parents=True, exist_ok=False)
    need = size * 1.05
    if shutil.disk_usage(backup).free < need:
        sys.exit(f'not enough space in {backup} for {size / 1e6:.1f} MB')
    manifest = []
    for x in actions:
        for p in x['remove']:
            src = Path(card) / 'Books' / p
            dst = backup / 'Books' / p
            dst.parent.mkdir(parents=True, exist_ok=True)
            h = sha256(src)
            shutil.copy2(src, dst)
            if sha256(dst) != h:
                sys.exit(f'backup copy of {p} does not match; stopped before deleting it')
            src.unlink()
            manifest.append({'removed': p, 'sha256': h, 'bytes': dst.stat().st_size,
                             'kept': x['keep'], 'work': x['work']})
            print(f'   moved off card: {p}')
    (backup / 'manifest.json').write_text(json.dumps(manifest, indent=1, ensure_ascii=False) + '\n')
    restore = ['#!/bin/sh', '# Put every removed file back: sh restore.sh /media/$USER/CARD', 'set -e',
               'CARD="${1:?usage: restore.sh CARD_ROOT}"', 'cd "$(dirname "$0")"',
               'find Books -type f | while IFS= read -r f; do',
               '  if [ -e "$CARD/$f" ]; then echo "exists, left as is: $f"; continue; fi',
               '  mkdir -p "$CARD/$(dirname "$f")" && cp -p "$f" "$CARD/$f"',
               'done', 'echo "restore finished"']
    (backup / 'restore.sh').write_text('\n'.join(restore) + '\n')
    write_tree(card, backup / 'directory-tree.md')
    print(f'\nDone: {len(manifest)} files moved to {backup}')
    print('Undo with: sh', backup / 'restore.sh', card)
    print('Next: copy directory-tree.md to the card as Books/directory-tree.md and run '
          'tools/card_from_tree.py on it to confirm every listed book is still there.')


if __name__ == '__main__':
    main()
