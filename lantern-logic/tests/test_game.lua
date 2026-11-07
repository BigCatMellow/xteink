-- Lantern Logic v0.1 on-host test suite. Fixtures are independent solver solutions.
_G.__TEST={}
dofile('app/index.lua')
local A=__TEST.api
local SOLUTIONS={
  {1,7,15,18,21},
  {2,10,14,18,21},
  {4,8,11,15,17,19},
  {5,6,12,14,20,21},
  {2,6,15,17,19,23},
  {4,9,13,18,23,25,34},
  {1,4,8,15,23,28,30,32,35},
  {1,6,17,22,30,33},
  {2,10,17,20,24,25,27,35},
  {5,7,14,16,21,25,36},
  {2,5,10,12,13,17,21,30,31},
  {1,5,11,20,23,35,43,49},
  {6,9,14,18,22,27,33,38,43,49},
  {5,10,15,18,28,33,37,43,45,48},
  {3,7,13,23,29,35,39,44,47},
  {6,9,15,21,24,27,33,39,44},
}
local function eq(a,b,description)
  assert(a==b,(description or 'mismatch')..': '..tostring(a)..' != '..tostring(b))
end
local store={}
local redraws=0
local font={measure=function(_,s) return #s*10 end}
local ctx={
  storage={
    read=function(_,name) return store[name] end,
    write=function(_,name,data) store[name]=data end
  },
  clock={millis=function() return 10000 end},
  fonts={small=font,medium=font,large=font},
  invalidate=function() redraws=redraws+1 end
}
on_load(ctx)
eq(A.state().level,1)
eq(A.state().unlocked,1)
assert(store['lantern-logic.txt']:find('version=1',1,true))
eq(#SOLUTIONS,16)
eq(#A.levels,16)
assert(not A.complete(A.state().b,A.state().marks))
assert(not A.next(),'cannot skip first puzzle')

-- Each tile cycles bulb -> cross -> clear, with undo and no animation.
local s=A.state()
local b=s.b
local first=SOLUTIONS[1][1]+1
local x=(first-1)%b.n+1
local y=math.floor((first-1)/b.n)+1
assert(A.choose(x,y))
eq(s.marks[first],1)
assert(A.choose(x,y))
eq(s.marks[first],2)
assert(A.choose(x,y))
eq(s.marks[first],0)
assert(A.undo())
eq(s.marks[first],2)
assert(A.undo())
eq(s.marks[first],1)
assert(A.reset())
eq(A.state().marks[first],0)

-- Validate every authored level end-to-end, including exact clue counts,
-- complete illumination, no bulb interactions, saving, and navigation.
for level=1,16 do
  A.start(level,level)
  local state=A.state()
  eq(state.level,level)
  local n=state.b.n
  eq(n,level<=5 and 5 or level<=11 and 6 or 7)
  local seen={}
  for _,p in ipairs(SOLUTIONS[level]) do
    local i=p+1
    assert(not seen[i],'duplicate bulb coordinate')
    seen[i]=true
    eq(state.b.tiles[i],'.','bulb must be on white tile')
    local px=(i-1)%n+1
    local py=math.floor((i-1)/n)+1
    assert(A.choose(px,py),'bulb placement succeeds')
  end
  local dark,conflicts,bad,clues=A.inspect(state.b,state.marks)
  eq(dark,0,'every white cell lit')
  eq(conflicts,0,'bulbs cannot see each other')
  eq(bad,0,'numbered wall clues exact')
  assert(clues>=2)
  assert(A.complete(state.b,state.marks),'puzzle valid')
  eq(state.unlocked,math.min(16,level+1))
  on_leave();on_load(ctx)
  assert(A.complete(A.state().b,A.state().marks),'save survives reload')
  if level<16 then assert(A.next()) else assert(not A.next()) end
end

-- Invalid wall/number taps cannot change board.
A.start(1,16)
local state=A.state()
local n=state.b.n
local wall_i
for i,ch in ipairs(state.b.tiles) do
  if ch~='.' then wall_i=i;break end
end
assert(wall_i)
local ax=(wall_i-1)%n+1
local ay=math.floor((wall_i-1)/n)+1
assert(not A.choose(ax,ay))
eq(state.marks[wall_i],0)

-- A conflicting pair is not a victory and has an explicit conflict count.
A.start(1,16)
state=A.state()
local a,b=nil,nil
for i,ch in ipairs(state.b.tiles) do
  if ch=='.' then
    local x1=(i-1)%state.b.n+1
    local y1=math.floor((i-1)/state.b.n)+1
    for j=i+1,#state.b.tiles do
      if state.b.tiles[j]=='.' then
        local x2=(j-1)%state.b.n+1
        local y2=math.floor((j-1)/state.b.n)+1
        if x1==x2 or y1==y2 then
          local clear=true
          if y1==y2 then
            for xx=math.min(x1,x2)+1,math.max(x1,x2)-1 do
              if state.b.tiles[(y1-1)*state.b.n+xx]~='.' then clear=false end
            end
          else
            for yy=math.min(y1,y2)+1,math.max(y1,y2)-1 do
              if state.b.tiles[(yy-1)*state.b.n+x1]~='.' then clear=false end
            end
          end
          if clear then a=i;b=j;break end
        end
      end
    end
    if a then break end
  end
end
assert(a and b)
local function touchindex(i)
  assert(A.choose((i-1)%state.b.n+1,math.floor((i-1)/state.b.n)+1))
end
touchindex(a)
touchindex(b)
local _,conflicts=A.inspect(state.b,state.marks)
assert(conflicts>0,'visibility conflict counted')
assert(not A.complete(state.b,state.marks))

-- Simulated pointer presses: single redraw only on pointer-up event.
A.start(2,16)
state=A.state()
local bx,by,cell=A.position(state.b.n)
local i=SOLUTIONS[2][1]+1
local x=(i-1)%state.b.n+1
local y=math.floor((i-1)/state.b.n)+1
local tx,ty=bx+(x-0.5)*cell,by+(y-0.5)*cell
local before=redraws
on_input(ctx,{type='pointer',phase='down',gesture='tap',x=tx,y=ty})
eq(redraws,before)
on_input(ctx,{type='pointer',phase='up',gesture='tap',x=tx,y=ty})
eq(redraws,before+1)
on_input(ctx,{type='pointer',phase='up',gesture='swipe',x=tx,y=ty})
eq(redraws,before+1)

-- Monochrome static rendering with bounded commands.
local g={}
local commands,counts=0,{}
for _,method in ipairs({'clear','rect','line','circle','text'}) do
  g[method]=function(_, ...)
    commands=commands+1
    counts[method]=(counts[method] or 0)+1
    local args={...}
    if type(args[#args])=='table' then
      assert(args[#args].opacity==nil and args[#args].color==nil,'no gray animation')
    end
  end
end
for level=1,16 do
  A.start(level,16)
  commands,counts=0,{}
  on_draw(ctx,g)
  assert(commands>=35 and commands<=300,'rendering command budget: '..commands)
  eq(counts.clear,1,'static full-frame draw')
end
assert(type(on_tick)=='nil','no background redraw loop')

-- Corrupt save file resets safely.
store['lantern-logic.txt']='version=1\nlevel=1000\nunlocked=5000\n'
on_load(ctx)
eq(A.state().level,1)
print('Lantern Logic: 16 unique boards, bulbs, clues, undo, save, rendering PASS')
