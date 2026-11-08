#!/usr/bin/env python3
"""Verify, archive and optionally apply the entire game family in one command.

--apply-only deploys the already verified latest catalogue. New standalone games
are staged as recovery installers and become playable through the existing Hub.
"""
import argparse
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import zipfile

from sync_game_ui import GAMES, COLLECTIONS, ROOT
import update_installed_games as Update


def source_hash(app):
    h=hashlib.sha256()
    for path in sorted(p for p in app.rglob('*') if p.is_file()):
        h.update(str(path.relative_to(app)).encode()+b'\0'+path.read_bytes())
    return h.hexdigest()


def archive_game(game, dist, releases, root=ROOT):
    app=root/game/'app'
    manifest=json.loads((app/'manifest.json').read_text())
    filename=f"{game}-{manifest['version']}.xtapp"
    target=releases/filename
    metadata=target.with_suffix('.json')
    fingerprint=source_hash(app)
    if game in COLLECTIONS:
        assert (app/'import_expected.lua').read_text().startswith('return false')
        assert not (app/'data').exists(),'Public collection contains personal data'
    if target.exists():
        if not metadata.exists():
            raise ValueError('Archived version has no source proof; bump version: '+game)
        previous=json.loads(metadata.read_text())
        if previous.get('source_sha256')!=fingerprint:
            raise ValueError('Source changed without a version bump: '+game)
        if Update.digest(target.read_bytes())!=previous['sha256']:
            raise ValueError('Archived package checksum mismatch: '+game)
        return previous
    data=(dist/(game+'.xtapp')).read_bytes()
    packed=Update.manifest(data)
    assert packed['app_id']==manifest['app_id'] and packed['version']==manifest['version']
    target.write_bytes(data)
    entry={'game':game,'app_id':manifest['app_id'],'name':manifest['display_name'],
           'version':manifest['version'],'file':filename,'bytes':len(data),
           'sha256':Update.digest(data),'source_sha256':fingerprint,
           'metadata_file':metadata.name,'personal_data':False,'device_tested':False}
    if game in COLLECTIONS:
        sources=list(app.glob('*.lua'))
        entry.update(code_files=len(sources),code_container_bytes=16+104*len(sources)+sum(p.stat().st_size for p in sources),
                     games={g:json.loads((root/g/'app/manifest.json').read_text())['version'] for g in GAMES})
    metadata.write_text(json.dumps(entry,indent=2)+'\n')
    return entry


def prepare(packer, linter):
    for script in ('make_game_fonts.py','make_icons.py','sync_game_ui.py','sync_game_theme.py','sync_puzzle_store.py','build_game_hub.py'):
        subprocess.run([sys.executable,str(ROOT/'scripts'/script)],check=True,cwd=ROOT)
    verified_sources={game:source_hash(ROOT/game/'app') for game in GAMES+COLLECTIONS}
    command=[sys.executable,str(ROOT/'scripts/check_games.py'),'--packer',str(packer),'--linter',str(linter)]
    subprocess.run(command,check=True,cwd=ROOT)
    assert all(source_hash(ROOT/game/'app')==fingerprint for game,fingerprint in verified_sources.items()), 'Source changed during verification; rerun the release'
    releases=ROOT/'releases';releases.mkdir(exist_ok=True)
    entries=[archive_game(game,ROOT/'dist',releases) for game in GAMES]
    hub=archive_game('games-hub',ROOT/'dist',releases)
    stamp=datetime.now(timezone.utc).strftime('%Y%m%d-%H%M%S')
    result={'created_utc':datetime.now(timezone.utc).isoformat(),'game_count':len(GAMES),
            'design_contract':'docs/GAME_DESIGN.md','games':entries,'hub':hub,
            'validation':{'quality_gate':'pass','all_source_and_bundled_games':True,
                          'native_and_bitmap_layouts':True,'save_and_update_regressions':True},
            'physical_status':'Host verified; physical reader checks remain pending'}
    dated=releases/('game-family-'+stamp+'.json')
    dated.write_text(json.dumps(result,indent=2)+'\n')
    (releases/'game-family-latest.json').write_bytes(dated.read_bytes())
    with zipfile.ZipFile(releases/('game-family-'+stamp+'.zip'),'w',compression=zipfile.ZIP_DEFLATED) as bundle:
        for entry in entries+[hub]:
            bundle.write(releases/entry['file'],'Apps/'+entry['game']+'.xtapp')
        bundle.write(dated,'game-family.json')
        bundle.write(releases/'game-font-licenses.txt','game-font-licenses.txt')
    sums=releases/'SHA256SUMS'
    lines=sums.read_text().splitlines() if sums.exists() else []
    for entry in entries+[hub]:
        lines=[line for line in lines if not line.endswith('  '+entry['file'])]
        lines.append(entry['sha256']+'  '+entry['file'])
    sums.write_text('\n'.join(lines)+'\n')
    print(f'Archived {len(entries)} games and Games Hub: {dated}')
    return releases/'game-family-latest.json'


