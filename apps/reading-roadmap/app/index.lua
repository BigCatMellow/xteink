-- Reading Roadmap, native XTOS Licorice InkApp for XTEINK X4 Pro (480x800).
-- Personal reading order from the user's curated November 2026 reading list.
-- No network, no book copies, no writes outside the app's own storage.
local RAW = [=[
A Knight of the Seven Kingdoms|George R. R. Martin|Fantasy|Three warm, witty Dunk and Egg stories in familiar Westeros.|A Knight of the Seven Kingdoms TV series
All Systems Red|Martha Wells|Sci-fi|A sarcastic security android with more personality than patience.|Murderbot TV series
The Thin Man|Dashiell Hammett|Mystery|Nick and Nora make witty conversation the real attraction.|The Thin Man film
Penric's Demon|Lois McMaster Bujold|Fantasy|A young man and a very opinionated demon learn to cooperate.|
The Blacktongue Thief|Christopher Buehlman|Fantasy|A sharp-tongued thief crosses a dangerous, lived-in world.|
True Grit|Charles Portis|Western|A remarkable narrator, dry humor, and a determined quest.|True Grit films
Guards! Guards!|Terry Pratchett|Fantasy|A ramshackle city watch meets a dragon and civic absurdity.|
Slow Horses|Mick Herron|Thriller|Disgraced spies, elaborate insults, and dangerous schemes.|Slow Horses TV series
The Blade Itself|Joe Abercrombie|Fantasy|Morally complicated people and bitterly funny conversations.|
The Martian|Andy Weir|Sci-fi|Scientific problem solving and a narrator worth spending time with.|The Martian film
We Are Legion (We Are Bob)|Dennis E. Taylor|Sci-fi|A witty engineer becomes a spacefaring intelligence.|
The Long Way to a Small, Angry Planet|Becky Chambers|Sci-fi|Found-family spaceship life with strong character chemistry.|
I Am Legend|Richard Matheson|Sci-fi|Isolation, changed humanity, and an unsettling moral question.|I Am Legend film
The Last Wish|Andrzej Sapkowski|Fantasy|Self-contained Witcher adventures, monsters, wit, and ethics.|The Witcher games and TV series
The Princess Bride|William Goldman|Fantasy|A playful, self-aware adventure with unforgettable characters.|The Princess Bride film
Kings of the Wyld|Nicholas Eames|Fantasy|An aging adventuring band reunites for one last quest.|
The Tainted Cup|Robert Jackson Bennett|Fantasy|A clever detective partnership solves an impossible mystery.|
Theft of Swords|Michael J. Sullivan|Fantasy|Two very different partners stumble into kingdom-wide trouble.|
The Black Company|Glen Cook|Fantasy|A mercenary physician chronicles a morally murky company.|
The Curse of Chalion|Lois McMaster Bujold|Fantasy|A weary veteran navigates politics, faith, and duty.|
The Lies of Locke Lamora|Scott Lynch|Fantasy|Schemes, hilarious dialogue, friendship, and dangerous rivals.|
The Hobbit|J. R. R. Tolkien|Fantasy|The classic warm adventure through a richly imagined world.|The Hobbit films
The Lord of the Rings|J. R. R. Tolkien|Fantasy|An ancient world, friendship, and stakes that feel earned.|The Lord of the Rings films
We Have Always Lived in the Castle|Shirley Jackson|Horror|A distinctive and unsettling voice drives a family mystery.|
The Sisters Brothers|Patrick deWitt|Western|Two hired-killer brothers in a darkly comic Western.|The Sisters Brothers film
The Last Policeman|Ben H. Winters|Mystery|A detective investigates a death with the apocalypse approaching.|
The Friends of Eddie Coyle|George V. Higgins|Crime|Remarkably natural dialogue inside a bleak criminal world.|The Friends of Eddie Coyle film
The Stepford Wives|Ira Levin|Horror|A seemingly perfect town hides a disturbing social mystery.|The Stepford Wives films
The Queen's Gambit|Walter Tevis|Literary|Competing, obsession, and controlled character-focused prose.|The Queen's Gambit TV series
A Walk in the Woods|Bill Bryson|Nonfiction|Observant comedy during an ill-prepared long hike.|A Walk in the Woods film
Smoke Gets in Your Eyes|Caitlin Doughty|Nonfiction|Funeral-home work opens questions about mortality and society.|
The Disaster Artist|Greg Sestero and Tom Bissell|Nonfiction|A hilarious and affecting account of an unlikely friendship.|The Disaster Artist film
The Big Year|Mark Obmascik|Nonfiction|The obsessive real-world competition behind the film.|The Big Year film
]=]
local books, by_id, states = {}, {}, {}
for line in RAW:gmatch('[^\n]+') do
  local title, author, genre, note, anchor = line:match('^([^|]+)|([^|]+)|([^|]+)|([^|]+)|?(.*)$')
  if title then
    local id = #books + 1
    local b = {id=id,title=title,author=author,genre=genre,note=note,anchor=anchor or ''}
    books[id],by_id[id] = b,b
    states[id]={status='todo',rid=''}
  end
