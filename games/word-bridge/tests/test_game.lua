-- Word Bridge: actual choices, dead ends, hint, undo, save and measured UI.
package.path='app/?.lua;../../tests/?.lua;'..package.path
local measured=require('game_canvas').check
_G.__TEST={}
dofile('app/index.lua')
local A=__TEST.api
local ROUTES={
  {"COLD","CORD","CARD","WARD","WARM"},
  {"HEAD","HEAT","BEAT","BOAT","GOAT","GOAL"},
  {"CARE","DARE","DATE","GATE","GAME"},
  {"MICE","DICE","DINE","DONE","DOVE"},
  {"FIRE","FINE","LINE","LIKE","LAKE"},
  {"LAKE","CAKE","CARE","CARD","CORD"},
  {"BOOK","BOOT","BOAT","GOAT","GOAL"},
  {"PINK","SINK","SICK","SOCK","LOCK"},
  {"MINT","DINT","DENT","SENT"},
  {"SAND","HAND","HARD","CARD","CORD","CORE","CONE","BONE"},
  {"SHIP","SHOP","STOP","STEP","STEM"},
  {"TONE","CONE","CORE","CORD","CARD","WARD","WARM"}
}
local function eq(a,b,msg)
  assert(a==b,(msg or 'mismatch')..': '..tostring(a)..' vs '..tostring(b))
end
local save={}
local redraws=0
local font={line_height=24,measure=function(_,str) return #str*11 end}
local ctx={
  storage={read=function(_,k) return save[k] end,
           write=function(_,k,v) save[k]=v end},
  fonts={small=font,medium=font,large=font},
  clock={millis=function() return 14000 end},
  invalidate=function() redraws=redraws+1 end
}
on_load(ctx)
local state=A.state()
eq(state.level,1);eq(state.unlocked,1)
eq(#A.levels,12);eq(#ROUTES,12)
assert(not A.done())
assert(not A.next())
assert(save['word-bridge.txt']:find('version=1',1,true))

local function word_index(level,word)
  for i,s in ipairs(A.levels[level].words) do if s==word then return i end end
  error('Missing authored word '..word)
end
local function advance(word)
  return A.move(word_index(state.level,word))
end
-- Reject invalid links and a reused card, but retain the board as an error prompt.
local before=save['word-bridge.txt']
assert(advance('WARM'));eq(#state.paths[1],1)
assert(save['word-bridge.txt']==before)
assert(advance('CORD'));eq(#state.paths[1],2)
assert(advance('CORD'));eq(#state.paths[1],2)
assert(A.undo());eq(#state.paths[1],1)
assert(A.restart())
eq(#state.paths[1],1)
-- Hint gives a real next word, and its used state survives relaunch.
assert(A.hint())
local target=state.hints[1]
assert(target>0)
assert(A.diff(A.levels[1].words[target],A.levels[1].start)==1)
on_leave();on_load(ctx)
state=A.state()
eq(state.hints[1],target)
assert(advance(A.levels[1].words[target]))
eq(state.hints[1],-1)
assert(A.hint())
eq(state.hints[1],-1,'hint cannot be reused after moving')
assert(A.undo())
eq(state.hints[1],-1)
assert(A.restart())
eq(state.hints[1],0)

-- A tempting but wrong opening consumes a move and cannot win on budget.
local bad=nil
for i,w in ipairs(A.levels[1].words) do
  if w~='CORD' and A.diff(w,'COLD')==1 then bad=i;break end
end
assert(bad)
assert(A.move(bad))
assert(not A.done())
assert(A.undo())
eq(#state.paths[1],1)

-- Complete the campaign via real moves; no fixture is embedded in the app.
for level=1,12 do
  eq(state.level,level)
  eq(#ROUTES[level]-1,A.levels[level].limit,'fixture length')
  measured(ctx,on_draw,'word bridge fresh '..level)
  local route=ROUTES[level]
  for i=2,#route do
    assert(advance(route[i]),'valid one-letter turn')
    eq(#state.paths[level],i)
  end
  assert(A.done(),'winning route in stage '..level)
  eq(state.unlocked,math.min(12,level+1))
  measured(ctx,on_draw,'word bridge solved '..level)
  on_leave();on_load(ctx)
  state=A.state()
  eq(state.level,level,'restored level')
  assert(A.done(),'winning path retained')
  if level<12 then assert(A.next()) else assert(not A.next()) end
end

-- Returning to a prior unlocked stage must preserve its route and last hint.
assert(A.visit(5))
assert(A.restart())
assert(advance('FINE'));assert(advance('LINE'))
eq(#state.paths[5],3)
assert(A.prev())
on_leave();on_load(ctx);state=A.state()
assert(A.next())
eq(#state.paths[5],3,'unfinished chain survives switching levels')
assert(A.undo())
eq(#state.paths[5],2,'undo survives an app restart')
eq(state.unlocked,12)

-- Accept only a static touch-release; swipes and down events never act.
assert(A.visit(1));assert(A.restart())
local i=word_index(1,'CORD')
local gx,gy,gw,gh=A.grid_point(i)
local x,y=gx+gw/2,gy+gh/2
local base=redraws
on_input(ctx,{type='pointer',phase='down',gesture='tap',x=x,y=y})
eq(redraws,base)
on_input(ctx,{type='pointer',phase='up',gesture='swipe',x=x,y=y})
eq(redraws,base)
on_input(ctx,{type='pointer',phase='up',gesture='tap',x=x,y=y})
eq(redraws,base+1)
eq(#state.paths[1],2)
on_input(ctx,{type='pointer',phase='up',gesture='tap',x=3,y=3})
eq(redraws,base+1,'outside screen does not redraw')

-- Validate all fresh, progressed, hint, solved and help screens in two fonts.
for level=1,12 do
  assert(A.visit(level));assert(A.restart())
  measured(ctx,on_draw,'bridge reset '..level)
  A.hint()
  measured(ctx,on_draw,'bridge hint '..level)
  local route=ROUTES[level]
  for step=2,#route do advance(route[step]) end
  measured(ctx,on_draw,'bridge complete '..level)
end
A.tap(440,33)
measured(ctx,on_draw,'bridge help')
A.tap(200,738)
save['word-bridge.txt']='version=1\nlevel=999\nunlocked=999\n'
on_load(ctx)
eq(A.state().level,1,'bad save safely resets')
assert(type(on_tick)=='nil','no animation callback')
print('Word Bridge: 12 optimal routes, traps, hints, save, undo, touch and layout PASS')