def stage(source,target):
    data=source.read_bytes()
    pending=target.with_name(target.name+'.pending')
    stream=pending.open('xb')
    try:
        with stream:
            stream.write(data);stream.flush();os.fsync(stream.fileno())
        if pending.read_bytes()!=data:
            raise OSError('Recovery installer readback failed')
        pending.replace(target)
    finally:
        if pending.exists():pending.unlink()
    if target.read_bytes()!=data:
        raise OSError('Recovery installer replacement failed')


def deploy(card,catalogue,backup):
    document=json.loads(catalogue.read_text())
    if document.get('validation',{}).get('quality_gate')!='pass':
        raise ValueError('Release must pass quality checks before deployment')
    if not (card/'Apps').is_dir():
        raise ValueError('Mounted card with Apps/ directory required')
    family=Update.plan(card,catalogue)
    hub=Update.plan(card,catalogue.parent/document['hub']['metadata_file'])
    result={'card':str(card),'updates':family['updates']+hub['updates'],
            'skipped':family['skipped']+hub['skipped'],'device_verified':False}
    if backup.resolve().is_relative_to(card.resolve()):
        raise ValueError('Backups must remain on the computer')
    backup.mkdir(parents=True,exist_ok=False)
    before=Update.tree(card/'XTApps')
    (backup/'before-installed-files.json').write_text(json.dumps(before,indent=2)+'\n')
    entries=document['games']+[document['hub']]
    for entry in entries:
        name=entry['game']+'.xtapp'
        target=card/'Apps'/name
        assert not target.is_symlink() and not target.with_name(name+'.pending').exists()
        if target.exists():
            (backup/'previous-installers').mkdir(exist_ok=True)
            shutil.copy2(target,backup/'previous-installers'/name)
        source=catalogue.parent/entry['file']
        assert Update.digest(source.read_bytes())==entry['sha256']
    # Installable recovery copies are separate from the installed packages.
    for entry in entries:
        stage(catalogue.parent/entry['file'],card/'Apps'/(entry['game']+'.xtapp'))
    if Update.tree(card/'XTApps')!=before:
        raise ValueError('Installed files changed before deployment')
    Update.apply(result,backup/'installed-apps')
    expected=dict(before)
    for item in result['updates']:
        expected[item['app_id']+'/app.xtapp']=item['sha256']
    os.sync()
    if Update.tree(card/'XTApps')!=expected:
        raise OSError('Non-package files changed during deployment')
    missing=[x['app_id'] for x in family['skipped'] if x['reason'].startswith('not installed')]
    hub_target=card/'XTApps'/document['hub']['app_id']/'app.xtapp'
    hub_current=hub_target.exists() and Update.manifest(hub_target.read_bytes())['version']==document['hub']['version']
    receipt={'card':str(card),'backup':str(backup),'updates':[{k:x[k] for k in ('app_id','from','to','sha256')} for x in result['updates']],
             'app_data_files_preserved':sum('/files/' in '/'+name for name in before),
             'installed_files_verified':len(expected),'new_games_available_in_hub':missing if hub_current else [],
             'standalone_apps_requiring_initial_registration':missing,
             'recovery_installers_verified':len(entries),'flushed':True,'device_launch_verified':False}
    (backup/'delivery.json').write_text(json.dumps(receipt,indent=2)+'\n')
    print(json.dumps(receipt,indent=2))
    return receipt


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--packer',type=Path,default=ROOT.parent/'touch-licorice-apps/xtpack.py')
    parser.add_argument('--linter',type=Path,default=ROOT.parent/'touch-licorice-apps/tools/lualint55.py')
    parser.add_argument('--card',type=Path)
    parser.add_argument('--apply-only',action='store_true')
    parser.add_argument('--backup',type=Path,default=Path.home()/'Backups'/('xteink-family-update-'+datetime.now().strftime('%Y%m%d-%H%M%S')))
    args=parser.parse_args()
    catalogue=ROOT/'releases/game-family-latest.json' if args.apply_only else prepare(args.packer.resolve(),args.linter.resolve())
    if args.card:
        document=json.loads(catalogue.read_text())
        assert {entry['game'] for entry in document['games']}==set(GAMES),'Incomplete game catalogue'
        for entry in document['games']+[document['hub']]:
            assert source_hash(ROOT/entry['game']/'app')==entry['source_sha256'],'Source changed since release verification'
        receipt=deploy(args.card.resolve(),catalogue,args.backup.resolve())
        (ROOT/'releases'/('game-family-sd-update-'+datetime.now().strftime('%Y%m%d-%H%M%S')+'.json')).write_text(json.dumps(receipt,indent=2)+'\n')


if __name__=='__main__':
    main()
