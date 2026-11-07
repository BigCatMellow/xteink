-- One image per new sleep. Timer/other redraw sessions keep the saved image.
local Wallpaper=require('wallpaper')
local UI=require('ui')
local C,picture,picked,history,status,committed,reuse
local function release()
  if picture then picture:release();picture=nil end
end
function on_load(c)
  release();C=c or ctx;picked=nil;committed=false;status=nil
  if C.lock then pcall(function() C.lock:set_interval(Wallpaper.interval) end) end
  history=Wallpaper.history(C)
  local reason=C.lock and C.lock.reason
  reuse=reason=='timer' or (reason~='first' and history.last~=nil)
  if reuse then
    picked=history.last
    if picked then picture,status=Wallpaper.load(C,picked)
    else status='No previous sleep image' end
  else
    local names=Wallpaper.scan(C)
    picture,picked,status=Wallpaper.find(C,names,history.last,history.sequence+1)
  end
  if picture then status=nil end
  Wallpaper.diagnostics(C,{frame=picked,status=picture and 'loaded' or 'load-error',error=status,
    load_ms=picture and picture.metrics.total_ms})
end
function on_draw(c,g)
  if not g then return end
  local cc=c or C
  if picture then
    g:clear(0)
    local ok,value,err=pcall(function() return picture:draw(g) end)
    if ok and value then
      if not committed then
        local saved,why=true,nil
        if not reuse then saved,why=Wallpaper.commit(cc,picked,history) end
        Wallpaper.diagnostics(cc,{frame=picked,status=saved and 'rendered' or 'rendered-history-error',
          error=why,load_ms=picture.metrics.total_ms})
        committed=true
      end
      return
    end
    status=tostring(err or value);release()
    Wallpaper.diagnostics(cc,{frame=picked,status='draw-error',error=status})
  end
  g:clear(0)
  UI.text(g,cc,24,320,'Wallpaper unavailable','medium')
  UI.paragraph(g,cc,24,365,432,140,'Open Wallpaper Randomizer to preview or rescan your images.','small')
end
function on_tick() end
function on_input() return false end
function on_leave() release() end
if rawget(_G,'__TEST') then
  __TEST.lock={current=function() return picked end,error=function() return status end}
end
