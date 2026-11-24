package.path='app/?.lua;../../tests/?.lua;'..package.path
local measured=require('game_canvas').check
_G.__TEST={}
dofile('app/index.lua')
local A=__TEST.api
local function eq(a,b,m)assert(a==b,(m or 'mismatch')..' '..tostring(a)..' vs '..tostring(b))end
local store={}
local count=0
local font={line_height=24,measure=function(_,s)return #s*11 end}
local ctx={storage={read=function(_,k)return store[k]end,write=function(_,k,v)store[k]=v end},
 fonts={small=font,medium=font,large=font},clock={millis=function()return 12000 end},
 invalidate=function()count=count+1 end}
on_load(ctx)
local S=A.state()
eq(S.level,1);eq(#A.levels,12);assert(not A.next())
-- Independent interval DP; find and execute a nested pair-removal proof.
local function witness(values)
 local cache={}
 local function f(a,b)
  if a>b then return {} end
  local key=a..':'..b
  if cache[key] then return cache[key]==false and nil or cache[key] end
  for j=a+1,b,2 do
   local x,y=values[a],values[j]
   if x==y or x+y==10 then
    local inside=f(a+1,j-1)
    if inside then
     local outside=f(j+1,b)
     if outside then
      local result={}
      for _,v in ipairs(inside) do result[#result+1]=v end
      result[#result+1]={a,j}
      for _,v in ipairs(outside) do result[#result+1]=v end
      cache[key]=result
      return result
     end
    end
   end
  end
  cache[key]=false
  return nil
 end
 return f(1,#values)
end
local board=S.boards[1]
assert(not A.can(board,1,3),'two blocked digits cannot pair')
assert(A.can({1,0,9},1,3),'cleared gap enables reading-order match')
assert(A.can({1,0,0,9,2,0,0,8},1,4),'straight line gap')
-- Selection, hint, undo, add and persisted expanded rows.
assert(A.hint())
eq(S.hintsUsed[1],1)
assert(A.hint());eq(S.hintsUsed[1],1)
assert(A.pick(1));eq(S.selected[1],1)
assert(A.pick(1));eq(S.selected[1],0)
assert(A.add());eq(#S.boards[1],64)
on_leave();on_load(ctx);S=A.state();eq(#S.boards[1],64)
assert(A.undo());eq(#S.boards[1],32)
assert(A.restart());eq(S.hintsUsed[1],0)
for level=1,12 do
 eq(S.level,level)
 local tiles=S.boards[level]
 eq(#tiles,32)
 measured(ctx,on_draw,'ten pairs fresh '..level)
 local sequence=witness(tiles)
 assert(sequence and #sequence==16,'complete nested pair witness')
 for step,pair in ipairs(sequence) do
  local a,b=pair[1],pair[2]
  assert(A.can(tiles,a,b),'currently accessible pair')
  assert(A.pick(a));assert(A.pick(b))
  eq(S.selected[level],0)
  if step==1 then
   on_leave();on_load(ctx);S=A.state();tiles=S.boards[level]
   eq(tiles[a],0);eq(tiles[b],0)
   measured(ctx,on_draw,'ten pairs partial '..level)
  end
 end
 assert(A.complete(),'cleared board')
 eq(S.unlocked,math.min(12,level+1))
 measured(ctx,on_draw,'ten pairs cleared '..level)
 on_leave();on_load(ctx);S=A.state()
 assert(A.complete(),'cleared state saved')
 if level<12 then assert(A.next()) else assert(not A.next()) end
end
-- Revisit a previously completed stage, restart and keep an unfinished board.
assert(A.visit(4));A.restart()
local pair=witness(S.boards[4])[1]
assert(A.pick(pair[1]));assert(A.pick(pair[2]))
assert(A.visit(5))
on_leave();on_load(ctx);S=A.state()
assert(A.prev());eq(S.boards[4][pair[1]],0)
assert(A.undo());assert(S.boards[4][pair[1]]>0)
eq(S.unlocked,12)
assert(A.visit(1));A.restart()
local x0,y0,cell=A.geometry()
local before=count
on_input(ctx,{type='pointer',phase='down',gesture='tap',x=x0+cell/2,y=y0+cell/2})
eq(count,before)
on_input(ctx,{type='pointer',phase='up',gesture='swipe',x=x0+cell/2,y=y0+cell/2})
eq(count,before)
on_input(ctx,{type='pointer',phase='up',gesture='tap',x=x0+cell/2,y=y0+cell/2})
eq(count,before+1);eq(S.selected[1],1)
-- Maxed-out board and hint states fit without overlapping buttons.
for level=1,12 do
 assert(A.visit(level));A.restart()
 measured(ctx,on_draw,'ten pairs reset '..level)
 A.hint();measured(ctx,on_draw,'ten pairs hint '..level)
end
A.visit(1)
local full={}
for i=1,88 do full[i]=(i%9)+1 end
S.boards[1]=full;S.selected[1]=0
measured(ctx,on_draw,'ten pairs 11-row full board')
A.tap(441,32);measured(ctx,on_draw,'ten pairs help')
A.tap(240,738)
store['ten-pairs.txt']='version=1\nlevel=999\nunlocked=999\n'
on_load(ctx);eq(A.state().level,1)
assert(type(on_tick)=='nil','no periodic animation')
print('Ten Pairs: 12 complete sheets, 16-pair solutions, add, hint, undo, save and layout PASS')
