-- Wallpaper Randomizer management screen for XTOS Licorice.
-- Locking is opt-in; only the user pressing ENABLE invokes the host dialog.
local W,H=480,800
local C, names, status, preview, photo=nil,{},nil,false,nil

local function accepted(s)
  return type(s)=='string' and #s<=96 and
    not s:find('[/%c\\]') and s:lower():match('%.png$')~=nil
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
  if #names==0 then status='Run the XTH sync tool, then rescan';return end
  local last=read('rotation.txt') or ''
  local choice=last:match('last=([^\n]+)')
  local available=false
  for _,name in ipairs(names) do if name==choice then available=true end end
  if not available then choice=names[1] end
  local bytes=read(choice)
  if not bytes then status='Cannot read '..choice;return end
  local ok,img=pcall(function() return C.image:decode(bytes) end)
  if not ok or not img then status='Cannot decode '..choice;return end
  release();photo=img;preview=true;status=choice
end

local function set_lock()
  if not C.lockscreen then status='Lock screen API unavailable';return end
  local ok,err=pcall(function() return C.lockscreen:set_default() end)
  status=ok and 'Confirm the system lock-screen prompt' or ('Cannot enable: '..tostring(err))
end

local function redraw()
  if C then pcall(function() C:invalidate() end) end
end

function on_load(c)
  C=c or ctx
  scan()
  status=#names..' lossless PNG image(s) found'
end

function on_draw(c,g)
  if c then C=c end
  if not g then return end
  g:clear(0)
  if preview and photo then g:image(photo,0,0);return end
  local medium=C.fonts and C.fonts.medium
  local large=C.fonts and C.fonts.large
  local small=C.fonts and C.fonts.small
  g:text(30,50,'WALLPAPER',{font=large})
  g:text(30,87,'RANDOMIZER',{font=large})
  g:line(30,134,450,134)
  g:text(30,173,tostring(#names)..' lossless PNGs ready',{font=medium})
  g:text(30,230,'Each lock selects a new image.',{font=medium})
  g:text(30,263,'No immediate repeats.',{font=medium})
  g:text(30,310,'Use XTH sync; it writes PNGs to:',{font=small})
  g:text(30,338,'XTApps/wallrandom/files/',{font=small})
  g:rect(30,420,420,66)
  g:text(65,441,'ENABLE LOCK SCREEN',{font=medium})
  g:rect(30,508,200,64)
  g:text(74,527,'RESCAN',{font=medium})
  g:rect(247,508,203,64)
  g:text(283,527,'PREVIEW',{font=medium})
  g:line(30,625,450,625)
  g:text(30,660,(status or ''):sub(1,39),{font=small})
  g:text(30,734,'Tap ENABLE once, then approve.',{font=small})
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
    set_lock()
  elseif x>=30 and x<230 and y>=508 and y<572 then
    scan();status=#names..' lossless PNG image(s) found'
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
