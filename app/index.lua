-- Pocket Golf: original, offline dice golf for XTOS Licorice API 2.9.
-- Portrait screen: 480 x 800. No network, images, fonts, or animations.
-- All game state is stored in the app's private save.txt.
local COLS, ROWS = 9, 12
local CELL, BX, BY = 40, 60, 144
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
local function make_course(seed, hole)
  local rng = (seed % MODULUS + hole * 7919) % MODULUS
  local function pick(n)
    rng = step_rng(rng)
    return rng % n
  end
  local map = {}
  for y = 1, ROWS do
    for x = 1, COLS do
      local n = pick(100)
      map[index(x, y)] = n < 8 and 'water' or (n < 16 and 'tree' or
                           (n < 29 and 'sand' or 'rough'))
    end
  end
  local tx, hx = 3 + pick(4), 3 + pick(4)
  for y = ROWS, 2, -1 do
    local t = (ROWS - y) / (ROWS - 2)
    local middle = math.floor(tx + (hx - tx) * t + 0.5)
    for x = middle - 1, middle + 1 do
      if in_bounds(x, y) then map[index(x, y)] = 'fairway' end
    end
  end
  for y = 1, 3 do
    for x = hx - 1, hx + 1 do
      if in_bounds(x, y) then map[index(x, y)] = 'green' end
    end
  end
  map[index(tx, ROWS)] = 'tee'
  map[index(hx, 2)] = 'cup'
  -- Avoid isolating a legal landing square with eight obstructed neighbours.
  for y = 1, ROWS do
    for x = 1, COLS do
      local v = map[index(x, y)]
      if v ~= 'tree' and v ~= 'water' then
        local open = false
        for dy = -1, 1 do
          for dx = -1, 1 do
            local nx, ny = x + dx, y + dy
            if (dx ~= 0 or dy ~= 0) and in_bounds(nx, ny) then
              local n = map[index(nx, ny)]
              if n ~= 'tree' and n ~= 'water' then open = true end
            end
          end
        end
        if not open then
          local nx = x < COLS and x + 1 or x - 1
          map[index(nx, y)] = 'rough'
        end
      end
    end
  end
  return { map = map, tx = tx, ty = ROWS, hx = hx, hy = 2,
           par = (hole % 3 == 0) and 4 or 3 }
end

local function totals()
  local strokes, par = 0, 0
  for i = 1, 9 do
    if S.scores[i] > 0 then
      strokes = strokes + S.scores[i]
      par = par + ((i % 3 == 0) and 4 or 3)
    end
  end
  return strokes, par
end

local function save()
  if not CTX or not CTX.storage then return end
  local fields = {
    'seed=' .. S.seed, 'rng=' .. S.rng,
    'hole=' .. S.hole, 'x=' .. S.x, 'y=' .. S.y,
    'strokes=' .. S.strokes, 'die=' .. S.die,
    'stage=' .. S.stage, 'scores=' .. table.concat(S.scores, ',')
  }
  pcall(function() CTX.storage:write('save.txt', table.concat(fields, '\n')) end)
end

local function start_round(seed)
  seed = (integer(seed, 1) % (MODULUS - 1)) + 1
  S = { seed = seed, rng = step_rng(seed), hole = 1,
        x = 0, y = 0, strokes = 0, die = 0, stage = 'roll',
        scores = { 0, 0, 0, 0, 0, 0, 0, 0, 0 } }
  COURSE = make_course(S.seed, S.hole)
  S.x, S.y = COURSE.tx, COURSE.ty
  confirm_new, message = false, 'Tap ROLL to begin'
  save()
end

