package.path='app/?.lua;../../tests/?.lua;'..package.path
local measured=require('game_canvas').check
_G.__TEST={}
dofile('app/index.lua')
local A=__TEST.api
local function eq(a,b,m) assert(a==b,(m or 'mismatch')..' '..tostring(a)..' vs '..tostring(b)) end
local store={}
local font={line_height=24,measure=function(_,s) return #s*11 end}
local ctx={storage={read=function(_,k) return store[k] end,write=function(_,k,v) store[k]=v end},
  fonts={small=font,medium=font,large=font},clock={millis=function() return 4242 end},
  invalidate=function() end}
local function apply(board,presses,cols,rows)
  for i=1,#presses do if presses[i]==1 then A.press(board,i,cols,rows) end end
  for i=1,#board do if board[i]~=0 then return false end end
  return true
end

-- Solver: the all-on 5x5 board needs exactly 15 presses (known result), and
-- every returned solution really clears its board.
do
  local b={};for i=1,25 do b[i]=1 end
  local s=assert(A.solve(b,5,5));eq(s.count,15,'all-on 5x5 minimum')
  assert(apply(b,s.presses,5,5),'all-on 5x5 solution clears the board')
end
-- Independent check on 5x5: an unreachable single light (5x5 has a 2-dim null space).
do
  local b={};for i=1,25 do b[i]=0 end;b[1]=1
  eq(A.solve(b,5,5),nil,'a lone corner light on 5x5 has no solution')
end
-- Minimality against brute force on the 3x3 board (every press subset).
do
  local best={}
  for mask=0,511 do
    local b={};for i=1,9 do b[i]=0 end
    local count=0
    for i=1,9 do if math.floor(mask/2^(i-1))%2==1 then A.press(b,i,3,3);count=count+1 end end
    local k=table.concat(b)
    if not best[k] or count<best[k] then best[k]=count end
  end
  local n=0
  for k,count in pairs(best) do
    local b={};for i=1,9 do b[i]=k:byte(i)-48 end
    local s=assert(A.solve(b,3,3));eq(s.count,count,'3x3 minimum for '..k)
    local c={};for i=1,9 do c[i]=b[i] end
    assert(apply(c,s.presses,3,3));n=n+1
  end
  eq(n,512,'3x3: every reachable pattern checked')
end
-- Generated boards: solvable, par at least 4, par equals the solver's minimum.
for _,sz in ipairs(A.sizes) do
  for _=1,4 do
    local b,par=A.generate(sz.cols,sz.rows)
    eq(#b,sz.cols*sz.rows)
    assert(par>=4,'par at least 4')
    local s=assert(A.solve(b,sz.cols,sz.rows));eq(s.count,par)
    assert(apply(b,s.presses,sz.cols,sz.rows),sz.label..' solution clears the board')
  end
end

on_load(ctx)
local S=A.state()
eq(S.size,1);eq(S.moves,0);assert(store['lights-out.txt'],'a new game is saved at once')
measured(ctx,on_draw,'lights out classic')
-- Taps: the touched tile and its orthogonal neighbours flip; gaps do nothing.
local x0,y0,t=A.geometry()
assert(t>=80,'classic tiles are large: '..t)
local before={};for i=1,25 do before[i]=S.board[i] end
assert(A.tap(x0+2*(t+3)+t/2,y0+2*(t+3)+t/2))
for i=1,25 do
  local flipped=(i==13 or i==8 or i==18 or i==12 or i==14)
  eq(S.board[i],flipped and 1-before[i] or before[i],'press shape at '..i)
end
eq(S.moves,1)
assert(not A.tap(x0+t+1,y0+t/2),'the 3px gap between tiles is not a tile')
eq(S.moves,1)
-- Undo restores board and counter.
local b=A.bar.undo
assert(A.tap(b[1]+b[3]/2,b[2]+b[4]/2));eq(S.moves,0)
for i=1,25 do eq(S.board[i],before[i]) end
assert(not A.undo(),'nothing left to undo')
-- Hint marks the first press of a minimal solution, and following hints wins.
local guard=0
while not S.won do
  assert(A.hint());local h=A.hinted();assert(h>0,'hint found')
  measured(ctx,on_draw,'lights out hint')
  assert(A.tap_tile(h));guard=guard+1;assert(guard<=25)
end
eq(S.moves,S.par,'following hints reaches par')
measured(ctx,on_draw,'lights out solved')
assert(not A.tap_tile(1),'a solved board is read-only')
-- Solved: the Undo slot becomes Next, which starts another board of this size.
local first=table.concat(S.initial)
assert(A.tap(b[1]+b[3]/2,b[2]+b[4]/2));S=A.state()
eq(S.won,false);eq(S.moves,0);eq(S.size,1)
-- Menu: sizes, restart, solution rings, persistence.
local m=A.bar.menu
assert(A.tap(m[1]+m[3]/2,m[2]+m[4]/2));measured(ctx,on_draw,'lights out menu')
local box=A.menu.solution
assert(A.tap(box[1]+box[3]/2,box[2]+box[4]/2));assert(A.state().show)
for i,sz in ipairs(A.sizes) do
  assert(A.open_menu())
  local s=A.menu['size'..i]
  assert(A.tap(s[1]+s[3]/2,s[2]+s[4]/2));S=A.state()
  eq(S.size,i);eq(#S.board,sz.cols*sz.rows)
  local _,_,tile=A.geometry()
  assert(tile>=60,sz.label..' tiles stay touchable: '..tile)
  measured(ctx,on_draw,'lights out '..sz.label..' with solution rings')
end
assert(S.show,'show solution persists across new games')
A.tap_tile(1);A.tap_tile(2)
local board,moves=table.concat(S.board),S.moves
on_leave();on_load(ctx);S=A.state()
eq(table.concat(S.board),board,'board survives relaunch');eq(S.moves,moves);eq(S.size,4)
assert(A.undo() and A.undo(),'undo history survives relaunch');eq(S.moves,0)
assert(A.open_menu());local r=A.menu.restart
A.tap_tile(5);assert(A.open_menu());assert(A.tap(r[1]+r[3]/2,r[2]+r[4]/2));eq(S.moves,0)
-- Damaged saves start a fresh game instead of failing.
store['lights-out.txt']='version=1\nsize=classic\ninitial=0101\nboard=01\nmoves=x'
on_load(ctx);S=A.state();eq(S.size,1);eq(S.moves,0)
assert(A.solve(S.initial,5,5).count>=4)
on_leave()
print('Lights Out: solver, generator, taps, undo, hints, menu sizes, saves and layout PASS')
