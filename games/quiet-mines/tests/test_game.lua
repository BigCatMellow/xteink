package.path='app/?.lua;../../tests/?.lua;'..package.path
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
eq(S.level,25);eq(#A.legacy_levels,24);assert(not A.next())
assert(not A.prev(),'PREV must not lead to fixed historical fields')
eq(S.level,25,'first generated field remains selected')
local firstGenerated=A.board(25)
assert(firstGenerated.n==10 and firstGenerated.total==18)
-- Playschool portrait style: a single grid, no inner rectangle per tile.
-- A tiny right/bottom bevel differentiates unopened tiles at low ink cost.
do
  local x,y,cell=A.geometry()
  local g=require('game_canvas').canvas()
  local old=g.rect
  local nested=0
  local bevelBottom,bevelRight=false,false
  function g:rect(px,py,w,h,opt)
    if px==x+4 and py==y+4 and w==cell-8 and h==cell-8 and
       not (opt and opt.fill) then nested=nested+1 end
    if opt and opt.fill then
      if px==x+3 and py==y+cell-4 and w==cell-6 and h==1 then
        bevelBottom=true
      end
      if px==x+cell-4 and py==y+3 and w==1 and h==cell-6 then
        bevelRight=true
      end
    end
    return old(self,px,py,w,h,opt)
  end
  g:reset();on_draw(ctx,g);g:verify('Mines clean unopened grid')
  assert(nested==0,'per-tile inset squares must not return')
  assert(bevelBottom and bevelRight,'hidden tiles retain subtle 1-bit depth')
end
assert(not firstGenerated.mines[1]);eq(A.nearby(firstGenerated,1),0)
local function signature(level)
  local b=A.board(level)
  local out={}
  for i=1,b.n*b.n do out[i]=b.mines[i] and '1' or '0' end
  return table.concat(out)
end
local firstLayout=signature(25)
assert(A.new());S=A.state();eq(S.level,26)
local secondLayout=signature(26)
assert(secondLayout~=firstLayout,'New must create a different mine layout')
on_leave();on_load(ctx);S=A.state()
eq(S.level,26);eq(signature(26),secondLayout,'generated layout survives reload')
assert(A.prev());eq(S.level,25);eq(signature(25),firstLayout,'prior generated layout survives revisits')
assert(A.difficulty());eq(S.difficulty,3,'difficulty cycles to hard')
assert(A.new());S=A.state();eq(A.board(S.level).n,12,'hard selects 12x12')
assert(A.difficulty());eq(S.difficulty,1,'difficulty cycles to easy')
assert(A.new());S=A.state();eq(A.board(S.level).n,8,'easy selects 8x8')
assert(A.visit(1));S=A.state()
local first=A.board(1)
assert(not first.mines[1]);eq(A.nearby(first,1),0)
assert(A.apply(2)) -- Before safe START, other cells are not revealed.
eq(S.marks[1][2],0)
-- Correct initial reveals and flags save across reload.
assert(A.apply(1))
-- Hint highlights a deduction from visible clue arithmetic but does not mark.
local candidate=A.infer_hint(1,S.marks[1])
assert(candidate and candidate.index and candidate.kind)
local frozen=table.concat(S.marks[1])
assert(A.hint())
eq(A.hinted(),candidate.index)
eq(table.concat(S.marks[1]),frozen,'hints do not change player marks')
if candidate.kind=='OPEN' then assert(not first.mines[candidate.index])
else assert(first.mines[candidate.index]) end
local count=0
for _,v in ipairs(S.marks[1]) do if v==2 then count=count+1 end end
assert(count>1,'zero-cell start floods neighbors')
local mine=A.legacy_levels[1].mines[1]
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
 assert(S.unlocked>=math.min(24,level+1))
 local open=0
 for _,v in ipairs(S.marks[level]) do if v==2 then open=open+1 end end
 eq(open,safe,'all safe cells exposed')
end
for level=1,24 do
 eq(S.level,level)
 A.restart()
 measured(ctx,on_draw,'mines fresh '..level)
 local b=A.board(level)
 reveal_safe(level)
 measured(ctx,on_draw,'mines cleared '..level)
 on_leave();on_load(ctx);S=A.state()
 assert(A.solved(level,S.marks[level]),'completed state preserved')
 assert(A.next())
end
-- Level changes do not destroy an incomplete board or flags.
assert(A.visit(4));A.restart()
assert(A.apply(1))
local mine=A.legacy_levels[4].mines[1]
assert(A.mode());assert(A.apply(mine))
assert(A.visit(5))
on_leave();on_load(ctx);S=A.state()
assert(A.prev());eq(S.marks[4][mine],1,'flag persisted after visit')
assert(S.unlocked>=25)
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
for level=1,24 do
 A.visit(level);A.restart()
 measured(ctx,on_draw,'mines reset '..level)
 A.apply(1);measured(ctx,on_draw,'mines partial '..level)
end
A.tap(442,33);measured(ctx,on_draw,'mines help')
A.tap(220,735)
-- The 12 original fields remain completable by direct arithmetic; advanced
-- fields must be playable by the same direct/subset rule implemented by Hint.
local advancedOverlap=0
for level=13,24 do
  assert(A.visit(level));assert(A.restart());assert(A.apply(1))
  local b=A.board(level)
  local safety=0
  while not A.solved(level,S.marks[level]) do
    local step,reason=A.infer_hint(level,S.marks[level])
    assert(step, 'No-guess solver stuck on field '..level..': '..tostring(reason))
    if step.rule=='overlap' then advancedOverlap=advancedOverlap+1 end
    if step.kind=='OPEN' then
      if S.mode~='OPEN' then A.mode() end
      assert(not b.mines[step.index],'unsafe inferred opening')
      assert(A.apply(step.index))
    else
      if S.mode~='FLAG' then A.mode() end
      assert(b.mines[step.index],'incorrect inferred flag')
      assert(A.apply(step.index))
    end
    safety=safety+1
    assert(safety<b.n*b.n*3,'inference loop did not converge')
  end
  assert(A.solved(level,S.marks[level]))
end
assert(advancedOverlap>=12,'advanced campaign requires multi-number overlap deductions')
-- Reconstruct the finished original twelfth board for the legacy-save case.
assert(A.visit(12));assert(A.restart());assert(A.apply(1))
local oldBoard=A.board(12)
for i=1,oldBoard.n*oldBoard.n do
  if not oldBoard.mines[i] and S.marks[12][i]~=2 then assert(A.apply(i)) end
end
assert(A.solved(12,S.marks[12]))
-- A saved original 12-field installation must gain the new levels without
-- destroying previously submitted boards, unfinished marks, or undo.
local old={}
old[#old+1]='version=1'
old[#old+1]='level=12'
old[#old+1]='unlocked=12'
old[#old+1]='mode=FLAG'
for level=1,12 do
  local value={}
  for _,v in ipairs(S.marks[level]) do value[#value+1]=tostring(v) end
  old[#old+1]='B'..level..'='..table.concat(value)
  old[#old+1]='F'..level..'=0'
  old[#old+1]='H'..level..'='
end
save['quiet-mines.txt']=table.concat(old,'\n')
on_load(ctx);S=A.state()
eq(S.level,12);eq(S.unlocked,13,'completed original campaign unlocks new field')
assert(A.solved(12,S.marks[12]),'completed original board retained')
assert(A.next());eq(S.level,13)
eq(#S.marks[13],100,'new fields are appended with empty state')
assert(A.new());S=A.state()
eq(S.level,25,'New from legacy field must start after all 24 authored fields')
assert(A.board(25).n>=8,'New creates a real procedural field')
save['quiet-mines.txt']='version=1\nlevel=999\nunlocked=999\n'
on_load(ctx);eq(A.state().level,25)
assert(type(on_tick)=='nil','no frame animation')
print('Quiet Mines: legacy 24 boards, random field, no-guess solver, save and layout PASS')
