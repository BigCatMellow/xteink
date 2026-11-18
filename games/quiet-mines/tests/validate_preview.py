#!/usr/bin/env python3
"""Check 480x800 Mines preview generates the same boards as the Lua app."""
from pathlib import Path
import re
import shutil
import subprocess
import tempfile

folder=Path(__file__).resolve().parents[1]
html=(folder/'preview.html').read_text()
assert 'width="480" height="800"' in html
assert 'id="difficultySelect"' in html and 'id="seedInput"' in html
assert 'function hint()' in html and 'function generateRandom(' in html
match=re.search(r'// PROCEDURAL_BEGIN(.*?)// PROCEDURAL_END',html,re.S)
assert match,'Preview generator is missing'
assert shutil.which('node'),'Node is required for browser-generator parity'
with tempfile.TemporaryDirectory() as tmp:
    program=Path(tmp)/'preview-generator.js'
    program.write_text(match.group(1)+r"""
for(let d=1;d<=3;d++)for(const seed of [15551,44442,31337]){
 const p=generateRandom(seed,d);
 if(!p)throw Error('Preview failed to generate '+seed+'/'+d);
 console.log(d+'\t'+seed+'\t'+p.n+'\t'+p.mines.join(','));
}
""")
    subprocess.run(['node','--check',str(program)],check=True)
    browser=subprocess.check_output(['node',str(program)],text=True).splitlines()
lua=r"""
package.path='app/?.lua;'..package.path
local G=require('generator')
for d=1,3 do
 for _,seed in ipairs({15551,44442,31337}) do
  local p,reason=G.generate(seed,d)
  assert(p,reason)
  print(d..'\t'..seed..'\t'..p.n..'\t'..table.concat(p.mines,','))
 end
end
"""
device=subprocess.check_output(['lua','-'],input=lua,text=True,cwd=folder).splitlines()
assert browser==device, 'Browser and Lua generator diverge on identical seeds'
print('PASS: Mines browser matches native procedurally generated boards across all tiers')
