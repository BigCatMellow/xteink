"""Verify Lua XTH strips with Pillow, independently of the host image decoder."""
import argparse
import ctypes
import ctypes.util
from pathlib import Path
import shutil
import struct
import subprocess
import tempfile

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]


def run_lua(source, args):
    executable = shutil.which('lua5.4') or shutil.which('lua5.3')
    if executable:
        subprocess.run([executable, '-', *args], input=source, text=True, cwd=ROOT, check=True)
        return
    # Some desktops install the Lua 5.4 library but leave `lua` pointing to 5.1.
    import os
    lib = ctypes.CDLL(ctypes.util.find_library('lua5.4'))
    ptr = ctypes.c_void_p
    for name, signature, result in [
        ('luaL_newstate', [], ptr), ('luaL_openlibs', [ptr], None),
        ('lua_createtable', [ptr, ctypes.c_int, ctypes.c_int], None),
        ('lua_pushstring', [ptr, ctypes.c_char_p], ptr),
        ('lua_rawseti', [ptr, ctypes.c_int, ctypes.c_longlong], None),
        ('lua_setglobal', [ptr, ctypes.c_char_p], None),
        ('luaL_loadstring', [ptr, ctypes.c_char_p], ctypes.c_int),
        ('lua_pcallk', [ptr, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_longlong, ptr], ctypes.c_int),
        ('lua_tolstring', [ptr, ctypes.c_int, ptr], ctypes.c_char_p),
        ('lua_close', [ptr], None),
    ]:
        fn = getattr(lib, name)
        fn.argtypes, fn.restype = signature, result
    previous = Path.cwd()
    state = lib.luaL_newstate()
    try:
        os.chdir(ROOT)
        lib.luaL_openlibs(state)
        lib.lua_createtable(state, len(args), 0)
        for index, arg in enumerate(args, 1):
            lib.lua_pushstring(state, arg.encode())
            lib.lua_rawseti(state, -2, index)
        lib.lua_setglobal(state, b'arg')
        code = lib.luaL_loadstring(state, source.encode())
        if code == 0:
            code = lib.lua_pcallk(state, 0, 0, 0, 0, None)
        if code:
            raise AssertionError(lib.lua_tolstring(state, -1, None).decode())
    finally:
        lib.lua_close(state)
        os.chdir(previous)


