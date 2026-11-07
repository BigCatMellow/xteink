-- Summit Putt: original card-routing puzzle for XTOS Licorice on the X4 Pro.
-- No animation, no network, no color dependence. 480x800 portrait.
local W,H=480,800
local N=7
local CELL,BX,BY=54,51,141
local MAX_LEVEL=10
local C,STATE,BOARD,ERR,MSG=nil,nil,nil,nil,nil
local show_help=false
local key_ms=-1000

-- These maps are original (not Golf Peaks maps).
-- # void  . ground  ~ pond  s sand  H elevated platform
-- ^>v< uphill ramp (must enter in arrow direction)
-- S starting ball (low)  O hole (low)  A starting ball (high)  G hole (high)
local LEVELS={
  {name='The Approach',hand={1,2,3},rows={
    ".#...#.",".#..#O#","#####..","####...","#..#.##","..~..#.","..##S.."
  }},
  {name='Side Route',hand={1,1,2,3},rows={
    "...~#~~","..###..","#.####O",".#.#...","..#~#..",".####..","..#S..."
  }},
  {name='Switchback',hand={1,2,2,3},rows={
    "#~##...","~#~~O..",".....#.","..###..","...##..","...#..#","#.#..S."
  }},
  {name='The Long Way',hand={1,1,2,2,3},rows={
    "###~..#",".#...~.",".....#.","#O#.##.",".##....","..#....",".....S."
  }},
  {name='Across the Water',hand={1,2,2,3,3},rows={
    "###~##.","..O...#",".#..#.#","#.###.#",".......",".#.#.#.","#~S.#~."
  }},
  {name='One Card Left',hand={1,1,2,3,3},rows={
    "###O...","##.#..#","##...##","##...#.",".#...##","..~....",".S....#"
  }},
  {name='False Shortcut',hand={1,1,2,2,3},rows={
    "~#...O~","~#.#...",".....#.","##...##",".#..#~#",".#.#...","..S..#."
  }},
  {name='The Last Turn',hand={1,2,2,3,3},rows={
    "......#","#...O#~","#..##.#","#...~#.","#.#..##","..#.#.#","....S.."
  }},
  {name='The High Road',hand={3,2,1,2,1},rows={
    "#######","##GHH##","##HH^##","#....##","##.####","##.####","##S####"
  }},
  {name='Final Ascent',hand={2,3,1,2,2},rows={
    "#######","#GHH###","###H###","##.>###","##.####","##.####","##..S##"
  }}
}
local DIRS={{0,-1},{1,0},{0,1},{-1,0}}
local LABELS={'UP','RIGHT','DOWN','LEFT'}
local ARROWS={'^','>','v','<'}
local function inside(x,y) return x>=1 and x<=N and y>=1 and y<=N end
local function index(x,y) return (y-1)*N+x end
local function used(mask,i) return math.floor(mask/2^(i-1))%2==1 end
local function setused(mask,i) return mask+math.floor(2^(i-1)) end
local function high(ch)
  return ch=='H' or ch=='^' or ch=='v' or ch=='<' or ch=='>' or ch=='A' or ch=='G'
end

local function parse_level(n)
  local level=LEVELS[n]
  if not level then error('No such level: '..tostring(n)) end
  local board={tiles={},hand=level.hand,name=level.name}
  local starts,goals=0,0
  for y=1,N do
    local row=level.rows[y]
    if not row or #row~=N then error('Level row size') end
    for x=1,N do
      local ch=row:sub(x,x)
      if not ch:match('^[#%.~sH%^>v<SOAG]$') then error('Unknown tile: '..ch) end
      board.tiles[index(x,y)]=ch
      if ch=='S' or ch=='A' then board.sx,board.sy=x,y;starts=starts+1 end
      if ch=='O' or ch=='G' then board.gx,board.gy=x,y;goals=goals+1 end
    end
  end
  if starts~=1 or goals~=1 then error('Level needs one ball and one hole') end
  return board
end

