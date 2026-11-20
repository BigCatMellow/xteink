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
on_load(ctx)
local first_x,first_y=grid.x+grid.cell/2,grid.y+grid.cell/2
local hubBoard=grid.y==66
local expectedCell=hubBoard and 49 or 53
local expectedSize=hubBoard and 441 or 477
local expectedX=hubBoard and 19 or 1
local expectedY=hubBoard and 66 or 1
eq(grid.x,expectedX);eq(grid.y,expectedY)
eq(grid.cell,expectedCell);eq(grid.size,expectedSize)
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
local oldSeed=s.seed
assert(type(oldSeed)=='number','first Sudoku was generated from a seed')
assert(A.new(1));s=A.state();eq(s.level,2);eq(s.difficulty,1)
assert(s.seed~=oldSeed,'New Sudoku must use a new generated seed')
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
  assert(A.check());assert(s.submitted)
  assert(not A.put(1));assert(not A.erase());assert(not A.undo())
  measured(ctx,on_draw,'sudoku solved '..difficulty)
  s=reload();assert(s.submitted)
end
local unlocked=s.unlocked
assert(A.visit(1));s=A.state();A.reset();eq(s.unlocked,unlocked)
eq(s.board[first],0);eq(s.notes[first],0);eq(#s.history,0)
assert(A.visit(2));s=A.state();assert(s.submitted,'reset leaves other boards alone')
-- Help and menu block accidental board edits; every overlay is measured.
assert(A.tap(240,760),'open menu from solved panel');assert(A.tap(350,630));measured(ctx,on_draw,'sudoku help')
assert(not A.tap(first_x,first_y));A.tap(240,740)
measured(ctx,on_draw,'sudoku new/history menu')
assert(not A.tap(first_x,first_y));A.tap(240,750)
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

-- Actual measured regions/touch positions (normal and enlarged font profiles).
do
 local reports=require('screen_space').occupancy(ctx,on_draw,'sudoku gameplay screen')
 for _,r in ipairs(reports) do
  eq(#r.regions,1,'one Sudoku puzzle region')
  local board=r.regions[1]
  eq(board.x,expectedX);eq(board.y,expectedY)
   eq(board.w,expectedSize);eq(board.h,expectedSize)
  assert(r.largest_gap.pixels<48,'unused band between screen elements '..r.largest_gap.pixels)
  eq(#r.number_keys,9,'all nine numeric buttons must be visible')
  for _,b in ipairs(r.number_keys) do
   eq(b.w,108);eq(b.h,90)
   assert(b.x>=0 and b.x+b.w<=480 and b.y>=0 and b.y+b.h<=800,'off-screen number key')
  end
 end
 for _,name in ipairs({'notes','undo','erase','menu'}) do
  local b=A.controls[name];eq(b[4],66,'stacked keypad-adjacent tool')
 end
 for n=1,9 do
  local x,y,w,h=A.digit_box(n)
  eq(y,510+math.floor((9-n)/3)*96,'HTML calculator keypad row')
  eq(w,108);eq(h,90)
 end
 local _,y,_,h=A.digit_box(1)
 eq(y+h,792,'reserve eight pixels at bottom')
end

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
 assert(grid.size==expectedSize and grid.cell==expectedCell,'device and Hub board geometry preserved')
 local function bar(x,y,w,h)
  for _,b in ipairs(bars) do if b.x==x and b.y==y and b.w==w and b.h==h and b.radius==0 then return true end end
  return false
 end
 for _,i in ipairs({3,6}) do
  assert(bar(grid.x+i*grid.cell-1,grid.y,3,grid.size),'missing solid vertical 3x3 separator')
  assert(bar(grid.x,grid.y+i*grid.cell-1,grid.size,3),'missing solid horizontal 3x3 separator')
 end
 assert(bar(grid.x,grid.y,3,grid.size) and bar(grid.x+grid.size-3,grid.y,3,grid.size),'outer frame must be solid')
 assert(bar(grid.x+grid.cell,grid.y,1,grid.size),'interior lines must be 1px')
 for n=1,9 do
  local x,y,w,h=A.digit_box(n)
  assert(w>=48 and h>=48,'comfortable number-key touch target')
  assert(x>=0 and x+w<=480 and y+h<=800)
  if s.board[blank]~=n then assert(A.tap(x+w/2,y+h/2)) end
  eq(s.board[blank],n,'each 3-column digit key matches its label')
 end
 for i=1,81 do
  local x=grid.x+(i-1)%9*grid.cell+math.floor(grid.cell/2)
  local y=grid.y+math.floor((i-1)/9)*grid.cell+math.floor(grid.cell/2)
  assert(A.tap(x,y));eq(s.selected,i,'all 81 expanded cell touch targets')
 end
end

-- Meditation interface parity: row/column/box guides, mini notes and settings.
do
  A.reset();s=A.state()
  assert(s.highlight and s.autoClean and s.showConflicts,'default enabled options')
  local firstBlank,secondBlank,numbered=nil,nil,nil
  for i=1,81 do
    if A.puzzle().given[i]==0 then
      firstBlank=firstBlank or i
      if firstBlank and i~=firstBlank then
        for _,peer in ipairs(Generator.peers[firstBlank]) do
          if peer==i then secondBlank=i;break end
        end
      end
    elseif not numbered then numbered=i end
    if firstBlank and secondBlank and numbered then break end
  end
  assert(firstBlank and secondBlank and numbered)
  select(firstBlank)
  local geometry=A.guides(firstBlank)
  eq(geometry.row,math.floor((firstBlank-1)/9))
  eq(geometry.col,(firstBlank-1)%9)
  local g=require('game_canvas').canvas()
  local outlines,lines={},{0}
  local original=g.rect
  function g:rect(x,y,w,h,options)
    if not(options and options.fill) then outlines[#outlines+1]={x=x,y=y,w=w,h=h} end
    return original(self,x,y,w,h,options)
  end
  local tiles={}
  if g.image then
    local image=g.image
    function g:image(im,x,y,o) tiles[x..','..y]=true;return image(self,im,x,y,o) end
  end
  g:reset();on_draw(ctx,g);g:verify('selection guides and 1px cell rules')
  local function hasRect(x,y,w,h)
    for _,q in ipairs(outlines) do
      if q.x==x and q.y==y and q.w==w and q.h==h then return true end
    end
    return false
  end
  -- Guides are grey shading only: never row/column outline bars (user
  -- feedback 2026-11-18: the lines were confusing on the reader).
  local function shaded(cells)
    for _,c in ipairs(cells) do if not tiles[(grid.x+c[1]*grid.cell)..','..(grid.y+c[2]*grid.cell)] then return false end end
    return true
  end
  local row,col={},{}
  for k=0,8 do
    if k~=geometry.col then row[#row+1]={k,geometry.row} end
    if k~=geometry.row then col[#col+1]={geometry.col,k} end
  end
  assert(not hasRect(grid.x,grid.y+geometry.row*grid.cell,grid.size,grid.cell),'row guide must not be an outline')
  assert(not hasRect(grid.x+geometry.col*grid.cell,grid.y,grid.cell,grid.size),'column guide must not be an outline')
  if g.image then
    assert(shaded(row),'row guide shading missing')
    assert(shaded(col),'column guide shading missing')
    assert(not tiles[(grid.x+geometry.col*grid.cell)..','..(grid.y+geometry.row*grid.cell)],'selected cell stays unshaded')
  end
  -- Pencil digits are drawn inside the cells as monochrome segments,
  -- not represented solely by a dot or a status caption.
  assert(tap_control('notes'))
  select(firstBlank)
  assert(A.put(1));assert(A.put(2));assert(A.put(3))
  local ink=0
  local brush=require('game_canvas').canvas()
  local origLine=brush.line
  function brush:line(...) ink=ink+1;return origLine(self,...) end
  brush:reset();on_draw(ctx,brush);brush:verify('pencil glyphs inside board')
  assert(ink>=8,'pencil digits should use visible vector strokes')
  select(numbered)
  eq(s.locked,A.puzzle().given[numbered],'tapping a filled digit locks the note')
  eq(s.selected,0,'lock mode separates the number from a cell')
  select(secondBlank)
  assert(s.notes[secondBlank]>0,'locked number writes note directly by tapping a cell')
  eq(A.note_total(),4)
  assert(A.clear_notes())
  eq(A.note_total(),0)
  assert(A.undo(),'clear-all pencil marks is undoable')
  eq(A.note_total(),4)
  -- The menu has the same Meditation preference toggles, persisted in v1 saves.
  assert(tap_control('notes'));assert(not s.noteMode)
  assert(tap_control('menu'))
  assert(A.tap(128,517));assert(not s.autoClean,'autoclean toggle')
  assert(A.tap(352,517));assert(not s.highlight,'highlight toggle')
  assert(A.tap(128,572));assert(not s.showConflicts,'conflict toggle')
  assert(A.tap(352,572));assert(s.showMistakes,'mistake toggle')
  assert(A.tap(128,630));assert(s.multiMode,'touch multi-select toggle')
  assert(A.tap(240,740))
  s=reload()
  assert(not s.autoClean and not s.highlight and not s.showConflicts and s.showMistakes and s.multiMode,
    'save and reload all Meditation settings')
  assert(A.tap(grid.x+((firstBlank-1)%9)*grid.cell+math.floor(grid.cell/2),grid.y+math.floor((firstBlank-1)/9)*grid.cell+math.floor(grid.cell/2)))
  assert(A.tap(grid.x+((secondBlank-1)%9)*grid.cell+math.floor(grid.cell/2),grid.y+math.floor((secondBlank-1)/9)*grid.cell+math.floor(grid.cell/2)))
  assert(s.multi[firstBlank] and s.multi[secondBlank],'multi-select contains both squares')
  assert(tap_control('notes'))
  assert(A.put(5))
  assert(math.floor(s.notes[firstBlank]/16)%2==1 and
      math.floor(s.notes[secondBlank]/16)%2==1,'multi-select applies notes to both')
  assert(tap_control('notes'))
  -- Legacy puzzle saves with no new options still reload against v1 seeds.
  local Store=require('puzzle_store')
  local classic=Generator.generate(1,2)
  local zero={}
  for i=1,81 do zero[i]=0 end
  Store.put(ctx.storage,'sudoku',1,table.concat({
    'version=1','difficulty=2','board='..table.concat(classic.given),
    'notes='..table.concat(zero,','),'history=','selected=0',
    'noteMode=0','submitted=0'
  },'\n'))
  Store.write(ctx.storage,'sudoku.txt','version=1\nlevel=1\nunlocked='..s.unlocked)
  on_load(ctx);s=A.state()
  eq(s.generation,1,'legacy seed keeps its original version')
  eq(table.concat(s.board),table.concat(classic.given),'legacy puzzle remains unchanged')
  assert(s.autoClean and s.highlight and s.showConflicts,'legacy preferences default ON')
end

-- HTML-port regressions: keypad order, toggle, reveal and persistent mistakes.
do
  for n=1,9 do
    local x,y,w,h=A.digit_box(n)
    eq(x,8+(n-1)%3*118,'HTML number-pad column')
    eq(y,510+math.floor((9-n)/3)*96,'HTML number-pad row')
    assert(w>=48 and h>=48)
  end
  A.reset();s=A.state()
  local blank
  for i=1,81 do if A.puzzle().given[i]==0 then blank=i;break end end
  select(blank)
  assert(A.put(2));eq(s.board[blank],2)
  assert(A.put(2));eq(s.board[blank],0,'same digit toggles off like HTML')
  assert(A.put(3))
  assert(tap_control('menu'))
  assert(A.tap(352,360),'reveal selected menu command')
  eq(s.board[blank],A.puzzle().solution[blank],'reveal places correct digit')
  assert(A.undo(),'reveal is undoable')
  eq(s.board[blank],3)
  assert(tap_control('menu'))
  assert(A.tap(352,573),'show mistakes toggle')
  assert(s.showMistakes,'mistakes assist enabled')
  s=reload();assert(s.showMistakes,'mistakes assist saved')
  assert(A.check(),'CHECK still requires explicit submission')
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
