-- Pocket Golf: original, offline exact-distance golf puzzle for XTOS Licorice API 2.9.
-- Portrait screen: 480 x 800. No network, images, fonts, or animations.
-- All game state is stored in the app's private save.txt.
local COLS, ROWS = 9, 12
local CELL, BX, BY = 46, 33, 94
local MODULUS = 4294967296
local CTX, S, COURSE, ERR
local confirm_new, message = false, nil
local last_key_ms = -1000

local function index(x, y) return (y - 1) * COLS + x end
local function in_bounds(x, y) return x >= 1 and x <= COLS and y >= 1 and y <= ROWS end
local function step_rng(s) return (s * 1664525 + 1013904223) % MODULUS end
local function integer(v, fallback)
  v = tonumber(v)
  if not v or v ~= v or v == math.huge or v == -math.huge then return fallback end
  return math.floor(v)
end

-- The puzzle has no shot randomness: all nine courses are authored and solver-checked.
-- The round seed may mirror a course, preserving the puzzle's difficulty.
local CLUBS = {
  {name='PUTT',distance=1},
  {name='CHIP',distance=2},
  {name='DRIVE',distance=4}
}
local DRIVE_ALLOWANCE = 2
local DIRECTIONS = { {-1,-1},{0,-1},{1,-1},{-1,0},{1,0},{-1,1},{0,1},{1,1} }

-- Nine escalating 9x12 puzzles (top to bottom).
-- . rough, f fairway, g green, ~ water, s sand, T tree, h hole, t tee.
-- Each layout has been solved independently with the two-drive and last-putt rules.
local PUZZLES = {
  {
    "....ggg..",
    ".fffghg..",
    "...fggg..",
    "..fTf~~..",
    "...Tf~~.T",
    "....f~~..",
    "...fss...",
    ".Tffss...",
    "..ff.....",
    "..ffT....",
    ".fff.....",
    "...tf...."
  },
  {
    "..ggg....",
    "..ghgff..",
    ".Tgggff..",
    "...ffff..",
    "....fff..",
    "..~~~f...",
    "..~~~f...",
    "...fffss.",
    "....ffss.",
    "..T.ff...",
    "...fff.T.",
    ".....tf.."
  },
  {
    "...ggg...",
    "...ghgf..",
    "...gggf..",
    "....ffff.",
    ".....fff.",
    "....TTf..",
    "s~~~..ff.",
    "s~~~fff..",
    ".....ff..",
    "TT..ff...",
    "....ffT..",
    "....tf..."
  },
  {
    "...ggg...",
    "..fghg...",
    ".T.ggg...",
    "T.ssT....",
    "..ssff...",
    "...ff....",
    "...Tf~~.T",
    "...ff~~..",
    "..T.~~~.T",
    "....~~~..",
    "...fss...",
    ".....tf.."
  },
  {
    "..ggg....",
    "..ghgf...",
    "..gggf...",
    "...fff...",
    "...fff.T.",
    "s~~.ff...",
    "s~~ff....",
    ".~~TT....",
    "..Tf.....",
    "..fss~~..",
    "..Tss~~..",
    "...tf...."
  },
  {
    "....ggg..",
    "....ghgf.",
    "....gggf.",
    ".....fff.",
    "..~~~fff.",
    "..~~~ssf.",
    ".ss.~~~fT",
    ".ss.~~~f.",
    "......fT.",
    ".....TTf.",
    "....fff..",
    "....tf..."
  },
  {
    "..ggg....",
    "..ghgff..",
    "..gggff..",
    "...fff..T",
    "...fff...",
    "...ff.~~.",
    "ss.TTs~~.",
    "ss.f~~~..",
    "....~~~..",
    ".....Tf..",
    ".....fff.",
    ".....tf.."
  },
  {
    "....ggg..",
    "..ffghg..",
    "..Tfggg..",
    "...ffT...",
    "..fff....",
    ".s~~~....",
    ".s~~~.~~~",
    ".~~~..~~~",
    ".~~~ss...",
    "...Tss...",
    "...ffT...",
    "...tf...."
  },
  {
    "..ggg....",
    "..ghgf...",
    "..gggff..",
    "...Tfff.T",
    "...ff~~..",
    "...Tf~~..",
    "..ss.~~..",
    "..ssf~~~.",
    "...~~~~~T",
    "..T~~fss.",
    "..T.TTf..",
    ".....tf.."
  }
}
local TILE = {
  ['.']='rough',f='fairway',g='green',['~']='water',
  s='sand',T='tree',h='cup',t='tee'
}

