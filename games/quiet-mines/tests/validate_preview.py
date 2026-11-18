#!/usr/bin/env python3
"""Verify the interactive browser preview has exactly the native mine layouts."""
from pathlib import Path
import json
import re
import shutil
import subprocess
import tempfile

root=Path(__file__).resolve().parents[1]
levels=(root/'app'/'levels.lua').read_text()
preview=(root/'preview.html').read_text()
native=[{'id':int(i),'n':int(n),'mines':[int(v) for v in m.split(',')]}
        for i,n,m in re.findall(r'\{title="FIELD (\d+)",n=(\d+),mines=\{([0-9,]+)\}\}',levels)]
match=re.search(r'const LEVELS=(\[[^\n;]+?\]);',preview)
assert match,'Missing or malformed browser level data'
web=json.loads(match.group(1))
assert web==native, 'Browser preview does not match device boards'
assert 'function infer()' in preview and 'function hint()' in preview
assert 'width="480" height="800"' in preview, 'Preview geometry changed'
script=re.search(r'<script>(.*?)</script>',preview,re.S)
assert script, 'Interactive preview JavaScript is missing'
if shutil.which('node'):
    with tempfile.TemporaryDirectory() as directory:
        path=Path(directory)/'check.js'
        path.write_text(script.group(1))
        subprocess.run(['node','--check',str(path)],check=True)
print('PASS: interactive 480x800 Quiet Mines preview contains 24 exact device boards')
