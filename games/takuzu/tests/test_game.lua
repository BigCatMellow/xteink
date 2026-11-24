package.path='app/?.lua;../../tests/?.lua;'..package.path
local measured=require('game_canvas').check
local P=require('puzzles')
_G.__TEST={}
dofile('app/index.lua')
local A=__TEST.api
local saves={};local redraw=0
local f={line_height=24,measure=function(_,s)return #s*10 end}
local ctx={storage={read=function(_,k)return saves[k] end,write=function(_,k,v)saves[k]=v;return true end},
fonts={small=f,medium=f,large=f},invalidate=function()redraw=redraw+1 end}
-- All old authored boards remain readable, but a clean install starts generated.
local lines={'version=1','level=1','unlocked=1','mode=1'}
for i,p in ipairs(A.levels) do
 local b={}
 for j=1,p.n*p.n do local ch=p.clues:sub(j,j);b[j]=(P.id=='takuzu' and ch~='.') and tonumber(ch)+1 or 0 end
 lines[#lines+1]='B'..i..'='..table.concat(b)
 lines[#lines+1]='W'..i..'=0';lines[#lines+1]='H'..i..'='
end
saves[P.id..'.txt']=table.concat(lines,'\n')
on_load(ctx)
assert(#A.levels>=12)
for i,p in ipairs(A.levels) do
 local S=A.state();assert(S.level==i)
 measured(ctx,on_draw,'fresh '..i)
 local j=1;while P.id=='takuzu' and p.clues:sub(j,j)~='.' do j=j+1 end
 assert(j<=p.n*p.n)
 local x,y,t=A.geometry();local px=x+((j-1)%p.n+.5)*t;local py=y+(math.floor((j-1)/p.n)+.5)*t
 A.mode(1)
 local before=redraw
 assert(not on_input(ctx,{type='pointer',phase='down',gesture='tap',x=px,y=py}))
 assert(on_input(ctx,{type='pointer',phase='up',gesture='tap',x=px,y=py}))
 assert(redraw==before+1)
 measured(ctx,on_draw,'partial '..i)
 on_leave();on_load(ctx)
 assert(A.state().boards[i][j]==1);assert(A.undo());assert(A.state().boards[i][j]==0)
 assert(A.check());measured(ctx,on_draw,'incorrect '..i)
 for k=1,#p.answer do
  if P.id~='takuzu' or p.clues:sub(k,k)=='.' then
   local bit=tonumber(p.answer:sub(k,k))
   local v=P.id=='takuzu' and bit+1 or (bit==1 and 1 or 2)
   A.mode(v);assert(A.paint(k))
  end
 end
 assert(A.valid(i,A.state().boards[i]))
 on_leave();on_load(ctx)
 assert(A.valid(i,A.state().boards[i]) and not A.state().won[i])
 assert(A.check() and A.state().won[i])
 measured(ctx,on_draw,'solved '..i)
 on_leave();on_load(ctx);assert(A.state().won[i])
 if i<#A.levels then assert(A.visit(i+1));assert(A.visit(i));assert(A.state().won[i]);assert(A.visit(i+1)) end
end
assert(A.visit(1));assert(A.reset());A.mode(1)
local p=A.levels[1];local j=1;while P.id=='takuzu' and p.clues:sub(j,j)~='.' do j=j+1 end
assert(A.paint(j));assert(A.visit(2));on_leave();on_load(ctx)
assert(A.visit(1));assert(A.state().boards[1][j]==1);assert(A.undo())
assert(A.state().boards[1][j]==0)
assert(A.tap(440,30));measured(ctx,on_draw,'help');assert(A.tap(240,740))
assert(type(on_tick)=='nil')
print(P.name..': levels, rules, save/undo, touch and layout PASS')