local function targets(course,x,y,club,drives)
  local selected=CLUBS[club]
  if not selected then return {} end
  if club==3 and (drives or DRIVE_ALLOWANCE)<=0 then return {} end
  local lie=course.map[index(x,y)]
  if lie=='sand' and club~=1 then return {} end
  if lie=='rough' and club==3 then return {} end
  local result={}
  for _,dir in ipairs(DIRECTIONS) do
    local dx,dy=dir[1],dir[2]
    local blocked,nx,ny=false,x,y
    for step=1,selected.distance do
      nx,ny=x+dx*step,y+dy*step
      if not in_bounds(nx,ny) or course.map[index(nx,ny)]=='tree' then
        blocked=true;break
      end
    end
    if not blocked then
      local landing=course.map[index(nx,ny)]
      if landing~='tree' and landing~='water' and
         (landing~='cup' or club==1) then
        result[#result+1]={x=nx,y=ny}
      end
    end
  end
  return result
end

local function shortest_path(course)
  local start={x=course.tx,y=course.ty,drives=DRIVE_ALLOWANCE,moves=0}
  local queue={start}
  local seen={}
  local function key(x,y,drives)
    return ((index(x,y)-1)*(DRIVE_ALLOWANCE+1))+drives+1
  end
  seen[key(start.x,start.y,start.drives)]=true
  local first=1
  while first<=#queue do
    local current=queue[first];first=first+1
    if current.x==course.hx and current.y==course.hy then return current.moves end
    for club=1,#CLUBS do
      for _,point in ipairs(targets(course,current.x,current.y,club,current.drives)) do
        local left=current.drives-(club==3 and 1 or 0)
        local k=key(point.x,point.y,left)
        if not seen[k] then
          seen[k]=true
          queue[#queue+1]={x=point.x,y=point.y,drives=left,moves=current.moves+1}
        end
      end
    end
  end
  return nil
end

local function make_course(seed,hole)
  local template=PUZZLES[hole]
  if not template then error('invalid puzzle number') end
  local mirror=((seed+hole)%2)==0
  local map,tx,ty,hx,hy={},nil,nil,nil,nil
  for y=1,ROWS do
    local line=template[y]
    if #line~=COLS then error('puzzle width is wrong') end
    for x=1,COLS do
      local symbol=line:sub(mirror and (COLS+1-x) or x,mirror and (COLS+1-x) or x)
      local tile=TILE[symbol]
      if not tile then error('invalid puzzle tile') end
      map[index(x,y)]=tile
      if tile=='tee' then tx,ty=x,y end
      if tile=='cup' then hx,hy=x,y end
    end
  end
  if not tx or not hx then error('missing tee or cup') end
  local course={map=map,tx=tx,ty=ty,hx=hx,hy=hy}
  local best=shortest_path(course)
  if not best then error('unsolvable puzzle '..hole) end
  course.par=best
  course.limit=best+(hole<=6 and 1 or 0)
  return course
end

local function totals()
  local strokes, par = 0, 0
  for i=1,9 do
    if S.scores[i] > 0 then
      strokes=strokes+S.scores[i]
      par=par+S.pars[i]
    end
  end
  return strokes,par
end

local function save()
  if not CTX or not CTX.storage then return end
  local fields={
    'version=3','seed='..S.seed,'rng='..S.rng,
    'hole='..S.hole,'x='..S.x,'y='..S.y,
    'strokes='..S.strokes,'club='..S.club,
    'drives='..S.drives,'stage='..S.stage,
    'scores='..table.concat(S.scores,','),
    'pars='..table.concat(S.pars,',')
  }
  pcall(function() CTX.storage:write('save.txt',table.concat(fields,'\n')) end)
end

local function reset_hole()
  COURSE=make_course(S.seed,S.hole)
  S.x,S.y=COURSE.tx,COURSE.ty
  S.strokes,S.club,S.drives,S.stage=0,2,DRIVE_ALLOWANCE,'aim'
  confirm_new,message=false,'Plan your route'
  save()
end

local function start_round(seed)
  seed=(integer(seed,1)%(MODULUS-1))+1
  S={
    seed=seed,rng=step_rng(seed),hole=1,x=0,y=0,
    strokes=0,club=2,drives=DRIVE_ALLOWANCE,stage='aim',
    scores={0,0,0,0,0,0,0,0,0},
    pars={0,0,0,0,0,0,0,0,0}
  }
  reset_hole()
end

local function restore()
  local ok,data=pcall(function() return CTX.storage:read('save.txt') end)
  if not ok or type(data)~='string' then return false end
  local f={}
  for k,v in data:gmatch('([%w_]+)=([^\n]*)') do f[k]=v end
  if f.version~='3' then return false end
  local seed,rng=integer(f.seed,0),integer(f.rng,-1)
  local hole,x,y=integer(f.hole,0),integer(f.x,0),integer(f.y,0)
  local strokes,club,drives=integer(f.strokes,-1),integer(f.club,0),integer(f.drives,-1)
  if seed<1 or seed>=MODULUS or rng<0 or rng>=MODULUS or
     hole<1 or hole>9 or not in_bounds(x,y) or
     strokes<0 or strokes>100 or club<1 or club>#CLUBS or
     drives<0 or drives>DRIVE_ALLOWANCE then return false end
  local stage=f.stage
  if stage~='aim' and stage~='finished' and stage~='failed' then return false end
  local scores,pars={},{}
  for n in (f.scores or ''):gmatch('%d+') do scores[#scores+1]=tonumber(n) end
  for n in (f.pars or ''):gmatch('%d+') do pars[#pars+1]=tonumber(n) end
  if #scores~=9 or #pars~=9 then return false end
  for i=1,9 do
    if scores[i]<0 or scores[i]>100 or pars[i]<0 or pars[i]>100 then return false end
  end
  local course=make_course(seed,hole)
  if strokes>course.limit or
     course.map[index(x,y)]=='tree' or course.map[index(x,y)]=='water' then return false end
  if (stage=='finished')~=(x==course.hx and y==course.hy) then return false end
  S={seed=seed,rng=rng,hole=hole,x=x,y=y,strokes=strokes,
     club=club,drives=drives,stage=stage,scores=scores,pars=pars}
  COURSE=course
  confirm_new,message=false,nil
  return true
end

local function legal_moves()
  if S.stage~='aim' then return {} end
  return targets(COURSE,S.x,S.y,S.club,S.drives)
end

local function select_club(n)
  if S.stage~='aim' or n<1 or n>#CLUBS then return false end
  if n==3 and S.drives==0 then
    message='No drives left'
    return false
  end
  S.club=n
  message=CLUBS[n].name..': '..CLUBS[n].distance..' squares'
  save()
  return true
end

local function no_moves()
  for c=1,#CLUBS do
    if #targets(COURSE,S.x,S.y,c,S.drives)>0 then return false end
  end
  return true
end

local function shoot(x,y)
  if S.stage~='aim' then return false end
  local valid=false
  for _,m in ipairs(legal_moves()) do
    if m.x==x and m.y==y then valid=true;break end
  end
  if not valid then message='Choose a ringed landing';return false end
  if S.club==3 then S.drives=S.drives-1 end
  S.x,S.y=x,y
  S.strokes=S.strokes+1
  if x==COURSE.hx and y==COURSE.hy then
    S.stage='finished'
    S.scores[S.hole]=S.strokes
    S.pars[S.hole]=COURSE.par
    message='Solved in '..S.strokes..' shots!'
  elseif S.strokes>=COURSE.limit then
    S.stage='failed'
    message='Out of shots - retry'
  elseif no_moves() then
    S.stage='failed'
    message='No safe shot - retry'
  else
    message='Choose your next shot'
    if S.club==3 and S.drives==0 then S.club=2 end
  end
  save()
  return true
end

local function next_hole()
  if S.stage~='finished' then return false end
  if S.hole==9 then start_round(step_rng(S.rng));return true end
  S.hole=S.hole+1
  reset_hole()
  return true
end

local function text_width(str, font)
  local f = CTX and CTX.fonts and CTX.fonts[font]
  if f then
    local ok, w = pcall(function() return f:measure(str) end)
    if ok and type(w) == 'number' then return w end
  end
  return #str * (font == 'large' and 16 or 12)
end

local function put(g, x, y, s, font)
  local f = CTX and CTX.fonts and CTX.fonts[font or 'medium']
  if f then g:text(x, y, s, { font=f }) else g:text(x, y, s) end
end

local function centered(g, cx, y, s, font)
  put(g, math.floor(cx - text_width(s, font or 'medium') / 2), y, s, font)
end

local function button(g, x, y, w, h, s)
  g:rect(x, y, w, h, { line_width=2 })
  centered(g, x + w / 2, y + 14, s, 'large')
end

-- Monochrome terrain language:
-- grass/fairway = unfilled connected stepped outline + sparse little ticks
-- water = connected outline + waves, sand = connected outline + stipple
-- trees = small solid triangles, background = regular paper dots
local function region(tile)
  if tile == 'fairway' or tile == 'green' or tile == 'tee' or tile == 'cup' then
    return 'grass'
  elseif tile == 'water' or tile == 'sand' then
    return tile
  end
  return nil
end

local function draw_tile(g, x, y, tile)
  if tile == 'water' then
    for row = -1, 1 do
      local ry = y + row * 11
      g:line(x - 12, ry, x - 6, ry + 4)
      g:line(x - 6, ry + 4, x, ry)
      g:line(x, ry, x + 6, ry + 4)
      g:line(x + 6, ry + 4, x + 12, ry)
    end
  elseif tile == 'tree' then
    -- Short horizontal bars form a readable solid triangle without polygons.
    for row = 0, 7 do
      local half = 2 + row * 1.7
      local yy = y - 14 + row * 3
      g:line(math.floor(x-half), yy, math.floor(x+half), yy)
    end
  elseif tile == 'sand' then
    for i = 0, 3 do
      local dx = (i * 11) % 27 - 13
      local dy = (i * 17) % 29 - 14
      g:circle(x + dx, y + dy, 1, { fill = true })
    end
  elseif tile == 'fairway' or tile == 'green' then
    -- An understated texture differentiates fairway from blank rough.
    g:line(x - 12, y + 12, x - 9, y + 9)
  elseif tile == 'tee' then
    g:line(x - 10, y + 12, x + 10, y + 12)
  elseif tile == 'cup' then
    g:circle(x, y + 9, 5, { fill = true })
    g:line(x, y - 16, x, y + 6)
    g:line(x, y - 16, x + 13, y - 12)
    g:line(x + 13, y - 12, x, y - 8)
  end
end

local function draw_board(g)
  local width, height = COLS * CELL, ROWS * CELL
  -- A half-cell dot grid is the paper texture (19x25 = 475 dots).
  -- Draw dots first, so regions remain readable over the background.
  for row = 0, ROWS * 2 do
    for col = 0, COLS * 2 do
      local px = BX + col * CELL / 2
      local py = BY + row * CELL / 2
      g:circle(px, py, 1, { fill = true })
    end
  end

  -- Draw only the EXTERIOR edge of each same-terrain cluster, not every tile.
  -- This produces the stepped fairway/water/sand silhouettes in the reference.
  for y = 1, ROWS do
    for x = 1, COLS do
      local tile = COURSE.map[index(x, y)]
      local kind = region(tile)
      if kind then
        local x0, y0 = BX + (x - 1) * CELL, BY + (y - 1) * CELL
        local function same(nx, ny)
          return in_bounds(nx, ny) and region(COURSE.map[index(nx, ny)]) == kind
        end
        if not same(x, y-1) then g:line(x0, y0, x0+CELL, y0) end
        if not same(x, y+1) then g:line(x0, y0+CELL, x0+CELL, y0+CELL) end
        if not same(x-1, y) then g:line(x0, y0, x0, y0+CELL) end
        if not same(x+1, y) then g:line(x0+CELL, y0, x0+CELL, y0+CELL) end
      end
      local cx, cy = BX + (x - 0.5) * CELL, BY + (y - 0.5) * CELL
      draw_tile(g, cx, cy, tile)
    end
  end

  -- Show only legal exact-distance landing spots for the selected club.
  if S.stage == 'aim' then
    for _, move in ipairs(legal_moves()) do
      local cx, cy = BX + (move.x - 0.5) * CELL, BY + (move.y - 0.5) * CELL
      g:circle(cx, cy, 15, { line_width = 2 })
    end
  end

  -- The player's ball is a white circle with two black outline rings.
  local px, py = BX + (S.x - 0.5) * CELL, BY + (S.y - 0.5) * CELL
  g:circle(px, py, 13, { line_width = 2 })
  g:circle(px, py, 10, { line_width = 2 })
  g:rect(BX, BY, width, height)
end

local function draw_summary(g)
  centered(g, 240, 165, 'ROUND COMPLETE', 'large')
  local total, par = totals()
  centered(g, 240, 212, tostring(total) .. ' strokes / par ' .. tostring(par), 'medium')
  g:line(74, 270, 406, 270)
  for i = 1, 9 do
    local y = 279 + (i - 1) * 36
    put(g, 100, y, 'Hole ' .. i, 'medium')
    put(g, 272, y, tostring(S.scores[i]), 'medium')
  end
  g:line(74, 620, 406, 620)
end

local function draw_confirm(g)
  centered(g, 240, 260, 'START A NEW ROUND?', 'large')
  centered(g, 240, 315, 'Current progress will be lost.', 'small')
  button(g, 55, 410, 170, 65, 'CANCEL')
  button(g, 255, 410, 170, 65, 'YES')
end

local function draw(g)
  g:clear(0)
  put(g,33,11,'POCKET GOLF','large')
  put(g,33,48,'HOLE '..S.hole..'/9  GOAL '..COURSE.par..'  SHOTS '..S.strokes..'/'..COURSE.limit,'medium')
  g:line(33,87,447,87)
  if not confirm_new then
    g:rect(378,12,69,38)
    centered(g,412,23,'NEW','small')
  end
  if confirm_new then draw_confirm(g)
  elseif S.hole==9 and S.stage=='finished' then draw_summary(g)
  else draw_board(g) end

  if not confirm_new then
    if S.stage=='finished' then
      centered(g,240,662,'HOLE SOLVED - '..S.strokes..' SHOTS','medium')
      button(g,33,714,414,58,S.hole==9 and 'PLAY AGAIN' or 'NEXT HOLE')
    elseif S.stage=='failed' then
      centered(g,240,662,message or 'OUT OF SHOTS','medium')
      button(g,33,714,414,58,'RETRY HOLE')
    else
      centered(g,240,657,message or 'Choose a landing ring','small')
      centered(g,240,684,'LONG DRIVES LEFT: '..S.drives,'medium')
      local xs={33,174,315}
      for i=1,#CLUBS do
        local club=CLUBS[i]
        button(g,xs[i],714,132,58,club.name..' '..club.distance)
        if i==S.club then g:rect(xs[i]+3,717,126,52) end
      end
    end
  end
end

local function inside(x, y, bx, by, bw, bh)
  return x >= bx and x < bx + bw and y >= by and y < by + bh
end

local function tap(x,y)
  if confirm_new then
    if inside(x,y,55,410,170,65) then confirm_new=false;message=nil
    elseif inside(x,y,255,410,170,65) then start_round(step_rng(S.rng)) end
    return
  end
  if inside(x,y,378,12,69,38) then confirm_new=true;return end
  if S.stage=='finished' then
    if inside(x,y,33,714,414,58) then next_hole() end
    return
  elseif S.stage=='failed' then
    if inside(x,y,33,714,414,58) then reset_hole() end
    return
  end
  for i,x0 in ipairs({33,174,315}) do
    if inside(x,y,x0,714,132,58) then select_club(i);return end
  end
  if inside(x,y,BX,BY,COLS*CELL,ROWS*CELL) then
    local cx=math.floor((x-BX)/CELL)+1
    local cy=math.floor((y-BY)/CELL)+1
    shoot(cx,cy)
  end
end

local function refresh()
  if CTX then pcall(function() CTX:invalidate() end) end
end

function on_load(c)
  CTX = c or ctx
  local ok, err = pcall(function()
    if not restore() then
      local seed = 13579
      if CTX and CTX.clock then
        local a, n = pcall(function() return CTX.clock:millis() end)
        if a and type(n) == 'number' then seed = seed + n end
        local b, now = pcall(function() return CTX.clock:now() end)
        if b and type(now) == 'table' then seed = seed + (tonumber(now.epoch_sec) or 0) end
      end
      start_round(seed)
    end
  end)
  if not ok then ERR = tostring(err) end
end

function on_draw(c, g)
  if c then CTX = c end
  if not g then return end
  if ERR then
    g:clear(0)
    g:text(25, 30, 'POCKET GOLF - ERROR')
    g:text(25, 75, ERR:sub(1, 42))
    return
  end
  local ok, err = pcall(function() draw(g) end)
  if not ok then
    ERR = tostring(err)
    pcall(function()
      g:clear(0)
      g:text(25, 30, 'POCKET GOLF - ERROR')
      g:text(25, 75, ERR:sub(1, 42))
    end)
  end
end

function on_input(c, ev)
  if c then CTX = c end
  if ERR or type(ev) ~= 'table' then return false end
  local ok, err = pcall(function()
    if ev.type == 'pointer' then
      if ev.phase ~= 'up' then return end
      if ev.gesture and ev.gesture ~= 'tap' and ev.gesture ~= 'double_tap' then return end
      tap(ev.x or -1, ev.y or -1)
    elseif ev.type == 'touch' then
      if ev.gesture == 'tap' or ev.gesture == 'double_tap' then tap(ev.x or -1, ev.y or -1) end
    elseif ev.type == 'key' then
      if ev.phase and ev.phase ~= 'down' then return end
      if ev.state and ev.state ~= 'down' then return end
      if ev.key == 'up' or ev.key == 'down' then
        local now = tonumber(ev.time_ms)
        if not now and CTX and CTX.clock then
          local a, n = pcall(function() return CTX.clock:millis() end)
          if a then now = tonumber(n) end
        end
        if now and now - last_key_ms >= 0 and now - last_key_ms < 220 then return end
        last_key_ms = now or last_key_ms
        if not confirm_new then
          if S.stage=='finished' then next_hole()
          elseif S.stage=='failed' then reset_hole()
          else select_club(((S.club - 1 + (ev.key=='up' and 1 or -1) + #CLUBS) % #CLUBS) + 1) end
        end
      end
    end
  end)
  if not ok then ERR = tostring(err) end
  refresh()
  return true
end

function on_leave()
  if S then save() end
end

-- Pure rules inspection for desktop tests. Never provided by the device.
if rawget(_G,'__TEST') then
  __TEST.api={
    generate=make_course,
    begin=start_round,
    state=function() return S end,
    course=function() return COURSE end,
    shoot=shoot,
    legal=legal_moves,
    select=select_club,
    targets=targets,
    solve=shortest_path,
    clubs=CLUBS,
    retry=reset_hole,
    next_hole=next_hole,
    totals=totals,
    rng=step_rng,
    restore=restore,
    tap=tap
  }
end
