"""Direct updates operate only on fake cards; include failure rollback."""
import hashlib
import json
from pathlib import Path
import struct
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]/'scripts'))
import update_installed_games as U


def package(appid, version, permissions=None):
    data = json.dumps({'app_id': appid, 'version': version, 'api': '2.0',
                       'permissions': permissions or []}).encode()
    header = bytearray(128)
    header[:4] = b'XTAP'
    struct.pack_into('<HHI', header, 4, 1, 128, 128+len(data))
    struct.pack_into('<II', header, 16, 128, len(data))
    return bytes(header)+data


class Updates(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.card = self.root/'card'
        self.catalogue = self.root/'releases/catalogue.json'
        self.catalogue.parent.mkdir()
        self.entries = []
        for appid in ('nonogram', 'linelift'):
            folder = self.card/'XTApps'/appid
            (folder/'files').mkdir(parents=True)
            (folder/'files/save.txt').write_bytes(b'unsubmitted board\x00undo\xff')
            (folder/'app.xtapp').write_bytes(package(appid,'0.1.0'))
            data = package(appid,'0.2.0')
            (self.catalogue.parent/(appid+'.xtapp')).write_bytes(data)
            self.entries.append({'app_id': appid, 'version': '0.2.0', 'file': appid+'.xtapp',
                                 'bytes': len(data), 'sha256': U.digest(data)})
        self.write_catalogue()

    def write_catalogue(self):
        self.catalogue.write_text(json.dumps({'games': self.entries}))

    def state(self):
        return {str(p.relative_to(self.card)): p.read_bytes() for p in self.card.rglob('*') if p.is_file()}

    def test_update_all_and_preserve_every_other_file(self):
        before = self.state()
        planned = U.plan(self.card,self.catalogue)
        self.assertEqual(len(planned['updates']),2)
        self.assertEqual(self.state(),before,'plan must not change card')
        backup = self.root/'backup'
        U.apply(planned,backup)
        for item in planned['updates']:
            target = Path(item['target'])
            self.assertEqual(U.manifest(target.read_bytes())['version'],'0.2.0')
            old_key = str(target.relative_to(self.card))
            self.assertEqual((backup/item['app_id']/'app.xtapp').read_bytes(),before.pop(old_key))
        after = self.state()
        for key,data in before.items():
            self.assertEqual(after[key],data)
        self.assertEqual(U.plan(self.card,self.catalogue)['updates'],[])

    def test_corrupt_release_and_permission_changes_are_rejected(self):
        before = self.state()
        source = self.catalogue.parent/'nonogram.xtapp'
        source.write_bytes(b'corrupt')
        with self.assertRaises(ValueError):
            U.plan(self.card,self.catalogue)
        data = package('nonogram','0.2.0',['net'])
        source.write_bytes(data)
        self.entries[0].update(bytes=len(data),sha256=U.digest(data))
        self.write_catalogue()
        with self.assertRaises(ValueError):
            U.plan(self.card,self.catalogue)
        self.assertEqual(self.state(),before)

    def test_failure_restores_all_previous_packages(self):
        before = self.state()
        result = U.plan(self.card,self.catalogue)
        original = U.replace
        failed = False
        def fail_second(target,data):
            nonlocal failed
            if target.parent.name=='linelift' and not failed:
                failed = True
                raise OSError('simulated disconnect')
            return original(target,data)
        with patch.object(U,'replace',fail_second):
            with self.assertRaises(OSError):
                U.apply(result,self.root/'backup')
        self.assertEqual(self.state(),before)

    def test_missing_app_stays_unregistered_and_downgrades_are_skipped(self):
        import shutil
        shutil.rmtree(self.card/'XTApps/nonogram')
        (self.card/'XTApps/linelift/app.xtapp').write_bytes(package('linelift','0.3.0'))
        result = U.plan(self.card,self.catalogue)
        self.assertEqual(result['updates'],[])
        self.assertEqual(len(result['skipped']),2)
        self.assertFalse((self.card/'XTApps/nonogram').exists())

    def test_stale_plan_and_symlink_cannot_write(self):
        result = U.plan(self.card,self.catalogue)
        (self.card/'XTApps/nonogram/files/save.txt').write_text('new progress')
        with self.assertRaises(ValueError):
            U.apply(result,self.root/'backup')
        self.assertEqual(U.manifest((self.card/'XTApps/nonogram/app.xtapp').read_bytes())['version'],'0.1.0')
        (self.card/'XTApps/nonogram/files/link').symlink_to(self.root/'outside')
        with self.assertRaises(ValueError):
            U.plan(self.card,self.catalogue)

    def test_collection_catalogue_and_first_import_guard(self):
        folder = self.card/'XTApps/gameshub'
        (folder/'files').mkdir(parents=True)
        (folder/'app.xtapp').write_bytes(package('gameshub','0.1.0'))
        data = package('gameshub','0.2.0')
        (self.catalogue.parent/'games-hub.xtapp').write_bytes(data)
        self.catalogue.write_text(json.dumps({'app_id': 'gameshub', 'version': '0.2.0',
            'bytes': len(data), 'file': 'games-hub.xtapp', 'sha256': U.digest(data),
            'games': {'nonogram': '0.5.0'}}))
        self.assertEqual(U.plan(self.card,self.catalogue)['updates'],[])
        (folder/'files/hub-import.txt').write_text('import finished')
        self.assertEqual(len(U.plan(self.card,self.catalogue)['updates']),1)


if __name__ == '__main__':
    unittest.main()