end
local view, page, chosen, hits = 'path', 1, 1, {}
local detail_origin,detail_page = 'path', 1
local pick_origin, pick_page = 'path', 1
local linked, library = {}, {}
local scan = {ok=false,found=0,issues={}}
local msg = ''
local last_key, last_ms = nil, nil
local W,H = 480,800

local function invalidate()
  if ctx and ctx.invalidate then pcall(function() ctx:invalidate() end) end
end
local function notify(s)
  msg=s
  if ctx and ctx.dialog and ctx.dialog.toast then
    pcall(function() ctx.dialog:toast(s) end)
  end
  invalidate()
end
local function safe_text(s)
  return tostring(s or ''):gsub('[\r\n\t]',' ')
end
local function save()
  local rows={'#roadmap1'}
  for i=1,#books do
    local s=states[i]
    rows[#rows+1]=table.concat({i,s.status,safe_text(s.rid)},'\t')
  end
  local ok,result=pcall(function() return ctx.storage:write('progress.txt',table.concat(rows,'\n')..'\n') end)
  if not ok or result==false then notify('Save failed; changes may not persist.'); return false end
  return true
end
local function load()
  local ok,s=pcall(function() return ctx.storage:read('progress.txt') end)
  if not ok or type(s)~='string' then return end
  for line in s:gmatch('[^\r\n]+') do
    local id,status,rid=line:match('^(%d+)\t([%a]+)\t?(.*)$')
    id=tonumber(id)
    if id and states[id] and (status=='todo' or status=='reading' or status=='done') then
      states[id].status=status
      states[id].rid=rid or ''
    end
  end
end
local function norm(s)
  return safe_text(s):lower():gsub('[^%w]+','')
end
-- Search ONLY the stock reader's opened-book catalogue. It is not an SD scan.
local function refresh_library()
  library,linked={},{}
  scan={ok=false,found=0,issues={},indexed=0}
  local collected={}
  if ctx and ctx.reader then
    for _,method in ipairs({'all_books','books'}) do
      local ok,res=pcall(function() return ctx.reader[method](ctx.reader) end)
      if ok and type(res)=='table' then
        scan.ok=true
        for _,r in ipairs(res) do
          if type(r)=='table' and r.id and type(r.title)=='string' then
            local id=tostring(r.id)
            local old=collected[id] or {}
            for k,v in pairs(r) do if v~=nil then old[k]=v end end
            collected[id]=old
          end
        end
      end
    end
  end
  for id,r in pairs(collected) do
    r.id=id
    library[#library+1]=r
    linked[id]=r
  end
  table.sort(library,function(a,b)
    return tostring(a.title):lower()<tostring(b.title):lower()
  end)
  scan.indexed=#library
  if not scan.ok then
    scan.issues[1]={id=0,title='Reader access unavailable',code='NO ACCESS',
      reason='Check reader permission or update'}
    return
  end
  -- Exact normalized titles auto-link only when UNIQUE. Similar titles are
  -- suggestions, never safe to launch or silently auto-select.
  for _,b in ipairs(books) do
    local s=states[b.id]
    local exact,suggest={},{}
    local key=norm(b.title)
    for _,r in ipairs(library) do
      local rk=norm(r.title:lower():gsub('%.epub$',''):gsub('%.txt$',''))
      if rk==key then
        exact[#exact+1]=r
      elseif #key>=8 and #rk>=8 and
         (rk:find(key,1,true) or key:find(rk,1,true)) then
        suggest[#suggest+1]=r
      end
    end
    local code,reason
    if s.rid~='' then
      if linked[s.rid] then
        scan.found=scan.found+1
      else
        code,reason='LINK CHANGED','Relink: saved ID not found'
      end
    elseif #exact==1 then
      s.rid=exact[1].id
      scan.found=scan.found+1
    elseif #exact>1 then
      code,reason='MULTIPLE','Choose the correct edition'
    elseif #suggest>0 then
      code,reason='CHECK TITLE','Verify similar title before link'
    else
      code,reason='NOT INDEXED','Open it once in Bookshelf'
    end
    if code then
      scan.issues[#scan.issues+1]={id=b.id,title=b.title,code=code,reason=reason}
    end
  end
end
local function percent(b)
  local r=linked[states[b.id].rid]
  if not r then return nil end
  if r.finished then return 100 end
  local p=tonumber(r.percent)
  if p then return math.max(0,math.min(100,math.floor(p+.5))) end
  return nil
end
local function done_count()
  local n=0
  for _,s in ipairs(states) do if s.status=='done' then n=n+1 end end
  return n
end
local function current_book()
  for i=1,9 do if states[i].status=='reading' then return books[i] end end
  for i=1,9 do if states[i].status~='done' then return books[i] end end
  for i=10,#books do if states[i].status=='reading' then return books[i] end end
  for i=10,#books do if states[i].status~='done' then return books[i] end end
  return nil
end
local function collect(which)
  local t={}
  for i,b in ipairs(books) do
    if which=='all' or (which=='path' and i<=9) or (which=='done' and states[i].status=='done') then
      t[#t+1]=b
    end
  end
  return t
end
local function font(name)
  return ctx and ctx.fonts and ctx.fonts[name] or nil
end
local function measure(name,s)
  local f=font(name)
  if f then
    local ok,w=pcall(function() return f:measure(s) end)
    if ok and type(w)=='number' then return w end
  end
  return #s * (name=='small' and 10 or 13)
end
local function shorten(name,s,maxwidth)
  s=tostring(s or '')
  if measure(name,s)<=maxwidth then return s end
  local function drop(z) return (z:gsub('[%z\1-\127\192-\255][\128-\191]*$','')) end
  while #s>0 and measure(name,s..'...')>maxwidth do s=drop(s) end
  return s..'...'
end
local function text(g,x,y,s,name,maxwidth)
  s=shorten(name or 'medium',s,maxwidth or W-2*x)
  g:text(x,y,s,{font=font(name or 'medium')})
end
local function line(g,y)
  g:line(12,y,W-12,y,{line_width=1})
end
local function hit(x,y,w,h,fn)
  hits[#hits+1]={x=x,y=y,w=w,h=h,fn=fn}
end
-- Shared-family button treatment: 9px corners, 3px ink, subtle lower edge.
local function button(g,x,y,w,h,label,fn,selected)
  g:rect(x,y,w,h,{line_width=3,radius=9})
  g:rect(x+9,y+h-1,w-18,1,{fill=true,radius=0})
  if selected then g:rect(x+5,y+5,w-10,h-10,{line_width=1,radius=5}) end
  local f='medium'
  local s=shorten(f,label,w-20)
  local tw=measure(f,s)
  text(g,x+math.max(10,math.floor((w-tw)/2)),y+math.floor((h-24)/2),s,f,w-20)
  if fn then hit(x,y,w,h,fn) end
end
local function chevron(g,x,y)
  g:line(x,y,x+6,y+6,{line_width=2})
  g:line(x+6,y+6,x,y+12,{line_width=2})
end
local function wrap(s,name,width,maxlines)
  local result,cur={},''
  for word in tostring(s or ''):gmatch('%S+') do
    local t=cur=='' and word or (cur..' '..word)
    if cur~='' and measure(name,t)>width then
      result[#result+1]=cur
      cur=word
      if #result>=maxlines-1 then break end
    else cur=t end
  end
  if cur~='' and #result<maxlines then result[#result+1]=cur end
  return result
end
local function set_view(v)
  view,page=v,1
  refresh_library()
  invalidate()
end
local function detail(b)
  if view~='detail' then detail_origin,detail_page=view,page end
  chosen=b.id
  set_view('detail')
end
local function back_from_detail()
  local target,previous=detail_origin,detail_page
  set_view(target)
  if target=='check' then page=math.min(previous,math.max(1,math.ceil(#scan.issues/6))) end
  invalidate()
end
local function set_status(st)
  local s=states[chosen]
  s.status=st
  save()
  invalidate()
end
local function try_open(b)
  local s=states[b.id]
  if s.rid=='' then
    notify('NOT INDEXED: open the book in Bookshelf once.')
    return
  end
  local target=linked[s.rid]
  if not target then notify('Book not available; open it once in Bookshelf.'); return end
  -- Firmware build 26110501 announced open-book APIs, but older APIs and the exact
  -- call signature differ. Only invoke a supported call on an explicit user tap.
  local function attempts(owner,method,args)
    if not owner or type(owner[method])~='function' then return false end
    for _,a in ipairs(args) do
      local ok,r=pcall(function() return owner[method](owner,a) end)
      if ok and r~=false and r~=nil then return true end
    end
    return false
  end
  local id=s.rid
  local candidates={{type='book',id=id},{kind='book',id=id},'book:'..id}
  if attempts(ctx.reader,'open',candidates) then return end
  if ctx.system and type(ctx.system.can_open)=='function' then
    for _,c in ipairs(candidates) do
      local ok,supported=pcall(function() return ctx.system:can_open(c) end)
      if ok and supported==true and attempts(ctx.system,'open',{c}) then return end
    end
  end
  notify('Open this book from Bookshelf. Direct launch unverified.')
end
-- A book row is a read action. Book management is intentionally secondary.
local function begin_pick(b)
  chosen=b.id
  pick_origin,pick_page=view,page
  view,page='pick',1
  refresh_library()
  invalidate()
end
local function leave_pick()
  view,page=pick_origin,pick_page
  refresh_library()
  invalidate()
end
local function open_or_link(b)
  chosen=b.id
  refresh_library()
  local s=states[b.id]
  if s.rid~='' and linked[s.rid] then
    try_open(b)
  else
    notify(scan.ok and 'NOT INDEXED: check Bookshelf, then tap CHECK.' or 'Reader index unavailable; check permission.')
  end
end
local function draw_head(g,title,subtitle)
  text(g,14,10,title,'large',452)
  text(g,14,47,subtitle,'small',452)
  line(g,75)
end
local function draw_list(g)
  local ls=view=='check' and scan.issues or collect(view)
  local next_book=current_book()
  local sub=view=='check' and (scan.ok and (scan.found..' / '..#books..' identified   |   '..#scan.issues..' issues') or 'Reader index unavailable') or (done_count()..' / '..#books..' finished    |    '..(view=='path' and 'Main path' or view=='all' and 'All books' or 'Finished'))
  draw_head(g,view=='check' and 'BOOK CHECK' or 'READING ROADMAP',sub)
  local rows=6
  local pages=math.max(1,math.ceil(#ls/rows))
  if page>pages then page=pages end
  local offset=(page-1)*rows
  for slot=1,rows do
    local b=ls[offset+slot]
    if b then
      local y=86+(slot-1)*91
      local st=states[b.id] and states[b.id].status or 'todo'
      local focused=view~='check' and next_book and next_book.id==b.id
      -- Only the book needing attention gets a frame; the remaining rows use quiet dividers.
      if focused then g:rect(9,y,W-18,84,{line_width=3,radius=8})
      else g:line(15,y+83,W-15,y+83,{line_width=1}) end
      text(g,18,y+18,b.id>0 and string.format('%02d',b.id) or '!!','medium',42)
      if view=='check' then
        text(g,67,y+4,b.title,'medium',314)
        text(g,67,y+32,b.code,'small',314)
        text(g,67,y+58,b.reason,'small',314)
      else
        local ls_title=wrap(b.title,'medium',314,2)
        local title_y=y+(#ls_title>1 and 4 or 14)
        for i,v in ipairs(ls_title) do text(g,67,title_y+(i-1)*27,v,'medium',314) end
        local p=percent(b)
        local state_label=st=='done' and 'FINISHED' or st=='reading' and 'READING' or focused and 'READ NEXT' or 'TO READ'
        local info=b.genre..'  |  '..state_label..(p and ('  |  '..p..'%') or '')
        text(g,67,y+(#ls_title>1 and 59 or 48),info,'small',314)
      end
      chevron(g,391,y+32)
      if view~='check' then
        g:line(407,y+9,407,y+75,{line_width=1})
        text(g,416,y+32,'INFO','small',50)
      else
        text(g,413,y+32,'FIX','small',56)
      end
      if view=='check' then
        hit(9,y,462,84,function()
          if b.id>0 then detail(books[b.id]) else notify('Reader index unavailable.') end
        end)
      else
        hit(9,y,399,84,function() open_or_link(b) end)
        hit(408,y,63,84,function() detail(b) end)
      end
    end
  end
  if #ls==0 then
    text(g,28,257,view=='check' and 'No indexing issues' or 'No finished books yet','large',428)
    text(g,28,309,view=='check' and 'All titles have reader matches.' or 'Finish a book to see it here.','medium',424)
    button(g,40,422,400,54,'BACK TO PATH',function()set_view('path')end)
  end
  if view=='check' then text(g,15,628,'Opened books only; SD not scanned','small',450) end
  if page>1 then button(g,12,652,118,54,'< PREV',function() page=page-1;invalidate() end) end
  text(g,183,669,page..' / '..pages,'medium',110)
  if page<pages then button(g,349,652,119,54,'NEXT >',function() page=page+1;invalidate() end) end
  button(g,8,725,109,58,'PATH',function() set_view('path') end,view=='path')
  button(g,126,725,109,58,'ALL',function() set_view('all') end,view=='all')
  button(g,244,725,109,58,'DONE',function() set_view('done') end,view=='done')
  button(g,362,725,109,58,'CHECK',function() set_view('check') end,view=='check')
end
local function draw_detail(g)
  local b=by_id[chosen]
  if not b then set_view('path');return end
  local st=states[b.id].status
  local label=st=='done' and 'Finished' or st=='reading' and 'Reading' or 'Not started'
  draw_head(g,'BOOK '..b.id..' / '..#books,b.genre..'  |  '..label)
  local title_lines=wrap(b.title,'large',444,2)
  for i,v in ipairs(title_lines) do text(g,18,91+(i-1)*35,v,'large',444) end
  local ay=91+#title_lines*35+7
  text(g,18,ay,b.author,'medium',444)
  local rule_y=ay+38
  line(g,rule_y)
  local note_head=rule_y+18
  text(g,18,note_head,'WHY THIS BOOK','small',442)
  local ls=wrap(b.note,'medium',430,3)
  for i,v in ipairs(ls) do text(g,18,note_head+29+(i-1)*30,v,'medium',438) end
  local y=note_head+29+#ls*30+22
  if b.anchor~='' then
    text(g,18,y,'VISUAL REFERENCE','small',440)
    local anchor_lines=wrap(b.anchor,'medium',430,2)
    for i,v in ipairs(anchor_lines) do text(g,18,y+28+(i-1)*28,v,'medium',438) end
    y=y+28+#anchor_lines*28+20
  end
  local p=percent(b)
  text(g,18,y,'ON YOUR XTEINK','small',440)
  text(g,18,y+29,p and ('Reader progress: '..p..'%') or (states[b.id].rid~='' and 'Linked: no progress reported' or 'Not linked to an opened book'),'medium',440)
  if y+59<513 then text(g,18,y+59,'Link an EPUB after opening it in Bookshelf.','small',440) end
  button(g,15,522,218,48,'< PREVIOUS',chosen>1 and function() detail(books[chosen-1]) end or nil)
  button(g,247,522,218,48,'NEXT BOOK >',chosen<#books and function() detail(books[chosen+1]) end or nil)
  button(g,15,584,218,55,'START',function() set_status('reading') end,st=='reading')
  button(g,247,584,218,55,'FINISHED',function() set_status('done') end,st=='done')
  if states[b.id].rid=='' then
    button(g,15,650,450,55,'LINK AN EPUB',function() begin_pick(b) end)
  else
    button(g,15,650,218,55,'LINK BOOK',function() begin_pick(b) end)
    button(g,247,650,218,55,'OPEN BOOK',function() try_open(b) end)
  end
  button(g,15,723,450,59,'BACK TO LIST',function() back_from_detail() end)
end
local function draw_pick(g)
  draw_head(g,'LINK A BOOK','Choose a book you have opened in Bookshelf.')
  local pages=math.max(1,math.ceil(#library/6))
  if page>pages then page=pages end
  for slot=1,6 do
    local r=library[(page-1)*6+slot]
    if r then
      local y=87+(slot-1)*90
      g:rect(10,y,460,82,{line_width=1})
      text(g,19,y+8,r.title or 'Untitled','medium',440)
      text(g,19,y+42,r.author or '', 'small',440)
      hit(10,y,460,82,function()
        states[chosen].rid=tostring(r.id)
        save()
        local return_to=pick_origin
        leave_pick()
        if return_to~='detail' then try_open(books[chosen]) end
      end)
    end
  end
  if #library==0 then
    text(g,18,115,'No opened books were reported by the reader.','medium',440)
    text(g,18,154,'Open the EPUB in Bookshelf first.','medium',440)
  end
  if page>1 then button(g,12,652,118,54,'< PREV',function() page=page-1;invalidate() end) end
  text(g,190,669,page..' / '..pages,'medium',92)
  if page<pages then button(g,349,652,119,54,'NEXT >',function() page=page+1;invalidate() end) end
  button(g,15,725,450,56,'BACK',function()leave_pick()end)
end
function on_load(c)
  ctx=c or ctx
  load()
  refresh_library()
end
function on_draw(c,g)
  ctx=c or ctx
  hits={}
  g:clear(0)
  if view=='detail' then draw_detail(g)
  elseif view=='pick' then draw_pick(g)
  else draw_list(g) end
  if msg~='' then
    text(g,15,(view=='path' or view=='all' or view=='done') and 628 or 782,msg,'small',450)
    msg=''
  end
end
function on_input(c,e)
  ctx=c or ctx
  if not e then return end
  if e.type=='key' then
    local ph=e.phase or e.action or e.state
    if ph=='up' or ph=='release' or e.pressed==false then return end
    local ms=tonumber(e.time_ms)
    if last_key==e.key and ms and last_ms and ms-last_ms>=0 and ms-last_ms<230 then return end
    last_key,last_ms=e.key,ms
    if e.key=='back' then
      if view=='pick' then leave_pick() elseif view=='detail' then back_from_detail() end
    elseif e.key=='right' or e.key=='down' then page=page+1;invalidate()
    elseif e.key=='left' or e.key=='up' then page=math.max(1,page-1);invalidate()
    elseif e.key=='ok' and view=='path' then open_or_link(current_book() or books[1])
    end
    return
  end
  if (e.type=='pointer' and e.phase=='up') or (e.type=='touch' and (e.gesture=='tap' or e.phase=='up')) then
    local x,y=tonumber(e.x),tonumber(e.y)
    if not x or not y then return end
    for i=#hits,1,-1 do
      local h=hits[i]
      if x>=h.x and x<h.x+h.w and y>=h.y and y<h.y+h.h then h.fn();invalidate();return end
    end
  end
end
function on_leave() end
