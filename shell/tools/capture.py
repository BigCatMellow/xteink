#!/usr/bin/env python3
"""Create and maintain a host-only shell probe capture template.

Validation checks this bundle's structure and hashes, not device behavior.
XTAP header and manifest checks do not prove that package code is safe or runnable.
Only explicitly supplied files are read; no device or SD discovery is performed.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import stat
import struct
import sys

MAX_JSON = 65536
MAX_EVIDENCE = 10 * 1024 * 1024
MAX_FILES = 24
ID = re.compile(r"[a-zA-Z0-9_-]{1,80}\Z")
SHA = re.compile(r"[0-9a-f]{64}\Z")
EXTENSIONS = {'.png', '.jpg', '.jpeg', '.txt'}


def fail(message):
    raise ValueError(message)


def safe_file(path, limit):
    path = Path(path).absolute()
    # Refuse symlinks in every component, including the final file.
    current = Path(path.anchor)
    for part in path.parts[1:]:
        current = current / part
        if current.is_symlink():
            fail(f"symlink not allowed: {current}")
    info = path.stat()
    if not stat.S_ISREG(info.st_mode) or info.st_size > limit:
        fail(f"not a regular file or too large: {path}")
    with path.open('rb') as stream:
        data = stream.read(limit + 1)
    if len(data) > limit:
        fail(f"file too large: {path}")
    return data


def digest(data):
    return hashlib.sha256(data).hexdigest()


def load_json(path):
    return json.loads(safe_file(path, MAX_JSON))


def contract_data(path):
    raw = safe_file(path, MAX_JSON)
    contract = json.loads(raw)
    if (not isinstance(contract, dict) or contract.get('schema_version') != 1
            or contract.get('probe_id') != 'DP0-DP3'
            or not ID.fullmatch(str(contract.get('contract_id', '')))
            or not ID.fullmatch(str(contract.get('app_id', '')))):
        fail('invalid contract identity')
    trials = contract.get('trials')
    if not isinstance(trials, list) or not trials or len(trials) > 100:
        fail('contract must contain a bounded trials list')
    ids = [x.get('id') if isinstance(x, dict) else None for x in trials]
    if any(not isinstance(x, str) or not ID.fullmatch(x) for x in ids) or len(set(ids)) != len(ids):
        fail('invalid or duplicate trial id')
    capture = contract.get('capture', {})
    if (capture.get('max_report_bytes') != MAX_JSON or capture.get('max_evidence_files') != MAX_FILES
            or capture.get('max_attachment_bytes') != MAX_EVIDENCE
            or not isinstance(capture.get('inventory_fields'), dict)):
        fail('unsupported capture limits or inventory contract')
    return raw, contract, ids


def json_bytes(value):
    data = (json.dumps(value, indent=2, sort_keys=True, ensure_ascii=True) + '\n').encode()
    if len(data) > MAX_JSON:
        fail('report exceeds size limit')
    return data


def write_new(path, data):
    with open(path, 'xb') as stream:
        stream.write(data)


def report_path(path):
    path = Path(path).absolute()
    safe_file(path, MAX_JSON)
    if path.name != 'report.json':
        fail('report must be named report.json')
    return path


def validate(path, report_override=None, prospective_evidence=None):
    path = report_path(path)
    report = load_json(path) if report_override is None else report_override
    raw, contract, ids = contract_data(path.parent / 'contract.json')
    if (not isinstance(report, dict) or set(report) != {'schema_version', 'mode', 'status', 'contract_sha256', 'contract_id', 'app_id', 'probe_id', 'package_sha256', 'package_version', 'code_sha256', 'inventory', 'trials'} or report.get('schema_version') != 1):
        fail('invalid report')
    if (report.get('mode') != 'host_template' or report.get('status') != 'pending'
            or report.get('contract_sha256') != digest(raw)
            or report.get('contract_id') != contract['contract_id']
            or report.get('app_id') != contract['app_id']
            or report.get('probe_id') != contract['probe_id']):
        fail('invalid report identity, status, or contract hash')
    if not SHA.fullmatch(str(report.get('package_sha256', ''))):
        fail('invalid package hash')
    if report.get('package_version') != contract.get('app_identity', {}).get('future_version'):
        fail('invalid package version')
    code_hash = report.get('code_sha256')
    if code_hash is not None and not SHA.fullmatch(str(code_hash)):
        fail('invalid code hash')
    inventory = report.get('inventory')
    fields = contract['capture']['inventory_fields']
    if not isinstance(inventory, dict) or set(inventory) != set(fields):
        fail('invalid inventory fields')
    for key, spec in fields.items():
        value = inventory[key]
        if value is None:
            continue
        kind = spec['type']
        if key == 'hardware_model':
            valid = value in ('X4 Pro', 'X4', 'X3')
        elif kind == 'string_or_null':
            valid = isinstance(value, str) and 0 < len(value) <= spec['max_length']
        elif kind == 'enum_or_null':
            valid = value in spec['values']
        elif kind in ('integer_or_null', 'number_or_null'):
            valid = (isinstance(value, int if kind == 'integer_or_null' else (int, float))
                     and not isinstance(value, bool) and spec['min'] <= value <= spec['max'])
        else:
            valid = False
        if not valid:
            fail('invalid inventory value: ' + key)
    trials = report.get('trials')
    if not isinstance(trials, dict) or set(trials) != set(ids):
        fail('trial IDs do not match contract')
    total = 0
    for trial in trials.values():
        fields = contract['capture']['observation_fields']
        if not isinstance(trial, dict) or set(trial) != set(fields):
            fail('invalid trial fields')
        outcome, observation, evidence = trial['observed_result'], trial['action'], trial['evidence_refs']
        if outcome not in ('PENDING', 'OBSERVED', 'FAILED', 'UNKNOWN', 'SKIPPED'):
            fail('invalid outcome: physical PASS is not supported')
        if observation is not None and (not isinstance(observation, str) or len(observation) > 256):
            fail('invalid observation')
        if not isinstance(evidence, list):
            fail('invalid evidence list')
        if outcome == 'PENDING' and (evidence or any(v is not None for k, v in trial.items() if k not in ('trial_id', 'observed_result', 'evidence_refs'))):
            fail('pending trial cannot contain observations')
        if outcome in ('OBSERVED', 'FAILED') and (not observation or not observation.strip() or not evidence):
            fail('observed or failed trial requires an observation and evidence')
        if trial['trial_id'] not in ids or trials[trial['trial_id']] is not trial:
            fail('trial identity mismatch')
        for key in ('initial_state', 'action'):
            if trial[key] is not None and (not isinstance(trial[key], str) or len(trial[key]) > 256):
                fail('invalid observation text')
        for key in ('load_count_before', 'load_count_after', 'tap_count_before', 'tap_count_after', 'leave_count_before', 'leave_count_after'):
            if trial[key] is not None and (type(trial[key]) is not int or not 0 <= trial[key] <= 2147483647):
                fail('invalid observation counter')
        for key in ('input_responded', 'marker_preserved'):
            if trial[key] is not None and type(trial[key]) is not bool:
                fail('invalid observation boolean')
        for key, enum in [('observed_destination', 'destination_enum'), ('power_semantics', 'power_semantics_enum'), ('save_status', 'save_status_enum')]:
            if trial[key] is not None and trial[key] not in contract['capture'][enum]:
                fail('invalid observation enum')
        total += len(evidence)
        for item in evidence:
            if not isinstance(item, dict) or set(item) != {'path', 'sha256'}:
                fail('invalid evidence entry')
            name = item['path']
            if (not isinstance(name, str) or not re.fullmatch(r'evidence/[a-f0-9]{64}\.(?:png|jpg|jpeg|txt)', name)
                    or not SHA.fullmatch(str(item['sha256']))):
                fail('unsafe evidence path or hash')
            data = (prospective_evidence[name] if prospective_evidence is not None and name in prospective_evidence
                    else safe_file(path.parent / name, MAX_EVIDENCE))
            if digest(data) != item['sha256'] or Path(name).stem != item['sha256']:
                fail('evidence hash mismatch')
    if total > MAX_FILES:
        fail('too many evidence files')
    return report


def init(args):
    raw, contract, ids = contract_data(args.contract)
    package = safe_file(args.package, 16 * 1024 * 1024)
    if len(package) < 128 or package[:4] != b'XTAP':
        fail('invalid XTAP package')
    version, header = struct.unpack_from('<HH', package, 4)
    total = struct.unpack_from('<I', package, 8)[0]
    offset, length = struct.unpack_from('<II', package, 16)
    if version != 1 or header != 128 or total != len(package) or offset != 128 or not 1 <= length <= 8192 or offset + length > len(package):
        fail('invalid XTAP header')
    manifest = json.loads(package[offset:offset + length])
    package_version = contract.get('app_identity', {}).get('future_version')
    identity = contract.get('app_identity', {})
    if (not isinstance(manifest, dict) or manifest.get('app_id') != contract['app_id']
            or manifest.get('version') != package_version or not isinstance(package_version, str)
            or not re.fullmatch(r'\d+\.\d+\.\d+', package_version)):
        fail('package identity does not match contract')
    if (identity.get('manifest_api') != '2.0' or identity.get('permissions') != []
            or identity.get('entry') != 'index.lua' or identity.get('lockscreen') is not False
            or manifest.get('api') != identity['manifest_api']
            or manifest.get('permissions') != identity['permissions']
            or manifest.get('entry') != identity['entry'] or 'lockscreen' in manifest):
        fail('package manifest configuration does not match contract')
    code_hash = args.code_sha256
    if code_hash is not None and not SHA.fullmatch(code_hash):
        fail('code SHA-256 must be lowercase hexadecimal')
    trials = {}
    for trial_id in ids:
        trial = {field: None for field in contract['capture']['observation_fields']}
        trial.update(trial_id=trial_id, observed_result='PENDING', evidence_refs=[])
        trials[trial_id] = trial
    report = {'schema_version': 1, 'mode': 'host_template', 'status': 'pending',
              'contract_id': contract['contract_id'], 'app_id': contract['app_id'],
              'probe_id': contract['probe_id'], 'contract_sha256': digest(raw),
              'package_sha256': digest(package), 'package_version': package_version,
              'code_sha256': code_hash,
              'inventory': {field: None for field in contract['capture']['inventory_fields']},
              'trials': trials}
    output = Path(args.output).absolute()
    current = Path(output.anchor)
    for part in output.parent.parts[1:]:
        current = current / part
        if current.is_symlink():
            fail('symlink in output path')
    # Creating a new directory is mandatory; never clobber a prior capture.
    output.mkdir()
    try:
        (output / 'evidence').mkdir()
        write_new(output / 'contract.json', raw)
        write_new(output / 'report.json', json_bytes(report))
    except Exception:
        # Leave incomplete output in place so nothing is silently removed.
        raise
    print(f'Created host template: {output / "report.json"}')


def record(args):
    path = report_path(args.report)
    report = validate(path)
    if args.trial not in report['trials']:
        fail('unknown trial')
    if report['trials'][args.trial]['observed_result'] != 'PENDING':
        fail('trial already recorded; preserve the original capture')
    observation = args.observation or ''
    if len(observation) > 256:
        fail('observation too long')
    if args.outcome in ('observed', 'failed') and (not observation.strip() or not args.evidence):
        fail('observed or failed requires --observation and --evidence')
    if len(args.evidence) + sum(len(t['evidence_refs']) for t in report['trials'].values()) > MAX_FILES:
        fail('too many evidence files')
    files = []
    for source in args.evidence:
        extension = Path(source).suffix.lower()
        if extension not in EXTENSIONS:
            fail('evidence must be PNG, JPEG, or TXT')
        data = safe_file(source, MAX_EVIDENCE)
        h = digest(data)
        files.append((f'evidence/{h}{extension}', h, data))
    evidence_dir = path.parent / 'evidence'
    if evidence_dir.is_symlink() or not evidence_dir.is_dir():
        fail('unsafe evidence directory')
    entries = [{'path': name, 'sha256': h} for name, h, _ in files]
    trial = report['trials'][args.trial]
    if args.values:
        values = load_json(args.values)
        allowed = set(trial) - {'trial_id', 'observed_result', 'evidence_refs', 'action'}
        if not isinstance(values, dict) or not set(values) <= allowed:
            fail('unexpected observation fields')
        trial.update(values)
    if args.inventory:
        inventory = load_json(args.inventory)
        if args.trial != 'dp0_inventory' or not isinstance(inventory, dict) or not set(inventory) <= set(report['inventory']):
            fail('unexpected inventory fields or wrong trial')
        report['inventory'].update(inventory)
    trial.update(observed_result={'observed': 'OBSERVED', 'failed': 'FAILED', 'not_run': 'SKIPPED', 'inconclusive': 'UNKNOWN'}[args.outcome], action=observation or None, evidence_refs=entries)
    prospective = {name: data for name, _, data in files}
    validate(path, report, prospective)
    report_bytes = json_bytes(report)
    created = []
    temp = path.parent / 'report.json.tmp'
    try:
        for name, h, data in files:
            dest = path.parent / name
            if dest.exists() or dest.is_symlink():
                if digest(safe_file(dest, MAX_EVIDENCE)) != h:
                    fail('existing evidence does not match hash')
            else:
                with dest.open('xb') as stream:
                    created.append(dest)
                    stream.write(data)
        with temp.open('xb') as stream:
            created.append(temp)
            stream.write(report_bytes)
        os.replace(temp, path)
    except Exception:
        for created_path in reversed(created):
            created_path.unlink(missing_ok=True)
        raise
    print('Observation saved; physical acceptance remains pending.')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest='command', required=True)
    p = sub.add_parser('init', help='create a new host template directory')
    p.add_argument('--contract', required=True)
    p.add_argument('--package', required=True)
    p.add_argument('--output', required=True)
    p.add_argument('--code-sha256', default=None)
    p.set_defaults(func=init)
    p = sub.add_parser('record', help='record one explicitly supplied observation')
    p.add_argument('--report', required=True)
    p.add_argument('--trial', required=True)
    p.add_argument('--outcome', choices=('observed', 'failed', 'not_run', 'inconclusive'), required=True)
    p.add_argument('--observation', default='')
    p.add_argument('--evidence', action='append', default=[])
    p.add_argument('--values', help='JSON object of allowed structured observation fields')
    p.add_argument('--inventory', help='JSON object of allowed inventory fields, for DP0 only')
    p.set_defaults(func=record)
    p = sub.add_parser('validate', help='check bundle integrity, not physical acceptance')
    p.add_argument('--report', required=True)
    p.set_defaults(func=lambda args: (validate(args.report), print('Bundle integrity valid; physical acceptance is not validated.')))
    args = parser.parse_args()
    try:
        args.func(args)
    except (ValueError, OSError, json.JSONDecodeError) as exc:
        print(f'error: {exc}', file=sys.stderr)
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())
