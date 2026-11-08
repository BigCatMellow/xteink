-- Replay an unchanged source suite against its bundled engine and storage adapter.
-- Run from a source game's directory: lua ../tests/run_hub_game.lua [--bitmap]
local native_require=require
local native_dofile=dofile
package.path='../games-hub/app/?.lua;../tests/?.lua;'..package.path
local manifest=assert(io.open('app/manifest.json')):read('*a')
local id=assert(manifest:match('"app_id"%s*:%s*"([a-z]+)"'))
local factory=native_require('game_'..id)
local Namespace=native_require('namespace')
local UI=native_require('ui')
local private=factory({})
function require(name)
  if name=='game_canvas' then return native_require(name) end
  return private.require(name)
end
function dofile(path)
  if path~='app/index.lua' then return native_dofile(path) end
  local engine=factory(_G.__TEST)
  private=engine
  local scope=Namespace.new(id)
  local function context(c)
    -- The existing suite inspects unprefixed fixture keys. Assert the real
    -- adapter's names, then bridge them back into that unchanged fixture.
    local root=setmetatable({}, {__index=c})
    root.storage={}
    for _,method in ipairs({'read','write','remove','exists','size'}) do
      root.storage[method]=function(_,key,...)
        assert(key:sub(1,#scope.prefix)==scope.prefix,'unscoped game save')
        return c.storage[method](c.storage,key:sub(#scope.prefix+1),...)
      end
    end
    return scope:context(root)
  end
  function on_load(c) return engine.load(context(c)) end
  function on_draw(c,g)
    UI.header(true)
    local ok,err=pcall(engine.draw,context(c),UI.game_canvas(g))
    UI.header(false)
    if not ok then error(err,0) end
    -- Audit the actual reserved navigation area, including text collisions.
    if _G.__LAYOUT then _G.__LAYOUT('button',{x=20,y=16,w=44,h=44,s='Games menu'}) end
  end
  function on_input(c,e) return engine.input(context(c),e) end
  function on_leave() return engine.leave() end
end
if arg[1]=='--bitmap' then dofile('../tests/run_themed_game.lua')
else dofile('tests/test_game.lua');on_leave() end
print('HUB ENGINE: '..id..' passed through private modules, header and save namespace')
