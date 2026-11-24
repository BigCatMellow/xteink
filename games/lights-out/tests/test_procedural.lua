package.path='app/?.lua;../../tests/?.lua;'..package.path
_G.__TEST={}
dofile('app/index.lua')
local A=__TEST.api
local saves,fail={},false
local f={line_height=24,measure=function(_,s)return #s*10 end}
local ctx={storage={read=function(_,k)return saves[k] end,
 write=function(_,k,v)if fail then return nil,'quota' end;saves[k]=v;return true end},
 fonts={small=f,medium=f,large=f},clock={millis=function()return 4242 end},invalidate=function()end}
on_load(ctx)
assert(A.tap_tile(1))
local old=A.state();local raw=saves['lights-out.txt'];local before=table.concat(old.board)
assert(not A.generate(5,5,function()return 0 end),'exhaustion cannot select a fixed board')
assert(not A.new(1,function()return 0 end))
assert(A.state()==old and saves['lights-out.txt']==raw and table.concat(old.board)==before)
fail=true;assert(not A.new(1));fail=false
assert(A.state()==old and saves['lights-out.txt']==raw)
assert(A.new(1));assert(table.concat(A.state().initial)~=table.concat(old.initial))
local clue=table.concat(A.state().initial)
on_leave();on_load(ctx);assert(table.concat(A.state().initial)==clue)
print('Lights Out: randomized New, no fixed fallback, safe failure and exact reload PASS')