LUA = r'''
package.path='app/?.lua;'..package.path
local X=require('xth')
local file=assert(io.open(arg[1],'rb'))
local raw=file:read('*a');file:close()
assert(X.validate(raw))
assert(not X.validate(raw:sub(1,-2)))
assert(not X.validate('BAD!'..raw:sub(5)))
assert(not X.validate(raw:sub(1,9)..string.char(1)..raw:sub(11)))
local function runtime(write_files)
  local stats={decodes=0,releases=0,copies=0,alive=0,peak=0,layer_alive=0}
  local queue={}
  local c={after=function(_,ms,fn) assert(ms==1);queue[#queue+1]=fn end}
  c.image={decode=function(_,png)
    if write_files then
      local out=assert(io.open(arg[2]..'/'..stats.decodes..'.png','wb'))
      out:write(png);out:close()
    end
    stats.decodes=stats.decodes+1;stats.alive=stats.alive+1
    stats.peak=math.max(stats.peak,stats.alive)
    local image={released=false}
    function image:release()
      assert(not self.released,'strip released twice')
      self.released=true;stats.alive=stats.alive-1;stats.releases=stats.releases+1
    end
    return image
  end}
  c.layers={create=function(_,w,h)
    assert(w==480 and h==800)
    stats.layer_alive=stats.layer_alive+1
    local layer={released=false}
    function layer:draw(fn)
      assert(not self.released)
      fn({clear=function() end,image=function(_,image,x,y)
        assert(not image.released,'image must survive until copy completes')
        assert(x==0 and y==stats.copies*16,'strip positions must cover every row')
        stats.copies=stats.copies+1
      end})
    end
    function layer:release()
      assert(not self.released);self.released=true;stats.layer_alive=stats.layer_alive-1
    end
    return layer
  end}
  local function drain()
    while #queue>0 do
      local before=stats.decodes
      local fn=table.remove(queue,1);fn(c)
      assert(stats.decodes-before<=1,'callback must never batch 50 decodes')
    end
  end
  return c,stats,drain,queue
end
local c,stats,drain=runtime(true)
local completed
local picture=assert(X.compose(c,raw,function(result,err) assert(not err);completed=result end))
assert(stats.decodes==0 and not completed,'compose must yield before doing expensive work')
drain()
assert(completed==picture and stats.copies==50 and stats.peak==1)
assert(stats.alive==0 and stats.releases==50 and stats.layer_alive==1)
local main_draws=0
local g={image=function(_,layer,x,y)
  assert(x==0 and y==0 and not layer.released);main_draws=main_draws+1
end}
assert(picture:draw(g));assert(picture:draw(g))
assert(main_draws==2 and stats.decodes==50,'redraw must reuse one layer')
picture:release();picture:release();assert(stats.layer_alive==0)

local cancel_c,cancel_stats,cancel_drain,cancel_queue=runtime(false)
local cancel=assert(X.compose(cancel_c,raw,function() error('cancelled build must not complete') end))
table.remove(cancel_queue,1)()
assert(cancel_stats.alive==1)
cancel:release();cancel_drain()
assert(cancel_stats.decodes==1 and cancel_stats.alive==0 and cancel_stats.layer_alive==0)

local bad_c,bad_stats,bad_drain=runtime(false)
bad_c.image.decode=function() return nil,'unsupported decoder' end
local failure
assert(X.compose(bad_c,raw,function(result,err) assert(not result);failure=err end))
bad_drain()
assert(failure:find('unsupported decoder') and bad_stats.layer_alive==0)
local bad_layer_c,bad_layer_stats,bad_layer_drain=runtime(false)
local create_layer=bad_layer_c.layers.create
bad_layer_c.layers.create=function(self,w,h)
  local layer=create_layer(self,w,h)
  layer.draw=function() return nil,'layer copy rejected' end
  return layer
end
local layer_error
assert(X.compose(bad_layer_c,raw,function(result,err) assert(not result);layer_error=err end))
bad_layer_drain()
assert(layer_error:find('layer copy rejected') and bad_layer_stats.alive==0 and bad_layer_stats.layer_alive==0)
local no_scheduler={image=c.image,layers=c.layers,after=function() error('scheduler unavailable') end}
assert(not X.compose(no_scheduler,raw,function() end))
assert(stats.layer_alive==0,'schedule failure must release its layer')
-- Production diagnostics exercise exactly one small native image per press.
local Probe=require('probe')
local checkpoint,decode_count='',0
local pc={storage={write=function(_,_,text) checkpoint=text end},image={decode=function(_,png)
  assert(checkpoint:find('stage=decode-start',1,true))
  decode_count=decode_count+1
  local out=assert(io.open(arg[2]..'/probe-'..decode_count..'.png','wb'))
  out:write(png);out:close()
  return {release=function() end}
end}}
local small=assert(Probe.run(pc,'png',nil,function() error('PNG test should not read XTH') end))
assert(decode_count==1)
small:release()
local stripe=assert(Probe.run(pc,'tile','fixture.xth',function() return raw end))
assert(decode_count==2,'strip probe must never decode 50 retained images')
stripe:release()
'''


def reference(raw):
    pixels = bytearray(480 * 800)
    shades = (255, 85, 170, 0)
    for col in range(480):
        for block in range(100):
            offset = col * 100 + block
            a, b = raw[22 + offset], raw[48022 + offset]
            for bit in range(8):
                mask = 128 >> bit
                value = (2 if a & mask else 0) + (1 if b & mask else 0)
                pixels[(block * 8 + bit) * 480 + 479 - col] = shades[value]
    return bytes(pixels)


def check(path, output):
    run_lua(LUA, [str(path), str(output)])
    result = Image.new('L', (480, 800))
    for i in range(50):
        with Image.open(output / f'{i}.png') as strip:
            strip.load()
            assert strip.size == (480, 16) and strip.mode == 'L'
            result.paste(strip, (0, i * 16))
    assert result.tobytes() == reference(path.read_bytes()), path.name
    with Image.open(output / 'probe-1.png') as tiny:
        assert tiny.size == (32, 32) and tiny.getpixel((0, 0)) == 0 and tiny.getpixel((31, 0)) == 255
    with Image.open(output / 'probe-2.png') as stripe:
        assert stripe.size == (480, 16)
        assert stripe.tobytes() == reference(path.read_bytes())[128*480:144*480]
    print(f'{path.name}: all 384000 pixels match, all four shades preserved')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('frames', nargs='*', type=Path)
    args = parser.parse_args()
    with tempfile.TemporaryDirectory(prefix='wallpaper-xth-test-') as temporary:
        folder = Path(temporary)
        # Asymmetric, nonuniform fixture exercises orientation, bit significance,
        # strip edges and all four gray levels.
        payload = bytes((i * 37 + i // 100) % 256 for i in range(96000))
        fixture = folder / 'fixture.xth'
        fixture.write_bytes(struct.pack('<4sHHBBIQ', b'XTH\0', 480, 800, 0, 0, 96000, 0) + payload)
        for path in [fixture, *args.frames]:
            check(path.resolve(), folder)


if __name__ == '__main__':
    main()
