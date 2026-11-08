-- Thin hub adapter; all typography/layout implementation stays in ui_core.lua.
local Core=require('ui_core')
local UI={}
local inset=0
function UI.header(enabled) inset=enabled and 52 or 0 end
function UI.text(g,c,x,y,s,name,align,w)
  if inset>0 and y<65 and x<80 and align~='center' then
    w=math.max(0,(w or (464-x))-inset);x=x+inset
    if name=='large' then
      s=tostring(s)
      if s==s:upper() then s=s:lower():gsub('(%a)([%w]*)',function(a,b) return a:upper()..b end) end
      if Core.width(c,s,name)>w then name='control' end
    end
  end
  return Core.text(g,c,x,y,s,name,align,w)
end
function UI.error(g,c,title,message)
  g:clear(0)
  UI.text(g,c,24,32,title..' ERROR','medium')
  Core.paragraph(g,c,24,80,432,640,tostring(message),'small')
end
function UI.game_canvas(raw)
  -- Only the Nonogram brand mark occupies this reserved menu-icon area.
  return setmetatable({rect=function(_,x,y,w,h,o)
    if x>=0 and y>=0 and x+w<=72 and y+h<=65 then return end
    return raw:rect(x,y,w,h,o)
  end},{__index=function(_,key)
    local value=raw[key]
    if type(value)=='function' then return function(_,...) return value(raw,...) end end
    return value
  end})
end
return setmetatable(UI,{__index=Core})
