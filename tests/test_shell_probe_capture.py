import json
from pathlib import Path
import subprocess
import struct
import sys
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / 'scripts/shell_probe_capture.py'


class CaptureTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        self.contract = self.root / 'contract.json'
        source = Path(__file__).resolve().parents[1] / 'docs/shell/probes/contract.json'
        self.contract.write_bytes(source.read_bytes())
        self.package = self.root / 'probe.xtapp'
        self.make_package('xteinkshellprobe')
        self.output = self.root / 'capture'
        self.report = self.output / 'report.json'
        self.evidence = self.root / 'screen.txt'
        self.evidence.write_text('Operator supplied evidence')

    def make_package(self, app_id, **changes):
        data = {'app_id': app_id, 'version': '0.1.0', 'api': '2.0', 'permissions': [], 'entry': 'index.lua'}
        data.update(changes)
        manifest = json.dumps(data).encode()
        header = bytearray(128)
        header[:4] = b'XTAP'
        struct.pack_into('<HHI', header, 4, 1, 128, 128 + len(manifest))
        struct.pack_into('<II', header, 16, 128, len(manifest))
        self.package.write_bytes(header + manifest)

    def tearDown(self):
        self.tmp.cleanup()

    def run_cli(self, *args, success=True):
        result = subprocess.run([sys.executable, str(SCRIPT), *map(str, args)], capture_output=True, text=True)
        self.assertEqual(result.returncode == 0, success, result.stderr)
        return result

    def init(self):
        self.run_cli('init', '--contract', self.contract, '--package', self.package, '--output', self.output)

    def test_pending_is_not_physical_pass_and_no_clobber(self):
        self.init()
        data = json.loads(self.report.read_text())
        self.assertEqual((data['status'], data['mode']), ('pending', 'host_template'))
        self.assertTrue(all(t['observed_result'] == 'PENDING' for t in data['trials'].values()))
        result = self.run_cli('validate', '--report', self.report)
        self.assertIn('physical acceptance is not validated', result.stdout)
        self.run_cli('init', '--contract', self.contract, '--package', self.package, '--output', self.output, success=False)
        data['status'] = 'PASS'
        self.report.write_text(json.dumps(data))
        self.run_cli('validate', '--report', self.report, success=False)

    def test_observed_requires_evidence_and_tampering_fails(self):
        self.init()
        base = ('record', '--report', self.report, '--trial', 'dp0_inventory', '--outcome', 'observed')
        self.run_cli(*base, '--observation', 'Seen', success=False)
        self.run_cli(*base, '--evidence', self.evidence, success=False)
        self.run_cli(*base, '--observation', 'Seen', '--evidence', self.evidence)
        self.run_cli('validate', '--report', self.report)
        item = json.loads(self.report.read_text())['trials']['dp0_inventory']['evidence_refs'][0]
        copied = self.output / item['path']
        copied.write_text('changed')
        self.run_cli('validate', '--report', self.report, success=False)
        copied.unlink()
        self.run_cli('validate', '--report', self.report, success=False)

    def test_failed_outcome_requires_evidence_and_stays_pending(self):
        self.init()
        base = ('record', '--report', self.report, '--trial', 'dp0_inventory', '--outcome', 'failed')
        self.run_cli(*base, '--observation', 'Input failed', success=False)
        self.run_cli(*base, '--evidence', self.evidence, success=False)
        self.run_cli(*base, '--observation', 'Input failed', '--evidence', self.evidence)
        self.run_cli('validate', '--report', self.report)
        data = json.loads(self.report.read_text())
        self.assertEqual(data['status'], 'pending')
        self.assertEqual(data['trials']['dp0_inventory']['observed_result'], 'FAILED')
        data['trials']['dp0_inventory']['evidence_refs'] = []
        self.report.write_text(json.dumps(data))
        self.run_cli('validate', '--report', self.report, success=False)

    def test_manifest_configuration_must_match_contract(self):
        for change in ({'api': '2.9'}, {'permissions': ['net']},
                       {'lockscreen': 'screen.lua'}, {'entry': 'other.lua'}):
            with self.subTest(change=change):
                self.make_package('xteinkshellprobe', **change)
                self.run_cli('init', '--contract', self.contract, '--package', self.package,
                             '--output', self.output, success=False)
                self.assertFalse(self.output.exists())

    def test_symlinks_and_path_escape_rejected(self):
        self.init()
        link = self.root / 'link.txt'
        link.symlink_to(self.evidence)
        self.run_cli('record', '--report', self.report, '--trial', 'dp0_inventory', '--outcome', 'observed',
                     '--observation', 'Seen', '--evidence', link, success=False)
        data = json.loads(self.report.read_text())
        data['trials']['dp0_inventory'].update(observed_result='OBSERVED', action='Seen',
                                              evidence_refs=[{'path': '../screen.txt', 'sha256': 'a' * 64}])
        self.report.write_text(json.dumps(data))
        self.run_cli('validate', '--report', self.report, success=False)

    def test_inventory_allowlist_and_limits(self):
        self.init()
        values = self.root / 'inventory.json'
        values.write_text(json.dumps({'hardware_model': 'x' * 65}))
        base = ('record', '--report', self.report, '--trial', 'dp0_inventory', '--outcome', 'observed',
                '--observation', 'Seen', '--evidence', self.evidence, '--inventory', values)
        self.run_cli(*base, success=False)
        values.write_text(json.dumps({'serial_number': 'private'}))
        self.run_cli(*base, success=False)
        values.write_text(json.dumps({'hardware_model': 'X4 Pro', 'runtime_api_major': 2}))
        self.run_cli(*base)
        self.run_cli('validate', '--report', self.report)
        data = json.loads(self.report.read_text())
        self.assertEqual(data['inventory']['hardware_model'], 'X4 Pro')
        self.assertIsNone(data['inventory']['firmware_build'])
        data['unexpected'] = 'private'
        self.report.write_text(json.dumps(data))
        self.run_cli('validate', '--report', self.report, success=False)

    def test_invalid_record_leaves_no_new_attachments(self):
        self.init()
        values = self.root / 'values.json'
        values.write_text(json.dumps({'load_count_before': -1}))
        before = self.report.read_bytes()
        base = ('record', '--report', self.report, '--trial', 'dp0_inventory', '--outcome', 'observed',
                '--observation', 'Seen', '--evidence', self.evidence, '--values', values)
        self.run_cli(*base, success=False)
        self.assertEqual(before, self.report.read_bytes())
        self.assertEqual(list((self.output / 'evidence').iterdir()), [])
        # A preexisting attachment is never removed if a later update fails.
        existing = self.output / 'evidence' / 'preserve.txt'
        existing.write_text('keep')
        self.run_cli(*base, success=False)
        self.assertEqual(existing.read_text(), 'keep')

    def test_model_family_only(self):
        self.init()
        values = self.root / 'inventory.json'
        base = ('record', '--report', self.report, '--trial', 'dp0_inventory', '--outcome', 'observed',
                '--observation', 'Seen', '--evidence', self.evidence, '--inventory', values)
        values.write_text(json.dumps({'hardware_model': 'X4 Pro serial SECRET'}))
        self.run_cli(*base, success=False)
        self.assertEqual(list((self.output / 'evidence').iterdir()), [])
        values.write_text(json.dumps({'hardware_model': 'X4 Pro'}))
        self.run_cli(*base)
        self.run_cli('validate', '--report', self.report)

    def test_invalid_package_and_contract(self):
        self.package.write_bytes(b'bad')
        self.run_cli('init', '--contract', self.contract, '--package', self.package, '--output', self.output, success=False)
        self.assertFalse(self.output.exists())
        self.make_package('wrongapp')
        self.run_cli('init', '--contract', self.contract, '--package', self.package, '--output', self.output, success=False)
        self.make_package('xteinkshellprobe')
        contract = json.loads(self.contract.read_text())
        contract['trials'].append({'id': '../escape'})
        self.contract.write_text(json.dumps(contract))
        self.run_cli('init', '--contract', self.contract, '--package', self.package, '--output', self.output, success=False)


if __name__ == '__main__':
    unittest.main()
