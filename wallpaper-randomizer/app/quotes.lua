-- Optional monochrome quote overlay. Original art and JPEGs remain untouched.
-- User quotes: XTApps/wallrandom/files/quotes.txt, one "quote | author" per line.
-- Keep bounded layout and source parsing safe on 32-bit Licorice Lua.
local UI=require('ui')
local Q={}
local DEFAULT={
 'A little attention can make an ordinary day extraordinary.',
 'The best discoveries begin with a better question.',
 'Not every meaningful journey needs a destination.',
 'Wonder is a habit worth practicing.',
 'There is more to notice than there is time to see.',
 'An open mind has room for another possibility.',
 'The world rewards those who keep looking closely.',
 'Some of the finest adventures happen slowly.',
 'What we understand today was once unfamiliar.',
 'A small beginning can hold a large story.',
 'Knowledge grows one honest question at a time.',
 'Good questions are worth keeping close.',
 'The details are where the larger world begins.',
 'Curiosity makes room for another chapter.',
 'You can travel far without going quickly.',
 'A quiet moment can still change your direction.'
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
  for line in (raw..'\n'):gmatch('(.-)\n') do
   line=line:gsub('\r$','')
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
 for _,text in ipairs(DEFAULT) do list[#list+1]={text=text,author=''} end
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
function Q.draw(g,c,quote)
 if not quote then return end
 -- Opaque white band, not grayscale/translucent: text stays readable over
 -- photographs and line art on e-ink. Preserve the upper 70% of the image.
 g:rect(14,560,452,212,{fill=true,color=0,radius=10})
 g:rect(14,560,452,212,{line_width=2,radius=10})
 UI.paragraph(g,c,34,582,412,130,'"'..quote.text..'"','small','center')
 if quote.author and quote.author~='' then
  UI.text(g,c,240,738,'- '..quote.author,'small','center',400)
 end
end
return Q
