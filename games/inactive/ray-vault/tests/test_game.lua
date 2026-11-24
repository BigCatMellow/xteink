-- Ray Vault Lua host tests. Verify deterministic beam mechanics and 12 full rounds.
package.path='app/?.lua;../../tests/?.lua;'..package.path
local measured=require('game_canvas').check
_G.__TEST={}
dofile('app/index.lua')
local A=__TEST.api
local function eq(a,b,name)
  assert(a==b,(name or 'mismatch')..': '..tostring(a)..' != '..tostring(b))
end
local store={}
local redraws=0
local f={measure=function(_,s) return #s*10 end}
local ctx={
  storage={
    read=function(_,name) return store[name] end,
    write=function(_,name,val) store[name]=val end
  },
  fonts={small=f,medium=f,large=f},
  clock={millis=function() return 10000 end},
  invalidate=function() redraws=redraws+1 end
}
on_load(ctx)
eq(A.state().level,1)
assert(store['ray-vault.txt']:find('version=1',1,true))
eq(#A.levels,12)
assert(not A.next(),'no skipping new stage')

-- Every level: all 24 probes terminate, detour partners are reciprocal,
-- secret atoms are unique within 6x6, and can be solved without a hint.
for level=1,12 do
  local locs=A.levels[level]
  eq(#locs,level<=6 and 3 or 4)
  local secret=A.atoms(level)
  local count=0
  for i=1,36 do if secret[i] then count=count+1 end end
  eq(count,#locs,'unique atom cells')
  local hits,refs,detours=0,0,0
  for port=1,24 do
    local outcome=A.trace(secret,port)
    assert(outcome~='LOOP' and outcome~=nil,'invalid ray')
    if outcome=='H' then hits=hits+1
    elseif outcome=='R' then refs=refs+1
    else
      assert(outcome>=1 and outcome<=24 and outcome~=port,'bad detour')
      eq(A.trace(secret,outcome),port,'detour reciprocity')
      detours=detours+1
    end
  end
  assert(hits>=4 and refs>=1 and detours>=4,'level has varied ray results')
end

-- H/R and detour probes should persist; repeated ports are not double charged.
A.start(1,1)
local s=A.state()
local target=A.atoms(1)
local selected=nil
for p=1,24 do
  if type(A.trace(target,p))=='number' then selected=p;break end
end
assert(selected)
assert(A.fire(selected))
eq(s.shots,1)
local to=A.trace(target,selected)
assert(s.probes[selected]~='-' and s.probes[to]==s.probes[selected])
assert(not A.fire(to),'paired exit is already known')
eq(s.shots,1)
on_leave();on_load(ctx)
eq(A.state().shots,1)
eq(A.state().probes[to],A.state().probes[selected])

-- Tap a cell cycles empty -> atom -> X -> empty.
A.start(1,1)
s=A.state()
assert(A.mark(0,0));eq(s.marks[1],1)
assert(A.mark(0,0));eq(s.marks[1],2)
assert(A.mark(0,0));eq(s.marks[1],0)
assert(not A.mark(-1,0))
assert(not A.mark(6,4))

-- CHECK with too few marks does not consume progress or unlock.
assert(A.check())
eq(s.stage,'play');eq(s.checks,0)

-- Test incorrect exact-K guess; marks remain editable afterward.
for i=1,#A.levels[1] do
  local p=i-1
  assert(A.mark(p%6,math.floor(p/6)))
end
assert(A.check())
eq(s.stage,'play');eq(s.checks,1)
assert(A.clear())
eq(s.shots,0);eq(s.checks,1)

-- Full 12-stage end-to-end complete, save/restore and unlock tests.
for level=1,12 do
  A.start(level,level)
  local state=A.state()
  local locs=A.levels[level]
  assert(not A.correct(),'level begins unsolved')
  -- Check probe readings are accessible without exposing hidden atoms.
  local one=1
  assert(A.fire(one))
  assert(state.probes[one]~='-')
  local past=state.shots
  for _,p in ipairs(locs) do assert(A.mark(p%6,math.floor(p/6))) end
  assert(A.correct())
  assert(A.check(),'submit all atoms')
  eq(state.stage,'won')
  eq(state.shots,past)
  eq(state.unlocked,math.min(12,level+1))
  measured(ctx,on_draw,'ray-vault solved '..level)
  on_leave();on_load(ctx)
  eq(A.state().stage,'won','saved solved state')
  eq(A.state().level,level)
  if level<12 then assert(A.next()) else assert(not A.next()) end
end

-- A correct but unsubmitted guess must survive closing before CHECK.
A.start(5,8)
for _,p in ipairs(A.levels[5]) do A.mark(p%6,math.floor(p/6)) end
assert(A.correct())
eq(A.state().stage,'play')
on_leave();on_load(ctx)
eq(A.state().level,5,'unsubmitted answer preserves current level')
eq(A.state().unlocked,8,'unsubmitted answer preserves unlocks')
eq(A.state().stage,'play','only CHECK can submit an answer')
assert(A.correct(),'all guessed atoms preserved')
assert(A.check());eq(A.state().stage,'won')

-- Page controls and touch: only complete up events cause one screen update.
A.start(2,12)
local before=redraws
local x,y=A.pos(2)
on_input(ctx,{type='pointer',phase='down',gesture='tap',x=x,y=y})
eq(redraws,before)
on_input(ctx,{type='pointer',phase='up',gesture='swipe',x=x,y=y})
eq(redraws,before)
on_input(ctx,{type='pointer',phase='up',gesture='tap',x=x,y=y})
eq(redraws,before+1,'one redraw per probe')
on_input(ctx,{type='pointer',phase='up',gesture='tap',x=x,y=y})
eq(redraws,before+1,'known port ignores repeated tap')
local bx,by,spacing=A.geometry()
local px,py=bx+spacing/2,by+spacing/2
on_input(ctx,{type='pointer',phase='up',gesture='tap',x=px,y=py})
eq(redraws,before+2,'mark a cell once')

-- Static e-ink graphics command budget (no alpha, grayscale or animation).
local g,commands,counts={},0,{}
for _,method in ipairs({'clear','line','circle','rect','text'}) do
  g[method]=function(_, ...)
    commands=commands+1
    counts[method]=(counts[method] or 0)+1
    local args={...}
    if type(args[#args])=='table' then
      assert(args[#args].opacity==nil and args[#args].color==nil)
    end
  end
end
for level=1,12 do
  A.start(level,12)
  commands,counts=0,{}
  on_draw(ctx,g)
  assert(commands>60 and commands<350,'bounded renderer '..commands)
  eq(counts.clear,1,'single frame')
end
assert(type(on_tick)=='nil','no redraw timer')
store['ray-vault.txt']='version=1\nlevel=999\nmarks=99\n'
on_load(ctx)
eq(A.state().level,1,'malformed save resets')
-- Regression: visiting other levels must not discard unfinished work.
A.start(2,12)
assert(A.mark(0,0));assert(A.fire(1))
local retained_reading=A.state().probes[1]
assert(A.next());on_leave();on_load(ctx);assert(A.prev())
eq(A.state().marks[1],1,'visits preserve atom guesses')
eq(A.state().probes[1],retained_reading,'visits preserve probe readings')
eq(A.state().shots,1,'visits preserve probe counts')
for port=1,24 do A.fire(port);measured(ctx,on_draw,'ray-vault probe '..port) end

-- All boards plus help are checked with distinct and enlarged font metrics.
local layout=require('game_canvas').check
for n=1,#A.levels do
  A.start(n,12)
  layout(ctx,on_draw,'ray-vault level '..n)
end
A.tap(420,30)
layout(ctx,on_draw,'ray-vault help')
A.tap(420,30)
-- Cell marks remain centered when the rim composition grows.
A.start(1,12);A.mark(0,0);A.mark(0,0)
do
 local bx,by,cell=A.geometry()
 local canvas={clear=function()end,rect=function()end,circle=function()end,text=function()end}
 local centered=0
 function canvas:line(x,y,xx,yy)
  if x~=xx and y~=yy and (x+xx)/2==bx+cell/2 and (y+yy)/2==by+cell/2 then centered=centered+1 end
 end
 on_draw(ctx,canvas)
 eq(centered,2,'both X strokes centered in their cell')
end
print('Ray Vault: 12 ray levels, reciprocal probes, guessing, save, touch, static display PASS')
