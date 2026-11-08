-- Canonical game typography. Run scripts/sync_game_ui.py after changing this.
local UI={}
local heights={small=20,medium=24,large=30,body=24,clue=24,clue_small=20,strong=30}
local aliases={body='medium',clue='medium',clue_small='small',control='medium',strong='large'}
local theme_fonts,themed=nil,false
function UI.set_theme(fonts,enabled) theme_fonts=fonts;themed=enabled end
local function observe(kind,box)
  local audit=rawget(_G,'__LAYOUT')
  if audit then audit(kind,box) end
end
function UI.font(c,name)
  name=name or 'medium'
  if theme_fonts then
    if name=='control' then return theme_fonts.fonts.medium end
    if name=='strong' then return theme_fonts.fonts.large end
    return theme_fonts.fonts[name=='medium' and 'body' or name]
  end
  return c and c.fonts and (c.fonts[name] or c.fonts[aliases[name]])
end
function UI.height(c,name)
  local f=UI.font(c,name)
  return f and tonumber(f.line_height) or heights[name or 'medium'] or 24
end
function UI.width(c,s,name)
  local f=UI.font(c,name)
  local ok,w=pcall(function() return f:measure(s) end)
  if ok and type(w)=='number' then return w end
  local n=0
  for _ in tostring(s):gmatch('[%z\1-\127\194-\244][\128-\191]*') do n=n+1 end
  return n*(name=='large' and 18 or name=='small' and 11 or 14)
end
local function shorten(c,s,name,w)
  if UI.width(c,s,name)<=w then return s end
  local chars={}
  for ch in s:gmatch('[%z\1-\127\194-\244][\128-\191]*') do chars[#chars+1]=ch end
  repeat table.remove(chars) until #chars==0 or UI.width(c,table.concat(chars)..'...',name)<=w
  return #chars>0 and table.concat(chars)..'...' or ''
end
function UI.text(g,c,x,y,s,name,align,w)
  name=name or 'medium';s=tostring(s)
  if themed and name=='large' and y<80 and s==s:upper() then
    s=s:lower():gsub('(%a)([%w]*)',function(a,b) return a:upper()..b end)
  end
  if themed and name=='large' and s:match('^%d+$') then name='clue' end
  w=w or (align=='center' and 2*math.min(x-16,464-x) or 464-x)
  w=math.max(0,w)
  s=shorten(c,s,name,w)
  local width=UI.width(c,s,name)
  if align=='center' then x=x-math.floor(width/2) end
  x,y=math.floor(x),math.floor(y)
  if s=='' then return end
  observe('text',{x=x,y=y,w=width,h=UI.height(c,name),s=s})
  local f=UI.font(c,name)
  if f and type(f.paint)=='function' then
    if f:paint(g,x,y,s) then return end
    f=f.native
  end
  g:text(x,y,s,f and {font=f} or {})
end
function UI.button(g,c,x,y,w,h,s,decorated,options)
  options=options or {}
  if themed and s==s:upper() and not s:find('[:%d]') then
    s=s:sub(1,1)..s:sub(2):lower()
  end
  observe('button',{x=x,y=y,w=w,h=h,s=s})
  local family=type(themed)=='table' and themed or nil
  local radius=options.radius or (themed and (family and family.control_radius or 12) or 0)
  local primary=themed and (s=='Next' or s=='Check' or s:match('^Next ') or s:match('^Back to '))
  local weight=family and ((primary and family.primary_stroke or family.control_stroke)-family.stroke_increment) or (primary and 3 or 2)
  g:rect(x,y,w,h,{line_width=options.line_width or weight,radius=radius})
  if decorated then
    g:rect(x+4,y+4,w-8,h-8,{line_width=1,radius=math.max(0,radius-4)})
    g:line(x+11,y+4,x+20,y+4)
    g:line(x+w-20,y+h-4,x+w-11,y+h-4)
  end
  local pad=themed and math.min(10,math.floor(w/5)) or 10
  local preferred=options.font or (themed and 'control' or 'medium')
  local name=UI.width(c,s,preferred)<=w-2*pad and UI.height(c,preferred)<=h-12 and preferred or 'small'
  UI.text(g,c,x+w/2,y+math.floor((h-UI.height(c,name))/2),s,name,'center',w-2*pad)
end
function UI.paragraph(g,c,x,y,w,h,s,name,align)
  name=name or 'small'
  local lines,line={},''
  for word in tostring(s):gmatch('%S+') do
    local candidate=line=='' and word or line..' '..word
    if line~='' and UI.width(c,candidate,name)>w then
      lines[#lines+1]=line;line=word
    else line=candidate end
  end
  if line~='' then lines[#lines+1]=line end
  local step=UI.height(c,name)+4
  local count=math.max(0,math.floor((h+4)/step))
  if #lines>count then observe('overflow',{s=tostring(s)}) end
  for i=1,math.min(#lines,count) do
    local sline=lines[i]
    if i==count and #lines>count then sline=sline..' ...' end
    UI.text(g,c,align=='center' and x+w/2 or x,y+(i-1)*step,sline,name,align,w)
  end
end
function UI.region(x,y,w,h) observe('region',{x=x,y=y,w=w,h=h}) end
function UI.error(g,c,title,message)
  g:clear(0)
  UI.text(g,c,24,32,title..' ERROR','medium')
  UI.paragraph(g,c,24,80,432,640,tostring(message),'small')
end
return UI
