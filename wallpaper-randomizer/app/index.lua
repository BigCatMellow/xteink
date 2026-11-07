-- Recovery diagnostics for a device-confirmed rendering crash.
-- Opening this build clears its custom lock-screen registration.
local W,H=480,800
local Probe=require('probe')
local C, names, status, preview, photo=nil,{},nil,false,nil

local function accepted(s)
  return type(s)=='string' and #s<=96 and
    not s:find('[/%c\\]') and s:lower():match('%.xth$')~=nil
end

local function scan()
  local seen,out={},{}
  local function add(list)
    if type(list)~='table' then return end
    for _,entry in ipairs(list) do
      local name=type(entry)=='table' and entry.name or entry
      if accepted(name) and not seen[name] then
        seen[name]=true;out[#out+1]=name
      end
    end
  end
  if C.files then
    local ok,v=pcall(function() return C.files:list() end)
    if ok then add(v) end
  end
  if C.storage then
    local ok,v=pcall(function() return C.storage:list() end)
    if ok then add(v) end
  end
  table.sort(out)
  names=out
end

local function read(name)
  if C.files then
    local ok,v=pcall(function() return C.files:read(name) end)
    if ok and type(v)=='string' then return v end
  end
  if C.storage then
    local ok,v=pcall(function() return C.storage:read(name) end)
    if ok and type(v)=='string' then return v end
  end
  return nil
end

local function release()
  if photo then pcall(function() photo:release() end) end
  photo=nil
end

local function show_preview()
  if #names==0 then status='Add XTHs to the app folder';return end
  release();preview=false
  local img,message=Probe.run(C,'tile',names[1],read)
  status=message
  if img then photo=img;preview=true end
end

local function test_png()
  release();preview=false
  local img,message=Probe.run(C,'png',nil,read)
  status=message
  if img then photo=img;preview=true end
end

local function redraw()
  if C then pcall(function() C:invalidate() end) end
end

function on_load(c)
  C=c or ctx
  if C.lockscreen then pcall(function() C.lockscreen:clear_default() end) end
  scan()
  status='Full renderer paused after device crash'
end

function on_draw(c,g)
  if c then C=c end
  if not g then return end
  g:clear(0)
  if preview and photo then
    local ok,result,err=pcall(function() return photo:draw(g) end)
    if ok and result then
      g:text(30,700,'Tap to return',{font=C.fonts and C.fonts.small})
      return
    end
    status='Preview failed: '..tostring(err or result)
    release();preview=false;g:clear(0)
  end
  local medium=C.fonts and C.fonts.medium
  local large=C.fonts and C.fonts.large
  local small=C.fonts and C.fonts.small
  g:text(30,50,'WALLPAPER',{font=large})
  g:text(30,87,'DIAGNOSTICS 0.4.2',{font=medium})
  g:line(30,134,450,134)
  g:text(30,173,tostring(#names)..' XTH images ready',{font=medium})
  g:text(30,230,'Automatic wallpaper is paused.',{font=medium})
  g:text(30,263,'Test one small image at a time.',{font=medium})
  g:text(30,310,'First: TEST PNG. If it displays,',{font=small})
  g:text(30,338,'return here and try TEST TILE.',{font=small})
  g:rect(30,420,420,66)
  g:text(120,441,'TEST SMALL PNG',{font=medium})
  g:rect(30,508,200,64)
  g:text(55,527,'CHECK XTH',{font=medium})
  g:rect(247,508,203,64)
  g:text(272,527,'TEST TILE',{font=medium})
  g:line(30,625,450,625)
  g:text(30,660,(status or ''):sub(1,39),{font=small})
  g:text(30,734,'Checkpoints saved for crash diagnosis.',{font=small})
end

function on_input(c,ev)
  if c then C=c end
  if type(ev)~='table' then return false end
  if ev.type=='pointer' and ev.phase~='up' then return true end
  if ev.type~='pointer' and ev.type~='touch' then return false end
  if ev.gesture and ev.gesture~='tap' and ev.gesture~='double_tap' then return true end
  local x,y=tonumber(ev.x) or -1,tonumber(ev.y) or -1
  if preview then
    preview=false;release();redraw();return true
  end
  if x>=30 and x<450 and y>=420 and y<486 then
    test_png()
  elseif x>=30 and x<230 and y>=508 and y<572 then
    scan();release();preview=false
    local _,message=Probe.run(C,'file',names[1],read)
    status=message
  elseif x>=247 and x<450 and y>=508 and y<572 then
    show_preview()
  else return false end
  redraw()
  return true
end

function on_leave() release() end

if rawget(_G,'__TEST') then
  __TEST.main={
    scan=scan, names=function() return names end,
    status=function() return status end,
    is_preview=function() return preview end
  }
end
