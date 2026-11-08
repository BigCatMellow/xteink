-- LINE LIFT: original static crossing-logic game for XTEINK X4 Pro Licorice.
-- Draws strictly black on white. No animation, timers, transitions or network.
-- A continuous rod passes over a rod interrupted by a small crossing gap.
-- Tap a circular pull point; if another rod lies above it, the puzzle resets.
local W,H=480,800
local UI=require('ui')
local Theme=require('theme')
local GX,GY,STEP=45,151,39
local MAX=12
local CTX,STATE,LEVEL,ERROR,MESSAGE
local tutorial=false
local show_hint=false
local last_key_ms=-1000

-- Rod: orientation, fixed coordinate, start, end, pull end, group, layer.
-- Coordinates are integers in the 0..10 lattice. Original authored puzzles.
-- Paired rods (same group name) are released together starting at level 11.
local LEVELS={
  {name='FIRST CROSSING',rods={
    {'h',5,0,10,'l','A',1},
    {'v',5,0,10,'t','B',2}
  }},
  {name='TWO ABOVE',rods={
    {'h',3,0,10,'l','A',3},
    {'h',7,0,10,'r','B',1},
    {'v',5,0,10,'b','C',2}
  }},
  {name='THE LADDER',rods={
    {'h',3,0,10,'l','A',2},
    {'h',7,0,10,'r','B',4},
    {'v',3,0,10,'t','C',1},
    {'v',7,0,10,'b','D',3}
  }},
  {name='HALF WAY',rods={
    {'h',2,0,6,'l','A',3},
    {'h',5,0,10,'r','B',1},
    {'h',8,4,10,'r','C',4},
    {'v',3,0,10,'t','D',5},
    {'v',7,0,10,'b','E',2}
  }},
  {name='CROSS PURPOSES',rods={
    {'h',2,0,10,'l','A',4},
    {'h',5,0,10,'r','B',1},
    {'h',8,0,10,'l','C',6},
    {'v',2,0,10,'b','D',2},
    {'v',5,0,10,'t','E',5},
    {'v',8,0,10,'b','F',3}
  }},
  {name='SHORT CUTS',rods={
    {'h',2,0,7,'l','A',2},
    {'h',5,3,10,'r','B',6},
    {'h',8,0,10,'l','C',4},
    {'v',2,0,6,'t','D',5},
    {'v',5,2,10,'b','E',1},
    {'v',8,4,10,'b','F',3}
  }},
  {name='NARROW ESCAPE',rods={
    {'h',1,0,10,'r','A',1},
    {'h',4,0,10,'l','B',6},
    {'h',7,0,7,'l','C',2},
    {'h',9,3,10,'r','D',4},
    {'v',2,0,10,'t','E',5},
    {'v',5,0,10,'b','F',7},
    {'v',8,0,10,'b','G',3}
  }},
  {name='THE WEAVE',rods={
    {'h',1,0,10,'l','A',5},
    {'h',3,0,9,'l','B',2},
    {'h',6,0,10,'r','C',8},
    {'h',9,1,10,'r','D',3},
    {'v',1,0,10,'t','E',1},
    {'v',4,0,10,'b','F',6},
    {'v',7,0,10,'t','G',4},
    {'v',9,0,10,'b','H',7}
  }},
  {name='CROWDED',rods={
    {'h',1,0,10,'l','A',8},
    {'h',3,0,10,'r','B',3},
    {'h',5,0,10,'l','C',6},
    {'h',7,0,10,'r','D',1},
    {'h',9,0,10,'l','E',9},
    {'v',2,0,10,'b','F',2},
    {'v',4,0,10,'t','G',7},
    {'v',6,0,10,'b','H',4},
    {'v',8,0,10,'t','I',5}
  }},
  {name='ALL CROSSED',rods={
    {'h',1,0,10,'r','A',5},
    {'h',3,0,10,'l','B',9},
    {'h',5,0,10,'r','C',1},
    {'h',7,0,10,'l','D',7},
    {'h',9,0,10,'r','E',3},
    {'v',1,0,10,'t','F',10},
    {'v',3,0,10,'b','G',4},
    {'v',5,0,10,'t','H',8},
    {'v',7,0,10,'b','I',2},
    {'v',9,0,10,'t','J',6}
  }},
  {name='PAIRED PULLS',rods={
    {'h',1,0,10,'l','A',3},
    {'h',9,0,10,'r','A',3},
    {'h',5,0,10,'r','B',6},
    {'v',1,0,10,'t','C',2},
    {'v',3,0,10,'b','D',5},
    {'v',7,0,10,'t','E',1},
    {'v',9,0,10,'b','F',4},
    {'h',3,0,10,'l','G',7}
  }},
  {name='DOUBLE KNOT',rods={
    {'h',1,0,10,'l','A',7},
    {'h',9,0,10,'r','A',7},
    {'v',1,0,10,'t','B',4},
    {'v',9,0,10,'b','B',4},
    {'h',3,0,10,'r','C',2},
    {'h',7,0,10,'l','C',2},
    {'h',5,0,10,'r','D',1},
    {'v',3,0,10,'t','E',6},
    {'v',7,0,10,'b','F',3},
    {'v',5,0,10,'b','G',5}
  }}
}

