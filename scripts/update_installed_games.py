#!/usr/bin/env python3
"""Prepare or apply a backed-up USB update of already-installed game packages.

This updates XTApps/<id>/app.xtapp, rather than staging installers in Apps/.
It never registers new apps or changes files/. Reader compatibility of direct
replacement is experimental until physically checked on the current firmware.
Default mode prints a read-only plan; --apply performs replacements.
"""
import argparse
from datetime import datetime
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import struct

from sync_game_ui import GAMES, COLLECTIONS, project_path

ROOT = Path(__file__).resolve().parents[1]


def digest(data):
    return hashlib.sha256(data).hexdigest()


def manifest(data):
    if len(data) < 128 or data[:4] != b'XTAP':
        raise ValueError('Invalid XTApp package')
    version, header = struct.unpack_from('<HH', data, 4)
    total = struct.unpack_from('<I', data, 8)[0]
    offset, length = struct.unpack_from('<II', data, 16)
    if version != 1 or header != 128 or total != len(data) or offset != 128 or not 1 <= length <= 8192 or offset+length > len(data):
        raise ValueError('Invalid XTApp header')
    value = json.loads(data[offset:offset+length])
    if not re.fullmatch('[a-z]+', value.get('app_id', '')):
        raise ValueError('Invalid app ID')
    return value


def version(value):
    if not re.fullmatch(r'\d+\.\d+\.\d+', value):
        raise ValueError('Unsupported version: ' + value)
    return tuple(map(int, value.split('.')))


def tree(folder):
    """Hash everything except the one replaceable package; reject links."""
    result = {}
    for source in sorted(folder.rglob('*')):
        if source.is_symlink():
            raise ValueError('Unexpected symlink: ' + str(source))
        if source.is_file() and source != folder / 'app.xtapp':
            result[str(source.relative_to(folder))] = digest(source.read_bytes())
    return result


def plan(card, catalogue):
    root = card / 'XTApps'
    if not root.is_dir() or root.is_symlink():
        raise ValueError('Mounted card with XTApps directory required')
    updates, skipped = [], []
    document = json.loads(catalogue.read_text())
    entries = document['games'] if isinstance(document.get('games'), list) else [document]
    allowed = {json.loads((project_path(game) /'app/manifest.json').read_text())['app_id'] for game in GAMES + COLLECTIONS}
    seen = set()
    for entry in entries:
        appid = entry['app_id']
        if not re.fullmatch('[a-z]+', appid) or appid in seen or appid not in allowed:
            raise ValueError('Invalid or duplicate catalogue ID')
        seen.add(appid)
        name = entry['file']
        if Path(name).name != name or name in {'.', '..'}:
            raise ValueError('Invalid catalogue filename')
        source = catalogue.parent / name
        data = source.read_bytes()
        if digest(data) != entry['sha256'] or len(data) != entry['bytes']:
            raise ValueError('Release checksum mismatch: ' + name)
        new = manifest(data)
        if new['app_id'] != appid or new['version'] != entry['version']:
            raise ValueError('Release manifest mismatch: ' + name)
        folder = root / appid
        target = folder / 'app.xtapp'
        if folder.is_symlink() or target.is_symlink():
            raise ValueError('Unexpected installed-app symlink')
        if not target.is_file():
            skipped.append({'app_id': appid, 'reason': 'not installed; firmware registration required'})
            continue
        old_data = target.read_bytes()
        old = manifest(old_data)
        if old['app_id'] != appid:
            raise ValueError('Installed app ID mismatch: ' + appid)
        if version(old['version']) >= version(new['version']):
            skipped.append({'app_id': appid, 'reason': 'installed version is current or newer'})
            continue
        if appid == 'gameshub' and not (folder/'files/hub-import.txt').is_file() and not (folder/'files/hub.txt').is_file():
            skipped.append({'app_id': appid, 'reason': 'open existing hub first to finish its save import'})
            continue
        if old.get('api') != new.get('api') or old.get('permissions', []) != new.get('permissions', []) or old.get('lockscreen') != new.get('lockscreen'):
            # The firmware must approve these; never swap the package behind its back.
            skipped.append({'app_id': appid, 'reason': 'firmware installation needed: API/permissions/lockscreen changed; '
                            'install the Apps/ recovery installer over the existing app once'})
            continue
        updates.append({'app_id': appid, 'from': old['version'], 'to': new['version'],
                        'source': str(source), 'target': str(target), 'old_sha256': digest(old_data),
                        'sha256': digest(data), 'preserved_files': tree(folder)})
    return {'card': str(card), 'updates': updates, 'skipped': skipped, 'device_verified': False}


def replace(target, data):
    pending = target.with_name('app.xtapp.pending')
    # Use exclusive creation, and never delete somebody else's stale file.
    stream = pending.open('xb')
    try:
        with stream:
            stream.write(data)
            stream.flush()
            os.fsync(stream.fileno())
        if pending.read_bytes() != data:
            raise OSError('Package copy verification failed')
        pending.replace(target)
        if target.read_bytes() != data:
            raise OSError('Package replacement verification failed')
    finally:
        if pending.exists():
            pending.unlink()


def apply(result, backup):
    if not result['updates']:
        return result
    if backup.resolve().is_relative_to(Path(result['card']).resolve()):
        raise ValueError('Backups must live on this computer, outside the SD card')
    backup.mkdir(parents=True, exist_ok=False)
    # Finish every backup and recheck the complete plan before changing any app.
    for item in result['updates']:
        target = Path(item['target'])
        if digest(target.read_bytes()) != item['old_sha256'] or tree(target.parent) != item['preserved_files']:
            raise ValueError('Installed files changed during planning')
        shutil.copytree(target.parent, backup / item['app_id'])
        if digest((backup/item['app_id']/'app.xtapp').read_bytes()) != item['old_sha256'] or tree(backup/item['app_id']) != item['preserved_files']:
            raise OSError('Backup verification failed')
        if digest(Path(item['source']).read_bytes()) != item['sha256']:
            raise ValueError('Release changed during planning')
    (backup/'plan.json').write_text(json.dumps(result, indent=2)+'\n')
    changed = []
    try:
        for item in result['updates']:
            target = Path(item['target'])
            if digest(target.read_bytes()) != item['old_sha256'] or tree(target.parent) != item['preserved_files']:
                raise ValueError('Installed files changed before replacement')
            data = Path(item['source']).read_bytes()
            if digest(data) != item['sha256']:
                raise ValueError('Release changed before replacement')
            changed.append(item)  # Include a replace that fails during readback.
            replace(target, data)
            if tree(target.parent) != item['preserved_files']:
                raise OSError('Non-package files changed during update')
    except Exception:
        for item in reversed(changed):
            target = Path(item['target'])
            if digest(target.read_bytes()) != item['old_sha256']:
                replace(target, (backup/item['app_id']/'app.xtapp').read_bytes())
        raise
    result['backup'] = str(backup)
    result['applied'] = True
    (backup/'receipt.json').write_text(json.dumps(result, indent=2)+'\n')
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--card', type=Path, required=True)
    parser.add_argument('--catalogue', type=Path, default=ROOT/'releases/game-family-latest.json')
    parser.add_argument('--apply', action='store_true')
    parser.add_argument('--backup', type=Path, default=Path.home()/'Backups'/('xteink-direct-update-'+datetime.now().strftime('%Y%m%d-%H%M%S')))
    args = parser.parse_args()
    result = plan(args.card.resolve(), args.catalogue.resolve())
    if args.apply:
        result = apply(result, args.backup.resolve())
    print(json.dumps(result, indent=2))


if __name__ == '__main__':
    main()
