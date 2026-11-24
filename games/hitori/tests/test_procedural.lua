package.path='app/?.lua;../../tests/?.lua;'..package.path
local P=require('puzzles')
local G=require('procedural_puzzles')
local measured=require('game_canvas').check
_G.__TEST={}
dofile('app/index.lua')
local A=__TEST.api
local saves,fail={},nil
local f={line_height=24,measure=function(_,s)return #s*10 end}
local ctx={storage={read=function(_,k)return saves[k],saves[k]==nil and 'not_found' or nil end,
 write=function(_,k,v) if fail and k:match(fail) then return nil,'quota' end;saves[k]=v;return true end},
 fonts={small=f,medium=f,large=f},clock={millis=function()return 123456 end},invalidate=function()end}
on_load(ctx)
local first=A.state().level
assert(first==#A.levels+1 and A.puzzle().seed,'fresh install must generate')
local clue=A.puzzle().clues
local j=1;while P.id=='takuzu' and clue:sub(j,j)~='.' do j=j+1 end
assert(A.paint(j));local marks=table.concat(A.state().boards[first])
measured(ctx,on_draw,'generated partial')
on_leave();on_load(ctx)
assert(A.puzzle().clues==clue and table.concat(A.state().boards[first])==marks)
assert(A.undo());assert(A.paint(j))
local function snapshot()return saves[P.id..'.txt'] end
local old=snapshot()
assert(not A.new(G.sizes[P.id][1],19,1))
assert(A.state().level==first and snapshot()==old,'budget failure changes no progress')
fail='^random%-';assert(not A.new(G.sizes[P.id][1],101));fail=nil
assert(A.state().level==first and snapshot()==old,'record failure changes no progress')
fail='^'..P.id..'%.txt$';assert(not A.new(G.sizes[P.id][1],101));fail=nil
assert(A.state().level==first and snapshot()==old,'pointer failure changes no progress')
assert(A.new(G.sizes[P.id][1],101))
assert(A.puzzle().clues~=clue and A.state().level==first+1)
assert(A.visit(first));assert(A.puzzle().clues==clue and table.concat(A.state().boards[first])==marks)
assert(A.undo());assert(A.visit(first+1))
local p=A.puzzle()
for i=1,#p.answer do
 if P.id~='takuzu' or p.clues:sub(i,i)=='.' then
  local bit=tonumber(p.answer:sub(i,i))
  A.mode(P.id=='takuzu' and bit+1 or (bit==1 and 1 or 2));assert(A.paint(i))
 end
end
assert(A.valid(A.state().level,A.state().boards[A.state().level]))
assert(A.check());measured(ctx,on_draw,'generated solved')
on_leave();on_load(ctx);assert(A.state().won[A.state().level])
assert(A.tap(440,30));measured(ctx,on_draw,'generated settings')
assert(A.tap(240,740))
assert(A.tap(440,30));assert(A.tap(240,660))
assert(A.state().level==first+2,'New touch must generate, not open fixed board')
on_leave();on_load(ctx);assert(A.puzzle().seed)
assert(not A.visit(#A.levels),'generated sessions cannot return to authored campaign')
print(P.name..': generated default, distinct New, durable puzzle and undo, failure safety and touch PASS')
