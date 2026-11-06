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

-- The entire layout is reproducible from a seed and hole number.
-- Courses use adjoining rectangular tiles rather than scattered random hazards.
-- That keeps the geometry close to a paper-grid golf puzzle and the fairway traversable.
-- Every club has an exact distance; chance plays no role in taking a shot.
-- This creates a predictable shortest-path puzzle, not a dice-roll lottery.
local CLUBS = {
  { name='PUTT', distance=1 },
  { name='CHIP', distance=2 },
  { name='DRIVE', distance=4 },
}
local DIRECTIONS = { {-1,-1},{0,-1},{1,-1},{-1,0},{1,0},{-1,1},{0,1},{1,1} }

local function targets(course, x, y, club)
  local chosen = CLUBS[club]
  if not chosen then return {} end
  local lie = course.map[index(x, y)]
  -- Sand traps demand a one-square recovery; rough prevents long drives.
  if lie == 'sand' and club ~= 1 then return {} end
  if lie == 'rough' and club == 3 then return {} end
  local result = {}
  for _, dir in ipairs(DIRECTIONS) do
    local dx, dy = dir[1], dir[2]
    local blocked, nx, ny = false, x, y
    for step = 1, chosen.distance do
      nx, ny = x + dx*step, y + dy*step
      if not in_bounds(nx, ny) or course.map[index(nx,ny)] == 'tree' then
        blocked = true
        break
      end
    end
    if not blocked then
      local landing = course.map[index(nx,ny)]
      -- Water may be cleared in flight, but is never a safe landing square.
      if landing ~= 'water' and landing ~= 'tree' then
        result[#result+1] = {x=nx, y=ny}
      end
    end
  end
  return result
end

local function shortest_path(course)
  local q = {{x=course.tx,y=course.ty,moves=0}}
  local seen = {[index(course.tx,course.ty)]=true}
  local first = 1
  while first <= #q do
    local p=q[first];first=first+1
    if p.x==course.hx and p.y==course.hy then return p.moves end
    for club=1,#CLUBS do
      for _, v in ipairs(targets(course,p.x,p.y,club)) do
        local key=index(v.x,v.y)
        if not seen[key] then
          seen[key]=true
          q[#q+1]={x=v.x,y=v.y,moves=p.moves+1}
        end
      end
    end
  end
  return nil
end

local function make_course(seed, hole)
  local rng = (seed % MODULUS + hole * 7919) % MODULUS
  local function pick(n)
    rng = step_rng(rng)
    return rng % n
  end
  local map = {}
  for y = 1, ROWS do
    for x = 1, COLS do map[index(x, y)] = 'rough' end
  end

  local tx, hx = 3 + pick(4), 3 + pick(4)
  local center = tx
  for y = ROWS, 3, -1 do
    local target = math.floor(tx + (hx - tx) * (ROWS - y) / (ROWS - 2) + 0.5)
    if center < target then center = center + 1
    elseif center > target then center = center - 1 end
    -- Occasional one-cell detours make the paper fairway less mechanical.
    if y > 4 and y < ROWS - 1 and pick(5) == 0 then
      center = math.max(2, math.min(COLS - 2, center + (pick(2) == 0 and -1 or 1)))
    end
    local left = center - (y % 3 == 0 and 1 or 0)
    for x = left, center + 1 do
      if in_bounds(x, y) then map[index(x, y)] = 'fairway' end
    end
  end
  -- A small rectangular green and a guaranteed route at the top.
  for y = 1, 3 do
    for x = hx - 1, hx + 1 do
      if in_bounds(x, y) then map[index(x, y)] = 'green' end
    end
  end
  for x = math.min(center, hx), math.max(center, hx) do
    map[index(x, 3)] = 'green'
  end
  map[index(tx, ROWS)] = 'tee'
  map[index(hx, 2)] = 'cup'

  -- Sand and water occupy 2x2/3x2 tile patches, retaining hard corners.
  local function patch(tile, width, height)
    local x0, y0 = 1 + pick(COLS - width + 1), 2 + pick(ROWS - height - 2)
    for dy = 0, height - 1 do
      for dx = 0, width - 1 do
        local x, y = x0 + dx, y0 + dy
        if map[index(x, y)] == 'rough' then map[index(x, y)] = tile end
      end
    end
  end
  patch('water', 2, 2)
  patch('water', 2, 3)
  patch('sand', 2, 2)
  patch('sand', 3, 2)

  -- Scattered triangular trees. Leave water/sand/fairway untouched.
  for n = 1, 9 do
    local x, y = 1 + pick(COLS), 1 + pick(ROWS)
    if map[index(x, y)] == 'rough' then map[index(x, y)] = 'tree' end
  end
  local course = { map=map, tx=tx, ty=ROWS, hx=hx, hy=2 }
  local target = shortest_path(course)
  if not target then
    -- Guaranteed contiguous rescue route; every square is puttable if needed.
    for y=2,ROWS-1 do map[index(tx,y)]='fairway' end
    for x=math.min(tx,hx),math.max(tx,hx) do map[index(x,2)]='green' end
    map[index(tx,ROWS)]='tee'
    map[index(hx,2)]='cup'
    target=shortest_path(course)
  end
  course.par = target or 10
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
  local fields = {
    'version=2', 'seed=' .. S.seed, 'rng=' .. S.rng,
    'hole=' .. S.hole, 'x=' .. S.x, 'y=' .. S.y,
    'strokes=' .. S.strokes, 'club=' .. S.club,
    'stage=' .. S.stage, 'scores=' .. table.concat(S.scores, ','),
    'pars=' .. table.concat(S.pars, ',')
  }
  pcall(function() CTX.storage:write('save.txt', table.concat(fields, '\n')) end)
end

local function start_round(seed)
  seed = (integer(seed,1) % (MODULUS-1))+1
  S = { seed=seed, rng=step_rng(seed), hole=1, x=0, y=0,
        strokes=0, club=2, stage='aim',
        scores={0,0,0,0,0,0,0,0,0}, pars={0,0,0,0,0,0,0,0,0} }
  COURSE=make_course(S.seed,S.hole)
  S.x,S.y=COURSE.tx,COURSE.ty
  confirm_new,message=false,'Select club and landing'
  save()
end

local function restore()
  local ok,data=pcall(function() return CTX.storage:read('save.txt') end)
  if not ok or type(data)~='string' then return false end
  local fields={}
  for key,val in data:gmatch('([%w_]+)=([^\n]*)') do fields[key]=val end
  if fields.version~='2' then return false end -- reset incompatible dice save
  local seed, rng=integer(fields.seed,0),integer(fields.rng,-1)
  local hole=integer(fields.hole,0)
  local x,y=integer(fields.x,0),integer(fields.y,0)
  local strokes=integer(fields.strokes,-1)
  local club=integer(fields.club,0)
  local stage=fields.stage
  if seed<1 or seed>=MODULUS or rng<0 or rng>=MODULUS or
     hole<1 or hole>9 or not in_bounds(x,y) or
     strokes<0 or strokes>999 or club<1 or club>#CLUBS or
     (stage~='aim' and stage~='finished') then return false end
  local scores,pars={},{}
  for num in (fields.scores or ''):gmatch('%d+') do scores[#scores+1]=tonumber(num) end
  for num in (fields.pars or ''):gmatch('%d+') do pars[#pars+1]=tonumber(num) end
  if #scores~=9 or #pars~=9 then return false end
  for i=1,9 do
    if scores[i]<0 or scores[i]>999 or pars[i]<0 or pars[i]>99 or
       (scores[i]>0 and pars[i]==0) then return false end
  end
  S={seed=seed,rng=rng,hole=hole,x=x,y=y,strokes=strokes,
     club=club,stage=stage,scores=scores,pars=pars}
  COURSE=make_course(seed,hole)
  if COURSE.map[index(x,y)]=='tree' or COURSE.map[index(x,y)]=='water' then return false end
  if (stage=='finished') ~= (x==COURSE.hx and y==COURSE.hy) then return false end
  confirm_new,message=false,nil
  return true
end

local function legal_moves()
  if S.stage~='aim' then return {} end
  return targets(COURSE,S.x,S.y,S.club)
end

local function select_club(n)
  if S.stage~='aim' or n<1 or n>#CLUBS then return false end
  S.club=n
  message=CLUBS[n].name .. ' ' .. CLUBS[n].distance .. ' squares'
  save()
  return true
end

local function shoot(x,y)
  if S.stage~='aim' then return false end
  local legal=false
  for _,move in ipairs(legal_moves()) do
    if move.x==x and move.y==y then legal=true;break end
  end
  if not legal then message='Choose a ringed dot';return false end
  S.x,S.y=x,y
  S.strokes=S.strokes+1
  if x==COURSE.hx and y==COURSE.hy then
    S.stage='finished'
    S.scores[S.hole]=S.strokes
    S.pars[S.hole]=COURSE.par
    message='Holed in ' .. S.strokes .. '! Target ' .. COURSE.par
  else
    message='Choose your next shot'
  end
  save()
  return true
end

local function next_hole()
  if S.stage~='finished' then return false end
  if S.hole==9 then start_round(step_rng(S.rng));return true end
  S.hole=S.hole+1
  S.strokes,S.club,S.stage=0,2,'aim'
  COURSE=make_course(S.seed,S.hole)
  S.x,S.y=COURSE.tx,COURSE.ty
  message='New puzzle: choose a club'
  save()
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

  -- The only targets shown are real, valid landing places for this die roll.
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
  put(g,33,49,'HOLE ' .. S.hole .. '/9  TARGET ' .. COURSE.par .. '  SHOTS ' .. S.strokes,'medium')
  g:line(33,87,447,87)
  -- A compact NEW button leaves enough space for the course and club picker.
  if not confirm_new then
    g:rect(378,12,69,38)
    centered(g,412,23,'NEW','small')
  end
  if confirm_new then draw_confirm(g)
  elseif S.hole==9 and S.stage=='finished' then draw_summary(g)
  else draw_board(g) end

  if not confirm_new then
    if S.stage=='finished' then
      centered(g,240,665,message or 'Hole complete','medium')
      button(g,33,714,414,58,S.hole==9 and 'PLAY AGAIN' or 'NEXT HOLE')
    else
      local club=CLUBS[S.club]
      local status=message or 'Select a club, then tap a ring'
      centered(g,240,659,status,'small')
      centered(g,240,684,'EXACT SHOTS:  1 / 2 / 4 SQUARES','small')
      local xs={33,174,315}
      for i=1,#CLUBS do
        local b=CLUBS[i]
        button(g,xs[i],714,132,58,b.name .. ' ' .. b.distance)
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
if rawget(_G, '__TEST') then
  __TEST.api = {
    generate = make_course,
    begin = start_round,
    state = function() return S end,
    course = function() return COURSE end,
    shoot = shoot,
    legal = legal_moves,
    select = select_club,
    targets = targets,
    solve = shortest_path,
    clubs = CLUBS,
    next_hole = next_hole,
    totals = totals,
    rng = step_rng,
    restore = restore,
    tap = tap
  }
end
