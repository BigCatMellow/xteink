-- Optional monochrome quote overlay. Original art and JPEGs remain untouched.
-- User quotes: XTApps/wallrandom/files/quotes.txt, one "quote | author" per line.
-- Keep bounded layout and source parsing safe on 32-bit Licorice Lua.
local UI=require('ui')
local Q={}
-- Only confirmed, short J.R.R. Tolkien excerpts belong in the built-in
-- quote rotation. Do not mix in Tolkien-like invented writing or quotes from
-- film adaptations. Optional quotes.txt remains a user-controlled override.
local DEFAULT={
 {text='Not all those who wander are lost;',author='J.R.R. Tolkien'},
 {text='The Road goes ever on and on',author='J.R.R. Tolkien'},
}
local function read(c,name)
 for _,store in ipairs({c.storage or false,c.files or false}) do
  if store then
   local ok,data=pcall(function() return store:read(name) end)
   if ok and type(data)=='string' then return data end
  end
 end
end
local function clean(s)
 s=(s or ''):gsub('^%s+',''):gsub('%s+$','')
 if #s==0 or #s>118 or s:find('[%c]') then return nil end
 -- Avoid a single unbreakable word silently truncated by the UI helper.
 for word in s:gmatch('%S+') do if #word>33 then return nil end end
 return s
