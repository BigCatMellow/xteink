-- Recovery entry: automatic rendering is paused after a confirmed device crash.
-- The selection helpers are retained for future work and host tests only.
local W, H = 480, 800
local XTH=require('xth')
local IDLE_REFRESH_SEC = 31536000 -- request only; firmware may clamp this
local picked, picture, status = nil, nil, nil
local current_ctx

local function usable_name(s)
  return type(s)=='string' and #s<=96 and
    not s:find('[/%c\\]') and s:lower():match('%.xth$')~=nil
end

local function filenames(c)
  local seen, out = {}, {}
  local function ingest(items)
    if type(items)~='table' then return end
    for _, item in ipairs(items) do
      local name = type(item)=='table' and item.name or item
      if usable_name(name) and not seen[name] then
        seen[name]=true
        out[#out+1]=name
      end
    end
  end
  if c.files then
    local ok, v = pcall(function() return c.files:list() end)
    if ok then ingest(v) end
  end
  if c.storage then
    local ok, v = pcall(function() return c.storage:list() end)
    if ok then ingest(v) end
  end
  table.sort(out)
  return out
end

local function read(c, name)
  if c.files then
    local ok, s = pcall(function() return c.files:read(name) end)
    if ok and type(s)=='string' then return s end
  end
  if c.storage then
    local ok, s = pcall(function() return c.storage:read(name) end)
    if ok and type(s)=='string' then return s end
  end
  return nil
end

local function random_index(n, last, seq, tick)
  if n==0 then return nil end
  if n==1 then return 1 end
  -- Choose uniformly from n-1 indices excluding the previous one.
  -- seq is persistent, so even identical clock values do not freeze rotation.
  local salt = (math.floor(tick or 0) + seq*1664525 + 1013904223) % 4294967296
  local index_ = (salt % (last and (n-1) or n)) + 1
  if last and index_>=last then index_=index_+1 end
  return index_
end

local function session_seed(c)
  local t=0
  if c.clock then
    local ok, value=pcall(function() return c.clock:millis() end)
    if ok then t=t+(tonumber(value) or 0) end
    local ok2, now=pcall(function() return c.clock:now() end)
    if ok2 and type(now)=='table' then t=t+(tonumber(now.epoch_sec) or 0) end
  end
  return math.floor(t)
end

local function select(c)
  local names=filenames(c)
  if #names==0 then return nil, 'Add XTH files to the app folder.' end
  local old=read(c,'rotation.txt') or ''
  local seq=tonumber(old:match('sequence=(%d+)')) or 0
  local last=old:match('last=([^\n]+)')
  -- Firmware may wake a sleep screen on a timer. Keep the displayed image
  -- through those wakes instead of advancing the deck while asleep.
  if c.lock and c.lock.reason=='timer' then
    for _,name in ipairs(names) do if name==last then return name,nil end end
  end
  local last_index=nil
  for i,name in ipairs(names) do
    if name==last then last_index=i; break end
  end
  local index_=random_index(#names,last_index,seq+1,session_seed(c))
  local name=names[index_]
  if c.storage then
    local payload='sequence='..tostring((seq+1)%100000000)..'\nlast='..name..'\n'
    pcall(function() c.storage:write('rotation.txt',payload) end)
  end
  return name,nil
end

local function decode(c,name)
  local bytes=read(c,name)
  if not bytes then return nil,'Cannot read '..name end
  return XTH.open(c,bytes)
end

local function diagnostics(c,message)
  if not c or not c.storage then return end
  pcall(function() c.storage:write('diagnostics.txt',
    'reason='..tostring(c.lock and c.lock.reason)..'\ninterval='..
    tostring(c.lock and c.lock.interval_sec)..'\nframe='..tostring(picked)..
    '\nstatus='..tostring(message)..'\n') end)
end

function on_load(c)
  current_ctx=c or ctx
  if picture then pcall(function() picture:release() end) end
  picked,picture,status=nil,nil,nil
  -- Device evidence: renderer crashed; the host clamps the interval to 3600s.
  -- Disarm this entry while the user runs the single-image diagnostic tests.
  status='Wallpaper paused. Open app diagnostics.'
  if current_ctx.lockscreen then
    pcall(function() current_ctx.lockscreen:clear_default() end)
  end
  diagnostics(current_ctx,'disabled-after-device-crash')
end

function on_draw(c,g)
  if not g then return end
  local cc=c or current_ctx
  g:clear(0)
  if picture then
    local ok,result,err=pcall(function() return picture:draw(g) end)
    if ok and result then diagnostics(cc,'rendered');return end
    status='Render failed: '..tostring(err or result)
    pcall(function() picture:release() end)
    picture=nil
    g:clear(0)
    diagnostics(cc,status)
  end
  local font=cc and cc.fonts and cc.fonts.medium or nil
  local message=status or 'Wallpaper Randomizer: add XTHs'
  if font then g:text(22,355,message:sub(1,42),{font=font})
  else g:text(22,355,message:sub(1,42)) end
end

function on_tick() end
function on_input() return false end

function on_leave()
  if picture then
    pcall(function() picture:release() end)
    picture=nil
  end
end

if rawget(_G,'__TEST') then
  __TEST.lock={
    filenames=filenames, choose=random_index, select=select,
    current=function() return picked end,
    error=function() return status end
  }
end