local function bit(n) return math.floor(2^(n-1)) end
local function is_set(mask,n) return math.floor(mask/bit(n))%2==1 end

local function interpret(n)
  local level=LEVELS[n]
  if not level then error('level out of range') end
  local groups,byName={},{}
  local rods={}
  for i,v in ipairs(level.rods) do
    local axis,a,lo,hi,side,label,depth=v[1],v[2],v[3],v[4],v[5],v[6],v[7]
    if axis~='h' and axis~='v' then error('invalid axis') end
    if lo<0 or hi>10 or lo>=hi or a<0 or a>10 then error('invalid rod') end
    if (axis=='h' and side~='l' and side~='r') or
       (axis=='v' and side~='t' and side~='b') then error('invalid pull side') end
    local gi=byName[label]
    if not gi then
      gi=#groups+1
      byName[label]=gi
      groups[gi]={name=label,depth=depth,rods={}}
    elseif groups[gi].depth~=depth then error('paired depth mismatch') end
    rods[i]={axis=axis,a=a,lo=lo,hi=hi,side=side,group=gi,depth=depth}
    groups[gi].rods[#groups[gi].rods+1]=i
  end
  return {name=level.name,rods=rods,groups=groups}
end

-- Only proper interior right-angle crossings are mechanical connections.
local function crossing(a,b)
  if a.axis==b.axis then return nil end
  local h=a.axis=='h' and a or b
  local v=a.axis=='v' and a or b
  if v.a>h.lo and v.a<h.hi and h.a>v.lo and h.a<v.hi then
    return v.a,h.a
  end
  return nil
end

local function active(group)
  return not is_set(STATE.mask,group)
end
local function blocked_by(group)
  if not active(group) then return nil end
  for _,id in ipairs(LEVEL.groups[group].rods) do
    local mine=LEVEL.rods[id]
    for _,other in ipairs(LEVEL.rods) do
      if other.group~=group and active(other.group) and
         other.depth>mine.depth and crossing(mine,other) then
        return other.group
      end
    end
  end
  return nil
end

local function all_cleared()
  for gi=1,#LEVEL.groups do
    if active(gi) then return false end
  end
  return true
end

local function write_save()
  if not CTX or not CTX.storage or not STATE then return end
  local s=table.concat({
    'version=1','level='..STATE.level,'unlocked='..STATE.unlocked,
    'mask='..math.floor(STATE.mask),'snags='..STATE.snags
  },'\n')
  pcall(function() CTX.storage:write('line-lift.txt',s) end)
  pcall(function() CTX.storage:write('line-lift-'..STATE.level..'.txt',s) end)
end

local function fresh_level(n,unlocked)
  LEVEL=interpret(n)
  STATE={level=n,unlocked=math.max(n,unlocked or n),mask=0,snags=0}
  MESSAGE='Trace the crossing gaps'
  tutorial=false;show_hint=false
  write_save()
end

local function restore(filename,expected)
  if not CTX or not CTX.storage then return false end
  local ok,data=pcall(function() return CTX.storage:read(filename or 'line-lift.txt') end)
  if not ok or type(data)~='string' then return false end
  local fields={}
  for k,v in data:gmatch('([%w_]+)=([^\n]*)') do fields[k]=v end
  if fields.version~='1' then return false end
  local function natural(s)
    local n=tonumber(s)
    if n and n==math.floor(n) then return n end
    return nil
  end
  local n,unlocked,mask,snags=natural(fields.level),natural(fields.unlocked),natural(fields.mask),natural(fields.snags)
  if not n or n<1 or n>MAX or not unlocked or unlocked<n or unlocked>MAX or
     not mask or mask<0 or not snags or snags<0 or snags>999999 then return false end
  if expected and n~=expected then return false end
  local lev=interpret(n)
  if mask>=bit(#lev.groups+1) then return false end
  LEVEL=lev
  STATE={level=n,unlocked=unlocked,mask=mask,snags=snags}
  MESSAGE=nil
  tutorial=false;show_hint=false
  return true
end

local function visit(n)
  local unlocked=STATE.unlocked
  write_save()
  if restore('line-lift-'..n..'.txt',n) then
    STATE.unlocked=math.max(unlocked,STATE.unlocked)
    write_save()
  else fresh_level(n,unlocked) end
  return true
end
local function pull(group)
  if not STATE or not group or not LEVEL.groups[group] or not active(group) or tutorial then return false end
  local above=blocked_by(group)
  if above then
    STATE.mask=0
    STATE.snags=STATE.snags+1
    MESSAGE='SNAG! All lines restored'
    write_save()
    return false
  end
  STATE.mask=STATE.mask+bit(group)
  MESSAGE=all_cleared() and 'CLEAR! All rods removed' or 'Clean pull. Find the next'
  if all_cleared() and STATE.level<MAX then
    STATE.unlocked=math.max(STATE.unlocked,STATE.level+1)
  end
  write_save()
  return true
end

local function next_level()
  if not STATE then return false end
  if STATE.level>=MAX or (not all_cleared() and STATE.level>=STATE.unlocked) then return false end
  visit(STATE.level+1)
  return true
end

local function previous_level()
  if STATE and STATE.level>1 then visit(STATE.level-1); return true end
  return false
end
local function reset()
  if STATE then fresh_level(STATE.level,STATE.unlocked); return true end
  return false
end
local function px(c) return GX+c*STEP end
local function py(r) return GY+r*STEP end
local function point(rod,pullend)
  local low=rod.lo
  local high=rod.hi
  local endCoordinate=(rod.side=='l' or rod.side=='t') and low or high
  local v=pullend and endCoordinate or
     ((rod.side=='l' or rod.side=='t') and high or low)
  if rod.axis=='h' then return px(v),py(rod.a) end
  return px(rod.a),py(v)
end

local function pull_point(rod) return point(rod,true) end
local function face(g,x,y,label,which)
  UI.text(g,CTX,x,y,label,which)
end
local function centered(g,x,y,label,which)
  UI.text(g,CTX,x,y,label,which,'center')
end
local function button(g,x,y,w,h,label)
  UI.button(g,CTX,x,y,w,h,label,false)
end

local function draw_rod(g,rod)
  local from=rod.lo*STEP
  local to=rod.hi*STEP
  local start=from+16
  local finish=to-1
  if rod.side=='r' or rod.side=='b' then
    start=from+1
    finish=to-16
  end
  local interruptions={}
  for _,other in ipairs(LEVEL.rods) do
    if other.group~=rod.group and active(other.group) and
       other.depth>rod.depth then
      local x,y=crossing(rod,other)
      if x then interruptions[#interruptions+1]=(rod.axis=='h' and x or y)*STEP end
    end
  end
  table.sort(interruptions)
  local cursor=start
  local function segment(a,b)
    if b<=a then return end
    if rod.axis=='h' then
      g:line(GX+a,py(rod.a),GX+b,py(rod.a),{line_width=3})
    else
      g:line(px(rod.a),GY+a,px(rod.a),GY+b,{line_width=3})
    end
  end
  for _,cross in ipairs(interruptions) do
    local left,right=math.max(start,cross-9),math.min(finish,cross+9)
    segment(cursor,left)
    cursor=math.max(cursor,right)
  end
  segment(cursor,finish)

  local tx,ty=point(rod,false)
  if rod.axis=='h' then
    local direction=rod.side=='l' and 1 or -1
    g:line(tx,ty,tx,ty-14,{line_width=2})
    g:line(tx,ty-14,tx-direction*8,ty-14,{line_width=2})
  else
    local direction=rod.side=='t' and 1 or -1
    g:line(tx,ty,tx+14,ty,{line_width=2})
    g:line(tx+14,ty,tx+14,ty-direction*8,{line_width=2})
  end
end

local function draw_pin(g,rod)
  local x,y=pull_point(rod)
  -- A machined pull knob: three crisp rings, alignment ticks, and a lettered
  -- centre. The double outer ring marks a paired mechanism.
  g:circle(x,y,19,{line_width=2})
  g:circle(x,y,14,{line_width=1})
  g:line(x-25,y-3,x-20,y-3,{line_width=2});g:line(x+20,y+3,x+25,y+3,{line_width=2})
  g:line(x,y-25,x,y-20,{line_width=2});g:line(x,y+20,x,y+25,{line_width=2})
  if #LEVEL.groups[rod.group].rods>1 then g:circle(x,y,24,{line_width=1}) end
  centered(g,x,y-8,LEVEL.groups[rod.group].name,'small')
end

local function draw_help(g)
  centered(g,240,178,'HOW TO PLAY','large')
  face(g,34,236,'Tap a lettered pull circle.','medium')
  face(g,34,285,'A continuous line is ABOVE','medium')
  face(g,34,319,'the interrupted line.','medium')
  face(g,34,382,'Remove the upper line first.','medium')
  face(g,34,441,'A blocked pull restores','medium')
  face(g,34,477,'the entire puzzle.','medium')
  face(g,34,540,'Double circles are paired:','medium')
  face(g,34,577,'both lines lift together.','medium')
  face(g,34,616,'HINT rings every safe pull.','small')
  button(g,96,691,288,67,'BACK TO PUZZLE')
end

local function draw(g)
  g:clear(0)
  face(g,30,14,'LINE LIFT','large')
  UI.text(g,CTX,31,49,'PRECISION PUZZLES','small',nil,245)
  button(g,294,16,72,45,show_hint and 'HIDE' or 'HINT')
  button(g,382,16,68,45,tutorial and 'X' or '?')
  local cleared=0
  for i=1,#LEVEL.groups do if not active(i) then cleared=cleared+1 end end
  UI.text(g,CTX,30,82,'Puzzle '..string.format('%02d',STATE.level)..' / '..string.format('%02d',MAX),'medium',nil,242)
  UI.text(g,CTX,294,82,cleared..'/'..#LEVEL.groups..' RELEASED','small',nil,156)
  g:line(30,110,450,110,{line_width=2})
  g:line(30,118,450,118,{line_width=1})
  if tutorial then draw_help(g); return end

  g:rect(28,136,424,422,{line_width=3})
  UI.region(18,126,444,442)

  for _,rod in ipairs(LEVEL.rods) do
    if active(rod.group) then draw_rod(g,rod) end
  end
  for _,rod in ipairs(LEVEL.rods) do
    if active(rod.group) then draw_pin(g,rod) end
  end
  if show_hint then
    for gi,group in ipairs(LEVEL.groups) do
      if active(gi) and not blocked_by(gi) then
        local rod=LEVEL.rods[group.rods[1]]
        local x,y=pull_point(rod)
        g:circle(x,y,25,{line_width=2})
      end
    end
  end

  if all_cleared() then
    centered(g,240,367,'ALL CLEAR','large')
    centered(g,240,414,STATE.level==MAX and 'ALL 12 LEVELS DONE' or 'NEXT PUZZLE READY','medium')
  end
  g:line(30,573,450,573,{line_width=1})
  centered(g,240,590,MESSAGE or 'Tap a circle to retract its line','medium')
  centered(g,240,628,'CONTINUOUS ABOVE GAP','small')
  centered(g,240,654,STATE.snags..' SNAGS','small')
  button(g,30,693,128,66,STATE.level>1 and 'PREV' or 'LEVEL 1')
  button(g,175,693,128,66,'RESTART')
  if (all_cleared() or STATE.level<STATE.unlocked) and STATE.level<MAX then
    button(g,320,693,130,66,'NEXT')
  elseif all_cleared() then
    button(g,320,693,130,66,'DONE')
  end
end

local function hit(x,y,a,b,w,h)
  return x>=a and x<a+w and y>=b and y<b+h
end
local function tap(x,y)
  if hit(x,y,294,16,72,45) and not tutorial then
    show_hint=not show_hint
    if show_hint then MESSAGE='HINT: safe pulls are ringed' else MESSAGE='Hint hidden' end
    return
  end
  if hit(x,y,382,16,68,45) then tutorial=not tutorial;return end
  if tutorial then
    if hit(x,y,96,691,288,67) then tutorial=false end
    return
  end
  if hit(x,y,30,693,128,66) then previous_level();return end
  if hit(x,y,175,693,128,66) then reset();return end
  if hit(x,y,320,693,130,66) then next_level();return end

  -- Only the large pull circles are clickable; touching the wire does nothing.
  local best=nil
  local bestd=25*25
  for _,rod in ipairs(LEVEL.rods) do
    if active(rod.group) then
      local bx,by=pull_point(rod)
      local dx,dy=x-bx,y-by
      local d=dx*dx+dy*dy
      if d<=bestd then best,bestd=rod.group,d end
    end
  end
  if best then pull(best) end
end
local function invalidate()
  if CTX then pcall(function() CTX:invalidate() end) end
end

function on_load(c)
  Theme.release()
  CTX=c or ctx
  ERROR=nil
  local ok,e=pcall(function()
    if not restore() then fresh_level(1,1) end
  end)
  if not ok then ERROR=tostring(e) end
end
function on_draw(c,g)
  if c then CTX=c end
  if not g then return end
  if ERROR then
    UI.error(g,CTX,'LINE LIFT',ERROR)
    return
  end
  local ok,e=pcall(function() Theme.draw(CTX,g,draw) end)
  if not ok then
    ERROR=tostring(e)
    pcall(function()
      UI.error(g,CTX,'LINE LIFT',ERROR)
    end)
  end
end
function on_input(c,e)
  if c then CTX=c end
  if ERROR or type(e)~='table' then return false end
  local handled=false
  local ok,err=pcall(function()
    if e.type=='pointer' or e.type=='touch' then
      if e.type=='pointer' and e.phase~='up' then return end
      if e.gesture and e.gesture~='tap' and e.gesture~='double_tap' then return end
      tap(tonumber(e.x) or -1,tonumber(e.y) or -1)
      handled=true
    elseif e.type=='key' and (not e.phase or e.phase=='down') and
      (e.key=='up' or e.key=='down') then
      local now=tonumber(e.time_ms)
      if not now and CTX and CTX.clock then
        local okclock,v=pcall(function() return CTX.clock:millis() end)
        if okclock then now=tonumber(v) end
      end
      if now and now>=last_key_ms and now-last_key_ms<230 then return end
      if now then last_key_ms=now end
      -- Hardware buttons: move to next level after completion; otherwise page
      -- buttons do not accidentally choose/remove a rod.
      if e.key=='down' then next_level()
      elseif e.key=='up' and STATE.level>1 then previous_level() end
      handled=true
    end
  end)
  if not ok then ERROR=tostring(err) end
  if handled then invalidate() end
  return handled
end
function on_leave() Theme.release();
  if STATE then write_save() end
end

if rawget(_G,'__TEST') then
  __TEST.api={
    raw=LEVELS,interpret=interpret,crossing=crossing,
    fresh=fresh_level,restore=restore,state=function() return STATE end,
    level=function() return LEVEL end,blocked=blocked_by,
    pull=pull,active=active,done=all_cleared,prev=previous_level,
    next=next_level,reset=reset,point=pull_point,tap=tap
  }
end
