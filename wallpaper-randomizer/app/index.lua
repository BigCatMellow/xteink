-- Recovery diagnostics for a device-confirmed rendering crash.
-- Opening this build clears its custom lock-screen registration.
local W,H=480,800
local Probe=require('probe')
local XTH=require('xth')
local C, names, status, preview, photo=nil,{},nil,false,nil
local building=false
local preview_full=false
local generation=0

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
  generation=generation+1;building=false;preview_full=false
  if photo then pcall(function() photo:release() end) end
  photo=nil
end

local function show_full()
  if #names==0 then status='Add XTHs to the app folder';return end
  release();preview=false
  local token=generation
  local owner=C
  local raw=read(names[1])
  if not raw then status='Cannot read '..names[1];return end
  Probe.note(C,'full-preview-start',names[1])
  building=true;status='Building off-screen; please wait'
  local picture,err=XTH.compose(C,raw,function(result,message)
    if token~=generation then if result then result:release() end;return end
    building=false
    if result then
      photo=result;preview=true;preview_full=true
      if result.metrics then
        Probe.timing(owner,result.metrics)
        status=string.format('%.1fs / %d cached strips',(result.metrics.total_ms or 0)/1000,result.metrics.cache_hits or 0)
      else status='Full preview ready' end
    else photo=nil;preview=false;status=message end
    pcall(function() owner:invalidate() end)
  end,Probe.composer_log(owner),{name=names[1]})
  if not picture then building=false;status=err;return end
  photo=picture
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

local function show_quick()
  if #names==0 then status='Add XTHs to the app folder';return end
  release();preview=false
  local img,message=Probe.run(C,'jpeg',names[1],read)
  status=message
  if img then
    photo=img;preview=true;preview_full=true
    Probe.timing(C,img.metrics)
    status=string.format('%.2fs / maximum-quality JPEG',(img.metrics.total_ms or 0)/1000)
  end
end

local function redraw()
  if C then pcall(function() C:invalidate() end) end
end

function on_load(c)
  release();preview=false
  C=c or ctx
  if C.lockscreen then pcall(function() C.lockscreen:clear_default() end) end
  scan()
  status='Cache preview; automatic mode paused'
end

function on_draw(c,g)
  if c then C=c end
  if not g then return end
  g:clear(0)
  if preview and photo then
    local ok,result,err=pcall(function() return photo:draw(g) end)
    if ok and result then
      if not preview_full then g:text(30,700,'Tap to return',{font=C.fonts and C.fonts.small}) end
      return
    end
    status='Preview failed: '..tostring(err or result)
    release();preview=false;g:clear(0)
  end
  local medium=C.fonts and C.fonts.medium
  local large=C.fonts and C.fonts.large
  local small=C.fonts and C.fonts.small
  g:text(30,50,'WALLPAPER',{font=large})
  g:text(30,87,'QUICK PREVIEW 0.4.6',{font=medium})
  g:line(30,134,450,134)
  g:text(30,173,tostring(#names)..' XTH images ready',{font=medium})
  g:text(30,230,'Automatic wallpaper is paused.',{font=medium})
  g:text(30,263,'Full preview builds off-screen.',{font=medium})
  g:text(30,310,'Maximum quality; full resolution.',{font=small})
  g:rect(30,336,420,66)
  g:text(120,357,'QUICK PREVIEW',{font=medium})
  g:rect(30,420,420,66)
  g:text(120,441,'FULL PREVIEW',{font=medium})
  g:rect(30,508,200,64)
  g:text(55,527,'TEST PNG',{font=medium})
  g:rect(247,508,203,64)
  g:text(272,527,'TEST TILE',{font=medium})
  g:line(30,625,450,625)
  g:text(30,660,(status or ''):sub(1,39),{font=small})
  g:text(30,734,'Render timings saved for comparison.',{font=small})
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
  if x>=30 and x<450 and y>=336 and y<402 then
    if not building then show_quick() end
  elseif x>=30 and x<450 and y>=420 and y<486 then
    if not building then show_full() end
  elseif x>=30 and x<230 and y>=508 and y<572 then
    test_png()
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
    is_preview=function() return preview end,
    is_building=function() return building end
  }
end
