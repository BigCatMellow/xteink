"""Check direct JPEG preview quality, source identity and native-call lifecycle."""
from pathlib import Path
import struct
import sys
import tempfile

from PIL import Image

from test_xth import reference, run_lua

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
from prepare_jpeg import prepare, prefix

LUA = r'''
package.path='app/?.lua;'..package.path
local P=require('probe')
local function load(path)
  local f=assert(io.open(path,'rb'));local raw=f:read('*a');f:close();return raw
end
local raw=load(arg[1])
local base=P.jpeg_prefix('source.xth')
assert(base==arg[3],'desktop and reader JPEG names must agree')
local files={['source.xth']=raw,[base..'.idx']=raw,[base..'.jpg']=load(arg[2]..'/'..base..'.jpg')}
local time,decodes,released,draws=0,0,0,0
local c={
  clock={millis=function() return time end},
  storage={write=function() end},
  layers={create=function() error('JPEG preview must not allocate a layer') end},
  after=function() error('JPEG preview must not schedule strip callbacks') end,
  budget={extend=function() end},gc={collect=function() end},
  image={decode=function(_,bytes)
    assert(bytes==files[base..'.jpg']);decodes=decodes+1;time=time+120
    return {width=480,height=800,release=function() released=released+1 end}
  end}
}
local function read(name) time=time+100;return files[name] end
local picture=assert(P.run(c,'jpeg','source.xth',read))
assert(decodes==1 and picture.metrics.total_ms==420 and picture.metrics.decode_ms==120)
assert(picture.metrics.cache_kind=='jpeg100' and picture.metrics.cache_hits==1)
local g={image=function(_,image,x,y) assert(image.width==480 and x==0 and y==0);draws=draws+1 end}
picture:draw(g);picture:draw(g);assert(decodes==1 and draws==2,'redraw must reuse the JPEG')
local ok,why=picture:draw({image=function() return nil,'native draw rejected' end})
assert(not ok and why:find('native draw rejected'))
picture:release();picture:release();assert(released==1)
files[base..'.idx']=raw:sub(1,-2)..string.char((raw:byte(-1)+1)%256)
local p,e=P.run(c,'jpeg','source.xth',read)
assert(not p and e:find('Prepare the quick preview') and decodes==1)
files[base..'.idx']=raw
local original=files[base..'.jpg']
for _,bad in ipairs({'missing','truncated','wrong-format'}) do
  files[base..'.jpg']=bad=='missing' and false or bad=='truncated' and '\255\216' or 'NOT JPEG'
  local p,e=P.run(c,'jpeg','source.xth',read)
  assert(not p and e:find('missing or damaged') and decodes==1)
end
files[base..'.jpg']=original
c.image.decode=function() return nil,'native rejected JPEG' end
local p,e=P.run(c,'jpeg','source.xth',read)
assert(not p and e:find('native rejected JPEG'))
c.image.decode=function() return {width=240,height=400,release=function() released=released+1 end} end
local p,e=P.run(c,'jpeg','source.xth',read)
assert(not p and e:find('incorrect dimensions') and released==2)
print('Direct JPEG preview: one decode, no layer/callbacks; source invalidation and failure cleanup PASS')
'''


def main():
    with tempfile.TemporaryDirectory(prefix='xth-jpeg-quality-') as temporary:
        folder = Path(temporary)
        source = folder / 'source.xth'
        payload = bytes((i * 29 + i // 100) % 256 for i in range(96000))
        original = struct.pack('<4sHHBBIQ', b'XTH\0', 480, 800, 0, 0, 96000, 0) + payload
        source.write_bytes(original)
        maximum, floor_diff, nearest_diff = prepare(source, folder)
        assert maximum <= 3 and floor_diff == 0 and nearest_diff == 0
        with Image.open(folder / f'{prefix(source.name)}.jpg') as decoded:
            expected = reference(original)
            actual = decoded.tobytes()
            assert max(abs(a - b) for a, b in zip(expected, actual)) == maximum
        assert source.read_bytes() == original
        run_lua(LUA, [str(source), str(folder), prefix(source.name)])
        print(f'Quality-100 JPEG: all 384000 pixels checked; max error {maximum}/255; both 4-bit mappings unchanged')


if __name__ == '__main__':
    main()
