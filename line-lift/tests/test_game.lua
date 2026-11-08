-- Line Lift v0.1: original layouts, logic, failure, persistence and static UI.
package.path='app/?.lua;../tests/?.lua;'..package.path
local measured=require('game_canvas').check
_G.__TEST={}
dofile('app/index.lua')
local A=__TEST.api
local function eq(a,b,n)
  assert(a==b,(n or 'mismatch')..': '..tostring(a)..' != '..tostring(b))
end
local saves={}
local invocations=0
local font={measure=function(_,s) return #s*10 end}
local ctx={
  storage={
    read=function(_,name) return saves[name] end,
    write=function(_,name,data) saves[name]=data end
  },
  clock={millis=function() return 10000 end},
  fonts={large=font,medium=font,small=font},
  invalidate=function() invocations=invocations+1 end
}
on_load(ctx)
eq(A.state().level,1)
eq(A.state().mask,0)
assert(saves['line-lift.txt']:find('version=1',1,true))

-- Verify pairwise geometry independently of the game's crossing checker.
local function intersection(a,b)
  if a.axis==b.axis then return nil end
  local h=a.axis=='h' and a or b
  local v=a.axis=='v' and a or b
  if h.lo<v.a and v.a<h.hi and v.lo<h.a and h.a<v.hi then
    return v.a,h.a
  end
  return nil
end
local function all_active(lev,mask,g)
  return math.floor(mask/math.floor(2^(g-1)))%2==0
end
local function computed_blocker(lev,mask,group)
  if not all_active(lev,mask,group) then return nil end
  for _,rid in ipairs(lev.groups[group].rods) do
    local rod=lev.rods[rid]
    for _,other in ipairs(lev.rods) do
      if rod.group~=other.group and all_active(lev,mask,other.group) and
         other.depth>rod.depth and intersection(rod,other) then
        return other.group
      end
    end
  end
  return nil
end

local levels={}
for n=1,#A.raw do
  local lev=A.interpret(n)
  local labels,ids={},{}
  for gi,grp in ipairs(lev.groups) do
    assert(not labels[grp.name],'duplicate group')
    labels[grp.name]=true
    for _,rid in ipairs(grp.rods) do
      local rod=lev.rods[rid]
      eq(rod.group,gi,'rod group identity')
      eq(rod.depth,grp.depth,'paired group depth')
    end
  end
  local crossings=0
  for i,a in ipairs(lev.rods) do
    for j,b in ipairs(lev.rods) do
      if j>i then
        if a.axis==b.axis then
          assert(a.a~=b.a,'overlapping parallel lines confuse layering')
        elseif intersection(a,b) then
          crossings=crossings+1
          local cx,cy=intersection(a,b)
          eq(A.crossing(a,b),cx,'game and test crossing x')
          local _x,_y=A.crossing(a,b)
          eq(_y,cy,'crossing y')
        end
      end
    end
    -- All pull circles stay at least 20 px from screen edges and each other.
    local px,py=A.point(a)
    assert(px>=20 and px<=460 and py>=125 and py<=555,'reachable pull button')
    for j,b in ipairs(lev.rods) do
      if j>i then
        local bx,by=A.point(b)
        assert((px-bx)^2+(py-by)^2>50^2,'overlapping touch targets')
      end
    end
  end
  assert(crossings >= #lev.groups-1,'not enough actual puzzle crossings')
  if n==11 or n==12 then
    local has_pair=false
    for _,group in ipairs(lev.groups) do
      if #group.rods==2 then has_pair=true end
    end
    assert(has_pair,'later stages introduce atomic paired pulls')
  end
  levels[#levels+1]=lev
end

-- Lower rod is blocked; wrong tap restores current board with one snag.
local first=A.level()
local below,above=nil,nil
for i,grp in ipairs(first.groups) do
  if computed_blocker(first,0,i) then below=i else above=i end
end
assert(below and above)
assert(not A.pull(below))
eq(A.state().mask,0,'failed action resets board')
eq(A.state().snags,1,'mistake count')
assert(A.pull(above))
assert(A.active(below))
assert(A.pull(below))
assert(A.done())
eq(A.state().unlocked,2)
assert(A.next())
eq(A.state().level,2)

-- Reload after a partially solved level retains the exact state.
A.fresh(5,5)
local lev=A.level()
local first_free=nil
for i=1,#lev.groups do
  if not A.blocked(i) then first_free=i;break end
end
assert(A.pull(first_free))
local mask=A.state().mask
on_leave()
on_load(ctx)
eq(A.state().mask,mask,'partial stage persisted')
eq(A.state().level,5)
eq(A.state().unlocked,5)

-- All stages have a solution found by following real visible dependencies.
for n=1,#levels do
  A.fresh(n,math.max(n,12))
  local lev=A.level()
  local trials=0
  while not A.done() do
    local options={}
    for i=1,#lev.groups do
      if A.active(i) and not computed_blocker(lev,A.state().mask,i) then
        options[#options+1]=i
      end
      if A.active(i) then
        eq(A.blocked(i)~=nil,computed_blocker(lev,A.state().mask,i)~=nil,
           'visual dependency and game agree')
      end
    end
    assert(#options>0,'deadlocked puzzle '..n)
    local candidate=options[#options]
    assert(A.pull(candidate),'every safe top rod can be lifted')
    trials=trials+1
    assert(trials<=#lev.groups,'cannot take more than one action per group')
  end
  eq(trials,#lev.groups)
  measured(ctx,on_draw,'line-lift solved '..n)
  if n<12 then assert(A.next()) end
end
eq(A.state().level,12)
eq(A.state().unlocked,12)
assert(not A.next(),'cannot advance beyond authored levels')

-- Touch only accepts buttons, never arbitrary wire strokes.
A.fresh(1,12)
local px,py=A.point(A.level().rods[1])
A.tap(240,600)
eq(A.state().mask,0,'tap outside endpoint does nothing')
A.tap(px,py)
eq(A.state().snags,1,'touch on lower rod triggers reset')
A.tap(405,30)
A.tap(px,py)
eq(A.state().snags,1,'help overlay shields gameplay')
A.tap(240,720)
A.tap(205,730)
eq(A.state().mask,0,'restart touch action')
A.tap(65,720)
eq(A.state().level,1,'previous on level one cannot underflow')
assert(type(on_tick)=='nil','no animation or timer callbacks')

-- Fake canvas captures proof of unbroken top and interrupted lower geometry.
local calls,methods=0,{}
local lines={}
local gfx={}
for _,method in ipairs({'clear','line','rect','circle','text'}) do
  gfx[method]=function(_, ...)
    calls=calls+1
    methods[method]=(methods[method] or 0)+1
    local v={...}
    if type(v[#v])=='table' then
      assert(v[#v].color==nil,'no gray/color effect')
      assert(v[#v].opacity==nil,'no alpha transition')
    end
    if method=='line' then lines[#lines+1]=v end
    if method=='rect' and v[5] and v[5].fill then
      if v[4]==4 then lines[#lines+1]={v[1],v[2]+2,v[1]+v[3]-1,v[2]+2} end
      if v[3]==4 then lines[#lines+1]={v[1]+2,v[2],v[1]+2,v[2]+v[4]-1} end
    end
    for i=1,math.min(4,#v) do
      if type(v[i])=='number' then
        assert(v[i]>=0 and v[i]<=800,'drawing coordinate out of bounds')
      end
    end
  end
end
local function render()
  calls,methods,lines=0,{},{}
  on_draw(ctx,gfx)
  assert(calls>8 and calls<450,'static graphics budget '..calls)
  eq(methods.clear,1,'one full-frame clear')
end
A.fresh(1,12)
render()
local crossing_y=151+5*39
local horizontal_segments=0
for _,v in ipairs(lines) do
  if v[2]==crossing_y and v[4]==crossing_y then horizontal_segments=horizontal_segments+1 end
end
eq(horizontal_segments,2,'lower line drawn as two segments with central gap')
assert(A.pull(2),'remove upper line')
render()
horizontal_segments=0
for _,v in ipairs(lines) do
  if v[2]==crossing_y and v[4]==crossing_y then horizontal_segments=horizontal_segments+1 end
end
eq(horizontal_segments,1,'lower line becomes continuous when no longer blocked')
assert(A.pull(1))
render()

-- Malformed saves are rejected and replaced with the first level.
saves['line-lift.txt']='version=1\nlevel=1000\nmask=0\n'
on_load(ctx)
eq(A.state().level,1,'bad save reset safely')
eq(A.state().mask,0)

-- Regression: visiting other levels must not discard unfinished work.
A.fresh(3,12)
for gi=1,#A.level().groups do if not A.blocked(gi) then assert(A.pull(gi));break end end
local retained_mask=A.state().mask
assert(retained_mask>0)
assert(A.prev());on_leave();on_load(ctx);assert(A.next())
eq(A.state().mask,retained_mask,'level visits preserve removed rods')
eq(A.state().unlocked,12,'visits preserve all unlocks')
A.tap(322,35)
measured(ctx,on_draw,'line-lift hint')
A.tap(322,35)
A.state().snags=999999
measured(ctx,on_draw,'line-lift maximum snag count')

-- All boards plus help are checked with distinct and enlarged font metrics.
local layout=require('game_canvas').check
for n=1,#A.raw do
  A.fresh(n,12)
  layout(ctx,on_draw,'line-lift level '..n)
end
A.tap(405,30)
layout(ctx,on_draw,'line-lift help')
A.tap(405,30)
print('Line Lift: 12 solvable static puzzles, layering, groups, reset, touch and save PASS')
