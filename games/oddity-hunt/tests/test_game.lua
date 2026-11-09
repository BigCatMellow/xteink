-- Oddity Hunt: original scene quality, tap behavior, navigation and layout.
package.path='app/?.lua;../../tests/?.lua;'..package.path
local measured=require('game_canvas').check
_G.__TEST={}
dofile('app/index.lua')
local A=__TEST.api
local function eq(a,b,description)
  assert(a==b,(description or 'mismatch')..': '..tostring(a)..' ~= '..tostring(b))
end
local storage={}
local redraws=0
local font={measure=function(_,s) return #s*10 end,line_height=24}
local ctx={
  storage={
    read=function(_,name) return storage[name] end,
    write=function(_,name,data) storage[name]=data end
  },
  fonts={small=font,medium=font,large=font},
  clock={millis=function() return 10000 end},
  invalidate=function() redraws=redraws+1 end
}
on_load(ctx)
eq(A.state().level,1)
eq(A.state().unlocked,1)
assert(storage['oddity-hunt.txt']:find('version=1',1,true))
assert(not A.next(),'cannot skip unopened scene')

local boardCount=0
for level=1,12 do
  local scene=A.build(level)
  local again=A.build(level)
  eq(scene.name,again.name,'stable authored scene')
  eq(#scene.objects,42,'illustration must be dense')
  eq(#scene.targets,5,'five objects to find')
  local chosen={}
  local targetCount={}
  local targetSlots={}
  local seenTypes={}
  for i,kind in ipairs(scene.targets) do
    assert(A.kinds[kind],'target name')
    assert(not chosen[kind],'two targets of identical type')
    chosen[kind]=i
  end
  for i,obj in ipairs(scene.objects) do
    local same=again.objects[i]
    eq(obj.x,same.x,'stable x')
    eq(obj.y,same.y,'stable y')
    eq(obj.kind,same.kind,'stable drawing')
    eq(obj.target,same.target,'stable target')
    assert(obj.x>=43 and obj.x<=429 and obj.y>=162 and obj.y<=526,
       'object artwork must fit inside the shelf')
    assert(A.kinds[obj.kind])
    seenTypes[obj.kind]=true
    if obj.target>0 then
      eq(obj.kind,scene.targets[obj.target],'target type matches clue')
      assert(not targetSlots[obj.target],'ambiguous duplicated target')
      targetCount[obj.kind]=(targetCount[obj.kind] or 0)+1
      targetSlots[obj.target]=i
    else
      assert(not chosen[obj.kind],'a decoy must not masquerade as a unique target')
    end
    for j=i+1,#scene.objects do
      local other=scene.objects[j]
      local dx,dy=obj.x-other.x,obj.y-other.y
      assert(dx*dx+dy*dy>=48*48,
        'overlapping touch targets in scene '..level..' slots '..i..'/'..j)
    end
  end
  for i=1,5 do assert(targetSlots[i],'all five targets uniquely placed') end
  local species=0
  for _ in pairs(seenTypes) do species=species+1 end
  eq(species,20,'all 20 types appear; target species are not repeated')
  boardCount=boardCount+#scene.objects
  -- Every scene must be renderable with default and enlarged font profiles.
  A.visit(level) -- later levels are not unlocked here; see complete playthrough below
end
eq(boardCount,504,'overall illustration count')

-- Wrong object selection leaves all finds intact, but counts one miss.
local s=A.state()
local firstScene=A.build(1)
local wrong
local targetSlots={}
for i,obj in ipairs(firstScene.objects) do
  if obj.target==0 then wrong=wrong or i
  else targetSlots[obj.target]=i end
end
assert(wrong)
assert(A.pick(wrong))
eq(s.misses[1],1)
eq(s.progress[1],0)
assert(not A.touch(500,600),'empty touch region ignored')

-- HINT highlights an actually uncollected object; repeated button is free.
assert(A.hint())
eq(s.hints[1],1)
eq(s.revealed[1],1)
assert(A.hint())
eq(s.hints[1],1)
assert(A.pick(targetSlots[1]))
eq(s.revealed[1],0)
assert(A.found(s.progress[1],1))
assert(A.hint())
eq(s.hints[1],2)
eq(s.revealed[1],2)
assert(A.pick(targetSlots[2]))
eq(s.revealed[1],0)
assert(A.hint())
eq(s.hints[1],2,'two-hint allowance enforced')

-- Partial scenes, misses, hints and revealed target must persist across restart.
on_leave();on_load(ctx)
s=A.state()
eq(s.level,1)
eq(s.misses[1],1)
eq(s.hints[1],2)
eq(A.found_count(s.progress[1]),2)
eq(s.unlocked,1)
measured(ctx,on_draw,'oddity-hunt partial with misses and hints')

-- First scene finishes and unlocks second, no false positives or duplicate finds.
for target=3,5 do assert(A.pick(targetSlots[target])) end
assert(A.done())
eq(s.unlocked,2)
assert(not A.pick(targetSlots[1]),'solved scene cannot mutate on repeated find')
measured(ctx,on_draw,'oddity-hunt solved first scene')
assert(A.next())
eq(s.level,2)
assert(not A.done())
assert(A.prev())
eq(s.level,1)
eq(A.found_count(s.progress[1]),5,'level visit does not clear finds')
assert(A.next())
eq(s.level,2)

-- Start an unfinished scene, visit another, reopen, return: preserve all state.
local second=A.build(2)
local target2
for i,obj in ipairs(second.objects) do
  if obj.target==4 then target2=i;break end
end
assert(target2)
assert(A.pick(target2))
assert(A.hint())
eq(s.revealed[2],1)
assert(A.prev())
on_leave();on_load(ctx)
s=A.state()
eq(s.level,1,'prior scene still current')
assert(A.next())
eq(s.level,2)
eq(A.found_count(s.progress[2]),1,'unfinished board retained')
eq(s.revealed[2],1,'unspent hint ring retained')
eq(s.hints[2],1,'hint count retained')
measured(ctx,on_draw,'oddity-hunt reopened partial scene')

-- A retry clears only the current scene. Previously solved scenes stay solved.
assert(A.reset())
eq(A.found_count(s.progress[2]),0)
eq(s.hints[2],0)
eq(s.revealed[2],0)
eq(s.unlocked,2)
assert(A.prev())
eq(A.found_count(s.progress[1]),5)
assert(A.next())

-- Complete all twelve scenes using real object selection (no bypass).
for level=2,12 do
  eq(s.level,level)
  local scene=A.build(level)
  for target=1,5 do
    local slot
    for i,obj in ipairs(scene.objects) do
      if obj.target==target then slot=i;break end
    end
    assert(slot,'target exists')
    -- Touch the object's physical coordinate, not the unit-test shortcut.
    assert(A.touch(scene.objects[slot].x,scene.objects[slot].y))
    eq(A.found_count(s.progress[level]),target,'one new discovery')
  end
  assert(A.done())
  eq(s.unlocked,math.min(12,level+1))
  measured(ctx,on_draw,'oddity-hunt complete '..level)
  on_leave();on_load(ctx)
  s=A.state()
  eq(s.level,level)
  assert(A.done(),'complete state survives app restart')
  if level<12 then assert(A.next()) end
end
assert(not A.next(),'last scene cannot advance beyond final')

-- Control zones, including help, must not accidentally pick a shelf item.
assert(A.visit(4))
local before=redraws
on_input(ctx,{type='pointer',phase='down',gesture='tap',x=420,y=30})
eq(redraws,before,'no redraw before pointer release')
on_input(ctx,{type='pointer',phase='up',gesture='swipe_left',x=420,y=30})
eq(redraws,before,'swipe ignored')
on_input(ctx,{type='pointer',phase='up',gesture='tap',x=420,y=30})
eq(redraws,before+1)
measured(ctx,on_draw,'oddity-hunt help')
local first=A.build(4).objects[1]
on_input(ctx,{type='pointer',phase='up',gesture='tap',x=first.x,y=first.y})
eq(redraws,before+1,'help protects active board')
on_input(ctx,{type='pointer',phase='up',gesture='tap',x=220,y=736})
eq(redraws,before+2,'help back')
A.reset()
before=redraws
on_input(ctx,{type='pointer',phase='up',gesture='tap',x=first.x,y=first.y})
eq(redraws,before+1,'object tap causes one redraw')
on_input(ctx,{type='pointer',phase='up',gesture='tap',x=3,y=3})
eq(redraws,before+1,'outside touch does not redraw')

-- Layout all authored states at both font scales, including max counters.
for level=1,12 do
  assert(A.visit(level))
  A.reset()
  measured(ctx,on_draw,'oddity-hunt fresh '..level)
  A.hint()
  measured(ctx,on_draw,'oddity-hunt hint '..level)
  local state=A.state()
  state.misses[level]=9999
  state.hints[level]=2
  measured(ctx,on_draw,'oddity-hunt maximum counters '..level)
end

-- Target names are essential clues: even UMBRELLA must remain a full label.
assert(A.visit(4))
do
 local T=require('game_canvas');local original=ctx.fonts;ctx.fonts=T.fonts(1.25)
 local g=T.canvas();g:reset()
 local audit=_G.__LAYOUT;local umbrella=false
 _G.__LAYOUT=function(kind,box)
  if kind=='text' and box.s=='UMBRELLA' then umbrella=true end
  audit(kind,box)
 end
 on_draw(ctx,g);g:verify('oddity-hunt complete target labels')
 assert(umbrella,'long object names must not be shortened')
 ctx.fonts=original
end
-- Corrupt saves safely initialize new progress (but valid saves stay intact).
storage['oddity-hunt.txt']='version=1\nlevel=200\nunlocked=400\n'
on_load(ctx)
eq(A.state().level,1)
eq(A.state().unlocked,1)
assert(type(on_tick)=='nil','no animation or tick function')
print('Oddity Hunt: 12 scenes, 504 illustrations, 60 unique finds, UI, hints, persistence PASS')
