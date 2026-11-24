package.path='app/?.lua;../../tests/?.lua;'..package.path
_G.__TEST={}
dofile('app/index.lua')
local G=require('generator')
local A=__TEST.api
local saves={}
local f={line_height=24,measure=function(_,s)return #s*10 end}
local ctx={storage={read=function(_,k)return saves[k] end,write=function(_,k,v)saves[k]=v;return true end},
 fonts={small=f,medium=f,large=f},clock={millis=function()return 4321 end},invalidate=function()end}
assert(G.generate_v2(14,false,0),'legacy fallback must remain readable')
assert(not G.generate_v2(14,true,0),'fresh generator must not use fixed fallback')
on_load(ctx)
assert(saves['pattern-12.txt']:find('v4:',1,true),'first fresh board must use strict generation')
local first=A.state().level
local picture=table.concat(A.shape(first).rows)
local old=G.generate_v2
G.generate_v2=function()return nil,'forced failure' end
assert(A.new())
assert(A.state().level==first and table.concat(A.shape(first).rows)==picture)
G.generate_v2=old
assert(A.new());assert(A.state().level==first+1)
assert(saves['pattern-13.txt']:find('v4:',1,true))
on_leave();on_load(ctx)
assert(A.prev());assert(table.concat(A.shape(first).rows)==picture)
print('Nonogram: strict random generation, legacy replay and failed New safety PASS')
