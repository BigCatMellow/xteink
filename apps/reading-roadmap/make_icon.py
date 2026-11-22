#!/usr/bin/env python3
"""Generate a monochrome native InkApp icon (96x96)."""
from pathlib import Path
from PIL import Image, ImageDraw
dest = Path(__file__).parent / "app" / "icon.png"
im = Image.new("1",(96,96),1)
d = ImageDraw.Draw(im)
d.rounded_rectangle((12,12,83,85),radius=9,outline=0,width=4)
d.line((47,22,47,69),fill=0,width=3)
d.arc((24,25,72,74),0,185,fill=0,width=3)
d.line((56,58,64,66),fill=0,width=4)
d.line((64,66,77,47),fill=0,width=4)
im.save(dest)
print(dest)
