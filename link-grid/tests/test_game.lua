-- Link Grid v0.1 Lua host-simulation tests.
-- Independent Python CSP test checks exact solution uniqueness.
package.path='app/?.lua;../tests/?.lua;'..package.path
local measured=require('game_canvas').check
_G.__TEST={}
dofile('app/index.lua')
local A=__TEST.api
local function eq(a,b,msg)
  assert(a==b,(msg or 'mismatch')..': '..tostring(a)..' ~= '..tostring(b))
end

-- Offline reference solutions live only in tests, never in the shipped app.
local solutions={
  '06AC050529010000','6AE8505010100000',
  '44003D0007A82900','6AA87AA810000000',
  '44003FA807802900','0068007C00552A91',
  '6EE851383A800000','046C47953D010100',
  '02AC02AD00692AB8','0000444453F93AB8',
  '0000000400685407E95013AB8','00000044006BD0056FEC11111',
  '2AC682C3F803AF80003800000','2C00043E843AD6902BD000290',
  '0400005400453AC3D2AD2BAA9','2EAEC294516AFF81013800000',
  '444003FB802FAA86FEA811100','6EAEC156D1055502D53C01101',
  '2EC6C417D5569153FA8103800','6AAA87AA8078440547BC3B901'
}
eq(#solutions,20)
local memory={}
local redraws=0
local font={measure=function(_,s) return #s*10 end}
local ctx={
  storage={
    read=function(_,n) return memory[n] end,
    write=function(_,n,data) memory[n]=data end
  },
  fonts={small=font,medium=font,large=font},
  clock={millis=function() return 5000 end},
  invalidate=function() redraws=redraws+1 end
}
on_load(ctx)
eq(A.state().level,1)
eq(A.state().unlocked,1)
assert(not A.solved(A.state().board,A.state().tiles))
assert(memory['link-grid.txt']:find('version=1',1,true))

local function tileinfo(level)
  local board=A.load_level(level)
  eq(board.size,level<=10 and 4 or 5,'board progression')
  return board
end
for level=1,20 do
  local b=tileinfo(level)
  eq(#b.initial,b.size*b.size,'tile array')
  eq(#solutions[level],#b.initial,'fixture length')
  local active,locked=0,0
  for i,v in ipairs(b.initial) do
    if v~=0 then active=active+1 end
    if b.locked[i] then
      locked=locked+1
      eq(v,tonumber(solutions[level]:sub(i,i),16),'fixed tile solved orientation')
    end
  end
  assert(active>=8 and locked>=2,'level contains meaningful tiles')
  assert(not A.solved(b,b.initial),'every level begins unsolved')
  local target={}
  for i=1,#b.initial do target[i]=tonumber(solutions[level]:sub(i,i),16) end
  assert(A.solved(b,target),'reference solution must be valid for '..level)
end

-- A board visit must preserve its exact rotations, including after relaunch.
A.start(5,8)
local visiting=A.state()
local target
for i,v in ipairs(visiting.tiles) do
  if v~=0 and not visiting.board.locked[i] and A.rotate(v)~=v then target=i;break end
end
A.rotate_tile((target-1)%4+1,math.floor((target-1)/4)+1)
local expected=A.state().tiles[target]
assert(A.next());on_leave();on_load(ctx)
assert(A.prev());eq(A.state().tiles[target],expected,'NEXT/PREV retains moves')
eq(A.state().unlocked,8,'visits preserve global unlocks')
assert(A.restart())
assert(A.state().tiles[target]~=expected,'RESET explicitly clears this board')
memory={} -- isolate this navigation regression from the new-game progression test
A.start(1,1)

-- Test clockwise rotation, preserved shape, fixed/empty handling and persistence.
local s=A.state()
local b=s.board
local changing=nil
local fixed,empty=nil,nil
for i,v in ipairs(b.initial) do
  if v~=0 and not b.locked[i] and not changing then changing=i end
  if b.locked[i] and not fixed then fixed=i end
  if v==0 and not empty then empty=i end
end
assert(changing and fixed and empty)
local w=b.size
local function coords(i)
  return (i-1)%w+1,math.floor((i-1)/w)+1
end
local fx,fy=coords(fixed)
local zx,zy=coords(empty)
assert(not A.rotate_tile(fx,fy),'fixed tile ignores tap')
assert(not A.rotate_tile(zx,zy),'empty tile ignores tap')
local px,py=coords(changing)
local initial=s.tiles[changing]
local rotated=A.rotate(initial)
assert(A.rotate_tile(px,py))
eq(s.tiles[changing],rotated,'quarter-turn')
on_leave()
on_load(ctx)
eq(A.state().tiles[changing],rotated,'rotated tile restored from storage')
assert(A.restart())
eq(A.state().tiles[changing],initial,'reset reverts puzzle')
assert(not A.next(),'cannot advance without solving')

-- Exercise full game loop on all 20 original stages, using the solutions.
for level=1,20 do
  local state=A.state()
  eq(state.level,level,'level advance')
  eq(state.unlocked,level,'earned next level')
  local board=state.board
  local goal=solutions[level]
  local taps=0
  for i=1,#board.initial do
    local desired=tonumber(goal:sub(i,i),16)
    if board.locked[i] then
      eq(state.tiles[i],desired,'unchangeable fixed tile')
    else
      local turns=0
      while state.tiles[i]~=desired do
        local x=(i-1)%board.size+1
        local y=math.floor((i-1)/board.size)+1
        assert(A.rotate_tile(x,y),'rotate towards solution')
        turns=turns+1;taps=taps+1
        assert(turns<=3,'valid rotation orbit')
      end
    end
  end
  assert(taps>=3,'puzzle requires deliberate input')
  assert(A.solved(board,state.tiles),'completed valid network')
  eq(state.unlocked,math.min(20,level+1),'progress unlock')
  measured(ctx,on_draw,'link-grid solved '..level)
  on_leave()
  on_load(ctx)
  assert(A.solved(A.state().board,A.state().tiles),'solved state survives relaunch')
  if level<20 then assert(A.next()) else assert(not A.next()) end
end
eq(A.state().level,20)
eq(A.state().unlocked,20)

-- Revisit older levels; unlocked progress remains accessible.
assert(A.prev())
eq(A.state().level,19)
eq(A.state().unlocked,20)
assert(A.next(),'can revisit already-unlocked next level')
eq(A.state().level,20)

-- Simulate physical device pointer release. No redraw on touches outside targets.
A.start(1,20)
local ox,oy,spacing=A.origin(4)
local count=redraws
on_input(ctx,{type='pointer',phase='down',gesture='tap',x=ox+30,y=oy+30})
eq(redraws,count,'no redraw before pointer up')
on_input(ctx,{type='pointer',phase='up',gesture='tap',x=5,y=5})
eq(redraws,count,'no redraw for empty area')
on_input(ctx,{type='pointer',phase='up',gesture='swipe_left',x=ox+30,y=oy+30})
eq(redraws,count,'swipes ignored')
local x,y=coords(changing)
on_input(ctx,{type='pointer',phase='up',gesture='tap',x=ox+(x-0.5)*spacing,y=oy+(y-0.5)*spacing})
eq(redraws,count+1,'one invalidate per valid tile tap')
assert(A.state().tiles[changing]~=initial)

-- Static graphics checks: no fades/animations, bounded call count and legible framing.
local g={}
local methods={}
local commands=0
local grid_bars={}
for _,method in ipairs({'clear','line','rect','circle','text'}) do
  g[method]=function(_, ...)
    commands=commands+1
    methods[method]=(methods[method] or 0)+1
    local args={...}
    if method=='rect' and args[5] and args[5].fill and args[5].radius==0 then grid_bars[#grid_bars+1]=args end
    if type(args[#args])=='table' then
      assert(args[#args].color==nil and args[#args].opacity==nil,'monochrome only')
    end
  end
end
for level=1,20 do
  A.start(level,20)
  commands=0;methods={};grid_bars={}
  on_draw(ctx,g)
  assert(commands<=250,'rendering commands bounded: '..commands)
  local bx,by,cell=A.origin(A.state().board.size)
  local size=A.state().board.size*cell
  local framed=false
  for _,bar in ipairs(grid_bars) do
    if bar[1]==bx and bar[2]==by and bar[3]==4 and bar[4]==size then framed=true end
  end
  assert(size>=440 and framed,'large board with explicit solid frame must be present')
  eq(methods.clear,1,'one frame clear')
end
assert(type(on_tick)=='nil','no timer/update callbacks; static states only')

-- Discard malformed/synthetic saves; never accept a fixed-tile change or bad mask.
memory['link-grid.txt']='version=1\nlevel=999\nunlocked=999\ntiles=XX\n'
on_load(ctx)
eq(A.state().level,1,'corrupt save resets')
-- All boards plus help are checked with distinct and enlarged font metrics.
local layout=require('game_canvas').check
for n=1,#A.levels do
  A.start(n,20)
  layout(ctx,on_draw,'link-grid level '..n)
end
print('Link Grid: 20 levels, rotation, network checks, persistence and static render PASS')
