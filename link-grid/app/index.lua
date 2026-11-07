-- LINK GRID - original monochrome tile-rotation puzzle for XTOS Licorice
-- XTEINK X4 Pro (480x800). Touch interaction and discrete redraws only.
-- No animation, frame loop, network access, timers, or grayscale.
local TOTAL=20
local DIR={{0,-1},{1,0},{0,1},{-1,0}}
local BIT={1,2,4,8} -- north/east/south/west
local OPP={4,8,1,2}
local CELL=78
local CONTEXT,STATE,ERROR,MESSAGE
local key_ms=-1000

-- Curated, frozen puzzles; an independent constraint solver verifies each has
-- exactly one connected solution (up to equivalent straight/cross rotations).
-- Rows are hex-encoded arm masks. 'X' locks a tile; '.' means rotatable.
local LEVELS={
  {name="FIRST LINK",size=4,rows={"0659","0A0A","1902","0000"},fixed={".X..","....",".X..","...."}},
  {name="CORNER TURN",size=4,rows={"C5B8","50A0","4020","0000"},fixed={"...X","X...","....","...."}},
  {name="THREE WAYS",size=4,rows={"4100","9D00","0754","4C00"},fixed={"X...",".X..",".X..","...."}},
  {name="THE BEND",size=4,rows={"C558","B558","1000","0000"},fixed={"...X","...X","X...","...."}},
  {name="FIRST BRANCH",size=4,rows={"8200","6FA8","0D10","4C00"},fixed={"....",".XXX","....","...."}},
  {name="CLOSE CALL",size=4,rows={"0062","007C","00AA","4538"},fixed={"..X.","..XX","....","...."}},
  {name="CROSSING",size=4,rows={"9ED8","A4C8","C520","0000"},fixed={".X.X","...X","....","...."}},
  {name="THE DETOUR",size=4,rows={"04C9","1B9A","3E04","0400"},fixed={".X..","..X.","X...","...."}},
  {name="HIDDEN PATH",size=4,rows={"0859","04AD","0036","25E1"},fixed={"....","..XX","....","X..."}},
  {name="SMALL NETWORK",size=4,rows={"0000","1428","A3F3","35E4"},fixed={"....",".X..",".X..","X..."}},
  {name="WIDER FIELD",size=5,rows={"00000","00200","91A20","DB650","135B8"},fixed={".....",".....",".....","...X.","XX.XX"}},
  {name="LONG WAY",size=5,rows={"00000","08200","6DE00","5CF79","11288"},fixed={".....",".....","X....","X.X..","XX..."}},
  {name="THE CLUSTER",size=5,rows={"25C31","293F1","065F4","00098","00000"},fixed={"X.X..","X.X..",".....","....X","....."}},
  {name="RIGHT ANGLES",size=5,rows={"26000","13781","6AE93","02BE0","00160"},fixed={"X....",".X.X.",".X...",".XX..","....."}},
  {name="BRANCHES",size=5,rows={"02000","0A800","8A356","3B157","2B5A9"},fixed={".....",".....","..X..","X....","XX.XX"}},
  {name="WINDING",size=5,rows={"2E5D6","492A2","65FF8","40462","00000"},fixed={"XX...",".X...","X.X.X",".....","....."}},
  {name="BUSY SIGNAL",size=5,rows={"44800","6FD40","8F5A2","CFD58","21100"},fixed={"XX...",".....",".X.X.","....X",".XX.."}},
  {name="ALL CONNECTED",size=5,rows={"3EAE6","4A974","0A550","4EA33","02108"},fixed={".XXX.",".....","..XX.","...X.","..X.."}},
  {name="NARROW ROUTE",size=5,rows={"8B33C","42DD5","59325","CF541","06400"},fixed={"....X","X..XX","X...X","....X","....."}},
  {name="FINAL GRID",size=5,rows={"65558","7A520","B1210","A2EB6","CE901"},fixed={"X...X","XX...",".....","...X.","..X.X"}},
}

local function index(x,y,w) return (y-1)*w+x end
local function arm(mask,dir)
  return math.floor(mask/BIT[dir])%2==1
end
local function rotate(mask)
  -- One clockwise quarter-turn; a straight rotates between N/S and E/W.
  return (mask*2)%16+math.floor(mask/8)
end
local function can_reach_mask(base,mask)
  local n=base
  for _=1,4 do
    if n==mask then return true end
    n=rotate(n)
  end
  return false
end
local function load_level(n)
  local p=LEVELS[n]
  if not p then error('Unknown level') end
  local w=p.size
  local initial,locked={},{}
  for y=1,w do
    local row,fix=p.rows[y],p.fixed[y]
    if #row~=w or #fix~=w then error('Invalid level data') end
    for x=1,w do
      local value=tonumber(row:sub(x,x),16)
      if value==nil then error('Bad tile mask') end
      local pos=index(x,y,w)
      initial[pos]=value
      locked[pos]=fix:sub(x,x)=='X'
    end
  end
  return {name=p.name,size=w,initial=initial,locked=locked}
