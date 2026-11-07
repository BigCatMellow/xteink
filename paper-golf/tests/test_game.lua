-- Rules and UI acceptance tests for Pocket Golf v0.4 (Lua host stub).
_G.__TEST={}
dofile('app/index.lua')
local A=__TEST.api
local function eq(a,b,msg)
  assert(a==b,(msg or 'mismatch')..': '..tostring(a)..' ~= '..tostring(b))
end
local storage={}
local f={measure=function(_,s) return #s*10 end}
local ctx={
  storage={
    read=function(_,name) return storage[name] end,
    write=function(_,name,data) storage[name]=data end
  },
  clock={millis=function() return 932 end,now=function() return {epoch_sec=2000000000} end},
  fonts={small=f,medium=f,large=f},
  invalidate=function() end
}
on_load(ctx)
eq(A.state().stage,'aim')
eq(A.state().drives,2)
assert(storage['save.txt']:find('version=4',1,true))

local function options(course,x,y,club,drives)
  return A.targets(course,x,y,club,drives)
end

-- Reconstruct one shortest legal solution, independently of the app's scorer.
-- State includes the remaining drives; reaching the cup must use a putt.
local function find_solution(course)
  local queue={{x=course.tx,y=course.ty,drives=2,path={}}}
  local seen={[course.tx..','..course.ty..',2']=true}
  local first=1
  while first<=#queue do
    local cur=queue[first];first=first+1
    if cur.x==course.hx and cur.y==course.hy then return cur.path end
    for club=1,3 do
      for _,dest in ipairs(options(course,cur.x,cur.y,club,cur.drives)) do
        local d=cur.drives-(club==3 and 1 or 0)
        local key=dest.x..','..dest.y..','..d
        if not seen[key] then
          seen[key]=true
          local path={}
          for k,v in ipairs(cur.path) do path[k]=v end
          path[#path+1]={club=club,x=dest.x,y=dest.y}
          queue[#queue+1]={x=dest.x,y=dest.y,drives=d,path=path}
        end
      end
    end
  end
  return nil
end

local expected={4,4,4,5,5,5,5,6,6}
local coursesSeen={}
for _,seed in ipairs({12345,12346}) do
  for hole=1,9 do
    local course=A.generate(seed,hole)
    local same=A.generate(seed,hole)
    eq(table.concat(course.map,','),table.concat(same.map,','),'deterministic puzzle')
    eq(course.map[(course.ty-1)*9+course.tx],'tee')
    eq(course.map[(course.hy-1)*9+course.hx],'cup')
    eq(course.par,expected[hole],'designed difficulty')
    eq(course.limit,course.par+(hole<=6 and 1 or 0),'stroke budget')
    eq(A.solve(course),course.par,'same target as actual solver')
    local solution=find_solution(course)
    assert(solution and #solution==course.par,'a real legal solution exists')
    eq(solution[#solution].club,1,'finishing shot is putt')
    local drives=0
    for _,s in ipairs(solution) do if s.club==3 then drives=drives+1 end end
    assert(drives<=2,'never exceed long club allowance')
    coursesSeen[hole]=true
  end
end
eq(#expected,9)

-- Water can be crossed, but not landed in. Trees block shots.
-- The cup cannot be sunk with a chip or drive.
local b=A.generate(12345,1)
local function find_tile(terrain)
  for y=1,12 do for x=1,9 do
    if b.map[(y-1)*9+x]==terrain then return x,y end
  end end
end
local waterX,waterY=find_tile('water')
local treeX,treeY=find_tile('tree')
assert(waterX and treeX,'water and trees must be real hazards')
for y=1,12 do for x=1,9 do b.map[(y-1)*9+x]='fairway' end end
b.map[5*9+5]='water' -- (5,6)
b.map[4*9+5]='tree' -- (5,5)
local function contains(spots,x,y)
  for _,p in ipairs(spots) do if p.x==x and p.y==y then return true end end
  return false
end
assert(not contains(options(b,5,7,2,2),5,5),'tree blocks chip')
assert(not contains(options(b,5,7,1,2),5,6),'cannot land in water')
b.map[4*9+5]='fairway'
assert(contains(options(b,5,7,2,2),5,5),'water can be crossed')
b.map[4*9+5]='cup'
assert(not contains(options(b,5,7,2,2),5,5),'long shots cannot sink cup')
assert(contains(options(b,5,6,1,2),5,5),'putt can sink cup')

-- The exact distances and restrictive lies remain part of the challenge.
b.map[6*9+5]='sand'
eq(#options(b,5,7,2,2),0,'sand only allows putts')
b.map[6*9+5]='rough'
eq(#options(b,5,7,3,2),0,'rough prevents drive')
b.map[6*9+5]='fairway'
eq(#options(b,5,7,3,0),0,'long clubs limited by remaining drives')

-- Save and restore the selected club and drive inventory.
A.begin(12345)
assert(A.select(1))
local first=A.legal()[1]
assert(first,'legal putt')
assert(A.shoot(first.x,first.y))
local state=A.state()
local sx,sy=state.x,state.y
assert(A.select(3))
on_leave()
on_load(ctx)
state=A.state()
eq(state.x,sx);eq(state.y,sy)
eq(state.club,3);eq(state.strokes,1);eq(state.drives,2)

-- Failure is possible, but retry resets only the current hole.
A.begin(12345)
state=A.state()
for i=1,A.course().limit do
  if state.stage~='aim' then break end
  A.select(1)
  local choices=A.legal()
  local choice=nil
  for _,p in ipairs(choices) do
    if p.x~=A.course().hx or p.y~=A.course().hy then choice=p;break end
  end
  assert(choice,'an avoid-cup putt is available')
  assert(A.shoot(choice.x,choice.y))
end
eq(state.stage,'failed','missed goal must be a real failure')
eq(state.hole,1)
eq(state.scores[1],0,'failed hole has no score')
assert(A.retry())
eq(state.stage,'aim');eq(state.strokes,0);eq(state.drives,2)
eq(state.x,A.course().tx);eq(state.y,A.course().ty)

-- A complete nine-hole round can be played using only legal input.
A.begin(86753)
local sumTarget=0
for hole=1,9 do
  local c=A.course()
  local path=find_solution(c)
  assert(path and #path==c.par)
  for _,shot in ipairs(path) do
    assert(A.select(shot.club))
    assert(A.shoot(shot.x,shot.y),'legal solution shot')
    assert(A.state().strokes<=c.limit)
  end
  eq(A.state().stage,'finished','hole completed')
  eq(A.state().scores[hole],c.par)
  eq(A.state().pars[hole],c.par)
  sumTarget=sumTarget+c.par
  on_leave()
  on_load(ctx)
  eq(A.state().stage,'finished','finished state survives restart')
  if hole<9 then assert(A.next_hole()) end
end
local strokes,target=A.totals()
eq(strokes,sumTarget);eq(target,sumTarget)
assert(A.next_hole(),'fresh round after hole nine')
eq(A.state().hole,1);eq(A.totals(),0)

-- Rendering stays inside the Lua host's 1024 command budget.
local commands,drawCount={},0
local g={}
for _,method in ipairs({'clear','text','rect','line','circle'}) do
  g[method]=function(_, ...)
    drawCount=drawCount+1
    commands[method]=(commands[method] or 0)+1
    local args={...}
    if type(args[#args])=='table' then
      assert(args[#args].color==nil,'monochrome rendering only')
    end
  end
end
local function draw_ok(expect_board)
  drawCount,commands=0,{}
  on_draw(ctx,g)
  assert(drawCount>0 and drawCount<=1024,'too many draw operations: '..drawCount)
  if expect_board then
    assert(commands.circle>=120,'paper dots missing')
    assert(commands.line>10,'hazard outlines missing')
  end
end
for hole=1,9 do
  A.begin(86753)
  for i=2,hole do
    -- Set the solved state using a legal path so next_hole() advances.
    local path=find_solution(A.course())
    for _,shot in ipairs(path) do A.select(shot.club);assert(A.shoot(shot.x,shot.y)) end
    assert(A.next_hole())
  end
  draw_ok(true)
end
A.tap(405,30);draw_ok(false);A.tap(90,440);draw_ok(true)

-- A v0.3 save is migrated while preserving its completed scores as bests.
storage['save.txt']='version=2\nhole=1\nstage=aim\n'
on_load(ctx)
eq(A.state().stage,'aim')
assert(storage['save.txt']:find('version=4',1,true))
print('Pocket Golf v0.4: 9 puzzle layouts, real fail/retry, finite drives, shortest paths, rendering PASS')
