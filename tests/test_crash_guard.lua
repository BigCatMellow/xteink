-- Crash guard (shared/game_ui.lua UI.guard): device-mode reports and recovery.
package.path='shared/?.lua;tests/?.lua;'..package.path
local UI=require('game_ui')
local T=require('game_canvas')

local files={}
local invalidated=0
local ctx={fonts=T.fonts(),
  storage={read=function(_,n) return files[n] end,write=function(_,n,v) files[n]=v;return true end},
  clock={millis=function() return 4242 end},
  gc={count=function() return 300*1024 end},
  device={firmware='test-fw'},api={minor=9}}
function ctx:invalidate() invalidated=invalidated+1 end

local loads,mode=0,'ok'
local spec={id='demo',state=function() return 'level=7' end}
function spec.load() loads=loads+1;if mode=='load' then error('load broke') end end
function spec.draw(_,g)
  g:clear(0)
  if mode=='draw' then local t=nil;return t.field end
end
function spec.input(_,e) if mode=='input' then error('tap broke') end;return e.type=='pointer' end
function spec.leave() if mode=='leave' then error({code='save_failed'}) end end
local G=UI.guard(spec)

local g=T.canvas()
local function draw() g:reset();G.draw(ctx,g) end
G.load(ctx);assert(loads==1)
draw()
assert(G.input(ctx,{type='pointer',phase='up',gesture='tap',x=100,y=200})==true)

-- A draw error is caught, reported and replaced by the recovery screen.
mode='draw'
draw()
local report=assert(files['crash.txt'],'crash report written')
assert(report:find('== demo crash in draw ==',1,true),'report names game and callback')
assert(report:find('state=level=7',1,true),'report includes game state')
assert(report:find('memory_kb=300',1,true),'report includes memory')
assert(report:find('firmware=test-fw api=9',1,true),'report includes firmware')
assert(report:find('recent_input=pointer,up,tap,100,200',1,true),'report includes the last tap')
assert(report:find('attempt to index',1,true),'report includes the error')
local texts={}
local text=g.text
function g:text(x,y,s,opt) texts[#texts+1]=s;return text(self,x,y,s,opt) end
mode='ok'
draw() -- still crashed: the recovery screen, not the game
g.text=text
assert(table.concat(texts,' '):find('Something went wrong',1,true),'recovery screen shown')

-- Pointer down is swallowed; the release reloads from the save.
assert(G.input(ctx,{type='pointer',phase='down',x=1,y=1})==true and loads==1)
assert(G.input(ctx,{type='pointer',phase='up',gesture='tap',x=1,y=1})==true)
assert(loads==2 and invalidated>=1,'tap reloads the game')
draw()

-- Input and load errors are also caught; only the newest three reports are kept.
mode='input';assert(G.input(ctx,{type='pointer',phase='up',x=5,y=6})==true)
mode='load';G.input(ctx,{type='pointer',phase='up',x=5,y=6})
mode='draw';G.load(ctx);draw()
local count=select(2,files['crash.txt']:gsub('\n== ',''))+1
assert(count==3,'three newest reports kept, got '..count)
assert(files['crash.txt']:sub(1,24)=='== demo crash in draw ==','newest report first')
assert(files['crash.txt']:find('crash in load',1,true) and files['crash.txt']:find('crash in input',1,true))

-- Leave errors are logged and re-raised with the original error value.
mode='leave'
local ok,err=pcall(G.leave)
assert(not ok and type(err)=='table' and err.code=='save_failed','leave re-raises the original error')
assert(files['crash.txt']:find('crash in leave',1,true))

-- Under tests every error is re-raised unchanged.
local tspec={id='demo',test={},load=spec.load,draw=spec.draw,input=spec.input,leave=spec.leave}
local TG=UI.guard(tspec)
mode='input'
ok,err=pcall(TG.input,ctx,{type='pointer',phase='up'})
assert(not ok and tostring(err):find('tap broke',1,true),'test mode re-raises')

-- A failing storage never turns a crash report into a second crash.
files=setmetatable({},{__newindex=function() error('card full') end})
ctx.storage.write=function() error('card full') end
mode='draw';local G2=UI.guard(spec);G2.load(ctx);g:reset();G2.draw(ctx,g)
print('Crash guard: reports, recovery screen, tap reload, three kept, leave/test re-raise PASS')
