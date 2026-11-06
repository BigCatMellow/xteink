-- Host-independent logic and graphics tests for the deterministic Pocket Golf puzzle.
_G.__TEST = {}
dofile('app/index.lua')
local A = __TEST.api
local function eq(a,b,label)
  assert(a==b,(label or 'mismatch') .. ': ' .. tostring(a) .. ' ~= ' .. tostring(b))
end
local storage={}
local f={measure=function(_,s) return #s*12 end}
local ctx={
  storage={
    read=function(_,name) return storage[name] end,
    write=function(_,name,value) storage[name]=value end
  },
  clock={
    millis=function() return 932 end,
    now=function() return {epoch_sec=2000000000} end
  },
  fonts={small=f,medium=f,large=f},
  invalidate=function() end,
}
on_load(ctx)
assert(storage['save.txt']:find('version=2',1,true),'save version 2')
eq(A.state().stage,'aim')
eq(A.state().club,2)
eq(A.state().hole,1)

-- Procedural holes are deterministic and have computed, obtainable stroke targets.
for seed=1,20 do
  for hole=1,9 do
    local course=A.generate(seed*10000,hole)
    local same=A.generate(seed*10000,hole)
    eq(course.tx,same.tx,'same tee')
    eq(course.hx,same.hx,'same cup')
    eq(table.concat(course.map,','),table.concat(same.map,','),'same terrain')
    eq(course.map[(course.ty-1)*9+course.tx],'tee')
    eq(course.map[(course.hy-1)*9+course.hx],'cup')
    assert(course.par and course.par>=2 and course.par<=15,'course target valid')
    eq(course.par,A.solve(course),'target is actual shortest path')
  end
end

-- Check exact-distance choices on an unobstructed test board.
A.begin(321654)
local s,b=A.state(),A.course()
s.x,s.y=5,6
for y=1,12 do for x=1,9 do b.map[(y-1)*9+x]='fairway' end end
assert(A.select(1))
local putt=A.legal()
eq(#putt,8,'one-square club')
for _,v in ipairs(putt) do
  eq(math.max(math.abs(v.x-5),math.abs(v.y-6)),1,'putt exact')
end
assert(A.select(2))
local chip=A.legal()
eq(#chip,8,'two-square club')
for _,v in ipairs(chip) do
  eq(math.max(math.abs(v.x-5),math.abs(v.y-6)),2,'chip exact')
end
assert(A.select(3))
local drive=A.legal()
eq(#drive,8,'four-square club')
for _,v in ipairs(drive) do
  eq(math.max(math.abs(v.x-5),math.abs(v.y-6)),4,'drive exact')
end

-- Sand allows only putts; rough denies drives.
b.map[(6-1)*9+5]='sand'
eq(#A.targets(b,5,6,1),8,'sand escape')
eq(#A.targets(b,5,6,2),0,'no chip from sand')
eq(#A.targets(b,5,6,3),0,'no drive from sand')
b.map[(6-1)*9+5]='rough'
eq(#A.targets(b,5,6,3),0,'no drive from rough')
b.map[(6-1)*9+5]='fairway'

-- Water is safe to fly over but forbidden as a landing; a tree obstructs flight.
b.map[(5-1)*9+5]='water'
b.map[(3-1)*9+5]='tree'
local function includes(t,x,y)
  for _,v in ipairs(t) do if v.x==x and v.y==y then return true end end
  return false
end
assert(includes(A.targets(b,5,6,2),5,4),'chip clears water')
assert(not includes(A.targets(b,5,6,1),5,5),'putt cannot land in water')
assert(not includes(A.targets(b,5,6,4),5,2),'out of range club invalid') -- no club 4
assert(not includes(A.targets(b,5,6,3),5,2),'tree blocks drive')
assert(not A.shoot(5,2),'invalid destination does not spend a stroke')
eq(s.strokes,0)

-- Save and load pending club and stroke count; no re-rolls exist.
A.begin(12345)
s=A.state()
assert(A.select(1))
local m=A.legal()[1]
assert(m,'at least one legal putt')
assert(A.shoot(m.x,m.y))
eq(s.strokes,1)
local px,py=s.x,s.y
assert(A.select(3))
on_leave()
on_load(ctx)
s=A.state()
eq(s.x,px);eq(s.y,py);eq(s.club,3);eq(s.strokes,1)
eq(s.stage,'aim')
assert(storage['save.txt']:find('club=3',1,true))

-- Touch buttons select the club; physical page buttons cycle it.
A.tap(355,740)
eq(A.state().club,3)
on_input(ctx,{type='key',phase='down',key='up',time_ms=1000})
eq(A.state().club,1)
on_input(ctx,{type='key',phase='down',key='down',time_ms=1400})
eq(A.state().club,3)

-- The nine-hole result records the computed optimum for each hole.
A.begin(202612)
local expected_par=0
for hole=1,9 do
  local state,course=A.state(),A.course()
  eq(state.hole,hole)
  eq(state.stage,'aim')
  expected_par=expected_par+course.par
  state.x,state.y=course.hx,course.hy+1
  assert(A.select(1))
  assert(A.shoot(course.hx,course.hy),'finish with putt')
  eq(state.stage,'finished')
  eq(state.scores[hole],1)
  eq(state.pars[hole],course.par)
  if hole<9 then assert(A.next_hole(),'advance hole') end
end
local strokes,par=A.totals()
eq(strokes,9,'completed strokes')
eq(par,expected_par,'calculated target scorecard')
on_leave()
on_load(ctx)
eq(A.state().hole,9)
eq(A.state().stage,'finished')
assert(A.next_hole(),'play again')
eq(A.state().hole,1)
eq(A.totals(),0,'new scorecard empty')

-- The renderer stays within the X4 Pro's limited draw command budget.
local commands={}
local drawCount=0
local g={}
for _,method in ipairs({'clear','text','rect','line','circle'}) do
  g[method]=function(_, ...)
    drawCount=drawCount+1
    commands[method]=(commands[method] or 0)+1
    local args={...}
    if type(args[#args])=='table' then
      assert(args[#args].color==nil,'no color-specific drawing')
    end
  end
end
local function draw_ok(on_course)
  drawCount,commands=0,{}
  on_draw(ctx,g)
  assert(drawCount>0,'expected graphics')
  assert(drawCount<=1024,'frame exceeds 1024 draw commands: '..drawCount)
  if on_course then
    assert(drawCount>480,'expected dotted paper field')
    assert(commands.circle>=475,'expected grid dots')
    assert(commands.line>10,'expected monochrome terrain edges')
  end
end
draw_ok(true)
A.tap(405,30) -- NEW confirmation
draw_ok(false)
A.tap(90,440) -- CANCEL
draw_ok(true)

-- Old dice saves are incompatible: reset safely rather than misinterpreting.
storage['save.txt']='hole=1\nstage=roll\n'
on_load(ctx)
eq(A.state().stage,'aim')
assert(storage['save.txt']:find('version=2',1,true),'migrated via new round')

print('Pocket Golf puzzle: exact clubs, hazard rules, solver, save, controls, graphics passed')
