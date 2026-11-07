-- Summit Putt's offline tests: solver, one-use cards, ramps, undo, save, and render.
_G.__TEST={}
dofile('app/index.lua')
local A=__TEST.api
local function eq(a,b,desc)
  assert(a==b,(desc or 'mismatch')..': '..tostring(a)..' != '..tostring(b))
end

local store={}
local font={measure=function(_,s) return #s*11 end}
local ctx={
  storage={
    read=function(_,name) return store[name] end,
    write=function(_,name,value) store[name]=value end
  },
  clock={millis=function() return 20000 end},
  fonts={small=font,medium=font,large=font},
  invalidate=function() end,
}
on_load(ctx)
eq(A.state().level,1,'new game starts at one')
eq(A.state().stage,'play')
assert(store['summit.txt']:find('version=1',1,true))

local DELTA={{0,-1},{1,0},{0,1},{-1,0}}
local function independent_step(b,x,y,dist,d)
  if b.tiles[(y-1)*7+x]=='s' and dist~=1 then return nil end
  local cx,cy=x,y
  for k=1,dist do
    local nx,ny=cx+DELTA[d][1],cy+DELTA[d][2]
    if nx<1 or nx>7 or ny<1 or ny>7 then return nil end
    local a=b.tiles[(cy-1)*7+cx]
    local z=b.tiles[(ny-1)*7+nx]
    if z=='#' or z=='~' then return nil end
    local hi=function(ch)
      return ch=='H' or ch=='^' or ch=='>' or ch=='v' or ch=='<' or ch=='A' or ch=='G'
    end
    if hi(z) and not hi(a) and z~=('^>v<'):sub(d,d) then return nil end
    if nx==b.gx and ny==b.gy and k<dist then return nil end
    cx,cy=nx,ny
  end
  return cx,cy
end
local function solved_path(b)
  local hand=b.hand
  local q={{x=b.sx,y=b.sy,mask=0,path={}}}
  local seen={[b.sx..':'..b.sy..':0']=true}
  for _,s in ipairs(q) do
    if s.x==b.gx and s.y==b.gy then return s.path end
    for i,dist in ipairs(hand) do
      if not A.used(s.mask,i) then
        for d=1,4 do
          local nx,ny=independent_step(b,s.x,s.y,dist,d)
          if nx then
            local mask=s.mask+2^(i-1)
            local key=nx..':'..ny..':'..mask
            if not seen[key] then
              seen[key]=true
              local path={}
              for _,move in ipairs(s.path) do path[#path+1]=move end
              path[#path+1]={i=i,dir=d,x=nx,y=ny}
              q[#q+1]={x=nx,y=ny,mask=mask,path=path}
            end
          end
        end
      end
    end
  end
  return nil
end

-- Every puzzle requires planning and is provably winnable by a real legal sequence.
local solution_paths={}
for level=1,#A.levels do
  local b=A.parse(level)
  local path=solved_path(b)
  assert(path,'unsolvable stage '..level)
  eq(#path,#b.hand,'no premature/trivial solutions on level '..level)
  local turns=0
  for j,step in ipairs(path) do
    if j>1 and path[j-1].dir~=step.dir then turns=turns+1 end
  end
  assert(turns>=1,'at least one direction change at level '..level)
  local x,y=b.sx,b.sy
  for _,move in ipairs(path) do
    eq(A.dest(b,x,y,b.hand[move.i],move.dir),move.x,'movement x matches')
    local ox,oy=A.dest(b,x,y,b.hand[move.i],move.dir)
    eq(oy,move.y,'movement y matches')
    x,y=ox,oy
  end
  solution_paths[level]=path
end

-- Height requires an actual ramp entered from the intended direction.
local b=A.parse(9)
-- At (5,4) stepping north enters the ramp at (5,3).
eq(b.tiles[(3-1)*7+5],'^')
local nx,ny=A.dest(b,5,4,1,1)
eq(nx,5);eq(ny,3)
-- On a test board where (4,3) is low, approaching an UP ramp from the west is forbidden.
local altered=A.parse(9)
altered.tiles[(3-1)*7+4]='.'
assert(A.dest(altered,4,3,1,2)==nil,'wrong direction cannot climb')
-- A high plateau is traversable without another ramp.
nx,ny=A.dest(b,5,3,2,4);eq(nx,3);eq(ny,3)

-- Blocked shot must not consume a card or alter position.
A.start(1,1)
local st=A.state()
local ox,oy,mask=st.x,st.y,st.mask
local blocked_dir=nil
for d=1,4 do
  if not A.dest(A.board(),ox,oy,A.board().hand[st.selected],d) then
    blocked_dir=d;break
  end
end
assert(blocked_dir,'first level needs a blocked direction')
assert(not A.advance(blocked_dir))
eq(st.x,ox);eq(st.y,oy);eq(st.mask,mask)

-- Undo restores a consumed card and the ball position.
local first=solution_paths[1][1]
assert(A.choose(first.i))
assert(A.advance(first.dir))
assert(st.mask~=0)
assert(A.undo())
eq(st.mask,0);eq(st.x,ox);eq(st.y,oy)
assert(not A.undo(),'undo empty history safely')

-- Win each authored stage, advance only when won, persist and restore.
A.start(1,1)
for level,path in ipairs(solution_paths) do
  eq(A.state().level,level)
  for _,move in ipairs(path) do
    assert(A.choose(move.i),'choose unused card')
    assert(A.advance(move.dir),'valid shot')
    eq(A.state().x,move.x)
    eq(A.state().y,move.y)
  end
  eq(A.state().stage,'won')
  local old_unlock=A.state().unlocked
  on_leave()
  on_load(ctx)
  assert(A.state().stage=='won','saved solved state: level '..level..' state '..A.state().stage..' file '..tostring(store['summit.txt']))
  eq(A.state().unlocked,old_unlock,'saved unlock progress')
  if level<#solution_paths then assert(A.next()) end
end
eq(A.state().unlocked,10,'all stages unlocked')
assert(A.next(),'replay after tenth level')
eq(A.state().level,1)
eq(A.state().unlocked,10,'unlock persisted')
eq(A.state().mask,0)

-- At least one wrong-order trajectory should end without reaching the hole.
local found_stuck=false
for level=1,8 do
  local board=A.parse(level)
  local hand=board.hand
  local queue={{x=board.sx,y=board.sy,mask=0}}
  local seen={[board.sx..':'..board.sy..':0']=true}
  for _,s in ipairs(queue) do
    if s.mask==2^#hand-1 and not(s.x==board.gx and s.y==board.gy) then
      found_stuck=true;break
    end
    for i,v in ipairs(hand) do
      if not A.used(s.mask,i) then
        for d=1,4 do
          local x,y=independent_step(board,s.x,s.y,v,d)
          if x then
            local mask=s.mask+2^(i-1)
            local key=x..':'..y..':'..mask
            if not seen[key] then
              seen[key]=true;queue[#queue+1]={x=x,y=y,mask=mask}
            end
          end
        end
      end
    end
  end
  if found_stuck then break end
end
assert(found_stuck,'puzzles must allow a wrong solution to fail')

-- Key input cycles card selection, while invalid touch does not spend cards.
A.start(2,10)
on_input(ctx,{type='key',phase='down',key='down',time_ms=30000})
eq(A.state().selected,2)
on_input(ctx,{type='key',phase='down',key='up',time_ms=30300})
eq(A.state().selected,1)
local oldmask=A.state().mask
on_input(ctx,{type='pointer',phase='up',gesture='tap',x=4,y=4})
eq(A.state().mask,oldmask)

-- Fake rendering asserts a dense but bounded, monochrome 480x800 UI.
local calls=0
local gfx={}
for _,m in ipairs({'clear','line','rect','circle','text'}) do
  gfx[m]=function(_, ...)
    calls=calls+1
    local args={...}
    if type(args[#args])=='table' then
      assert(args[#args].color==nil,'no color-dependent drawing')
    end
  end
end
for level=1,10 do
  A.start(level,10)
  calls=0
  on_draw(ctx,gfx)
  assert(calls>50 and calls<600,'unexpected command count '..calls)
end

-- Malformed saves should reset rather than error.
store['summit.txt']='version=1\nlevel=999\n'
on_load(ctx)
eq(A.state().level,1,'corrupt save replaced')
print('Summit Putt: all 10 levels solved, card constraints, elevation, undo, persistence and drawing PASS')
