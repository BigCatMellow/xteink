-- Ink Runes host simulator. Validates all 20 authored solutions and no animation.
package.path='app/?.lua;../tests/?.lua;'..package.path
local measured=require('game_canvas').check
_G.__TEST={}
dofile('app/index.lua')
local A=__TEST.api
local SOLUTIONS={
  {{7,11,10}},
  {{4,8,12}},
  {{3,7,8},{11,10,6}},
  {{11,10,6},{14,13,9}},
  {{13,9,10},{8,12,11}},
  {{6,7,11},{13,9,10}},
  {{7,8,3},{11,16,17},{21,22,23}},
  {{4,9,10},{14,15,20},{17,16,11}},
  {{8,9,10},{14,19,20},{17,16,21}},
  {{9,8,7},{11,6,1},{24,23,18}},
  {{3,4,5},{10,15,14},{23,22,17},{12,11,16}},
  {{1,2,7},{5,10,9},{17,16,21},{25,20,19}},
  {{1,6,7},{21,16,17},{25,24,23},{13,18,19}},
  {{9,8,2},{11,12,6},{17,18,24},{28,22,21},{35,29,30}},
  {{21,15,16},{12,11,10},{31,25,19},{35,34,33},{36,30,29}},
  {{18,24,23},{25,19,13},{28,29,35},{3,9,10},{31,32,26}},
  {{11,12,6},{16,22,28},{21,15,9},{34,33,32},{7,8,14},{23,29,35}},
  {{2,1,7},{6,5,11},{16,17,18},{20,14,15},{30,36,35},{32,26,27}},
  {{10,9,8},{7,1,2},{11,5,6},{15,21,27},{23,24,18},{31,25,26}},
  {{3,9,15},{8,7,13},{11,5,6},{23,29,28},{30,36,35},{32,31,25}},
}
local function eq(a,b,msg)
  assert(a==b,(msg or 'mismatch')..': '..tostring(a)..' != '..tostring(b))
