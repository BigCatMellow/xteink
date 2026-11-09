-- Word Hunt: classic and FOX completion, hint use, saves, input and measured UI.
package.path='app/?.lua;../../tests/?.lua;'..package.path
local measured=require('game_canvas').check
_G.__TEST={}
dofile('app/index.lua')
local A=__TEST.api
local function eq(a,b,what)
  assert(a==b,(what or 'mismatch')..': '..tostring(a)..' vs '..tostring(b))
end
local storage={}
local redraws=0
local font={line_height=24,measure=function(_,s) return #s*11 end}
local ctx={
  storage={
    read=function(_,name) return storage[name] end,
    write=function(_,name,data) storage[name]=data end
  },
  fonts={small=font,medium=font,large=font},
  clock={millis=function() return 10000 end},
  invalidate=function() redraws=redraws+1 end
}
on_load(ctx)
local s=A.state()
eq(s.mode,1);eq(s.levels[1],1);eq(s.unlocked[2],1)
assert(not A.next())
assert(storage['word-hunt.txt']:find('version=2',1,true))
eq(#A.data.classic,8);eq(#A.data.fox,8)

local function choose_word(p,i,reverse)
  local word=p.words[i]
  local a=p.paths[i]
  local x,y=a[1],a[2]
  local xe,ye=x+(#word-1)*a[3],y+(#word-1)*a[4]
  if reverse then x,xe=xe,x;y,ye=ye,y end
  assert(A.select(x,y),'start first tile')
  assert(A.select(xe,ye),'finish last tile')
end
local function finish(mode,number)
  if s.mode~=mode then assert(A.mode(mode)) end
  eq(s.levels[mode],number)
  local p=A.data[mode==1 and 'classic' or 'fox'][number]
  assert(not A.complete(),'fresh puzzle unsolved')
  for i=1,#p.words do
    choose_word(p,i,i%2==0)
    eq(A.count(),i,'found count increases by one')
  end
  assert(A.complete(),'puzzle completed')
  eq(s.unlocked[mode],number+1,'unlocked stage')
  measured(ctx,on_draw,'word-hunt solved '..mode..'/'..number)
  on_leave();on_load(ctx)
  s=A.state()
  eq(s.levels[mode],number,'saved stage')
  assert(A.complete(),'solved state persisted')
end
-- Invalid pair does not credit a target and wrong second tap resets selection.
assert(A.select(1,1))
assert(A.select(1,2))
eq(A.count(),0)
assert(A.select(1,1))
assert(A.select(1,1))
eq(A.count(),0)
-- Help overlay catches taps without changing progress.
local bx,by,cell=A.geometry()
local before=redraws
on_input(ctx,{type='pointer',phase='down',gesture='tap',x=bx+cell/2,y=by+cell/2})
eq(redraws,before)
on_input(ctx,{type='pointer',phase='up',gesture='swipe',x=bx+cell/2,y=by+cell/2})
eq(redraws,before)
on_input(ctx,{type='pointer',phase='up',gesture='tap',x=440,y=35})
eq(redraws,before+1)
measured(ctx,on_draw,'word-hunt help first')
on_input(ctx,{type='pointer',phase='up',gesture='tap',x=bx+cell/2,y=by+cell/2})
eq(redraws,before+1,'help blocks puzzle')
on_input(ctx,{type='pointer',phase='up',gesture='tap',x=240,y=740})
eq(redraws,before+2)
-- Hints highlight the next missing word and spend at most two.
assert(A.hint())
eq(s.hints[1][1],1)
eq(s.revealed[1][1],1)
assert(A.hint())
eq(s.hints[1][1],1,'same reveal not double charged')
measured(ctx,on_draw,'word-hunt first hint')
choose_word(A.data.classic[1],1)
eq(s.revealed[1][1],0)
assert(A.hint());eq(s.hints[1][1],2)
choose_word(A.data.classic[1],2)
assert(A.hint());eq(s.hints[1][1],2,'third hint not charged')
measured(ctx,on_draw,'word-hunt two hints')
on_leave();on_load(ctx)
s=A.state()
eq(A.count(),2)
eq(s.hints[1][1],2)
assert(A.reset())
eq(A.count(),0)
eq(s.hints[1][1],0)

for n=1,8 do
  eq(s.levels[1],n)
  measured(ctx,on_draw,'classic unsolved '..n)
  finish(1,n)
  if n<8 then assert(A.next()) end
end
assert(A.next(),'generated classic puzzle follows authored finale')
eq(s.levels[1],9);assert(A.prev())
-- Separate-mode progress and independent save arrays.
assert(A.mode(2))
eq(s.levels[2],1);eq(s.unlocked[2],1)
eq(s.unlocked[1],9)
assert(A.hint());measured(ctx,on_draw,'fox hint')
on_leave();on_load(ctx);s=A.state()
eq(s.mode,2);eq(s.hints[2][1],1)
assert(A.reset())
for n=1,8 do
  eq(s.levels[2],n)
  measured(ctx,on_draw,'fox unsolved '..n)
  finish(2,n)
  if n<8 then assert(A.next()) end
end
assert(A.next(),'generated FOX follows authored finale')
eq(s.levels[2],9);assert(A.prev())
assert(A.mode(1))
eq(s.unlocked[1],9)
assert(A.prev())
eq(s.levels[1],7)
assert(A.next())
eq(s.levels[1],8)
assert(A.mode(2))
eq(s.levels[2],8)
assert(A.prev())
eq(s.levels[2],7)
assert(A.reset())
local p=A.data.fox[7]
choose_word(p,1)
assert(A.complete())
assert(A.next())
eq(s.levels[2],8)
on_leave();on_load(ctx);s=A.state()
eq(s.levels[2],8)
-- A revisit must not discard unfinished work.
assert(A.mode(1))
assert(A.visit(4))
assert(A.reset())
local p=A.data.classic[4]
choose_word(p,1)
assert(A.prev())
on_leave();on_load(ctx);s=A.state()
assert(A.next())
eq(A.count(),1,'partially found word retained across visited scenes')
-- Incoming touch coordinates must select correct board cells exactly once.
assert(A.mode(2))
assert(A.visit(8))
assert(A.reset())
local fx,fy,spacing=A.geometry()
local word=A.data.fox[8]
local point=word.paths[1]
local tx=fx+(point[1]-.5)*spacing
local ty=fy+(point[2]-.5)*spacing
before=redraws
on_input(ctx,{type='pointer',phase='up',gesture='tap',x=tx,y=ty})
eq(redraws,before+1)
eq(s.selected[1],point[1])
eq(s.selected[2],point[2])
on_input(ctx,{type='pointer',phase='up',gesture='tap',x=2,y=4})
eq(redraws,before+1)
-- Help, hint, boards, solved states, and max counters at both font sizes.
for mode=1,2 do
  if s.mode~=mode then A.mode(mode) end
  for n=1,8 do
    A.visit(n);A.reset()
    measured(ctx,on_draw,'word hunt fresh '..mode..'/'..n)
    A.hint()
    measured(ctx,on_draw,'word hunt hint '..mode..'/'..n)
    s.hints[mode][n]=2
    measured(ctx,on_draw,'word hunt max hints '..mode..'/'..n)
    local board=A.data[mode==1 and 'classic' or 'fox'][n]
    for i=1,#board.words do choose_word(board,i) end
    measured(ctx,on_draw,'word hunt complete '..mode..'/'..n)
  end
  A.tap(440,35)
  measured(ctx,on_draw,'word-hunt help '..mode)
  A.tap(440,35)
end
-- A legacy v1 save migrates all finds/hints and opens the generated continuation.
local legacy=storage['word-hunt.txt']:gsub('version=2','version=1'):gsub('unlocked=[^\n]+','unlocked=8,8')
storage['word-hunt.txt']=legacy
on_load(ctx);s=A.state()
eq(s.levels[2],8);eq(s.unlocked[1],9);eq(s.unlocked[2],9)
assert(A.complete(),'legacy completed board retained')
-- Reproducible generated boards, both independent mode saves and sparse state.
for mode=1,2 do
  if s.mode~=mode then A.mode(mode) end
  assert(A.visit(9))
  for number=9,20 do
    local p=A.puzzle()
    local signature=table.concat(p.rows)
    eq(s.levels[mode],number)
    A.hint();measured(ctx,on_draw,'generated hint '..mode..'/'..number)
    choose_word(p,1)
    on_leave();on_load(ctx);s=A.state()
    eq(table.concat(A.puzzle().rows),signature,'seed survives reload')
    eq(A.count(),1,'generated find retained')
    if mode==1 then
      assert(A.prev());on_leave();on_load(ctx);s=A.state();assert(A.next())
      eq(A.count(),1,'generated partial survives a level visit')
      eq(s.hints[mode][number],1,'generated hint use retained')
      for i=2,4 do choose_word(A.puzzle(),i) end
    end
    assert(A.complete())
    measured(ctx,on_draw,'generated solved '..mode..'/'..number)
    assert(A.next(),'no authored last-level stop')
  end
  local entries=0
  for _ in pairs(s.found[mode]) do entries=entries+1 end
  assert(entries<=9,'generated boards do not accumulate in RAM')
end
-- Header, hints and counters also fit a very large puzzle number.
s.unlocked[s.mode]=999999999
assert(A.visit(999999999))
A.hint();measured(ctx,on_draw,'word hunt maximum puzzle number')
local working_write=ctx.storage.write
ctx.storage.write=function() return nil,'quota' end
assert(A.prev());eq(s.levels[s.mode],999999999,'failed save prevents leaving generated puzzle')
measured(ctx,on_draw,'word hunt save failure')
ctx.storage.write=working_write
assert(A.visit(1))
before=redraws
assert(not on_input(ctx,{type='key',phase='down',key='up',time_ms=20000}))
eq(s.levels[s.mode],1,'PREV at first puzzle must not fall through to NEXT')
eq(redraws,before)
storage['word-hunt.txt']='version=1\nmode=9\nlevels=400\n'
on_load(ctx)
eq(A.state().mode,1,'corrupt save safely reset')
assert(type(on_tick)=='nil','no animation timer')
print('Word Hunt: authored + generated WORDS/FOX, legacy saves, visits, hints and layout PASS')