local function tile(board,x,y)
  if not inside(x,y) then return '#' end
  return board.tiles[index(x,y)]
end

-- Pure stepwise movement: a finite card is consumed ONLY for a valid shot.
-- The ball cannot jump a void, pond, or the hole during a long shot.
-- Climbing requires a ramp tile approached in its arrow direction.
local function destination(board,x,y,steps,dir)
  local delta=DIRS[dir]
  if not delta or not steps or steps<1 then return nil end
  if tile(board,x,y)=='s' and steps~=1 then return nil end
  local dx,dy=delta[1],delta[2]
  local cx,cy=x,y
  for k=1,steps do
    local nx,ny=cx+dx,cy+dy
    local previous,nexttile=tile(board,cx,cy),tile(board,nx,ny)
    if nexttile=='#' or nexttile=='~' then return nil end
    if high(nexttile) and not high(previous) and nexttile~=ARROWS[dir] then
      return nil
    end
    if (nx==board.gx and ny==board.gy) and k<steps then return nil end
    cx,cy=nx,ny
  end
  return cx,cy
end

local function first_available()
  for i=1,#BOARD.hand do
    if not used(STATE.mask,i) then return i end
  end
  return 0
end
local function read_save()
  if not C or not C.storage then return nil end
  local ok,data=pcall(function() return C.storage:read('summit.txt') end)
  if ok and type(data)=='string' then return data end
  return nil