end
local store={}
local invalidates=0
local font={measure=function(_,str) return #str*10 end}
local ctx={
  storage={
    read=function(_,name) return store[name] end,
    write=function(_,name,data) store[name]=data end
  },
  fonts={small=font,medium=font,large=font},
  clock={millis=function() return 10100 end},
  invalidate=function() invalidates=invalidates+1 end
}
on_load(ctx)
eq(A.state().level,1)
eq(A.state().unlocked,1)
assert(store['ink-runes.txt']:find('version=1',1,true))
eq(#A.levels,20)
eq(#SOLUTIONS,20)

-- The first rune teaches three orthogonally adjacent taps and their exact effect.
local state=A.state()
local path=SOLUTIONS[1][1]
local word=A.rune(state.b,state.ink,path)
eq(word,'MIR','first puzzle')
assert(not A.rune(state.b,state.ink,{7,10,11}),'diagonal jumps rejected')
assert(not A.next(),'no skipping unsolved stages')
assert(not A.choose(1),'void cell is not selectable')
assert(A.choose(path[1]))
assert(A.choose(path[2]))
eq(#state.selected,2,'only two pending')
local before=invalidates
assert(A.choose(path[3]))
eq(#state.selected,0,'completed word automatically applies')
assert(A.complete(state.b,state.ink),'first level solved')
eq(#state.history,1,'word undo snapshot')
eq(state.unlocked,2,'next level unlocked')
assert(A.undo())
assert(not A.complete(state.b,state.ink),'undo restores unsolved state')
eq(state.unlocked,2,'unlock progress preserved')
for _,i in ipairs(path) do assert(A.choose(i)) end
assert(A.next())
eq(A.state().level,2)

-- All 20 frozen puzzles are independently proven solvable by a separate CSP
-- search in validate_levels.py; these are full black-box UI action sequences.
for level=1,20 do
  A.start(level,level,'')
  local s=A.state()
  assert(not A.complete(s.b,s.ink),'puzzle not solved at start')
  for _,indices in ipairs(SOLUTIONS[level]) do
    assert(A.rune(s.b,s.ink,indices),'fixture is still a live word')
    for _,i in ipairs(indices) do
      assert(A.choose(i),'tap the selected path')
    end
  end
  assert(A.complete(s.b,s.ink),'level '..level..' cannot be completed')
  eq(s.unlocked,math.min(20,level+1),'progress advances once')
  measured(ctx,on_draw,'ink-runes solved '..level)
  on_leave();on_load(ctx)
  assert(A.complete(A.state().b,A.state().ink),'completed board saved '..level)
  eq(A.state().level,level,'same level after load')
  if level<20 then assert(A.next()) else assert(not A.next()) end
end

-- A partial word and a completed word can be undone without breaking saving.
A.start(8,20,'MVD')
local s=A.state()
for _,i in ipairs(SOLUTIONS[8][1]) do assert(A.choose(i)) end
local saved=A.encoding(s.ink)
assert(s.history[1])
on_leave();on_load(ctx)
eq(A.encoding(A.state().ink),saved,'partial board persisted')
assert(A.undo())
assert(not A.complete(A.state().b,A.state().ink))
assert(A.restart())
eq(A.state().level,8)
eq(A.state().unlocked,20)

-- One redraw for each accepted touch release, not intermediate/down events.
A.start(2,20,'')
local bx,by,cell=A.geometry(4)
local hitidx=SOLUTIONS[2][1][1]
local x=(hitidx-1)%4+1
local y=math.floor((hitidx-1)/4)+1
before=invalidates
on_input(ctx,{type='pointer',phase='down',gesture='tap',x=bx+(x-0.5)*cell,y=by+(y-0.5)*cell})
eq(invalidates,before,'down does not redraw')
on_input(ctx,{type='pointer',phase='up',gesture='swipe_left',x=bx+(x-0.5)*cell,y=by+(y-0.5)*cell})
eq(invalidates,before,'swipes do not redraw')
on_input(ctx,{type='pointer',phase='up',gesture='tap',x=bx+(x-0.5)*cell,y=by+(y-0.5)*cell})
eq(invalidates,before+1,'one redraw after valid tap')
on_input(ctx,{type='pointer',phase='up',gesture='tap',x=bx+(x-0.5)*cell,y=by+(y-0.5)*cell})
eq(invalidates,before+2,'tapping the same tile cancels selection')

-- Help is a static overlay and cannot accidentally activate a rune.
before=invalidates
on_input(ctx,{type='pointer',phase='up',gesture='tap',x=415,y=30})
eq(invalidates,before+1)
on_input(ctx,{type='pointer',phase='up',gesture='tap',x=bx+(x-0.5)*cell,y=by+(y-0.5)*cell})
eq(invalidates,before+1,'help shields the puzzle')
on_input(ctx,{type='pointer',phase='up',gesture='tap',x=120,y=711})
eq(invalidates,before+2)

-- Every render stays bounded, strictly monochrome and deterministic.
local g={}
local commands=0
local counts={}
for _,m in ipairs({'clear','text','rect','line','circle'}) do
  g[m]=function(_, ...)
    commands=commands+1
    counts[m]=(counts[m] or 0)+1
    local args={...}
    if type(args[#args])=='table' then
      assert(args[#args].color==nil and args[#args].opacity==nil,'no fade or grayscale')
    end
  end
end
for level=1,20 do
  A.start(level,20,'MVD')
  counts={};commands=0
  on_draw(ctx,g)
  assert(commands>=5 and commands<=220,'draw budget '..commands)
  eq(counts.clear,1,'one full-state clear')
end
assert(type(on_tick)=='nil','no timer or animation callback')

-- Old, malformed and impossible masks are not accepted as live progress.
store['ink-runes.txt']='version=1\nlevel=200\nunlocked=201\nink=101\n'
on_load(ctx)
eq(A.state().level,1,'corrupt save safely resets')
assert(store['ink-runes.txt']:find('version=1',1,true))
-- Regression: visiting other levels must not discard unfinished work.
A.start(8,20,'MVD')
for _,p in ipairs(SOLUTIONS[8][1]) do assert(A.choose(p)) end
local retained_ink=A.encoding(A.state().ink)
local retained_history=#A.state().history
assert(A.next());on_leave();on_load(ctx);assert(A.prev())
eq(A.encoding(A.state().ink),retained_ink,'visits preserve covered tiles')
eq(#A.state().history,retained_history,'visits preserve undo history')
eq(A.state().unlocked,20)
for _,p in ipairs(SOLUTIONS[8][2]) do
  A.choose(p)
  measured(ctx,on_draw,'ink-runes partial trace')
end

-- All boards plus help are checked with distinct and enlarged font metrics.
local layout=require('game_canvas').check
for n=1,#A.levels do
  A.start(n,20,'MVD')
  layout(ctx,on_draw,'ink-runes level '..n)
end
A.tap(415,30)
layout(ctx,on_draw,'ink-runes help')
A.tap(415,30)
print('Ink Runes: all 20 levels, rune effects, undo, saving, touch, render PASS')
