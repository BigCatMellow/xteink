-- Island Links Lua host tests. Independent solution-uniqueness in verify_levels.py.
_G.__TEST={}
dofile('app/index.lua')
local A=__TEST.api
local W={
  {2,1,2,2,2,1,1,0},
  {2,0,1,1,2,0,1,2},
  {1,1,2,2,0,1,1,0},
  {1,0,2,1,2,1,1,1,1,0},
  {1,2,2,1,2,2,1,2,0,0},
  {2,2,1,0,0,0,2,1,2,2},
  {1,1,0,1,0,1,2,0,1,2},
  {2,2,2,1,2,1,0,1,2,2,2,2},
  {1,2,0,0,1,0,1,0,1,1,2,1},
  {2,2,1,0,2,0,1,1,1,1,0,0},
  {2,1,1,0,0,0,1,1,1,0,2,1},
  {2,2,0,1,1,1,1,2,2,0,2,2},
}
local function eq(a,b,name)
  assert(a==b,(name or 'mismatch')..': '..tostring(a)..' != '..tostring(b))
end
local memory={}
local redraws=0
local font={measure=function(_,s) return #s*11 end}
local ctx={
  storage={
    read=function(_,name) return memory[name] end,
    write=function(_,name,value) memory[name]=value end
  },
  fonts={small=font,medium=font,large=font},
  clock={millis=function() return 10000 end},
  invalidate=function() redraws=redraws+1 end
}
on_load(ctx)
eq(A.state().level,1)
eq(#A.levels,12)
eq(#W,12)
assert(memory['island-links.txt']:find('version=1',1,true))
assert(not A.next(),'cannot skip unsolved level')
assert(not A.solved(),'empty board unsolved')

-- Geometric validation of all candidate links, correct target degrees,
-- independently specified full solutions, and no illegal crossings.
for n=1,12 do
  local points=A.nodes(n)
  local edges=A.links(points)
  local weights=W[n]
  eq(#edges,#weights,'edge count fixture')
  assert(#points>5)
  for i,a in ipairs(points) do
    assert(a.need>=1 and a.need<=8)
    for j,b in ipairs(points) do
      if j>i then assert(not(a.x==b.x and a.y==b.y)) end
    end
  end
  for i,e in ipairs(edges) do
    local a,b=points[e.a],points[e.b]
    assert(a.x==b.x or a.y==b.y,'bridges are orthogonal')
    for j,f in ipairs(edges) do
      if j>i and weights[i]>0 and weights[j]>0 then
        assert(not A.crosses(points,e,f),'solution cannot have crossing bridges')
      end
    end
  end
  local mismatch,active,cross,connected=A.stats(points,edges,weights)
  eq(mismatch,0,'island clues exact')
  eq(cross,0,'no crossing')
  assert(connected,'solution forms one network')
  assert(active>=#points-1)
end

-- Tapping a link cycles none -> single -> double -> none, undo and save.
local state=A.state()
assert(A.change(1))
eq(state.weights[1],1)
assert(A.change(1))
eq(state.weights[1],2)
assert(A.change(1))
eq(state.weights[1],0)
assert(A.undo())
eq(state.weights[1],2)
assert(A.undo())
eq(state.weights[1],1)
assert(A.reset())
eq(A.state().weights[1],0)

-- Complete 12 levels using only the exact game UI operations.
for level=1,12 do
  A.start(level,level)
  local s=A.state()
  eq(s.level,level)
  for i,target in ipairs(W[level]) do
    for _=1,target do
      assert(A.change(i),'draw a legal bridge')
    end
  end
  assert(A.solved(),'solved level '..level)
  eq(s.unlocked,math.min(12,level+1))
  on_leave()
  on_load(ctx)
  eq(A.state().level,level)
  assert(A.solved(),'solved board survives relaunch')
  if level<12 then assert(A.next()) else assert(not A.next()) end
end

-- Revisit already-unlocked puzzles; progress stays unlocked.
eq(A.state().unlocked,12)
assert(A.prev())
eq(A.state().level,11)
eq(A.state().unlocked,12)
assert(A.next())
eq(A.state().level,12)
assert(A.reset())

-- Actual pointer behavior: only a completed tap causes a redraw.
A.start(1,12)
state=A.state()
local e=state.edges[1]
local p,q=state.points[e.a],state.points[e.b]
local x1,y1=A.pos(p)
local x2,y2=A.pos(q)
local midpointX,midpointY=(x1+x2)/2,(y1+y2)/2
local before=redraws
on_input(ctx,{type='pointer',phase='down',gesture='tap',x=midpointX,y=midpointY})
eq(redraws,before)
on_input(ctx,{type='pointer',phase='up',gesture='swipe',x=midpointX,y=midpointY})
eq(redraws,before)
on_input(ctx,{type='pointer',phase='up',gesture='tap',x=midpointX,y=midpointY})
eq(redraws,before+1,'one screen update for bridge toggle')
assert(state.weights[1]>0)
on_input(ctx,{type='pointer',phase='up',gesture='tap',x=2,y=2})
eq(redraws,before+1)

-- Static renderer: bounded simple black-on-white vector command count.
local g={}
local commandCount=0
local perMethod={}
for _,method in ipairs({'clear','line','circle','rect','text'}) do
  g[method]=function(_, ...)
    commandCount=commandCount+1
    perMethod[method]=(perMethod[method] or 0)+1
    local args={...}
    if type(args[#args])=='table' then
      assert(args[#args].color==nil and args[#args].opacity==nil)
    end
  end
end
for n=1,12 do
  A.start(n,12)
  commandCount,perMethod=0,{}
  on_draw(ctx,g)
  assert(commandCount>12 and commandCount<250,'render budget '..commandCount)
  eq(perMethod.clear,1,'single static draw')
end
assert(type(on_tick)=='nil','no animation timer')
memory['island-links.txt']='version=1\nlevel=999\nweights=99\n'
on_load(ctx)
eq(A.state().level,1,'invalid save resets')
print('Island Links: 12 levels, exact degrees, connectivity, undo, save and static UI PASS')
