#!/usr/bin/env python3
"""Build and stage one Games Hub installer, carrying over existing SD game saves.

Uses only the standard library plus the community packer's dependencies. Firmware
still performs installation: open Apps/games-hub.xtapp once on the reader.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
from datetime import datetime

from build_game_hub import HUB, outputs
from sync_game_ui import GAMES, ROOT, project_path
from verify_package_icons import verify_icon


def snapshot(card):
    """Strict read-only snapshot. Unknown apps and the hub's own saves stay alone."""
    assert (card / 'XTApps').is_dir(), 'This card has no XTApps directory'
    assert (card / 'Apps').is_dir(), 'This card has no Apps directory'
    records = {}
    originals = {}
    for game in GAMES:
        appid = json.loads((project_path(game) / 'app/manifest.json').read_text())['app_id']
        folder = card / 'XTApps' / appid / 'files'
        if not folder.exists():
            continue
        assert not folder.is_symlink() and not folder.parent.is_symlink(), f'Unexpected symlink: {folder}'
        for source in sorted(folder.iterdir()):
            key = appid + '--' + source.name
            assert source.is_file() and not source.is_symlink(), f'Unexpected save entry: {source}'
            assert re.fullmatch(r'[A-Za-z0-9._-]+', source.name) and '..' not in source.name and len(key) <= 64, f'Unsupported save name: {source}'
            data = source.read_bytes()
            records[key] = data
            originals[str(source.relative_to(card))] = data
    # Reserve room for all documented authored-board saves, 4 x 64 generated
    # shards, hub state and receipt. Snapshot must never exhaust file quota.
    assert len(records) <= 450 and sum(map(len, records.values())) < 120 * 1024 * 1024, 'Save import exceeds safe quota'
    return records, originals


def encode(records):
    # xtpack treats >=90% equal-length lines as a puzzle bank and discards
    # the others (including our header). Sort by base length, then use harmless
    # leading zeroes in the decimal byte count to make every line a distinct
    # length. Padding stays small and the importer reads the same byte counts.
    rows = [(key, str(len(value)), value.hex()) for key, value in records.items()]
    rows.sort(key=lambda row: (len('\t'.join(row)), row[0]))
    lines, previous = ['HUBSAVES1'], len('HUBSAVES1')
    for key, count, payload in rows:
        width = len(key) + len(count) + len(payload) + 2
        count = '0' * max(0, previous + 1 - width) + count
        line = '\t'.join((key, count, payload))
        lines.append(line)
        previous = len(line)
    return ('\n'.join(lines) + '\n').encode()


def prepare(card, packer, output, backup):
    records, originals = snapshot(card)
    backup.mkdir(parents=True, exist_ok=False)
    hashes = {}
    for name, data in originals.items():
        target = backup / name
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(data)
        hashes[name] = hashlib.sha256(data).hexdigest()
    previous = card / 'Apps/games-hub.xtapp'
    if previous.exists():
        assert previous.is_file() and not previous.is_symlink()
        shutil.copy2(previous, backup / 'previous-games-hub.xtapp')
    payload = encode(records)
    identifier = hashlib.sha256(payload).hexdigest()
    (backup / 'snapshot.json').write_text(json.dumps({'import_id': identifier, 'files': hashes}, indent=2) + '\n')
    with tempfile.TemporaryDirectory(prefix='games-hub-') as temp:
        app = Path(temp) / 'app'
        app.mkdir()
        for name, data in outputs().items():
            (app / name).write_bytes(data)
        for name in ('manifest.json', 'icon.png'):
            shutil.copy2(HUB / 'app' / name, app / name)
        if records:
            (app / 'data').mkdir()
            (app / 'data/import-saves.txt').write_bytes(payload)
            (app / 'import_expected.lua').write_text('return {id=' + json.dumps(identifier) + ',count=' + str(len(records)) + '}\n')
        output.parent.mkdir(parents=True, exist_ok=True)
        subprocess.run([sys.executable, str(packer), str(app), '-o', str(output)], check=True)
        verify_icon(output, app / 'icon.png')
    # Detect changes during preparation; do not stage a stale snapshot.
    current, again = snapshot(card)
    assert again == originals, 'Game saves changed while preparing; try again with reader disconnected'
    return {'save_count': len(records), 'sha256': hashlib.sha256(output.read_bytes()).hexdigest(),
            'backup': str(backup), 'import_id': identifier}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--card', type=Path, required=True)
    parser.add_argument('--packer', type=Path, default=ROOT.parent / 'touch-licorice-apps/xtpack.py')
    parser.add_argument('--output', type=Path, default=ROOT / 'dist/games-hub-personal.xtapp')
    parser.add_argument('--backup', type=Path, default=Path.home() / 'Backups' / ('xteink-hub-' + datetime.now().strftime('%Y%m%d-%H%M%S')))
    parser.add_argument('--prepare-only', action='store_true', help='Create the private installer without copying onto the card')
    args = parser.parse_args()
    assert args.packer.is_file(), 'Pass --packer /path/to/xtpack.py'
    result = prepare(args.card.resolve(), args.packer.resolve(), args.output.resolve(), args.backup.resolve())
    if not args.prepare_only:
        target = args.card / 'Apps/games-hub.xtapp'
        assert not target.is_symlink(), 'Unexpected installer symlink'
        temporary = args.card / 'Apps/games-hub.xtapp.pending'
        assert not temporary.exists(), 'A previous staging file exists; inspect it first'
        try:
            with temporary.open('xb') as stream:
                stream.write(args.output.read_bytes())
                stream.flush()
                import os
                os.fsync(stream.fileno())
            assert hashlib.sha256(temporary.read_bytes()).hexdigest() == result['sha256'], 'Installer copy failed verification'
            temporary.replace(target)
        finally:
            if temporary.exists():
                temporary.unlink()
        result['installed_package'] = str(target)
    (args.backup / 'delivery.json').write_text(json.dumps(result, indent=2) + '\n')
    print(json.dumps(result, indent=2))
    if args.prepare_only:
        print(f'Prepared {args.output}; the card has not been changed.')
    else:
        print('Open Apps/games-hub.xtapp on the reader to install. Existing hub progress always wins over imported saves.')


if __name__ == '__main__':
    main()