end
local function neighboring_mask(tiles,w,x,y,d)
  local nx,ny=x+DIR[d][1],y+DIR[d][2]
  if nx<1 or nx>w or ny<1 or ny>w then return 0 end
  return tiles[index(nx,ny,w)]
end
local function solved(board,tiles)
  local w=board.size
  local active=0
  local start=nil
  for y=1,w do
    for x=1,w do
      local i=index(x,y,w)
      local mask=tiles[i]
      if mask~=0 then active=active+1;start=start or i end
      for d=1,4 do
        local neighbor=neighboring_mask(tiles,w,x,y,d)
        if arm(mask,d)~=arm(neighbor,((d+1)%4)+1) then return false end
      end
    end
  end
  if active<2 then return false end
  -- A set of independent closed paths is NOT a solution: one network only.
  local queue={start}
  local seen={[start]=true}
  local first=1
  local connected=0
  while first<=#queue do
    local i=queue[first];first=first+1;connected=connected+1
    local x=(i-1)%w+1
    local y=math.floor((i-1)/w)+1
    for d=1,4 do
      if arm(tiles[i],d) then
        local nx,ny=x+DIR[d][1],y+DIR[d][2]
        local j=index(nx,ny,w)
        if not seen[j] then seen[j]=true;queue[#queue+1]=j end
      end
    end
  end
  return connected==active
end

local function save()
  if not CONTEXT or not CONTEXT.storage or not STATE then return end
  local chars='0123456789ABCDEF'
  local values={}
  for i=1,#STATE.tiles do
    local mask=STATE.tiles[i]
    values[i]=chars:sub(mask+1,mask+1)
  end
  local data=table.concat({
    'version=1','level='..STATE.level,
    'unlocked='..STATE.unlocked,
    'tiles='..table.concat(values)
  },'\n')
  pcall(function() CONTEXT.storage:write('link-grid.txt',data) end)
end
local function start(n,unlocked)
  local board=load_level(n)
  STATE={
    level=n,unlocked=math.max(n,unlocked or n),board=board,tiles={}
  }
  for i,value in ipairs(board.initial) do STATE.tiles[i]=value end
  MESSAGE=nil
  save()
end
local function restore()
  if not CONTEXT or not CONTEXT.storage then return false end
  local ok,data=pcall(function() return CONTEXT.storage:read('link-grid.txt') end)
  if not ok or type(data)~='string' then return false end
  local fields={}
  for k,v in data:gmatch('([%w_]+)=([^\n]*)') do fields[k]=v end
  if fields.version~='1' then return false end
  local level=tonumber(fields.level)
  local unlocked=tonumber(fields.unlocked)
  if not level or level~=math.floor(level) or level<1 or level>TOTAL or
     not unlocked or unlocked~=math.floor(unlocked) or
     unlocked<level or unlocked>TOTAL then return false end
  local board=load_level(level)
  local chars=fields.tiles
  if not chars or #chars~=board.size^2 or
     chars:find('[^0123456789ABCDEF]') then return false end
  local values={}
  for i=1,#board.initial do
    local v=tonumber(chars:sub(i,i),16)
    if not can_reach_mask(board.initial[i],v) or
      (board.locked[i] and v~=board.initial[i]) then return false end
    values[i]=v
  end
  STATE={level=level,unlocked=unlocked,board=board,tiles=values}
  MESSAGE=nil
  return true
end
local function rotate_tile(x,y)
  if not STATE then return false end
  local b=STATE.board
  if x<1 or x>b.size or y<1 or y>b.size then return false end
  local i=index(x,y,b.size)
  if b.locked[i] or STATE.tiles[i]==0 or solved(b,STATE.tiles) then return false end
  STATE.tiles[i]=rotate(STATE.tiles[i])
  if solved(b,STATE.tiles) then
    STATE.unlocked=math.min(TOTAL,math.max(STATE.unlocked,STATE.level+1))
    MESSAGE='CONNECTED!'
  else
    MESSAGE=nil
  end
  save()
  return true
end
local function next_level()
  if not STATE or STATE.level>=TOTAL then return false end
  if STATE.level>=STATE.unlocked and not solved(STATE.board,STATE.tiles) then return false end
  start(STATE.level+1,STATE.unlocked)
  return true
end
local function prev_level()
  if not STATE or STATE.level<=1 then return false end
  start(STATE.level-1,STATE.unlocked)
  return true
end
local function restart()
  if not STATE then return false end
  start(STATE.level,STATE.unlocked)
  return true
end
local function font(which)
  return CONTEXT and CONTEXT.fonts and CONTEXT.fonts[which or 'medium']
end
local function put(g,x,y,s,which,align)
  local f=font(which)
  local opts={}
  if f then opts.font=f end
  if align then opts.align=align end
  g:text(x,y,s,opts)
end
local function center(g,x,y,s,which) put(g,x,y,s,which,'center') end
local function button(g,x,y,w,h,s)
  g:rect(x,y,w,h,{line_width=2})
  center(g,x+w/2,y+h/2-10,s,'medium')
end
local function board_origin(w)
  return math.floor((480-w*CELL)/2),w==4 and 182 or 161
end
local function draw(g)
  g:clear(0)
  put(g,30,18,'LINK GRID','large')
  put(g,30,65,string.format('PUZZLE %d / %d',STATE.level,TOTAL),'medium')
  g:line(30,104,450,104)
  center(g,240,116,'TAP A TILE TO ROTATE','small')
  local board,tiles=STATE.board,STATE.tiles
  local w=board.size
  local bx,by=board_origin(w)
  for y=1,w do
    for x=1,w do
      local i=index(x,y,w)
      local v=tiles[i]
      local px,py=bx+(x-1)*CELL,by+(y-1)*CELL
      local cx,cy=px+CELL/2,py+CELL/2
      -- Subtle square outlines. All strokes are black; no shaded fills.
      g:rect(px,py,CELL,CELL,{line_width=1})
      if v~=0 then
        if arm(v,1) then g:line(cx,cy,cx,py,{line_width=4}) end
        if arm(v,2) then g:line(cx,cy,px+CELL,cy,{line_width=4}) end
        if arm(v,3) then g:line(cx,cy,cx,py+CELL,{line_width=4}) end
        if arm(v,4) then g:line(cx,cy,px,cy,{line_width=4}) end
        g:circle(cx,cy,4,{fill=true})
        if board.locked[i] then
          -- Solid top-left corner marker = nonrotatable anchor.
          g:rect(px+8,py+8,10,10,{fill=true})
        end
      end
    end
  end
  local won=solved(board,tiles)
  if won then
    center(g,240,585,STATE.level==TOTAL and 'ALL 20 PUZZLES SOLVED' or 'CONNECTED!','medium')
  else
    center(g,240,585,'MATCH ALL LINES INTO ONE NETWORK','small')
  end
  center(g,240,630,'CORNER SQUARE = FIXED TILE','small')
  button(g,30,689,128,68,STATE.level>1 and 'PREV' or 'LEVEL 1')
  button(g,175,689,128,68,'RESET')
  if STATE.level<TOTAL and (STATE.level<STATE.unlocked or won) then
    button(g,320,689,130,68,'NEXT')
  elseif won then
    center(g,386,720,'DONE','medium')
  end
end
local function in_rect(x,y,bx,by,w,h)
  return x>=bx and x<bx+w and y>=by and y<by+h
end
local function tap(x,y)
  if in_rect(x,y,30,689,128,68) then return prev_level() end
  if in_rect(x,y,175,689,128,68) then return restart() end
  if in_rect(x,y,320,689,130,68) then return next_level() end
  local w=STATE.board.size
  local bx,by=board_origin(w)
  if x>=bx and x<bx+w*CELL and y>=by and y<by+w*CELL then
    local cx=math.floor((x-bx)/CELL)+1
    local cy=math.floor((y-by)/CELL)+1
    return rotate_tile(cx,cy)
  end
  return false
end
local function invalidate()
  if CONTEXT then pcall(function() CONTEXT:invalidate() end) end
end
function on_load(c)
  CONTEXT=c or ctx
  ERROR=nil
  local ok,err=pcall(function()
    if not restore() then start(1,1) end
  end)
  if not ok then ERROR=tostring(err) end
end
function on_draw(c,g)
  if c then CONTEXT=c end
  if not g then return end
  if ERROR then
    g:clear(0)
    g:text(26,35,'LINK GRID ERROR')
    g:text(26,75,ERROR:sub(1,48))
    return
  end
  local ok,err=pcall(function() draw(g) end)
  if not ok then
    ERROR=tostring(err)
    pcall(function()
      g:clear(0)
      g:text(26,35,'LINK GRID ERROR')
      g:text(26,75,ERROR:sub(1,48))
    end)
  end
end
function on_input(c,event)
  if c then CONTEXT=c end
  if ERROR or not STATE or type(event)~='table' then return false end
  local handled=false
  local ok,err=pcall(function()
    if event.type=='pointer' or event.type=='touch' then
      if event.type=='pointer' and event.phase~='up' then return end
      if event.gesture and event.gesture~='tap' and event.gesture~='double_tap' then return end
      handled=tap(tonumber(event.x) or -1,tonumber(event.y) or -1)
    elseif event.type=='key' and (not event.phase or event.phase=='down') and
       (event.key=='up' or event.key=='down') then
      local now=tonumber(event.time_ms)
      if not now and CONTEXT and CONTEXT.clock then
        local yes,value=pcall(function() return CONTEXT.clock:millis() end)
        if yes then now=tonumber(value) end
      end
      if now and now>=key_ms and now-key_ms<225 then return end
      if now then key_ms=now end
      if event.key=='up' then handled=prev_level()
      else handled=next_level() end
    end
  end)
  if not ok then ERROR=tostring(err);handled=true end
  if handled then invalidate() end
  return handled
end
function on_leave()
  if STATE then save() end
end

if rawget(_G,'__TEST') then
  __TEST.api={
    levels=LEVELS,load_level=load_level,solved=solved,rotate=rotate,
    start=start,restore=restore,state=function() return STATE end,
    rotate_tile=rotate_tile,restart=restart,prev=prev_level,
    next=next_level,origin=board_origin,arm=arm,tap=tap
  }
end
