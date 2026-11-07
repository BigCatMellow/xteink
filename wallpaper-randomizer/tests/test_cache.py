"""Cross-check desktop cache bundles, Lua loading, invalidation and failures."""
from io import BytesIO
from pathlib import Path
import struct
import sys
import tempfile

from PIL import Image

from test_xth import reference, run_lua

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
from prepare_cache import check_cache, prefix, prepare, unpack_group

LUA = r'''
package.path='app/?.lua;'..package.path
local X=require('xth')
local Cache=require('cache')
local f=assert(io.open(arg[1],'rb'));local raw=f:read('*a');f:close()
local name='source.xth'
local base=Cache.prefix(name)
assert(base==arg[3],'desktop and device cache names must match')
local initial={['original.xth']=raw}
for _,suffix in ipairs({'.idx','-0.bin','-1.bin','-2.bin','-3.bin','-4.bin'}) do
  local input=assert(io.open(arg[2]..'/'..base..suffix,'rb'))
  initial[base..suffix]=input:read('*a');input:close()
end
local function clone(source)
  local out={};for key,value in pairs(source) do out[key]=value end;return out
end
local function runtime(disk,quota)
  local q={}
  local stats={reads=0,writes=0,write_order={},alive=0,peak=0,layers=0,decodes=0,copies=0}
  local c={}
  c.after=function(_,_,fn) q[#q+1]=fn end
  c.storage={read=function(_,key) stats.reads=stats.reads+1;return disk[key] end,
    size=function(_,key) return disk[key] and #disk[key] end,
    write=function(_,key,value)
      if quota then return nil,'quota exceeded' end
      stats.writes=stats.writes+1;disk[key]=value
      stats.write_order[#stats.write_order+1]=key
    end,
    remove=function(_,key) disk[key]=nil end}
  c.image={decode=function(_,png)
    assert(png:sub(1,8)=='\137PNG\r\n\26\n')
    stats.decodes=stats.decodes+1;stats.alive=stats.alive+1
    stats.peak=math.max(stats.peak,stats.alive)
    local released=false
    return {release=function() assert(not released);released=true;stats.alive=stats.alive-1 end}
  end}
  c.layers={create=function()
    stats.layers=stats.layers+1
    return {draw=function(_,fn) fn({clear=function() end,image=function(_,_,x,y)
      assert(x==0 and y==stats.copies*32);stats.copies=stats.copies+1
    end}) end,release=function() stats.layers=stats.layers-1 end}
  end}
  local function drain(limit)
    local n=0
    while #q>0 and (not limit or n<limit) do
      local fn=table.remove(q,1);fn(c);n=n+1
    end
  end
  return c,stats,drain
end
local function build(disk,source,quota)
  local c,stats,drain=runtime(disk,quota)
  local completed,failure
  local picture=assert(X.compose(c,source,function(result,err) completed=result;failure=err end,nil,{name=name}))
  drain()
  assert(stats.peak<=1,'cache must not retain 25 decoded images')
  return picture,completed,failure,stats
end

-- A desktop-prepared cache must need zero encodes or cache writes, even after
-- discarding the entire Lua state/cache object (simulating app restarts).
local original_strip=X.strip
X.strip=function() error('warm cache must never encode XTH') end
for _=1,2 do
  local disk=clone(initial)
  local picture,result,err,stats=build(disk,raw)
  assert(result==picture and not err)
  assert(picture.metrics.cache_hits==25 and picture.metrics.encoded_strips==0)
  assert(stats.writes==0 and stats.reads==6 and stats.copies==25)
  picture:release();assert(stats.alive==0 and stats.layers==0)
end
X.strip=original_strip

-- Cold preparation commits five verified bundles, then its exact-source marker.
local disk={['original.xth']=raw}
local picture,result,err,stats=build(disk,raw)
assert(result==picture and not err and disk[base..'.idx']==raw)
assert(stats.writes==6 and picture.metrics.cache_hits==0 and picture.metrics.encoded_strips==25)
assert(stats.write_order[6]==base..'.idx','source marker must be committed last')
picture:release()
for key,value in pairs(disk) do
  if key:sub(1,#base)==base then
    local output=assert(io.open(arg[2]..'/native-'..key,'wb'));output:write(value);output:close()
  end
end

-- A single changed XTH bit must invalidate all cached pixels, not just compare
-- the filename/size. The user's original file is never overwritten.
local changed=raw:sub(1,-2)..string.char((raw:byte(-1)+1)%256)
local p,r,e=build(disk,changed)
assert(r==p and not e and p.metrics.cache_hits==0 and disk[base..'.idx']==changed)
assert(disk['original.xth']==raw);p:release()

-- Missing and malformed bundles are repaired from source. Existing validated
-- groups can still be reused in this build; commit the marker only at the end.
for _,bad in ipairs({'missing','truncated','wrong-format'}) do
  local damaged=clone(initial)
  if bad=='missing' then damaged[base..'-2.bin']=nil
  elseif bad=='truncated' then damaged[base..'-2.bin']='WPC1'
  else damaged[base..'-2.bin']=string.rep('x',40) end
  local p,r,e,st=build(damaged,raw)
  assert(r==p and not e and p.metrics.cache_hits==20 and p.metrics.encoded_strips==5)
  assert(st.writes==2 and damaged[base..'.idx']==raw);p:release()
end

-- Aborted builds and quota failures cannot leave a falsely valid marker.
local partial={['original.xth']=raw}
local c,st,drain=runtime(partial)
local cancelled=assert(X.compose(c,raw,function() error('cancelled job completed') end,nil,{name=name}))
drain(5);assert(partial[base..'-0.bin'] and not partial[base..'.idx'])
cancelled:release();drain();assert(st.alive==0 and st.layers==0)
local p,r,e=build(partial,raw)
assert(r==p and not e and p.metrics.cache_hits==0);p:release()
local full={['original.xth']=raw}
local p,r,e,st=build(full,raw,true)
assert(not r and e:find('quota exceeded') and not full[base..'.idx'])
assert(st.alive==0 and st.layers==0 and full['original.xth']==raw)

-- If the native decoder rejects an otherwise structurally valid warm cache,
-- invalidate it so the next attempt rebuilds from XTH.
local rejected=clone(initial)
local c,st,drain=runtime(rejected)
c.image.decode=function() return nil,'native decode failure' end
local failure
assert(X.compose(c,raw,function(result,err) assert(not result);failure=err end,nil,{name=name}))
drain();assert(failure:find('native decode failure') and not rejected[base..'.idx'] and st.layers==0)
print('Cache: warm restart skips all encodes; cold/rebuild, corruption, cancellation, quota and decoder failures PASS')
'''


def check_pixels(source, folder, native=False):
    expected = reference(source.read_bytes())
    name = ('native-' if native else '') + prefix(source.name)
    result = Image.new('L', (480, 800))
    for group in range(5):
        entries = unpack_group((folder / f'{name}-{group}.bin').read_bytes(), group)
        for part, entry in enumerate(entries):
            with Image.open(BytesIO(entry)) as strip:
                result.paste(strip, (0, group * 160 + part * 32))
    assert result.tobytes() == expected, 'cache must preserve every source pixel'


def main():
    with tempfile.TemporaryDirectory(prefix='xth-persistent-cache-test-') as temporary:
        folder = Path(temporary)
        source = folder / 'source.xth'
        payload = bytes((i * 29 + i // 100) % 256 for i in range(96000))
        source.write_bytes(struct.pack('<4sHHBBIQ', b'XTH\0', 480, 800, 0, 0, 96000, 0) + payload)
        prepare(source, folder)
        check_cache(source, folder)
        check_pixels(source, folder)
        run_lua(LUA, [str(source), str(folder), prefix(source.name)])
        check_pixels(source, folder, native=True)
        print('Desktop and reader-built caches: all 384000 pixels match independent reference')


if __name__ == '__main__':
    main()
