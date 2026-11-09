-- Canonical game presentation. Contract and exceptions: docs/GAME_DESIGN.md.
local UI=require('ui')
local Typefaces=require('typefaces')
local Style=require('game_style')
local Theme={}
local fonts,retired,initialized,reason=nil,nil,false,nil
local function options(old,kind,w,h)
  local o={}
  for k,v in pairs(old or {}) do o[k]=v end
  if not o.fill then o.line_width=(o.line_width or 1)+Style.stroke_increment end
  if kind=='rect' and o.radius==nil then
    if o.fill then o.radius=math.min(Style.ink_radius,math.floor(math.min(w,h)/3))
    elseif w>=180 and h>=180 and w/h<1.2 and h/w<1.2 then
      o.radius=Style.board_radius
    elseif w>h*1.2 then
      o.radius=math.min(Style.control_radius,math.floor(math.min(w,h)/4))
    end
  end
  return o
end
function Theme.canvas(raw)
  local g={}
  function g:rect(x,y,w,h,o) return raw:rect(x,y,w,h,options(o,'rect',w,h)) end
  function g:line(x,y,xx,yy,o) return raw:line(x,y,xx,yy,options(o,'line')) end
  function g:circle(x,y,r,o) return raw:circle(x,y,r,options(o,'circle')) end
  return setmetatable(g,{__index=function(_,key)
    local method=raw[key]
    if type(method)=='function' then return function(_,...) return method(raw,...) end end
    return method
  end})
end
function Theme.release()
  if fonts then fonts:release() end
  if retired then retired:release() end
  fonts,retired,initialized,reason=nil,nil,false,nil
end
function Theme.state() return fonts,reason end
function Theme.draw(context,raw,draw)
  if not initialized and type(raw.image)=='function' then
    initialized=true
    fonts,reason=Typefaces.open(context)
  end
  local usable=fonts and type(raw.image)=='function'
  UI.set_theme(usable and fonts or nil,Style)
  local ok,err=pcall(draw,Theme.canvas(raw))
  UI.set_theme(nil,false)
  if not ok and usable then
    -- Earlier queued commands may still reference the images in this frame.
    retired=fonts;fonts=nil;reason=tostring(err)
    UI.set_theme(nil,Style)
    ok,err=pcall(draw,Theme.canvas(raw))
    UI.set_theme(nil,false)
  end
  if not ok then error(err,0) end
end
return Theme
