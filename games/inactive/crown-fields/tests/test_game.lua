package.path='app/?.lua;../../tests/?.lua;'..package.path
local measured=require('game_canvas').check
_G.__TEST={}
dofile('app/index.lua')
local A=__TEST.api
local SOLUTIONS={
  {1,3,5,2,4},
  {4,1,3,5,2},
  {5,3,1,4,2},
  {3,5,2,4,1},
  {1,3,6,4,2,5},
  {5,3,6,1,4,2},
  {2,4,1,6,3,5},
  {2,5,1,3,6,4},
  {1,3,5,2,7,4,6},
  {7,5,2,4,6,3,1},
  {3,1,4,6,2,5,7},
  {3,1,6,4,2,5,7},
}
local function eq(a,b,label) assert(a==b,(label or 'mismatch')..' '..tostring(a)..' / '..tostring(b)) end
local files={}
local count=0
local font={line_height=24,measure=function(_,s)return #s*11 end}
local ctx={storage={read=function(_,k)return files[k]end,write=function(_,k,v)files[k]=v end},
  fonts={small=font,medium=font,large=font},clock={millis=function()return 14500 end},
  invalidate=function()count=count+1 end}
on_load(ctx)
local S=A.state()
eq(S.level,1);eq(#A.levels,12);assert(not A.next())
assert(files['crown-fields.txt']:find('version=1',1,true))
local function cell(n,x,y)return (y-1)*n+x end
local function solve(level)
 local b=A.board(level)
 local mask=S.marks[level]
 for y,x0 in ipairs(SOLUTIONS[level]) do
  local i=cell(b.n,x0,y)
  assert(A.mark(i));assert(A.mark(i))
  eq(mask[i],2,'crown marked')
 end
 assert(A.valid(level,mask),'valid solution for level '..level)
end
-- Two successive touches are required to place a crown; a third clears.
assert(A.mark(1));eq(S.marks[1][1],1)
assert(A.mark(1));eq(S.marks[1][1],2)
assert(A.mark(1));eq(S.marks[1][1],0)
assert(A.undo());eq(S.marks[1][1],2)
assert(A.undo());eq(S.marks[1][1],1)
assert(A.restart());eq(S.marks[1][1],0)
assert(A.check());eq(S.unlocked,1,'incorrect not unlocked')
for level=1,12 do
 eq(S.level,level)
 local b=A.board(level)
 eq(b.n,level<=4 and 5 or level<=8 and 6 or 7)
 measured(ctx,on_draw,'crown fresh '..level)
 solve(level)
 measured(ctx,on_draw,'crown correct but not submitted '..level)
 assert(not S.submitted[level],'must require explicit CHECK')
 on_leave();on_load(ctx);S=A.state()
 assert(A.valid(level,S.marks[level]),'saved complete but unsubmitted')
 assert(not S.submitted[level])
 assert(A.check())
 eq(S.unlocked,math.min(12,level+1))
 assert(S.submitted[level])
 measured(ctx,on_draw,'crown submitted '..level)
 on_leave();on_load(ctx);S=A.state()
 assert(S.submitted[level],'submitted restored')
 if level<12 then assert(A.next()) else assert(not A.next()) end
end
assert(A.visit(4))
assert(A.restart())
local b=A.board(4)
assert(A.mark(cell(b.n,1,1)))
assert(A.visit(5))
on_leave();on_load(ctx);S=A.state()
assert(A.prev())
eq(S.marks[4][1],1,'unfinished marked level survived revisit')
assert(A.undo());eq(S.marks[4][1],0)
eq(S.unlocked,12)
-- Touch events: one release, one redraw. Swipes, press-down ignored.
assert(A.visit(1));assert(A.restart())
local x0,y0,spacing=A.geometry()
local before=count
on_input(ctx,{type='pointer',phase='down',gesture='tap',x=x0+spacing/2,y=y0+spacing/2})
eq(count,before)
on_input(ctx,{type='pointer',phase='up',gesture='swipe',x=x0+spacing/2,y=y0+spacing/2})
eq(count,before)
on_input(ctx,{type='pointer',phase='up',gesture='tap',x=x0+spacing/2,y=y0+spacing/2})
eq(count,before+1)
eq(S.marks[1][1],1)
for level=1,12 do
 assert(A.visit(level));A.restart()
 measured(ctx,on_draw,'crown reset '..level)
 local b=A.board(level)
 A.mark(1);measured(ctx,on_draw,'crown x '..level)
 A.mark(1);measured(ctx,on_draw,'crown placed '..level)
end
A.tap(440,30);measured(ctx,on_draw,'crown help')
A.tap(220,733)
files['crown-fields.txt']='version=1\nlevel=999\nunlocked=999\n'
on_load(ctx);eq(A.state().level,1,'corrupt save reset')
assert(type(on_tick)=='nil','no animation')
print('Crown Fields: 12 unique region boards, partial saves, 2-tap crowns, layouts PASS')
