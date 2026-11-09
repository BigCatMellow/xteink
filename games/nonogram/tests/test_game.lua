-- Nonogram: 12 unique pixel pictures, undo, CHECK, saved stages, touch & layout.
package.path='app/?.lua;../../tests/?.lua;'..package.path
local measured=require('game_canvas').check
_G.__TEST={}
dofile('app/index.lua')
local A=__TEST.api
local function eq(a,b,msg)
  assert(a==b,(msg or 'mismatch')..': '..tostring(a)..' vs '..tostring(b))
end
local store={}
local redraws=0
local font={line_height=24,measure=function(_,s) return #s*11 end}
local ctx={
  storage={
    read=function(_,name) return store[name] end,
    write=function(_,name,val) store[name]=val end
  },
  fonts={small=font,medium=font,large=font},
  clock={millis=function() return 10000 end},
  invalidate=function() redraws=redraws+1 end
}
on_load(ctx)
local s=A.state()
eq(s.level,1);eq(s.unlocked,1)
eq(#A.pictures,12)
assert(store['nonogram.txt']:find('version=2',1,true))
assert(not A.next(),'cannot skip unopened puzzle')
assert(not A.correct(1,s.boards[1]))
assert(not s.submitted[1])

-- Every authored picture has consistent row and column clue sums.
for level=1,12 do
  local p=A.shape(level)
  eq(p.n,level<=4 and 5 or level<=8 and 7 or 8)
  local black=0
  for y=1,p.n do
    for x=1,p.n do
      if p.rows[y]:sub(x,x)=='#' then black=black+1 end
    end
  end
  local rowBlack=0
  for _,clues in ipairs(p.rowClues) do
    for _,count in ipairs(clues) do rowBlack=rowBlack+count end
    assert(#clues<=3,'row clues fit')
  end
  local colBlack=0
  for _,clues in ipairs(p.colClues) do
    for _,count in ipairs(clues) do colBlack=colBlack+count end
    assert(#clues<=3,'column clues fit')
  end
  eq(rowBlack,black,'row totals correct')
  eq(colBlack,black,'column totals correct')
end

-- The board owns the screen: enforce usable cell sizes and a shared right edge.
for _,level in ipairs({1,5,9}) do
  s.unlocked=math.max(s.unlocked,level)
  assert(A.visit(level));A.reset()
  local bx,by,cell,gutter,clueArea=A.geometry()
  local n=A.shape(level).n
  assert(cell>=44,'touch cells must not return to the cramped 39px layout')
  assert(n*cell>=336,'the puzzle must receive meaningful screen area')
  assert(math.abs(((bx-gutter)+(bx+n*cell))/2-240)<=.5,'clues and board centered horizontally')
  assert(math.abs(((by-clueArea)+(by+n*cell))/2-356)<=.5,'clues and board centered vertically')
  assert(by+n*cell<=584,'board leaves room for feedback and controls')
  assert(not A.tap(bx-1,by+cell/2),'clue gutter must not paint a square')
  assert(A.tap(bx+1,by+1));eq(s.boards[level][1],1,'top-left touch matches drawn cell')
  assert(A.tap(bx+n*cell-1,by+n*cell-1));eq(s.boards[level][n*n],1,'bottom-right touch matches drawn cell')
  local undo=A.controls.undo
  assert(A.tap(undo[1]+1,undo[2]+undo[4]/2),'full rounded control remains a touch target')
  eq(s.boards[level][n*n],0)
end
-- Restore the fresh initial progression used by the behavioral scenarios below.
store={};on_load(ctx);s=A.state()

-- Touch cycles blank -> black -> X -> blank; undo has true snapshots.
local board=s.boards[1]
assert(A.paint(1,1));eq(s.boards[1][1],1)
assert(A.paint(1,1));eq(s.boards[1][1],2)
assert(A.paint(1,1));eq(s.boards[1][1],0)
assert(A.undo());eq(s.boards[1][1],2,'undo last mark')
assert(A.undo());eq(s.boards[1][1],1)
assert(A.undo());eq(s.boards[1][1],0)
assert(not A.undo())
assert(A.paint(1,1))
assert(A.check(),'incorrect board can be submitted but not completed')
eq(s.unlocked,1);assert(not s.submitted[1])
measured(ctx,on_draw,'nonogram unsolved first')
assert(A.reset())
eq(s.boards[1][1],0)

-- Complete a board but close BEFORE CHECK: preserve unsubmitted correctness.
local function fill_pattern(level)
  local p=A.shape(level)
  for y=1,p.n do
    for x=1,p.n do
      if p.rows[y]:sub(x,x)=='#' then
        assert(A.paint(x,y))
      end
    end
  end
end
fill_pattern(1)
assert(A.correct(1,s.boards[1]))
assert(not s.submitted[1])
eq(s.unlocked,1)
on_leave();on_load(ctx);s=A.state()
eq(s.level,1)
assert(A.correct(1,s.boards[1]))
assert(not s.submitted[1])
assert(A.check())
assert(s.submitted[1])
eq(s.unlocked,2)
assert(not A.paint(1,1),'submitted board is read-only')
measured(ctx,on_draw,'nonogram submitted first')
local primary=A.controls.check
assert(A.tap(primary[1]+primary[3]/2,primary[2]+primary[4]/2),'solved primary action opens the next puzzle')
eq(s.level,2)

-- Solve all twelve with real tap API, save before and after submission.
for level=2,12 do
  eq(s.level,level)
  measured(ctx,on_draw,'nonogram fresh '..level)
  fill_pattern(level)
  assert(A.correct(level,s.boards[level]),'fully filled image matches answer')
  local rows,cols=A.counters()
  eq(rows,#A.shape(level).rows,'all row runs satisfied')
  eq(cols,#A.shape(level).rows,'all column runs satisfied')
  assert(not s.submitted[level],'correct unsubmitted board')
  on_leave();on_load(ctx);s=A.state()
  eq(s.level,level,'unsubmitted puzzle remains active')
  assert(A.correct(level,s.boards[level]),'correct unsent board retained')
  assert(not s.submitted[level])
  assert(A.check())
  assert(s.submitted[level])
  eq(s.unlocked,level+1)
  measured(ctx,on_draw,'nonogram submitted '..level)
  on_leave();on_load(ctx);s=A.state()
  assert(s.submitted[level],'submission persisted')
  if level<12 then assert(A.next()) end
end
assert(A.next(),'generated puzzles follow the authored pictures')
eq(s.level,13);assert(A.prev())

-- Revisit earlier stages; reset does not discard global unlocks.
assert(A.visit(5))
assert(A.reset())
assert(not s.submitted[5])
assert(A.paint(1,1))
assert(A.paint(2,1))
local beforeMarks=s.boards[5][1]..s.boards[5][2]
assert(A.prev())
on_leave();on_load(ctx);s=A.state()
assert(A.next())
eq(s.level,5)
eq(s.boards[5][1]..s.boards[5][2],beforeMarks,'in-progress board survives visit')
assert(A.undo(),'undo history preserved across visits')
eq(s.boards[5][2],0)
eq(s.unlocked,13,'global unlock unaffected by local reset')
assert(A.visit(9))
assert(s.submitted[9],'other completed puzzle still submitted')

-- Pointer release only; no animation or redraw on swipe.
assert(A.visit(3))
assert(A.reset())
local x0,y0,cell=A.geometry()
local px,py=x0+cell*.5,y0+cell*.5
local before=redraws
on_input(ctx,{type='pointer',phase='down',gesture='tap',x=px,y=py})
eq(redraws,before)
on_input(ctx,{type='pointer',phase='up',gesture='swipe',x=px,y=py})
eq(redraws,before)
on_input(ctx,{type='pointer',phase='up',gesture='tap',x=px,y=py})
eq(redraws,before+1)
eq(s.boards[3][1],1)
on_input(ctx,{type='pointer',phase='up',gesture='tap',x=3,y=3})
eq(redraws,before+1)

-- Every layout and all help views at normal and enlarged variable-width fonts.
for level=1,12 do
  assert(A.visit(level))
  A.reset()
  measured(ctx,on_draw,'nonogram blank '..level)
  A.paint(1,1)
  measured(ctx,on_draw,'nonogram partial '..level)
  A.reset()
  fill_pattern(level)
  measured(ctx,on_draw,'nonogram correct but unsubmitted '..level)
  A.check()
  measured(ctx,on_draw,'nonogram revealed '..level)
end
A.tap(443,34)
measured(ctx,on_draw,'nonogram help')
local opened=s.level
local nextButton=A.controls.next
assert(not A.tap(nextButton[1]+nextButton[3]/2,nextButton[2]+nextButton[4]/2),'help must block navigation hitboxes')
eq(s.level,opened)
A.tap(443,34)
-- Upgrade a v1 save without losing submitted pictures or undo snapshots.
assert(A.visit(5));A.reset();A.paint(1,1);A.paint(2,1)
local legacy=store['nonogram.txt']:gsub('version=2','version=1'):gsub('unlocked=%d+','unlocked=12')
store['nonogram.txt']=legacy
on_load(ctx);s=A.state()
eq(s.level,5);eq(s.unlocked,13);assert(A.undo());eq(s.boards[5][2],0)
assert(A.visit(13))
for number=13,24 do
  local p=A.shape(number)
  local signature=table.concat(p.rows)
  measured(ctx,on_draw,'generated nonogram blank '..number)
  assert(A.paint(1,1));assert(A.paint(2,1))
  assert(A.prev());on_leave();on_load(ctx);s=A.state();assert(A.next())
  eq(s.boards[number][1],1);eq(s.boards[number][2],1)
  assert(A.undo(),'generated undo survives navigation and relaunch')
  eq(s.boards[number][2],0)
  A.reset();fill_pattern(number)
  on_leave();on_load(ctx);s=A.state()
  eq(table.concat(A.shape(number).rows),signature,'generated picture stable across reload')
  assert(A.correct(number,s.boards[number]),'correct unsubmitted generated board retained')
  assert(not s.submitted[number]);measured(ctx,on_draw,'generated unsubmitted '..number)
  assert(A.check());assert(s.submitted[number]);eq(s.unlocked,number+1)
  measured(ctx,on_draw,'generated nonogram solved '..number)
  assert(A.next())
end
local entries=0
for _ in pairs(s.boards) do entries=entries+1 end
eq(entries,13,'only one generated board is resident')
s.unlocked=999999999
assert(A.visit(999999999))
measured(ctx,on_draw,'nonogram maximum puzzle number')
A.reset();fill_pattern(999999999);A.check()
measured(ctx,on_draw,'nonogram maximum solved number')
local working_write=ctx.storage.write
ctx.storage.write=function() return nil,'quota' end
assert(A.prev());eq(s.level,999999999,'failed save prevents leaving generated puzzle')
measured(ctx,on_draw,'nonogram save failure')
ctx.storage.write=working_write
assert(A.visit(1))
before=redraws
assert(not on_input(ctx,{type='key',phase='down',key='up',time_ms=20000}))
eq(s.level,1,'PREV at first puzzle must not fall through to NEXT')
eq(redraws,before)
store['nonogram.txt']='version=1\nlevel=500\nunlocked=800\n'
on_load(ctx)
eq(A.state().level,1,'malformed saves reset')
assert(type(on_tick)=='nil','no background animation')
print('Nonogram: authored + generated puzzles, legacy saves, undo, unsubmitted answers and layout PASS')
