-- Exercise both generated region and lamp games, standalone and hosted.
package.path='app/?.lua;../../tests/?.lua;'..package.path
_G.__TEST={}
dofile('app/index.lua')
local A=__TEST.api
local crowns=type(A.mark)=='function'
local kind=crowns and 'crowns' or 'akari'
local Random=require('random_session')
local measured=require('game_canvas').check
local saves,fail={},nil
local font={line_height=24,measure=function(_,s)return #s*10 end}
local ctx={storage={read=function(_,k)return saves[k],saves[k]==nil and 'not_found' or nil end,
 write=function(_,k,v)if fail and k:match(fail) then return nil,'quota' end;saves[k]=v;return true end},
 fonts={small=font,medium=font,large=font},clock={millis=function()return 123456 end},invalidate=function()end}
on_load(ctx)
local S=assert(A.state());local first=S.level
assert(first==#A.levels+1 and S.generated.seed)
local clues=S.generated.clues
local function mark(i,v)
 if crowns then return A.mark(i,v) end
 local n=A.state().b.n
 return A.choose((i-1)%n+1,math.floor((i-1)/n)+1,v)
end
local function marks()
 local s=A.state();return crowns and s.marks[s.level] or s.marks
end
local i=1
if not crowns then while S.b.tiles[i]~='.' do i=i+1 end end
assert(mark(i,2))
local before=table.concat(marks())
on_leave();on_load(ctx)
assert(A.state().generated.clues==clues and table.concat(marks())==before)
assert(A.undo());assert(mark(i,2))
local index=saves['random-index.txt']
assert(not A.new(5,19,1))
assert(A.state().level==first and saves['random-index.txt']==index)
fail='^random%-';assert(not A.new(5,101));fail=nil
assert(A.state().level==first and saves['random-index.txt']==index)
assert(A.new(5,101))
assert(A.state().level==first+1 and A.state().generated.clues~=clues)
assert(A.prev());assert(A.state().generated.clues==clues and table.concat(marks())==before)
assert(A.undo());assert(A.next())
local p=A.state().generated
for j=1,#p.answer do if p.answer:sub(j,j)=='1' then assert(mark(j,crowns and 2 or 1)) end end
if crowns then assert(A.valid(A.state().level,marks()));assert(A.check())
else assert(A.complete(A.state().b,marks())) end
measured(ctx,on_draw,'generated solved')
on_leave();on_load(ctx)
assert(A.state().generated.clues==p.clues)
assert(A.tap(440,30));measured(ctx,on_draw,'generated menu')
assert(A.tap(240,740));assert(A.tap(440,30));assert(A.tap(240,650))
assert(A.state().level==first+2)
on_leave();on_load(ctx);assert(A.state().generated.seed)
print(kind..': generated default, unique New, archive, undo, failed generation/save and touch PASS')
