package.path='app/?.lua;../tests/?.lua;'..package.path
local measured=require('game_canvas').check
_G.__TEST={}
dofile('app/index.lua')
local A=__TEST.api
local function eq(a,b,m)assert(a==b,(m or 'mismatch')..' '..tostring(a)..' vs '..tostring(b))end
local save={}
local redraws=0
local font={line_height=24,measure=function(_,s)return #s*11 end}
local ctx={storage={read=function(_,k)return save[k]end,write=function(_,k,v)save[k]=v end},
 fonts={small=font,medium=font,large=font},clock={millis=function()return 16000 end},
 invalidate=function()redraws=redraws+1 end}
on_load(ctx)
local S=A.state()
eq(S.level,1);eq(#A.levels,12);assert(not A.next())
local first=A.board(1)
assert(not first.mines[1]);eq(A.nearby(first,1),0)
assert(A.apply(2)) -- Before safe START, other cells are not revealed.
eq(S.marks[1][2],0)
-- Correct initial reveals and flags save across reload.
assert(A.apply(1))
local count=0
for _,v in ipairs(S.marks[1]) do if v==2 then count=count+1 end end
assert(count>1,'zero-cell start floods neighbors')
local mine=A.levels[1].mines[1]
assert(A.mode());eq(S.mode,'FLAG')
assert(A.apply(mine));eq(S.marks[1][mine],1)
on_leave();on_load(ctx);S=A.state()
eq(S.marks[1][mine],1,'flag persists')
eq(S.mode,'FLAG')
assert(A.undo());eq(S.marks[1][mine],0,'flag can undo')
assert(A.mode());eq(S.mode,'OPEN')
-- Hitting a mine ends the field, but Reset is recoverable.
assert(A.apply(mine));assert(S.failed[1])
measured(ctx,on_draw,'mines loss')
assert(not A.apply(mine),'cannot open after failure')
assert(A.restart());assert(not S.failed[1])
local function reveal_safe(level)
 local b=A.board(level)
 assert(not b.mines[1] and A.nearby(b,1)==0)
 assert(A.apply(1))
 local safe=0
 for i=1,b.n*b.n do
  if not b.mines[i] then
   safe=safe+1
   if S.marks[level][i]~=2 then assert(A.apply(i),'safe cell can be opened') end
  end
 end
 assert(A.solved(level,S.marks[level]))
 eq(S.unlocked,math.min(12,level+1))
 local open=0
 for _,v in ipairs(S.marks[level]) do if v==2 then open=open+1 end end
 eq(open,safe,'all safe cells exposed')
end
for level=1,12 do
 eq(S.level,level)
 A.restart()
 measured(ctx,on_draw,'mines fresh '..level)
 local b=A.board(level)
 reveal_safe(level)
 measured(ctx,on_draw,'mines cleared '..level)
 on_leave();on_load(ctx);S=A.state()
 assert(A.solved(level,S.marks[level]),'completed state preserved')
 if level<12 then assert(A.next()) else assert(not A.next()) end
end
-- Level changes do not destroy an incomplete board or flags.
assert(A.visit(4));A.restart()
assert(A.apply(1))
local mine=A.levels[4].mines[1]
assert(A.mode());assert(A.apply(mine))
assert(A.visit(5))
on_leave();on_load(ctx);S=A.state()
assert(A.prev());eq(S.marks[4][mine],1,'flag persisted after visit')
eq(S.unlocked,12)
-- Physical touch pointer release only.
assert(A.visit(2));A.restart()
local x0,y0,cell=A.geometry()
local base=redraws
on_input(ctx,{type='pointer',phase='down',gesture='tap',x=x0+cell/2,y=y0+cell/2})
eq(redraws,base)
on_input(ctx,{type='pointer',phase='up',gesture='swipe',x=x0+cell/2,y=y0+cell/2})
eq(redraws,base)
-- Current mode is FLAG, so this places a flag, one redraw.
on_input(ctx,{type='pointer',phase='up',gesture='tap',x=x0+cell/2,y=y0+cell/2})
eq(redraws,base+1)
for level=1,12 do
 A.visit(level);A.restart()
 measured(ctx,on_draw,'mines reset '..level)
 A.apply(1);measured(ctx,on_draw,'mines partial '..level)
end
A.tap(442,33);measured(ctx,on_draw,'mines help')
A.tap(220,735)
save['quiet-mines.txt']='version=1\nlevel=999\nunlocked=999\n'
on_load(ctx);eq(A.state().level,1)
assert(type(on_tick)=='nil','no frame animation')
print('Quiet Mines: 12 no-guess boards, flood reveal, flags, loss, save and layout PASS')