local function restore()
  local ok, data = pcall(function() return CTX.storage:read('save.txt') end)
  if not ok or type(data) ~= 'string' then return false end
  local fields = {}
  for key, val in data:gmatch('([%w_]+)=([^\n]*)') do fields[key] = val end
  local seed = integer(fields.seed, 0)
  local hole = integer(fields.hole, 0)
  local x, y = integer(fields.x, 0), integer(fields.y, 0)
  local strokes = integer(fields.strokes, -1)
  local die = integer(fields.die, -1)
  local rng = integer(fields.rng, -1)
  local stage = fields.stage
  if seed < 1 or seed >= MODULUS or hole < 1 or hole > 9 or
     not in_bounds(x, y) or strokes < 0 or strokes > 999 or
     die < 0 or die > 6 or rng < 0 or rng >= MODULUS or
     (stage ~= 'roll' and stage ~= 'aim' and stage ~= 'finished') then return false end
  local scores = {}
  for s in (fields.scores or ''):gmatch('%d+') do scores[#scores + 1] = tonumber(s) end
  if #scores ~= 9 then return false end
  for i = 1, 9 do if scores[i] < 0 or scores[i] > 999 then return false end end
  if (stage == 'aim' and die == 0) or (stage ~= 'aim' and die ~= 0) then return false end
  S = { seed=seed, rng=rng, hole=hole, x=x, y=y,
        strokes=strokes, die=die, stage=stage, scores=scores }
  COURSE = make_course(seed, hole)
  if COURSE.map[index(x, y)] == 'water' or COURSE.map[index(x, y)] == 'tree' then return false end
  confirm_new, message = false, nil
  return true
end

local DIRECTIONS = { {-1,-1}, {0,-1}, {1,-1}, {-1,0}, {1,0}, {-1,1}, {0,1}, {1,1} }

local function range()
  local lie = COURSE.map[index(S.x, S.y)]
  local bonus = lie == 'fairway' and 1 or (lie == 'sand' and -1 or 0)
  return math.max(1, math.min(7, S.die + bonus)), bonus
end

local function legal_moves()
  local result = {}
  if S.stage ~= 'aim' then return result end
  local max_dist = range()
  for _, dir in ipairs(DIRECTIONS) do
    local dx, dy = dir[1], dir[2]
    for dist = 1, max_dist do
      local nx, ny = S.x + dx * dist, S.y + dy * dist
      if not in_bounds(nx, ny) then break end
      local tile = COURSE.map[index(nx, ny)]
      if tile == 'tree' then break end -- tree stops the ball in flight
      if tile ~= 'water' then
        result[#result + 1] = { x=nx, y=ny }
      end
    end
  end
  return result
end

local function roll()
  if S.stage ~= 'roll' then return false end
  S.rng = step_rng(S.rng)
  S.die = (S.rng % 6) + 1
  S.stage = 'aim'
  message = 'Tap any ring to land'
  save()
  return true
end

local function shoot(x, y)
  if S.stage ~= 'aim' then return false end
  local legal = false
  for _, move in ipairs(legal_moves()) do
    if move.x == x and move.y == y then legal = true; break end
  end
  if not legal then message = 'Choose a ringed dot'; return false end
  S.x, S.y = x, y
  S.strokes = S.strokes + 1
  S.die = 0
  if x == COURSE.hx and y == COURSE.hy then
    S.stage = 'finished'
    S.scores[S.hole] = S.strokes
    message = 'In the hole! ' .. S.strokes .. ' strokes'
  else
    S.stage = 'roll'
    message = 'Nice shot. Roll again'
  end
  save()
  return true
end

local function next_hole()
  if S.stage ~= 'finished' then return false end
  if S.hole == 9 then
    start_round(step_rng(S.rng))
    return true
  end
  S.hole = S.hole + 1
  S.strokes, S.die, S.stage = 0, 0, 'roll'
  COURSE = make_course(S.seed, S.hole)
  S.x, S.y = COURSE.tx, COURSE.ty
  message = 'New hole. Tap ROLL'
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

local function draw_tile(g, x, y, tile)
  if tile == 'water' then
    for row = -1, 1 do
      local ry = y + row * 8
      g:line(x - 12, ry, x - 5, ry - 3)
      g:line(x - 5, ry - 3, x + 2, ry)
      g:line(x + 2, ry, x + 10, ry - 3)
    end
  elseif tile == 'tree' then
    g:circle(x, y - 4, 10)
    g:line(x, y + 6, x, y + 14)
    g:line(x - 4, y + 14, x + 4, y + 14)
  elseif tile == 'sand' then
    g:circle(x - 9, y - 5, 2)
    g:circle(x + 7, y - 8, 2)
    g:circle(x - 1, y + 9, 2)
    g:circle(x + 10, y + 6, 2)
  elseif tile == 'rough' then
    g:line(x - 9, y + 6, x - 12, y - 2)
    g:line(x - 9, y + 6, x - 5, y - 3)
    g:line(x + 7, y + 8, x + 9, y - 1)
  elseif tile == 'tee' then
    centered(g, x, y - 12, 'T', 'small')
  elseif tile == 'cup' then
    g:circle(x, y + 5, 6)
    g:line(x, y - 14, x, y + 4)
    g:line(x, y - 14, x + 13, y - 10)
    g:line(x + 13, y - 10, x, y - 6)
  elseif tile == 'green' then
    g:circle(x, y, 4)
  end
end

local function draw_board(g)
  g:rect(BX, BY, COLS * CELL, ROWS * CELL)
  for y = 0, ROWS do
    for x = 0, COLS do
      g:circle(BX + x * CELL, BY + y * CELL, 1)
    end
  end
  for y = 1, ROWS do
    for x = 1, COLS do
      local cx = BX + (x - 1) * CELL + CELL / 2
      local cy = BY + (y - 1) * CELL + CELL / 2
      draw_tile(g, cx, cy, COURSE.map[index(x, y)])
    end
  end
  if S.stage == 'aim' then
    for _, move in ipairs(legal_moves()) do
      local cx = BX + (move.x - 0.5) * CELL
      local cy = BY + (move.y - 0.5) * CELL
      g:circle(cx, cy, 17, { line_width=2 })
    end
  end
  local px, py = BX + (S.x - 0.5) * CELL, BY + (S.y - 0.5) * CELL
  g:circle(px, py, 9, { fill=true })
  g:circle(px, py, 13)
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
  put(g, 28, 18, 'POCKET GOLF', 'large')
  put(g, 28, 60, 'HOLE ' .. S.hole .. '/9  PAR ' .. COURSE.par .. '  SHOTS ' .. S.strokes, 'medium')
  local total, par = totals()
  put(g, 28, 96, 'SCORECARD  ' .. total .. ' / PAR ' .. par, 'small')
  g:line(28, 129, 452, 129)
  if confirm_new then
    draw_confirm(g)
  elseif S.hole == 9 and S.stage == 'finished' then
    draw_summary(g)
  else
    draw_board(g)
    put(g, 42, 633, '~ water   o tree   : sand   T tee', 'small')
  end
  local status = message or 'Tap ROLL to begin'
  if not confirm_new and S.stage == 'aim' then
    local max_dist, bonus = range()
    local change = bonus > 0 and ' (+1)' or (bonus < 0 and ' (-1)' or '')
    status = 'DIE ' .. S.die .. change .. '  RANGE ' .. max_dist
  end
  centered(g, 240, 666, status, 'small')
  if not confirm_new then
    button(g, 28, 711, 132, 56, 'NEW')
    local label = (S.stage == 'finished') and
                  (S.hole == 9 and 'AGAIN' or 'NEXT') or
                  (S.stage == 'aim' and 'TAP A RING' or 'ROLL')
    button(g, 180, 711, 272, 56, label)
  end
  centered(g, 240, 779, 'One hole at a time', 'small')
end

local function inside(x, y, bx, by, bw, bh)
  return x >= bx and x < bx + bw and y >= by and y < by + bh
end

local function tap(x, y)
  if confirm_new then
    if inside(x,y,55,410,170,65) then confirm_new=false; message=nil
    elseif inside(x,y,255,410,170,65) then start_round(step_rng(S.rng))
    end
    return
  end
  if inside(x,y,28,711,132,56) then
    confirm_new = true
    return
  end
  if inside(x,y,180,711,272,56) then
    if S.stage == 'roll' then roll()
    elseif S.stage == 'finished' then next_hole()
    end
    return
  end
  if S.stage == 'aim' and inside(x,y,BX,BY,COLS*CELL,ROWS*CELL) then
    local cx = math.floor((x - BX) / CELL) + 1
    local cy = math.floor((y - BY) / CELL) + 1
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
          if S.stage == 'roll' then roll()
          elseif S.stage == 'finished' then next_hole() end
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
    roll = roll,
    shoot = shoot,
    legal = legal_moves,
    range = range,
    next_hole = next_hole,
    totals = totals,
    rng = step_rng,
    restore = restore,
    tap = tap
  }
end