end
local function save()
  if not C or not C.storage or not STATE then return end
  local history={}
  for _,h in ipairs(STATE.history) do
    history[#history+1]=table.concat({h.x,h.y,math.floor(h.mask),h.selected},',')
  end
  local body=table.concat({
    'version=1',
    'level='..STATE.level,
    'x='..STATE.x,
    'y='..STATE.y,
    'mask='..math.floor(STATE.mask),
    'selected='..STATE.selected,
    'unlocked='..STATE.unlocked,
    'stage='..STATE.stage,
    'history='..table.concat(history,';')
  },'\n')
  pcall(function() C.storage:write('summit.txt',body) end)
end
local function start_level(n,unlocked)
  BOARD=parse_level(n)
  STATE={
    level=n,x=BOARD.sx,y=BOARD.sy,mask=0,
    selected=1,unlocked=math.max(n,unlocked or n),
    stage='play',history={}
  }
  MSG='Choose a card, then a direction'
  save()
end

local function load()
  local s=read_save()
  if not s then return false end
  local t={}
  for k,v in s:gmatch('([%a]+)=([^\n]*)') do t[k]=v end
  if t.version~='1' then return false end
  local function num(s) local n=tonumber(s);if n and n==math.floor(n) then return n end end
  local n,x,y=num(t.level),num(t.x),num(t.y)
  local mask,selection,unlocked=num(t.mask),num(t.selected),num(t.unlocked)
  if not n or n<1 or n>MAX_LEVEL or not x or not inside(x,y or -1) or
     not mask or mask<0 or mask>=2^#LEVELS[n].hand or
     not selection or selection<0 or selection>#LEVELS[n].hand or
     not unlocked or unlocked<n or unlocked>MAX_LEVEL then return false end
  if t.stage~='play' and t.stage~='won' and t.stage~='stuck' then return false end
  BOARD=parse_level(n)
  if tile(BOARD,x,y)=='#' or tile(BOARD,x,y)=='~' then return false end
  local hist={}
  for entry in (t.history or ''):gmatch('[^;]+') do
    local a,b,c,d=entry:match('^(%d+),(%d+),(%d+),(%d+)$')
    a,b,c,d=num(a),num(b),num(c),num(d)
    if not a or not inside(a,b or -1) or
       not c or c<0 or c>=2^#BOARD.hand or
       not d or d<0 or d>#BOARD.hand or
       #hist>=#BOARD.hand then return false end
    hist[#hist+1]={x=a,y=b,mask=c,selected=d}
  end
  if #hist>0 and mask==0 then return false end
  if t.stage=='won' and (x~=BOARD.gx or y~=BOARD.gy) then return false end
  if t.stage=='play' and x==BOARD.gx and y==BOARD.gy then return false end
  STATE={level=n,x=x,y=y,mask=mask,selected=selection,
         unlocked=unlocked,stage=t.stage,history=hist}
  MSG=nil
  return true
end

local function choose(i)
  if STATE.stage~='play' or not BOARD.hand[i] or used(STATE.mask,i) then return false end
  STATE.selected=i
  MSG='Card '..i..' moves '..BOARD.hand[i]..' square(s)'
  save()
  return true
end

local function can_use()
  return STATE.selected>0 and not used(STATE.mask,STATE.selected)
end
local function advance(dir)
  if STATE.stage~='play' or not can_use() then return false end
  local cx,cy=destination(BOARD,STATE.x,STATE.y,BOARD.hand[STATE.selected],dir)
  if not cx then
    MSG='Blocked. Try another direction'
    return false
  end
  STATE.history[#STATE.history+1]={
    x=STATE.x,y=STATE.y,mask=STATE.mask,selected=STATE.selected
  }
  STATE.x,STATE.y=cx,cy
  STATE.mask=setused(STATE.mask,STATE.selected)
  if STATE.x==BOARD.gx and STATE.y==BOARD.gy then
    STATE.stage='won'
    if STATE.level<MAX_LEVEL then STATE.unlocked=math.max(STATE.unlocked,STATE.level+1) end
    MSG='Level solved!'
  else
    STATE.selected=first_available()
    if STATE.selected==0 then
      STATE.stage='stuck'
      MSG='No cards remain. Undo or reset'
    else
      MSG='Plan your next move'
    end
  end
  save()
  return true
end

local function undo()
  if #STATE.history==0 then MSG='Nothing to undo';return false end
  local h=table.remove(STATE.history)
  STATE.x,STATE.y,STATE.mask,STATE.selected=h.x,h.y,h.mask,h.selected
  STATE.stage='play'
  MSG='Move undone'
  save()
  return true
end

local function next_level()
  if STATE.stage~='won' then return false end
  if STATE.level<MAX_LEVEL then
    start_level(STATE.level+1,STATE.unlocked)
  else
    start_level(1,MAX_LEVEL)
    MSG='All ten cleared! Play again'
  end
  return true
end

local function font(which)
  return C and C.fonts and C.fonts[which] or nil
end
local function text(g,x,y,s,which)
  local f=font(which or 'medium')
  if f then g:text(x,y,s,{font=f}) else g:text(x,y,s) end
end
local function center(g,x,y,s,which)
  local f=font(which or 'medium')
  if f then g:text(x,y,s,{font=f,align='center'})
  else g:text(x-math.floor(#s*6),y,s) end
end
local function box(g,x,y,w,h,label)
  g:rect(x,y,w,h,{line_width=2})
  g:rect(x+4,y+4,w-8,h-8,{line_width=1})
  g:line(x+10,y+4,x+19,y+4)
  g:line(x+w-19,y+h-4,x+w-10,y+h-4)
  center(g,x+w/2,y+h/2-9,label,'medium')
end
local function draw_tiles(g)
  -- A tabletop topographic board: every mark is hard-edged vector geometry,
  -- so the terrain stays as crisp as a printed puzzle card on e-ink.
  g:rect(BX-9,BY-9,N*CELL+18,N*CELL+18,{line_width=2})
  g:rect(BX-4,BY-4,N*CELL+8,N*CELL+8,{line_width=1})
  for y=1,N do
    for x=1,N do
      local ch=tile(BOARD,x,y)
      local px,py=BX+(x-1)*CELL,BY+(y-1)*CELL
      if ch~='#' then
        g:rect(px+1,py+1,CELL-2,CELL-2,{line_width=1})
        if high(ch) then
          -- Raised tiles carry a bold north/west cap and a thin lower edge.
          g:line(px+3,py+6,px+CELL-4,py+6,{line_width=2})
          g:line(px+6,py+3,px+6,py+CELL-4,{line_width=2})
          g:line(px+5,py+CELL-5,px+CELL-5,py+CELL-5)
          g:line(px+CELL-5,py+5,px+CELL-5,py+CELL-5)
        end
        if ch=='~' then
          for j=0,2 do
            local xx,yy=px+10,py+12+j*13
            g:line(xx,yy,xx+8,yy+3)
            g:line(xx+8,yy+3,xx+16,yy)
            g:line(xx+16,yy,xx+24,yy+3)
          end
        elseif ch=='s' then
          for i=1,5 do
            local xx=px+7+(i*13)%39
            local yy=py+9+(i*17)%35
            g:circle(xx,yy,1,{fill=true})
          end
        elseif ch=='^' or ch=='>' or ch=='v' or ch=='<' then
          center(g,px+CELL/2,py+CELL/2-10,ch,'large')
        end
        if x==BOARD.gx and y==BOARD.gy then
          g:circle(px+CELL/2,py+CELL/2+6,8,{fill=true})
          g:line(px+CELL/2,py+6,px+CELL/2,py+CELL/2+4)
          g:line(px+CELL/2,py+6,px+CELL/2+15,py+11)
          g:line(px+CELL/2+15,py+11,px+CELL/2,py+17)
        end
      end
    end
  end
  -- Show all legal destinations for the selected card.
  if STATE.stage=='play' and can_use() then
    for d=1,4 do
      local nx,ny=destination(BOARD,STATE.x,STATE.y,BOARD.hand[STATE.selected],d)
      if nx and not (nx==STATE.x and ny==STATE.y) then
        g:circle(BX+(nx-0.5)*CELL,BY+(ny-0.5)*CELL,17,{line_width=1})
      end
    end
  end
  local x=BX+(STATE.x-0.5)*CELL
  local y=BY+(STATE.y-0.5)*CELL
  g:circle(x,y,15,{line_width=2})
  g:circle(x,y,10,{line_width=1})
  g:circle(x,y,5,{fill=true})
end

local function draw_help(g)
  center(g,240,138,'HOW TO PLAY','large')
  text(g,36,202,'1. Tap an unused number card.','small')
  text(g,36,240,'2. Tap a direction to move exactly that far.','small')
  text(g,36,295,'Cards are single-use. A blocked move costs nothing.','small')
  text(g,36,350,'Avoid gaps and water. Sand accepts only a 1 card.','small')
  text(g,36,405,'Hatched tiles are high ground. Enter a ramp','small')
  text(g,36,435,'from the direction shown by its arrow.','small')
  text(g,36,490,'Reach the flag exactly. UNDO restores a card.','small')
  box(g,30,694,420,65,'BACK TO PUZZLE')
end

local function draw(g)
  g:clear(0)
  text(g,30,14,'SUMMIT PUTT','large')
  text(g,31,46,'TOPOGRAPHIC CARD PUZZLES','small')
  if not show_help then box(g,402,12,48,42,'?') end
  text(g,30,72,string.format('PUZZLE %02d/%02d  //  %s',STATE.level,MAX_LEVEL,BOARD.name),'small')
  if show_help then draw_help(g); return end
  box(g,30,82,195,42,'UNDO')
  box(g,255,82,195,42,'RESTART')
  draw_tiles(g)
  center(g,240,532,MSG or 'Select a card, then a direction','small')
  text(g,30,544,'CLUB CARDS','small')

  if STATE.stage=='won' then
    center(g,240,601,STATE.level==MAX_LEVEL and 'ALL PUZZLES CLEARED' or 'PUZZLE COMPLETE','large')
    box(g,30,704,420,65,STATE.level==MAX_LEVEL and 'PLAY AGAIN' or 'NEXT PUZZLE')
    return
  end
  if STATE.stage=='stuck' then
    center(g,240,608,'OUT OF CARDS','large')
    box(g,30,704,420,65,'RESTART LEVEL')
    return
  end
  for i,v in ipairs(BOARD.hand) do
    local cx=30+(i-1)*87
    g:rect(cx,562,75,65,{line_width=2})
    g:rect(cx+4,566,67,57,{line_width=1})
    if used(STATE.mask,i) then
      g:line(cx+8,570,cx+67,619)
      g:line(cx+8,619,cx+67,570)
    else
      center(g,cx+37,576,tostring(v),'large')
      for p=1,v do g:circle(cx+18+(p-1)*18,613,2,{fill=true}) end
      if STATE.selected==i then g:rect(cx+3,565,69,59,{line_width=1}) end
    end
  end
  center(g,240,647,'Tap a card, then choose a direction','small')
  for i,label in ipairs(LABELS) do
    box(g,30+(i-1)*112,701,87,68,label)
  end
end
local function within(x,y,px,py,w,h)
  return x>=px and x<px+w and y>=py and y<py+h
end
local function touch(x,y)
  if show_help then
    if within(x,y,30,694,420,65) then show_help=false end
    return
  end
  if within(x,y,402,12,48,42) then show_help=true;return end
  if within(x,y,30,82,195,42) then undo();return end
  if within(x,y,255,82,195,42) then start_level(STATE.level,STATE.unlocked);return end
  if STATE.stage=='won' then
    if within(x,y,30,704,420,65) then next_level() end
    return
  end
  if STATE.stage=='stuck' then
    if within(x,y,30,704,420,65) then start_level(STATE.level,STATE.unlocked) end
    return
  end
  for i=1,#BOARD.hand do
    if within(x,y,30+(i-1)*87,562,75,65) then choose(i);return end
  end
  for i=1,4 do
    if within(x,y,30+(i-1)*112,701,87,68) then advance(i);return end
  end
end
local function refresh()
  if C then pcall(function() C:invalidate() end) end
end
function on_load(c)
  C=c or ctx
  ERR=nil
  local ok,err=pcall(function()
    if not load() then start_level(1,1) end
  end)
  if not ok then ERR=tostring(err) end
end
function on_draw(c,g)
  if c then C=c end
  if not g then return end
  if ERR then
    g:clear(0);g:text(20,40,'Summit Putt: '..ERR:sub(1,40))
    return
  end
  local ok,err=pcall(function() draw(g) end)
  if not ok then ERR=tostring(err) end
end
function on_input(c,e)
  if c then C=c end
  if ERR or not STATE or type(e)~='table' then return false end
  local ok,err=pcall(function()
    if e.type=='pointer' or e.type=='touch' then
      if e.type=='pointer' and e.phase~='up' then return end
      if e.gesture and e.gesture~='tap' and e.gesture~='double_tap' then return end
      touch(tonumber(e.x) or -1,tonumber(e.y) or -1)
    elseif e.type=='key' and (not e.phase or e.phase=='down') and
      (e.key=='up' or e.key=='down') then
      local now=tonumber(e.time_ms)
      if not now and C and C.clock then
        local yes,value=pcall(function() return C.clock:millis() end)
        if yes then now=tonumber(value) end
      end
      if now and now>=key_ms and now-key_ms<220 then return end
      if now then key_ms=now end
      if STATE.stage=='play' then
        local free={}
        for i=1,#BOARD.hand do
          if not used(STATE.mask,i) then free[#free+1]=i end
        end
        if #free>0 then
          local pos=1
          for i,x in ipairs(free) do if x==STATE.selected then pos=i;break end end
          local change=e.key=='up' and -1 or 1
          choose(free[(pos-1+change+#free)%#free+1])
        end
      end
    end
  end)
  if not ok then ERR=tostring(err) end
  refresh()
  return true
end
function on_leave()
  if STATE then save() end
end
if rawget(_G,'__TEST') then
  __TEST.api={
    levels=LEVELS,parse=parse_level,dest=destination,high=high,
    start=start_level,read=load,save=save,
    state=function() return STATE end,
    board=function() return BOARD end,
    choose=choose,advance=advance,undo=undo,next=next_level,
    used=used,touch=touch
  }
end
