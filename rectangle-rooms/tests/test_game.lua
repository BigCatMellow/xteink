-- Rectangle Rooms: original partitions, rejected bad rectangles, save, UI.
package.path='app/?.lua;../tests/?.lua;'..package.path
local measured=require('game_canvas').check
_G.__TEST={}
dofile('app/index.lua')
local A=__TEST.api
local ANSWERS={
  {{1,1,3,1},{1,2,5,3},{1,5,2,1},{3,5,3,1},{4,1,2,1}},
  {{1,1,3,1},{1,2,3,3},{1,5,3,1},{4,1,1,5},{5,1,1,5}},
  {{1,1,1,5},{2,1,4,2},{2,3,3,2},{2,5,2,1},{4,5,2,1},{5,3,1,2}},
  {{1,1,2,2},{1,3,2,1},{1,4,5,2},{3,1,2,2},{3,3,3,1},{5,1,1,2}},
  {{1,1,4,4},{1,5,4,1},{1,6,2,1},{3,6,2,1},{5,1,1,2},{5,3,1,2},{5,5,1,2},{6,1,1,4},{6,5,1,2}},
  {{1,1,3,1},{1,2,3,2},{1,4,4,1},{1,5,4,2},{4,1,2,3},{5,4,1,3},{6,1,1,2},{6,3,1,2},{6,5,1,2}},
  {{1,1,1,3},{1,4,1,3},{2,1,3,1},{2,2,3,5},{5,1,1,2},{5,3,1,4},{6,1,1,2},{6,3,1,4}},
  {{1,1,1,3},{1,4,1,3},{2,1,1,2},{2,3,1,2},{2,5,1,2},{3,1,1,4},{3,5,4,2},{4,1,3,4}},
  {{1,1,2,2},{1,3,2,4},{1,7,2,1},{3,1,5,1},{3,2,1,3},{3,5,2,3},{4,2,2,3},{5,5,3,1},{5,6,3,2},{6,2,2,3}},
  {{1,1,6,1},{1,2,1,2},{1,4,5,1},{1,5,4,3},{2,2,5,2},{5,5,1,3},{6,4,2,1},{6,5,2,3},{7,1,1,3}},
  {{1,1,2,1},{1,2,3,3},{1,5,2,3},{3,1,2,1},{3,5,2,2},{3,7,2,1},{4,2,1,3},{5,1,3,4},{5,5,3,3}},
  {{1,1,2,3},{1,4,1,4},{2,4,2,3},{2,7,2,1},{3,1,1,3},{4,1,3,2},{4,3,3,5},{7,1,1,2},{7,3,1,2},{7,5,1,3}},
}
local function eq(a,b,what)
  assert(a==b,(what or 'mismatch')..': '..tostring(a)..' ~= '..tostring(b))
