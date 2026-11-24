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
  {5,7,1,4,6,3,8,2},
  {7,5,3,6,4,2,8,1},
  {3,6,8,1,7,5,2,4},
  {4,7,2,5,3,8,1,6},
  {6,1,7,9,4,8,2,5,3},
  {6,1,9,7,2,4,8,5,3},
  {1,8,5,3,6,9,2,4,7},
  {3,7,1,4,8,5,9,2,6},
}
local function eq(a,b,label) assert(a==b,(label or 'mismatch')..' '..tostring(a)..' / '..tostring(b)) end
local files={}
local count=0
local font={line_height=24,measure=function(_,s)return #s*11 end}
local ctx={storage={read=function(_,k)return files[k]end,write=function(_,k,v)files[k]=v end},
  fonts={small=font,medium=font,large=font},clock={millis=function()return 14500 end},
  invalidate=function()count=count+1 end}
local initial={'version=1','total='..#A.levels,'level=1','unlocked=1','mode=2'}
for i,p in ipairs(A.levels) do
 initial[#initial+1]='B'..i..'='..string.rep('0',#p.rows^2)
 initial[#initial+1]='S'..i..'=0';initial[#initial+1]='H'..i..'='
end
files['crown-fields.txt']=table.concat(initial,'\n')
on_load(ctx)
local S=A.state()
eq(S.level,1);eq(#A.levels,20);assert(not A.next())
assert(files['crown-fields.txt']:find('version=1',1,true))
local function cell(n,x,y)return (y-1)*n+x end
local function solve(level)
 local b=A.board(level)
 local mask=S.marks[level]
 for y,x0 in ipairs(SOLUTIONS[level]) do
  local i=cell(b.n,x0,y)
  assert(A.mark(i,2))
  eq(mask[i],2,'crown marked')
 end
 assert(A.valid(level,mask),'valid solution for level '..level)
end
-- Direct mark modes.
assert(A.mark(1,1));eq(S.marks[1][1],1)
assert(A.mark(1,2));eq(S.marks[1][1],2)
assert(A.mark(1,2));eq(S.marks[1][1],0)
assert(A.undo());eq(S.marks[1][1],2)
assert(A.undo());eq(S.marks[1][1],1)
assert(A.restart());eq(S.marks[1][1],0)
assert(A.check());eq(S.unlocked,1,'incorrect not unlocked')
for level=1,20 do
 eq(S.level,level)
 local b=A.board(level)
 eq(b.n,math.floor((level-1)/4)+5)
 measured(ctx,on_draw,'crown fresh '..level)
 solve(level)
 measured(ctx,on_draw,'crown correct but not submitted '..level)
 assert(not S.submitted[level],'must require explicit CHECK')
 on_leave();on_load(ctx);S=A.state()
 assert(A.valid(level,S.marks[level]),'saved complete but unsubmitted')
 assert(not S.submitted[level])
 assert(A.check())
 eq(S.unlocked,math.min(20,level+1))
 assert(S.submitted[level])
 measured(ctx,on_draw,'crown submitted '..level)
 on_leave();on_load(ctx);S=A.state()
 assert(S.submitted[level],'submitted restored')
 if level<20 then assert(A.next()) else assert(not A.next()) end
end
assert(A.visit(4))
assert(A.restart())
local b=A.board(4)
assert(A.mark(cell(b.n,1,1),1))
assert(A.visit(5))
on_leave();on_load(ctx);S=A.state()
assert(A.prev())
eq(S.marks[4][1],1,'unfinished marked level survived revisit')
assert(A.undo());eq(S.marks[4][1],0)
eq(S.unlocked,20)
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
eq(S.marks[1][1],2)
for level=1,20 do
 assert(A.visit(level));A.restart()
 measured(ctx,on_draw,'crown reset '..level)
 local b=A.board(level)
 A.mark(1,1);measured(ctx,on_draw,'crown x '..level)
 A.mark(1,2);measured(ctx,on_draw,'crown placed '..level)
end
A.tap(440,30);measured(ctx,on_draw,'crown help')
A.tap(220,733)
-- Existing 12-level v1 save: retain completed last board and unlock continuation.
local old={'version=1','level=12','unlocked=12'}
for i=1,12 do
 local b=A.board(i);local a={}
 for j=1,b.n*b.n do a[j]=0 end
 if i==12 then for y,x in ipairs(SOLUTIONS[i]) do a[(y-1)*b.n+x]=2 end end
 old[#old+1]='B'..i..'='..table.concat(a)
 old[#old+1]='S'..i..'='..(i==12 and '1' or '0')
 old[#old+1]='H'..i..'='
end
files['crown-fields.txt']=table.concat(old,'\n')
on_load(ctx)
assert(A.state().submitted[12] and A.valid(12,A.state().marks[12]))
assert(A.state().unlocked==13 and A.next())
assert(A.state().level==13 and #A.state().marks[13]==64)
local corrupt='version=1\nlevel=999\nunlocked=999\n'
files['crown-fields.txt']=corrupt
on_load(ctx);assert(A.state()==nil and files['crown-fields.txt']==corrupt,'corrupt save retained')
A.start()
assert(type(on_tick)=='nil','no animation')
print('Crown Fields: 20 unique region boards, partial saves, direct crown modes, layouts PASS')
