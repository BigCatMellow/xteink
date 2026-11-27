#!/usr/bin/env python3
"""Parse inline mockup JavaScript using Node; fail builds on syntax regressions."""
from pathlib import Path
import re
import subprocess
import tempfile

source = (Path(__file__).resolve().parents[1] / "preview.html").read_text()
scripts = re.findall(r"<script[^>]*>([\s\S]*?)</script>", source, re.I)
assert len(scripts) == 1, "Expected exactly one self-contained mockup script"
with tempfile.TemporaryDirectory() as tmp:
    filename = Path(tmp) / "preview.js"
    filename.write_text(scripts[0])
    subprocess.run(["node", "--check", str(filename)], check=True)
print("PASS: preview JavaScript parses successfully")