end
local memory={}
local redraws=0
local font={line_height=24,measure=function(_,s) return #s*11 end}
local ctx={
  storage={read=function(_,key) return memory[key] end,
           write=function(_,key,val) memory[key]=val end},
  fonts={small=font,medium=font,large=font},
  clock={millis=function() return 10000 end},
  invalidate=function() redraws=redraws+1 end
}
on_load(ctx)
local state=A.state()
eq(state.level,1);eq(state.unlocked,1)
eq(#A.puzzles,12);eq(#ANSWERS,12)
assert(memory['rectangle-rooms.txt']:find('version=1',1,true))
assert(not A.next(),'new puzzles are locked')
assert(not A.done())

local function rect_actions(rec)
  local x,y,w,h=rec[1],rec[2],rec[3],rec[4]
  assert(A.set_cell(x,y),'select first corner')
  eq(state.picks[state.level],(y-1)*A.grid(state.level).n+x)
  assert(A.set_cell(x+w-1,y+h-1),'select second corner')
  eq(state.picks[state.level],0)
end
local function room_count() return #state.rooms[state.level] end

-- Bad rectangles do not mutate the board; selected corners are saved.
local first=A.grid(1)
assert(not A.check_rect(first,{}, {x=1,y=1,w=1,h=1}),'no clue in this cell')
assert(not A.check_rect(first,{}, {x=2,y=1,w=1,h=1}),'area must match number')
assert(A.set_cell(1,1))
eq(state.picks[1],1)
on_leave();on_load(ctx);state=A.state()
eq(state.picks[1],1,'unfinished first corner survives relaunch')
assert(A.set_cell(1,1))
eq(state.picks[1],0,'same corner cancels selection')
rect_actions({1,1,1,1})
eq(room_count(),0,'invalid rectangle not placed')
rect_actions(ANSWERS[1][1])
eq(room_count(),1)
assert(not A.check_rect(first,state.rooms[1],{x=1,y=1,w=3,h=1}),
  'overlap never allowed')
assert(A.undo())
eq(room_count(),0,'last rectangle removed')
assert(not A.undo())
assert(A.restart())
eq(room_count(),0)

-- All 12 frozen puzzles are solved with actual two-corner tap actions.
for level=1,12 do
  eq(state.level,level)
  local g=A.grid(level)
  eq(g.n,level<=4 and 5 or level<=8 and 6 or 7)
  measured(ctx,on_draw,'rooms fresh '..level)
  for i,rec in ipairs(ANSWERS[level]) do
    local x,y,w,h=rec[1],rec[2],rec[3],rec[4]
    assert(A.check_rect(g,state.rooms[level],{x=x,y=y,w=w,h=h}),
      'every reference rectangle must be legal')
    rect_actions(rec)
    eq(room_count(),i)
    if i==1 then
      on_leave();on_load(ctx);state=A.state()
      eq(room_count(),1,'partial board retained on relaunch')
      measured(ctx,on_draw,'rooms partial '..level)
    end
  end
  assert(A.done(),'all numbered areas must partition the grid')
  eq(A.covered(state.rooms[level]),g.n*g.n)
  eq(state.unlocked,math.min(12,level+1),'new level unlocked')
  measured(ctx,on_draw,'rooms complete '..level)
  on_leave();on_load(ctx);state=A.state()
  eq(state.level,level)
  assert(A.done(),'completed partition persists')
  if level<12 then assert(A.next()) else assert(not A.next()) end
end

-- Revisiting unfinished older boards must not discard placed rectangles.
assert(A.visit(6))
assert(A.restart())
rect_actions(ANSWERS[6][1])
eq(room_count(),1)
assert(A.prev())
on_leave();on_load(ctx);state=A.state()
assert(A.next())
eq(room_count(),1,'incomplete board retained through visits')
assert(A.undo())
eq(room_count(),0,'undo works after returning')
eq(state.unlocked,12,'global unlock not reset')
assert(A.visit(9));assert(A.done())

-- Actual touch hitboxes, down-event ignored, one redraw for each completed tap.
assert(A.visit(2));assert(A.restart())
local bx,by,cell=A.geometry(5)
local before=redraws
local x,y=bx+cell/2,by+cell/2
on_input(ctx,{type='pointer',phase='down',gesture='tap',x=x,y=y})
eq(redraws,before)
on_input(ctx,{type='pointer',phase='up',gesture='swipe',x=x,y=y})
eq(redraws,before)
on_input(ctx,{type='pointer',phase='up',gesture='tap',x=x,y=y})
eq(redraws,before+1)
eq(state.picks[2],1)
on_input(ctx,{type='pointer',phase='up',gesture='tap',x=2,y=2})
eq(redraws,before+1,'taps outside controls do nothing')
assert(A.undo())
eq(state.picks[2],0)

-- Every unsolved, mid-selection, partial, completed and help view at 2 scales.
for level=1,12 do
  assert(A.visit(level));assert(A.restart())
  measured(ctx,on_draw,'rooms reset '..level)
  assert(A.set_cell(1,1))
  measured(ctx,on_draw,'rooms selected '..level)
  assert(A.undo())
  for i,rec in ipairs(ANSWERS[level]) do
    rect_actions(rec)
    if i==1 then measured(ctx,on_draw,'rooms first rectangle '..level) end
  end
  measured(ctx,on_draw,'rooms solved '..level)
end
A.tap(435,34)
measured(ctx,on_draw,'rooms help')
A.tap(240,736)
memory['rectangle-rooms.txt']='version=1\nlevel=999\nunlocked=999\n'
on_load(ctx)
eq(A.state().level,1,'malformed save reset safely')
assert(type(on_tick)=='nil','no background animation callback')
print('Rectangle Rooms: 12 unique partitions, undo, saved stages, touch and layout PASS')
