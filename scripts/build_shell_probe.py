#!/usr/bin/env python3
"""Build the host-only Shell Probe; never discovers or writes a card/device."""
import argparse
import hashlib
import json
import shutil
import struct
import subprocess
import sys
from pathlib import Path

from make_icons import render, validate
from verify_package_icons import verify_icon

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'shell/probe/src'
STAGE = ROOT / 'dist/shell-probe/app'
PIN = '3d7e6225efc9b18d2b4aeed324a32b2e352d1f0d'


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--packer', type=Path, default=ROOT.parent / 'touch-licorice-apps/xtpack.py')
    parser.add_argument('--linter', type=Path)
    parser.add_argument('--check', action='store_true', help='Require staged sources to match, then lint and rebuild package')
    args = parser.parse_args()
    packer = args.packer.resolve()
    linter = (args.linter or packer.parent / 'tools/lualint55.py').resolve()
    # Verify the actual bytes against the repository's existing tooling pin,
    # allowing a checkout with a newer HEAD when these tools remain identical.
    for path in (packer, linter, packer.parent / 'tools/vendor/xtapp.py'):
        relative = path.relative_to(packer.parent).as_posix()
        pinned = subprocess.check_output(['git', '-C', str(packer.parent), 'show', f'{PIN}:{relative}'])
        assert path.read_bytes() == pinned, f'Tool differs from pin {PIN}: {relative}'
    contract_path = ROOT / 'docs/shell/probes/contract.json'
    contract = json.loads(contract_path.read_text())
    manifest = json.loads((SOURCE / 'manifest.json').read_text())
    assert manifest['app_id'] == contract['app_id'] == 'xteinkshellprobe'
    assert manifest['version'] == contract['app_identity']['future_version'] == '0.1.0'
    assert manifest['api'] == '2.0' and manifest['permissions'] == []
    assert not manifest.get('lockscreen')
    assert contract['marker']['filename'] == 'shell-probe-marker.json'
    assert contract['marker']['max_bytes'] == 2048
    assert contract['authority']['sd_writes_enabled_in_this_wave'] is False
    for other in ROOT.glob('*/app/manifest.json'):
        assert json.loads(other.read_text())['app_id'] != manifest['app_id'], f'ID collision: {other}'
    icon = render(SOURCE / 'icon.svg')
    validate(icon, 'shell-probe')
    from PIL import Image
    for other in ROOT.glob('*/app/icon.png'):
        with Image.open(other) as image:
            assert image.convert('1').tobytes() != icon.tobytes(), f'Icon collision: {other}'
    contents = {p.name: p.read_bytes() for p in SOURCE.glob('*.lua')}
    contents['ui.lua'] = (ROOT / 'shared/game_ui.lua').read_bytes()
    contents['config.lua'] = ('-- Generated from the frozen probe contract.\nreturn {trials={' + ','.join(json.dumps(t['id']) for t in contract['trials']) + '}}\n').encode()
    size = 16 + 104 * len(contents) + sum(map(len, contents.values()))
    assert len(contents) <= min(4, contract['minimal_package']['code_file_count_max'])
    assert size <= min(32768, contract['minimal_package']['xtco_target_bytes_max'])
    if args.check:
        assert {p.name for p in STAGE.iterdir()} == set(contents) | {'manifest.json', 'icon.png'}, 'Unexpected staged code/assets'
        assert all(p.is_file() and not p.is_symlink() for p in STAGE.iterdir()), 'Staging must contain regular files only'
        for name, data in contents.items():
            assert (STAGE / name).read_bytes() == data, f'Stale staged file: {name}'
    else:
        if STAGE.exists():
            shutil.rmtree(STAGE)
        STAGE.mkdir(parents=True)
        for name, data in contents.items():
            (STAGE / name).write_bytes(data)
    (STAGE / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    icon.save(STAGE / 'icon.png')
    subprocess.run([sys.executable, str(linter), *map(str, sorted(STAGE.glob('*.lua')))], check=True)
    package = STAGE.parent / 'shell-probe.xtapp'
    packed = subprocess.run([sys.executable, str(packer), str(STAGE), '-o', str(package)], check=True, capture_output=True, text=True)
    # Upstream prints generic card-copy instructions; this command is host-only.
    for line in packed.stdout.splitlines():
        if 'copy to the SD' not in line:
            print(line)
    raw = package.read_bytes()
    offset, length = struct.unpack_from('<II', raw, 0x10)
    packed_manifest = json.loads(raw[offset:offset + length])
    assert all(packed_manifest[k] == manifest[k] for k in ('app_id', 'version', 'api', 'permissions'))
    verify_icon(package, STAGE / 'icon.png')
    receipt = dict(contract_id=contract['contract_id'], contract_sha256=digest(contract_path),
                   app_id=manifest['app_id'], package_version=manifest['version'], package_sha256=digest(package),
                   source_sha256={p.name: digest(p) for p in sorted(STAGE.iterdir())},
                   tool_pin=PIN, code_files=len(contents), xtco_bytes=size,
                   physical_execution='NOT_RUN', sd_writes=False, host_only=True)
    (STAGE.parent / 'receipt.json').write_text(json.dumps(receipt, indent=2) + '\n')
    print(f'Host-only Shell Probe: {len(contents)}/4 Lua files, {size}/32768 XTCO bytes; no device execution')


if __name__ == '__main__':
    main()