end
function Q.entries(c)
 local raw=read(c,'quotes.txt')
 local list={}
 if raw and #raw<=16384 then
  for record in (raw..'\n'):gmatch('(.-)\n') do
   local line=record:gsub('\r$','')
   if not line:match('^%s*#') then
    local body,author=line:match('^(.-)%s*|%s*(.-)%s*$')
    body=clean(body or line)
    author=(author or ''):gsub('^%s+',''):gsub('%s+$','')
    if body and #author<=42 and not author:find('[%c]') then
     list[#list+1]={text=body,author=author}
     if #list>=128 then break end
    end
   end
  end
 end
 if #list>0 then return list end
 for _,item in ipairs(DEFAULT) do list[#list+1]={text=item.text,author=item.author} end
 return list
end
function Q.enabled(c)
 return read(c,'quotes-mode.txt')~='off\n'
end
function Q.set_enabled(c,enabled)
 if not c.storage then return false,'App storage unavailable' end
 local value=enabled and 'on\n' or 'off\n'
 local ok,result,err=pcall(c.storage.write,c.storage,'quotes-mode.txt',value)
 if not ok or result==false or (result==nil and err) or read(c,'quotes-mode.txt')~=value then
  return false,'Could not save quote setting'
 end
 return true
end
function Q.choose(c,history)
 local list=Q.entries(c)
 if #list==0 then return nil end
 local tick=0
 local ok,v=pcall(function() return c.clock:millis() end)
 if ok then tick=tonumber(v) or 0 end
 local seq=(tonumber(history and history.sequence) or 0)%8388593
 local seed=(math.floor(tick)%8388593+seq*13+193)%8388593
 local i=seed%#list+1
 local previous=history and history.quote
 if previous and #list>1 and previous.text==list[i].text and previous.author==list[i].author then
  i=i%#list+1
 end
 return {text=list[i].text,author=list[i].author}
end
-- Native text has no verified 90-degree orientation in the Licorice canvas.
-- Draw a compact monoline stroke alphabet in LANDSCAPE coordinates and
-- map each point back to the native portrait framebuffer. No bitmap decode,
-- extra layer, opaque panel or edits to the original wallpaper image.
-- On the submitted wallpapers, the illustration sits on the landscape RIGHT.
local FONT={
 A='0,6 0,2 2,0 4,2 4,6|0,4 4,4',
 B='0,0 0,6 3,6 4,5 4,4 3,3 0,3|0,0 3,0 4,1 4,2 3,3',
 C='4,1 3,0 1,0 0,1 0,5 1,6 3,6 4,5',
 D='0,0 0,6 2,6 4,4 4,2 2,0 0,0',
 E='4,0 0,0 0,6 4,6|0,3 3,3',
 F='0,6 0,0 4,0|0,3 3,3',
 G='4,1 3,0 1,0 0,1 0,5 1,6 3,6 4,5 4,3 2,3',
 H='0,0 0,6|4,0 4,6|0,3 4,3',
 I='0,0 4,0|2,0 2,6|0,6 4,6',
 J='0,0 4,0 4,5 3,6 1,6 0,5',
 K='0,0 0,6|4,0 0,3 4,6',
 L='0,0 0,6 4,6',
 M='0,6 0,0 2,3 4,0 4,6',
 N='0,6 0,0 4,6 4,0',
 O='1,0 3,0 4,1 4,5 3,6 1,6 0,5 0,1 1,0',
 P='0,6 0,0 3,0 4,1 4,2 3,3 0,3',
 Q='1,0 3,0 4,1 4,5 3,6 1,6 0,5 0,1 1,0|2,4 4,7',
 R='0,6 0,0 3,0 4,1 4,2 3,3 0,3|2,3 4,6',
 S='4,1 3,0 1,0 0,1 0,2 1,3 3,3 4,4 4,5 3,6 1,6 0,5',
 T='0,0 4,0|2,0 2,6',
 U='0,0 0,5 1,6 3,6 4,5 4,0',
 V='0,0 2,6 4,0',
 W='0,0 0.8,6 2,3 3.2,6 4,0',
 X='0,0 4,6|4,0 0,6',
 Y='0,0 2,3 4,0|2,3 2,6',
 Z='0,0 4,0 0,6 4,6',
 ['0']='1,0 3,0 4,1 4,5 3,6 1,6 0,5 0,1 1,0|0,6 4,0',
 ['1']='1,1 2,0 2,6|0,6 4,6',
 ['2']='0,1 1,0 3,0 4,1 4,2 0,6 4,6',
 ['3']='0,0 4,0 2,3 4,3 4,5 3,6 0,6',
 ['4']='3,6 3,0 0,4 4,4',
 ['5']='4,0 0,0 0,3 3,3 4,4 4,5 3,6 0,6',
 ['6']='4,0 1,0 0,2 0,5 1,6 3,6 4,5 4,4 3,3 0,3',
 ['7']='0,0 4,0 1,6',
 ['8']='1,0 3,0 4,1 4,2 3,3 1,3 0,2 0,1 1,0|1,3 0,4 0,5 1,6 3,6 4,5 4,4 3,3',
 ['9']='4,3 1,3 0,2 0,1 1,0 3,0 4,1 4,4 3,6 0,6',
 ['.']='2,5.5 2,6',
 [',']='2,5.5 1,7',
 ['!']='2,0 2,4|2,5.5 2,6',
 ['?']='0,1 1,0 3,0 4,1 4,2 2,4|2,5.5 2,6',
 [':']='2,2 2,2.4|2,5.5 2,6',
 [';']='2,2 2,2.4|2,5 1,7',
 ['-']='0,3 4,3',
 ["'"]='2,0 2,1.5',
 ['"']='1,0 1,1.5|3,0 3,1.5',
 ['(']='3,0 1,2 1,4 3,6',
 [')']='1,0 3,2 3,4 1,6',
 ['&']='4,6 1,2 1,1 2,0 3,1 3,2 0,5 1,6 4,6|0,3 4,1',
 ['/']='0,6 4,0',
 ['+']='2,1 2,5|0,3 4,3',
 ['=']='0,2 4,2|0,4 4,4'
}
local COMPILED={}
for ch,pattern in pairs(FONT) do
 local glyph={}
 for stroke in pattern:gmatch('[^|]+') do
  local pts={}
  for token in stroke:gmatch('%S+') do
   local x,y=token:match('([%d%.%-]+),([%d%.%-]+)')
   if not x then error('Malformed quote glyph') end
   pts[#pts+1]=tonumber(x)
   pts[#pts+1]=tonumber(y)
  end
  if #pts>=4 then glyph[#glyph+1]=pts end
 end
 COMPILED[ch]=glyph
end
local function round(x) return math.floor(x+0.5) end
local function draw_line(g,line,u,v,scale)
 -- Display is rotated clockwise; therefore landscape (u,v) corresponds
 -- to native frame (x=v,y=799-u). Render all characters upright when held sideways.
 local step=6*scale
 line=line:upper()
 for i=1,#line do
  local glyph=COMPILED[line:sub(i,i)] or COMPILED['?']
  if glyph then
   for _,stroke in ipairs(glyph) do
    local pts,thick={},{}
    for j=1,#stroke,2 do
     local ux=u+(i-1)*step+stroke[j]*scale
     local vy=v+stroke[j+1]*scale
     local x,y=round(vy),round(799-ux)
     pts[#pts+1]=x;pts[#pts+1]=y
     thick[#thick+1]=x+1;thick[#thick+1]=y
    end
    g:polyline(pts)
    g:polyline(thick) -- two pixels, clear on the 4-level display
   end
  end
 end
end
local function wrap(text,cap)
 local out,line={},''
 for token in text:gmatch('%S+') do
  local word=token
  while #word>cap do
   if #line>0 then out[#out+1]=line;line='' end
   out[#out+1]=word:sub(1,cap)
   word=word:sub(cap+1)
  end
  if #line==0 then line=word
  elseif #line+#word+1<=cap then line=line..' '..word
  else out[#out+1]=line;line=word end
 end
 if #line>0 then out[#out+1]=line end
 return out
end
local function fit(text,preferred,limit)
 local result,scale
 for _,s in ipairs({preferred,3.2,3.0,2.8,2.6,2.4,2.2}) do
  if not scale or s<scale then
   local lines=wrap(text,math.floor(428/(6*s)))
   result,scale=lines,s
   if #lines<=limit then break end
  end
 end
 return result,scale
end
function Q.draw(g,c,quote)
 if not quote or not quote.text then return end
 -- The supplied 480x800 pictures rotate CW into an 800x480 landscape
 -- view. Their illustrations occupy the right side; preserve them untouched.
 -- No white/black rectangle: the empty paper is the typography background.
 local content='"'..quote.text..'"'
 local lines,scale=fit(content,3.6,8)
 local author=(quote.author and quote.author~='') and ('- '..quote.author) or ''
 local author_lines,author_scale={},2.3
 if author~='' then author_lines,author_scale=fit(author,2.3,2) end
 local line_height=9*scale
 local author_height=#author_lines>0 and (#author_lines*9*author_scale+14) or 0
 local height=#lines*line_height+author_height
 local top=(480-height)/2
 for i,line in ipairs(lines) do
  local width=#line*6*scale
  draw_line(g,line,50+(428-width)/2,top+(i-1)*line_height,scale)
 end
 for i,line in ipairs(author_lines) do
  local width=#line*6*author_scale
  draw_line(g,line,50+(428-width)/2,top+#lines*line_height+14+(i-1)*9*author_scale,author_scale)
 end
end
return Q
