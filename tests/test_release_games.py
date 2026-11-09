"""Release immutability and complete deployment on a fake card."""
import json
from pathlib import Path
import struct
import sys
import tempfile
import unittest

sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'scripts'))
import release_games as Release
import update_installed_games as Update


def package(appid,version):
    body=json.dumps({'app_id':appid,'version':version,'api':'2.0','permissions':[]}).encode()
    head=bytearray(128);head[:4]=b'XTAP'
    struct.pack_into('<HHI',head,4,1,128,128+len(body))
    struct.pack_into('<II',head,16,128,len(body))
    return bytes(head)+body


class Releases(unittest.TestCase):
    def test_immutable_archive_and_source_version_guard(self):
        with tempfile.TemporaryDirectory() as temp:
            root=Path(temp);app=root/'games/nonogram/app';app.mkdir(parents=True)
            (app/'manifest.json').write_text(json.dumps({'app_id':'nonogram','version':'0.7.0','display_name':'Nonogram'}))
            (app/'index.lua').write_text('return 1')
            dist=root/'dist';dist.mkdir();releases=root/'releases';releases.mkdir()
            original=package('nonogram','0.7.0');(dist/'nonogram.xtapp').write_bytes(original)
            first=Release.archive_game('nonogram',dist,releases,root)
            (dist/'nonogram.xtapp').write_bytes(b'fresh random encryption would differ')
            again=Release.archive_game('nonogram',dist,releases,root)
            self.assertEqual(first,again)
            self.assertEqual((releases/first['file']).read_bytes(),original)
            (app/'index.lua').write_text('return 2')
            with self.assertRaises(ValueError):
                Release.archive_game('nonogram',dist,releases,root)

    def test_batch_updates_hub_and_game_and_preserves_unrelated_data(self):
        with tempfile.TemporaryDirectory() as temp:
            root=Path(temp);card=root/'card';(card/'Apps').mkdir(parents=True)
            releases=root/'releases';releases.mkdir()
            entries=[]
            for game,appid in [('nonogram','nonogram'),('games-hub','gameshub')]:
                folder=card/'XTApps'/appid;(folder/'files').mkdir(parents=True)
                (folder/'app.xtapp').write_bytes(package(appid,'0.1.0'))
                (folder/'files/progress.txt').write_bytes(b'notes\x00undo\xff')
                if appid=='gameshub':(folder/'files/hub-import.txt').write_text('already imported')
                data=package(appid,'0.2.0');name=game+'-0.2.0.xtapp'
                (releases/name).write_bytes(data)
                entry={'game':game,'app_id':appid,'version':'0.2.0','file':name,'bytes':len(data),
                       'sha256':Update.digest(data),'metadata_file':game+'.json'}
                (releases/entry['metadata_file']).write_text(json.dumps(entry))
                (card/'Apps'/(game+'.xtapp')).write_bytes(b'previous recovery copy')
                entries.append(entry)
            # A new standalone game has no firmware registration but is in Hub.
            data=package('crownfields','0.2.0');(releases/'crown-fields.xtapp').write_bytes(data)
            new={'game':'crown-fields','app_id':'crownfields','version':'0.2.0','file':'crown-fields.xtapp','bytes':len(data),'sha256':Update.digest(data)}
            untouched=card/'XTApps/unrelated/files';untouched.mkdir(parents=True)
            (untouched/'data.bin').write_bytes(b'keep this')
            catalogue=releases/'latest.json'
            catalogue.write_text(json.dumps({'games':[entries[0],new],'hub':entries[1],'validation':{'quality_gate':'pass'}}))
            before={str(p.relative_to(card)):p.read_bytes() for p in card.glob('XTApps/*/files/*')}
            result=Release.deploy(card,catalogue,root/'backup')
            self.assertEqual(len(result['updates']),2)
            self.assertEqual(result['new_games_available_in_hub'],['crownfields'])
            self.assertFalse((card/'XTApps/crownfields').exists(),'do not invent firmware registration')
            self.assertEqual(result['recovery_installers_verified'],3)
            for name,data in before.items():self.assertEqual((card/name).read_bytes(),data)
            self.assertEqual((root/'backup/previous-installers/nonogram.xtapp').read_bytes(),b'previous recovery copy')
            catalogue.write_text(json.dumps({'validation':{'quality_gate':'failed'}}))
            with self.assertRaises(ValueError):Release.deploy(card,catalogue,root/'another-backup')


if __name__=='__main__':
    unittest.main()
