local Wallpaper=require('wallpaper')
local Probe=require('probe')
local UI=require('ui')
local Quotes=require('quotes')
local C,names,missing,photo,preview_name,preview_quote,help,active,status,pending
local function release()
  if photo then photo:release();photo=nil end
end
local function redraw() if C then pcall(function() C:invalidate() end) end end
local function scan()
  names,missing=Wallpaper.scan(C)
  if #names==0 then status='No prepared images. Reconnect the card to add wallpapers.'
  elseif missing>0 then status=tostring(missing)..' images still need preparation on the computer.'
  elseif not active then status='Tap Enable to use these images as your sleep screen.'
  else status='Ready. Close this app and press power briefly to sleep.' end
end
local function preview()
  release()
  local picture,name=Wallpaper.find(C,names,preview_name,0)
  if picture then
    photo=picture;preview_name=name
    if Quotes.enabled(C) then preview_quote=Quotes.choose(C,{sequence=Wallpaper.history(C).sequence,quote=preview_quote})
    else preview_quote=nil end
    Probe.timing(C,picture.metrics)
    status=string.format('Preview loaded in %.2f seconds.',picture.metrics.total_ms/1000)
  else
    status='Could not load an image. Rescan or prepare the images again.'
    Wallpaper.diagnostics(C,{status='preview-error'})
  end
end
local function toggle()
  active=Wallpaper.is_active(C)
  if not C.lockscreen then status='This firmware does not expose sleep-screen controls.';return end
  if not C.storage then status='App storage is unavailable. Sleep rotation needs saved history.';return end
  if active then
    local ok,value,err=pcall(function() return C.lockscreen:clear_default() end)
    active=Wallpaper.is_active(C)
    if not ok or value==false or (value==nil and err) or active~=false then
      status='Could not disable sleep rotation. Try again.'
    else status='Sleep rotation is off.' end
    return
  end
  -- Verify a real prepared image before opening the firmware's enable prompt.
  local test=Wallpaper.find(C,names,nil,0)
  if not test then status='Prepare at least one image before enabling sleep rotation.';return end
  test:release()
  local ok,value,err=pcall(function() return C.lockscreen:set_default() end)
  if not ok or value==false or (value==nil and err) then status='Could not open the sleep-screen prompt.';return end
  active=Wallpaper.is_active(C)
  pending=active~=true
  status=active and 'Enabled. Close this app and put the device to sleep.' or 'Approve the reader\'s Set as lock screen prompt.'
end
function on_load(c)
  release();C=c or ctx;help=false;preview_name=nil;preview_quote=nil;pending=false
  active=Wallpaper.is_active(C);scan()
end
function on_resume(c)
  C=c or C
  active=Wallpaper.is_active(C)
  if pending then
    status=active and 'Enabled. Close this app and put the device to sleep.' or 'Sleep rotation is off.'
    pending=false
  end
  redraw()
end
function on_draw(c,g)
  C=c or C
  if not g then return end
  g:clear(0)
  if photo then
    local ok,value=pcall(function() return photo:draw(g) end)
    if ok and value then
      if preview_quote then
        local quoted=pcall(Quotes.draw,g,C,preview_quote)
        if not quoted then status='Quote preview unavailable; wallpaper is still usable.' end
      end
      return
    end
    release();status='Could not display this image. Rescan and try again.'
    g:clear(0)
  end
  if help then
    UI.text(g,C,24,30,'HOW TO USE','large')
    UI.paragraph(g,C,24,108,432,96,'1. In Settings > Display, set Off wallpaper to Default.','small')
    UI.paragraph(g,C,24,218,432,96,'2. Tap Enable, then approve the reader\'s Set as lock screen prompt.','small')
    UI.paragraph(g,C,24,332,432,120,'3. Close this app. Press power briefly to sleep. Wake and sleep again for another image.','small')
    UI.paragraph(g,C,24,476,432,144,'4. Quotes appear over your wallpapers. Put one quote per line in XTApps/wallrandom/files/quotes.txt. Add | Author if wanted. Quotes stay fixed through timer wakes.','small')
    UI.button(g,C,24,680,432,66,'BACK')
    return
  end
  active=Wallpaper.is_active(C)
  UI.text(g,C,24,28,'WALLPAPER','large')
  UI.text(g,C,24,70,'Random image on each sleep.','small')
  g:line(24,112,456,112)
  UI.text(g,C,24,138,'Sleep rotation: '..(active==nil and 'UNKNOWN' or active and 'ON' or 'OFF'),'medium')
  UI.text(g,C,24,178,tostring(#names)..' images prepared','medium')
  local last=preview_name or Wallpaper.history(C).last
  UI.text(g,C,24,218,last and ('Last image: '..last) or 'No wallpaper selected yet.','small')
  UI.button(g,C,24,262,432,66,active and 'DISABLE' or 'ENABLE',true)
  UI.button(g,C,24,344,432,66,'PREVIEW NEXT')
  UI.button(g,C,24,426,208,62,'RESCAN')
  UI.button(g,C,248,426,208,62,'HOW TO USE')
  UI.button(g,C,24,508,432,66,Quotes.enabled(C) and 'QUOTES: ON' or 'QUOTES: OFF')
  g:line(24,586,456,586)
  UI.paragraph(g,C,24,604,432,52,'Upright quotes use open white space.','small')
  UI.paragraph(g,C,24,676,432,76,status or 'Ready.','small')
  UI.text(g,C,24,768,'0.6.3','small')
end
function on_input(c,ev)
  C=c or C
  if type(ev)~='table' then return false end
  if ev.type=='pointer' and ev.phase~='up' then return true end
  if ev.type~='pointer' and ev.type~='touch' then return false end
  if ev.gesture and ev.gesture~='tap' and ev.gesture~='double_tap' then return true end
  local x,y=tonumber(ev.x) or -1,tonumber(ev.y) or -1
  if photo then release();redraw();return true end
  if help then
    if x>=24 and x<456 and y>=680 and y<746 then help=false;redraw() end
    return true
  end
  if x<24 or x>=456 then return false end
  if y>=262 and y<328 then toggle()
  elseif y>=344 and y<410 then preview()
  elseif y>=426 and y<488 then
    if x<232 then scan() elseif x>=248 then help=true else return false end
  elseif y>=508 and y<574 then
    local enabled=not Quotes.enabled(C)
    local ok,why=Quotes.set_enabled(C,enabled)
    if ok then status=enabled and 'Quotes will appear on the next sleep.' or 'Quotes off. Wallpapers remain unchanged.'
    else status=why end
  else return false end
  redraw();return true
end
function on_leave() release() end
if rawget(_G,'__TEST') then
  __TEST.main={names=function() return names end,status=function() return status end,
    is_preview=function() return photo~=nil end,
    quote_enabled=function() return Quotes.enabled(C) end,
    preview_quote=function() return preview_quote end}
end
