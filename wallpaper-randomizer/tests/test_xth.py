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
local releases,decodes,draws=0,0,0
local c={image={decode=function(_,png)
  local n=decodes;decodes=decodes+1
  local out=assert(io.open(arg[2]..'/'..n..'.png','wb'))
  out:write(png);out:close()
  return {release=function() releases=releases+1 end}
end}}
local picture=assert(X.open(c,raw))
local g={image=function(_,img,x,y) assert(x==0 and y==draws%50*16);draws=draws+1 end}
assert(picture:draw(g))
assert(decodes==50 and releases==0)
assert(picture:draw(g))
assert(decodes==50 and draws==100,'redraw should reuse decoded strips')
picture:release();assert(releases==50)
picture:release();assert(releases==50,'release is idempotent')
local failed=assert(X.open({image={decode=function()
  if releases==50 then releases=51;return {release=function() releases=releases+1 end} end
  return nil,'unsupported'
end}},raw))
local ok,err=failed:draw(g)
assert(not ok and err:find('unsupported') and releases==52,'decode failure releases earlier strips')
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
