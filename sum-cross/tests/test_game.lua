package.path='app/?.lua;../tests/?.lua;'..package.path
local measured=require('game_canvas').check
_G.__TEST={}
dofile('app/index.lua')
local A=__TEST.api
local ANSWERS={
{[7]=5,[8]=9,[12]=4,[13]=7,[19]=3,[20]=2,[24]=5,[25]=1},
{[9]=2,[10]=9,[14]=6,[15]=7,[17]=2,[18]=8,[22]=1,[23]=3},
{[7]=3,[8]=9,[12]=1,[13]=8,[19]=6,[20]=3,[24]=5,[25]=1},
{[9]=9,[10]=8,[14]=1,[15]=3,[17]=9,[18]=4,[22]=5,[23]=1},
{[8]=1,[9]=3,[11]=2,[12]=9,[14]=4,[15]=8,[17]=1,[18]=7,[26]=9,[27]=8,[29]=8,[30]=4,[32]=4,[33]=6,[35]=7,[36]=9},
{[8]=9,[9]=2,[10]=5,[14]=7,[15]=1,[16]=3,[29]=7,[30]=3,[35]=9,[36]=8},
{[8]=4,[9]=7,[11]=7,[12]=1,[14]=1,[15]=3,[17]=8,[18]=2,[20]=3,[21]=5,[23]=9,[24]=6},
{[8]=1,[9]=5,[14]=2,[15]=1,[20]=3,[21]=4,[29]=8,[30]=9,[35]=1,[36]=3},
{[9]=9,[10]=7,[12]=7,[13]=2,[16]=1,[17]=9,[19]=3,[20]=1,[23]=3,[24]=1,[26]=9,[27]=8,[37]=9,[38]=8,[40]=3,[41]=1,[42]=9,[44]=6,[45]=1,[47]=5,[48]=3,[49]=7},
{[9]=1,[10]=7,[11]=6,[13]=9,[14]=7,[16]=3,[17]=9,[18]=8,[20]=5,[21]=1,[27]=8,[28]=4,[30]=6,[31]=8,[37]=2,[38]=6,[40]=3,[41]=9,[42]=8,[44]=4,[45]=9,[47]=1,[48]=3,[49]=5},
{[9]=1,[10]=3,[12]=1,[13]=3,[14]=4,[16]=2,[17]=1,[19]=2,[20]=7,[21]=1,[23]=7,[24]=5,[34]=6,[35]=7,[37]=1,[38]=7,[39]=3,[41]=1,[42]=3,[44]=3,[45]=9,[46]=8,[48]=8,[49]=9},
{[9]=6,[10]=8,[11]=1,[13]=1,[14]=4,[16]=2,[17]=6,[18]=3,[20]=5,[21]=9,[27]=2,[28]=8,[30]=2,[31]=5,[32]=4,[37]=1,[38]=3,[39]=2,[41]=2,[42]=6,[48]=4,[49]=8}
}
local function eq(a,b,label)assert(a==b,(label or 'mismatch')..' '..tostring(a)..' vs '..tostring(b))end
local store={}
local redraws=0
local font={line_height=24,measure=function(_,s)return #s*11 end}
local ctx={storage={read=function(_,k)return store[k]end,write=function(_,k,v)store[k]=v end},
  fonts={small=font,medium=font,large=font},clock={millis=function()return 10000 end},
  invalidate=function()redraws=redraws+1 end}
on_load(ctx)
local S=A.state()
eq(S.level,1);eq(#A.levels,12);assert(not A.next())
assert(store['sum-cross.txt']:find('version=1',1,true))
local function enter_cell(index,value)
 assert(A.select(index));assert(A.digit(value))
end
-- Cell selection, wrong answer, clear and undo.
local g=A.grid(1)
local i=nil
for j,white in ipairs(g.white) do if white then i=j;break end end
assert(i)
assert(A.select(i));eq(S.selected[1],i)
assert(A.digit(9));eq(S.boards[1][i],9)
assert(A.digit(0));eq(S.boards[1][i],0)
assert(A.undo());eq(S.boards[1][i],9)
assert(A.undo());eq(S.boards[1][i],0)
assert(A.check());eq(S.unlocked,1,'incorrect cannot unlock')
assert(A.restart())
local function fill(level)
 local b=A.grid(level)
 for index,v in pairs(ANSWERS[level]) do
   assert(b.white[index])
   assert(A.select(index));assert(A.digit(v))
 end
 assert(A.valid(level,S.boards[level]),'all cross sums correct')
end
for level=1,12 do
 eq(S.level,level)
 local b=A.grid(level)
 eq(b.n,level<=4 and 5 or level<=8 and 6 or 7)
 measured(ctx,on_draw,'cross sums empty '..level)
 -- Partly completed board survives a relaunch.
 local first=next(ANSWERS[level])
 assert(A.select(first));assert(A.digit(ANSWERS[level][first]))
 on_leave();on_load(ctx);S=A.state()
 eq(S.boards[level][first],ANSWERS[level][first])
 measured(ctx,on_draw,'cross sums partial '..level)
 for index,v in pairs(ANSWERS[level]) do
   if index~=first then assert(A.select(index));assert(A.digit(v)) end
 end
 assert(A.valid(level,S.boards[level]))
 assert(not S.submitted[level],'correct answer must remain unsent')
 measured(ctx,on_draw,'cross sums solved but unsubmitted '..level)
 on_leave();on_load(ctx);S=A.state()
 assert(A.valid(level,S.boards[level]))
 assert(not S.submitted[level])
 assert(A.check())
 assert(S.submitted[level])
 eq(S.unlocked,math.min(12,level+1))
 measured(ctx,on_draw,'cross sums submitted '..level)
 on_leave();on_load(ctx);S=A.state()
 assert(S.submitted[level])
 if level<12 then assert(A.next()) else assert(not A.next()) end
end
-- Save a partially filled revisited board independently of solved others.
assert(A.visit(5));assert(A.restart())
local k=next(ANSWERS[5])
assert(A.select(k));assert(A.digit(ANSWERS[5][k]))
assert(A.visit(6))
on_leave();on_load(ctx);S=A.state()
assert(A.prev());eq(S.boards[5][k],ANSWERS[5][k])
assert(A.undo());eq(S.boards[5][k],0)
eq(S.unlocked,12)
-- Verify touch target for a white cell and keypad interaction.
assert(A.visit(3));assert(A.restart())
local b=A.grid(3)
local index=next(ANSWERS[3])
local x0,y0,cell=A.geometry()
local row=math.floor((index-1)/b.n)
local col=(index-1)%b.n
local x,y=x0+(col+.5)*cell,y0+(row+.5)*cell
local before=redraws
on_input(ctx,{type='pointer',phase='down',gesture='tap',x=x,y=y})
eq(redraws,before)
on_input(ctx,{type='pointer',phase='up',gesture='swipe',x=x,y=y})
eq(redraws,before)
on_input(ctx,{type='pointer',phase='up',gesture='tap',x=x,y=y})
eq(redraws,before+1);eq(S.selected[3],index)
local digitValue=ANSWERS[3][index]
local bx=15+((digitValue-1)%5)*93
local by=560+math.floor((digitValue-1)/5)*56
on_input(ctx,{type='pointer',phase='up',gesture='tap',x=bx+40,y=by+24})
eq(redraws,before+2);eq(S.boards[3][index],digitValue)
for level=1,12 do
 A.visit(level);A.restart()
 measured(ctx,on_draw,'cross sums reset '..level)
 local idx=next(ANSWERS[level])
 A.select(idx);measured(ctx,on_draw,'cross sums selected '..level)
end
A.tap(438,31);measured(ctx,on_draw,'cross sums help')
A.tap(220,742)
store['sum-cross.txt']='version=1\nlevel=999\nunlocked=999\n'
on_load(ctx);eq(A.state().level,1)
assert(type(on_tick)=='nil','no animation')
print('Sum Cross: 12 unique Kakuro levels, digit keypad, saved partial and layout PASS')
