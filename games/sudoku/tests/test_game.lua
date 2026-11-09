package.path='app/?.lua;../../tests/?.lua;'..package.path
local measured=require('game_canvas').check
local Generator=require('generator')
_G.__TEST={}
dofile('app/index.lua')
local A=__TEST.api
local function eq(a,b,msg) assert(a==b,(msg or 'mismatch')..': '..tostring(a)..' / '..tostring(b)) end
local storage={}
local redraws=0
local ctx={storage={read=function(_,n) return storage[n] end,write=function(_,n,v) storage[n]=v end},
  invalidate=function() redraws=redraws+1 end,clock={millis=function() return 10000 end}}
local function reload() on_leave();on_load(ctx);return A.state() end
local function select(i) assert(A.select((i-1)%9+1,math.floor((i-1)/9)+1)) end
local function tap_control(key)
  local b=A.controls[key];return A.tap(b[1]+b[3]/2,b[2]+b[4]/2)
end
local grid=A.geometry
local first_x,first_y=grid.x+grid.cell/2,grid.y+grid.cell/2
on_load(ctx)
local s=A.state()
eq(s.level,1);eq(s.unlocked,1);eq(s.difficulty,2)
measured(ctx,on_draw,'sudoku fresh')
local first,given=nil,nil
for i=1,81 do if A.puzzle().given[i]==0 then first=first or i else given=given or i end end
assert(first and given)
select(given);assert(not A.put(1),'givens immutable');assert(not A.erase())
select(first)
tap_control('notes');assert(s.noteMode)
for n=1,9 do assert(A.put(n)) end
eq(s.notes[first],511);measured(ctx,on_draw,'sudoku all nine notes')
s=reload();eq(s.notes[first],511);assert(s.noteMode);eq(s.selected,first)
-- Lua 5.4/5.5 used to serialize arithmetic masks as 511.0. Recover those
-- existing boards and every undo snapshot, then write canonical integer masks.
do
  local Store=require('puzzle_store')
  on_leave()
  local saved=Store.get(ctx.storage,'sudoku',1)
  assert(not saved:match('notes=([^\n]+)'):find('%.'),'integer note encoding')
  local function decimals(masks) return (masks:gsub('%d+',function(n) return n..'.0' end)) end
  local legacy=saved:gsub('(notes=)([^\n]+)',function(k,v) return k..decimals(v) end)
  legacy=legacy:gsub('(history=)([^\n]+)',function(k,v)
    return k..v:gsub('(:)([%d,]+)',function(colon,masks) return colon..decimals(masks) end)
  end)
  local history=#s.history
  Store.put(ctx.storage,'sudoku',1,legacy)
  on_load(ctx);s=A.state()
  eq(s.notes[first],511,'legacy decimal notes recovered');eq(#s.history,history)
  assert(s.noteMode);eq(s.selected,first)
end
assert(tap_control('undo'));eq(s.notes[first],255,'note undo persisted')
assert(A.put(9));tap_control('notes');assert(not s.noteMode)
assert(A.put(A.puzzle().solution[first]));eq(s.notes[first],0)
assert(A.undo());eq(s.notes[first],511,'entering value can be undone with notes')
assert(tap_control('erase'));eq(s.notes[first],0)
assert(A.undo());eq(s.notes[first],511)
-- Cleaning a peer's note is part of the same undo snapshot.
local peer=nil
for _,j in ipairs(Generator.peers[first]) do if A.puzzle().given[j]==0 then peer=j;break end end
assert(peer)
select(peer);tap_control('notes');assert(s.noteMode);A.put(7)
select(first);tap_control('notes');A.put(7)
eq(s.notes[peer],0);assert(A.undo());eq(s.notes[peer],64,'peer notes restored by undo')
-- A conflicting number remains editable; CHECK reports errors without erasing it.
local clash=nil
for _,j in ipairs(Generator.peers[first]) do if s.board[j]>0 then clash=s.board[j];break end end
assert(clash);A.put(clash);assert(A.conflicts(first));A.check()
measured(ctx,on_draw,'sudoku conflicting entry')
s=reload();eq(s.board[first],clash)
-- NEW is deliberate and retains the unfinished board and its undo.
local oldHistory=#s.history
assert(A.new(1));s=A.state();eq(s.level,2);eq(s.difficulty,1)
assert(A.visit(1));s=A.state();eq(s.board[first],clash);eq(#s.history,oldHistory)
assert(A.undo());s=reload();eq(s.level,1)
assert(A.visit(2));s=A.state();eq(s.level,2)
-- Correct answers survive close/reopen before explicit submission.
local function fill()
  local p=A.puzzle()
  if s.noteMode then tap_control('notes') end
  for i=1,81 do if p.given[i]==0 then select(i);if s.board[i]~=p.solution[i] then assert(A.put(p.solution[i])) end end end
end
for difficulty=1,3 do
  if difficulty~=1 then assert(A.new(difficulty));s=A.state() end
  measured(ctx,on_draw,'sudoku difficulty '..difficulty)
  fill();assert(A.solved());assert(not s.submitted)
  s=reload();assert(A.solved());assert(not s.submitted)
  measured(ctx,on_draw,'sudoku correct unsubmitted '..difficulty)
  assert(tap_control('check'));assert(s.submitted)
  assert(not A.put(1));assert(not A.erase());assert(not A.undo())
  measured(ctx,on_draw,'sudoku solved '..difficulty)
  s=reload();assert(s.submitted)
end
local unlocked=s.unlocked
assert(A.visit(1));s=A.state();A.reset();eq(s.unlocked,unlocked)
eq(s.board[first],0);eq(s.notes[first],0);eq(#s.history,0)
assert(A.visit(2));s=A.state();assert(s.submitted,'reset leaves other boards alone')
-- Help and menu block accidental board edits; every overlay is measured.
tap_control('help');measured(ctx,on_draw,'sudoku help')
assert(not A.tap(first_x,first_y));A.tap(240,740)
tap_control('new');measured(ctx,on_draw,'sudoku new/history menu')
assert(not A.tap(first_x,first_y));A.tap(240,740)
-- Pointer down, swipes and released keys do not produce a redraw.
A.reset()
local before=redraws
assert(not on_input(ctx,{type='pointer',phase='down',x=first_x,y=first_y}))
assert(not on_input(ctx,{type='pointer',phase='up',gesture='swipe',x=first_x,y=first_y}))
assert(not on_input(ctx,{type='key',phase='up',key='up',time_ms=1000}))
eq(redraws,before)
assert(on_input(ctx,{type='pointer',phase='up',gesture='tap',x=first_x,y=first_y}))
eq(A.state().selected,1);eq(redraws,before+1)
assert(on_input(ctx,{type='key',phase='down',key='up',time_ms=1000}))
eq(A.state().level,1)
assert(not on_input(ctx,{type='key',phase='down',key='down',time_ms=1100}))
eq(A.state().level,1,'page key debounced')
assert(on_input(ctx,{type='key',phase='down',key='down',time_ms=1300}))
eq(A.state().level,2)
-- Touch digit rectangles match the drawn numpad.
s=A.state();A.reset()
local blank=nil
for i=1,81 do if A.puzzle().given[i]==0 then blank=i;break end end
select(blank)
local dx,dy,dw,dh=A.digit_box(5)
assert(on_input(ctx,{type='pointer',phase='up',gesture='tap',x=dx+dw/2,y=dy+dh/2}))
eq(s.board[blank],5)
-- Device-photo regression: inspect filled geometry, independent of line_width.
do
 local g=require('game_canvas').canvas()
 local bars={}
 local rect=g.rect
 function g:rect(x,y,w,h,o)
  if o and o.fill then bars[#bars+1]={x=x,y=y,w=w,h=h,radius=o.radius} end
  return rect(self,x,y,w,h,o)
 end
 g:reset();on_draw(ctx,g);g:verify('sudoku solid divisions')
 assert(grid.size>=468 and grid.cell==52,'board must use the available width')
 local function bar(x,y,w,h)
  for _,b in ipairs(bars) do if b.x==x and b.y==y and b.w==w and b.h==h and b.radius==0 then return true end end
  return false
 end
 for _,i in ipairs({3,6}) do
  assert(bar(grid.x+i*52-2,grid.y,4,468),'missing solid vertical 3x3 separator')
  assert(bar(grid.x,grid.y+i*52-2,468,4),'missing solid horizontal 3x3 separator')
 end
 assert(bar(grid.x,grid.y,4,468) and bar(grid.x+464,grid.y,4,468),'outer frame must be solid')
 assert(bar(grid.x+52,grid.y,1,468),'fine cell grid must remain lighter')
 for n=1,9 do
  local x,y,w,h=A.digit_box(n)
  assert(w>=48 and h>=48,'comfortable number-key touch target')
  assert(x>=0 and x+w<=480 and y+h<=800)
  if s.board[blank]~=n then assert(A.tap(x+w/2,y+h/2)) end
  eq(s.board[blank],n,'each 3-column digit key matches its label')
 end
 for i=1,81 do
  local x=grid.x+(i-1)%9*52+26
  local y=grid.y+math.floor((i-1)/9)*52+26
  assert(A.tap(x,y));eq(s.selected,i,'all 81 expanded cell touch targets')
 end
end
-- Maximum displayed puzzle number and error counter have bounded text.
assert(A.new(3));s=A.state();s.level=999999999;s.unlocked=999999999
measured(ctx,on_draw,'sudoku maximum number')
for i=1,81 do if A.puzzle().given[i]==0 then s.board[i]=A.puzzle().solution[i]%9+1 end end
A.check();measured(ctx,on_draw,'sudoku maximum mistakes')
local working_write=ctx.storage.write
ctx.storage.write=function() return nil,'quota' end
assert(A.visit(1));eq(s.level,999999999,'failed save prevents leaving current puzzle')
measured(ctx,on_draw,'sudoku save failure')
ctx.storage.write=working_write
storage['sudoku.txt']='version=1\nlevel=500\nunlocked=1'
on_load(ctx);eq(A.state().level,1,'malformed index handled')
assert(type(on_tick)=='nil','no animation loop')
print('Sudoku: generated puzzles, notes/cleanup, saved undo, visits, CHECK, touch and measured layouts PASS')
