-- Shared catalogue, JPEG renderer and transactional sleep history.
local Probe=require('probe')
local M={interval=3600}
function M.read(c,name)
  for _,store in ipairs({c.files or false,c.storage or false}) do
    if store then
      local ok,value=pcall(function() return store:read(name) end)
      if ok and type(value)=='string' then return value end
    end
  end
end
local function usable(name)
  return type(name)=='string' and #name<=96 and not name:find('[/%c\\]') and
    not name:find('%s') and name:lower():match('%.xth$')~=nil
end
local function exists(c,name,present)
  if present[name] then return true end
  -- Some hosts cap directory listings. Check derived names directly rather
  -- than hiding prepared originals that appeared earlier in the listing.
  for _,store in ipairs({c.files or false,c.storage or false}) do
    if store then
      local ok,value=pcall(function() return store:exists(name) end)
      if ok and value==true then return true end
      local sized,size=pcall(function() return store:size(name) end)
      if sized and type(size)=='number' and size>=0 then return true end
    end
  end
  return false
end
function M.scan(c)
  local present,sources,ready={},{},{}
  for _,store in ipairs({c.files or false,c.storage or false}) do
    if store then
      local ok,items=pcall(function() return store:list() end)
      if ok and type(items)=='table' then
        for _,item in ipairs(items) do
          local name=type(item)=='table' and item.name or item
          if type(name)=='string' then present[name]=true end
        end
      end
    end
  end
  for name in pairs(present) do if usable(name) then sources[#sources+1]=name end end
  table.sort(sources)
  for _,name in ipairs(sources) do
    local base=Probe.jpeg_prefix(name)
    if exists(c,base..'.jpg',present) and exists(c,base..'.idx',present) then ready[#ready+1]=name end
  end
  return ready,#sources-#ready
end
function M.history(c)
  local old=M.read(c,'rotation.txt') or ''
  local sequence=tonumber(old:match('sequence=(%d+)')) or 0
  if sequence~=sequence or sequence==math.huge then sequence=0 end
  sequence=math.floor(sequence)%100000000
  local last=old:match('last=([^\r\n]+)')
  return {sequence=sequence,last=usable(last) and last or nil}
end
function M.choose(n,last,seq,tick)
  if n==0 then return nil end
  if n==1 then return 1 end
  -- Every integer intermediate is below 1.12 billion on 32-bit Lua.
  -- Reduce clock/sequence BEFORE multiplication or addition.
  local salt=((math.floor(tick or 0)%8388593)+(seq%8388593)*131+1037)%8388593
  local index=(salt%(last and (n-1) or n))+1
  if last and index>=last then index=index+1 end
  return index
end
function M.seed(c)
  local seed=0
  local ok,value=pcall(function() return c.clock:millis() end)
  if ok then seed=(tonumber(value) or 0)%8388593 end
  local ok2,date=pcall(function() return c.clock:now() end)
  if ok2 and type(date)=='table' then seed=(seed+(tonumber(date.epoch_sec) or 0)%8388593)%8388593 end
  return math.floor(seed)
end
function M.order(names,last,sequence,tick)
  local others,previous={},nil
  for _,name in ipairs(names) do
    if name==last then previous=name else others[#others+1]=name end
  end
  local out={}
  local first=M.choose(#others,nil,sequence,tick)
  if first then
    for offset=0,#others-1 do out[#out+1]=others[(first-1+offset)%#others+1] end
  end
  -- Only reuse the previous image if every alternative is unavailable/broken.
  if previous then out[#out+1]=previous end
  return out
end
function M.load(c,name)
  return Probe.run(c,'jpeg',name,function(file) return M.read(c,file) end,{quiet=true})
end
function M.find(c,names,last,sequence)
  if not c.image then return nil,nil,'Image decoder unavailable' end
  local failure
  for _,name in ipairs(M.order(names,last,sequence,M.seed(c))) do
    local picture,err=M.load(c,name)
    if picture then return picture,name end
    failure=err
  end
  return nil,nil,failure or 'No prepared wallpapers available'
end
function M.commit(c,name,history)
  if not c.storage then return nil,'App storage unavailable' end
  local text='sequence='..tostring((history.sequence+1)%100000000)..'\nlast='..name..'\n'
  local ok,value,err=pcall(function() return c.storage:write('rotation.txt',text) end)
  if not ok or value==false or (value==nil and err) then return nil,tostring(err or value) end
  if M.read(c,'rotation.txt')~=text then return nil,'Cannot save wallpaper history' end
  return true
end
function M.diagnostics(c,state)
  if not c.storage then return end
  local device=c.device or {}
  local text='reason='..tostring(c.lock and c.lock.reason)..'\ninterval='..
    tostring(c.lock and c.lock.interval_sec)..'\nframe='..tostring(state.frame)..
    '\nstatus='..tostring(state.status)..'\nload_ms='..tostring(state.load_ms or 0)..
    '\nfirmware='..tostring(device.firmware)..'\nmodel='..tostring(device.model)..
    '\nerror='..tostring(state.error or ''):gsub('[\r\n]',' '):sub(1,240)..'\n'
  pcall(function() c.storage:write('diagnostics.txt',text) end)
end
function M.is_active(c)
  local ok,value=pcall(function() return c.lockscreen:is_default() end)
  if ok and type(value)=='boolean' then return value end
  return nil
end
return M
