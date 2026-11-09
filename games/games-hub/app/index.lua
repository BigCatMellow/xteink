-- Games Hub is the card-loaded shell (shell/docs/DESIGN.md): Home, Library,
-- Games and Settings around the canonical engines, whose save formats come
-- from the source games. Reading data is display-only.
local UI=require('ui')
local Theme=require('theme')
local Catalogue=require('catalogue')
local Shell=require('shell')
local Namespace=require('namespace')
local Importer=require('importer')
local Expected=require('import_expected')
local C,active,scope,selected=nil,nil,nil,nil
local last,notice,blocked=1,nil,false
local held=false
local S={screen='home',page=1}
local orient,pages,back,saved_state='portrait',{},'home',nil
local SCREENS={home=true,library=true,games=true,settings=true,game=true}
local function redraw() if C then C:invalidate() end end
local function inside(x,y,a,b,w,h) return x>=a and y>=b and x<a+w and y<b+h end
local function size()
  local ok,w,h=pcall(function() return tonumber(C.screen.width),tonumber(C.screen.height) end)
  if ok and w and h and w>0 and h>0 then return w,h end
  return 480,800
end
local function can_rotate()
  local ok,f=pcall(function() return C.screen.set_orientation end)
  return ok and type(f)=='function'
end
local function rotate(o) if can_rotate() then pcall(function() C.screen:set_orientation(o) end) end end
local function written(ok,value,err) return ok and value~=false and not (value==nil and err) end
local function save_last()
  if not written(pcall(C.storage.write,C.storage,'hub.txt','id='..Catalogue[last].id)) then
    notice='Could not remember your last game'
  end
end
local function save_shell(screen)
  local value='screen='..screen..'\norient='..orient..'\n'
  if value==saved_state then return end
  if written(pcall(C.storage.write,C.storage,'shell.txt',value)) then saved_state=value
  else notice='Could not save your shell settings' end
end
local function load_shell()
  local ok,value=pcall(C.storage.read,C.storage,'shell.txt')
  if not ok or type(value)~='string' then return 'home' end
  saved_state=value
  local o=value:match('orient=(%a+)')
  if o=='portrait' or o=='landscape' then orient=o end
  local s=value:match('screen=(%a+)')
  return SCREENS[s] and s or 'home'
end
local function refresh()
  S.battery,S.charging=nil,nil
  local ok,b=pcall(function() return C.device:battery() end)
  if not (ok and type(b)=='table') then ok,b=pcall(function() return C.sys.battery() end) end
  if ok and type(b)=='table' and tonumber(b.percent) then
    S.battery=math.max(0,math.min(100,math.floor(tonumber(b.percent)+0.5)));S.charging=b.charging==true
  end
  S.reader,S.current,S.streak,S.today,S.books=false,nil,nil,nil,{}
  local okr,reader=pcall(function() return C.reader end)
  if not okr or (type(reader)~='table' and type(reader)~='userdata') then return end
  S.reader=true
  local okc,cur=pcall(function() return reader:current() end)
  if okc and type(cur)=='table' and cur.title then
    S.current={title=tostring(cur.title),author=cur.author and tostring(cur.author) or nil,percent=tonumber(cur.percent) or 0}
  end
  local oks,sum=pcall(function() return reader:summary() end)
  if oks and type(sum)=='table' then
    S.streak=tonumber(sum.streak_days)
    local today=tonumber(sum.today_sec)
    S.today=today and math.floor(today/60) or nil
  end
  local okb,books=pcall(function() return reader:books() end)
  if okb and type(books)=='table' then
    for _,book in ipairs(books) do
      if type(book)=='table' and book.title and #S.books<500 then S.books[#S.books+1]=book end
    end
  end
end
local function items(name)
  local list={}
  if name=='library' then
    for _,book in ipairs(S.books) do
      local pct=tonumber(book.percent)
      local state=book.finished and 'Finished' or pct and pct>0 and math.floor(pct+0.5)..'% read' or 'Not started'
      local author=book.author and tostring(book.author)~='' and tostring(book.author)..' - ' or ''
      list[#list+1]={id='book',passive=true,title=tostring(book.title),meta=author..state}
    end
    S.empty=S.reader and 'Books you open in the reader appear here.' or 'Reading details are unavailable on this firmware.'
  elseif name=='games' then
    for n,item in ipairs(Catalogue) do list[#list+1]={id='game',game=n,title=item.name,meta=item.description} end
    S.empty=nil
  elseif name=='settings' then
    if can_rotate() then
      list[#list+1]={id='orient',title='Screen',meta=orient=='landscape' and 'Landscape - tap for portrait' or 'Portrait - tap for landscape'}
    else
      list[#list+1]={id='info',passive=true,title='Screen',meta='Portrait only on this firmware'}
    end
    local okf,fw=pcall(function() return C.device.firmware end)
    local about=#Catalogue..' games'..((okf and fw) and ' - firmware '..tostring(fw) or '')
    list[#list+1]={id='info',passive=true,title='About',meta=about}
    S.empty=nil
  end
  return list
end
local function go(name,nosave)
  if S.screen~='home' and S.screen~='blocked' then pages[S.screen]=S.page end
  S.screen=name;notice=nil
  if name=='home' or name=='library' then refresh() end
  S.items=items(name)
  if name=='games' then S.page=math.floor((last-1)/Shell.per_page(size()))+1 else S.page=pages[name] or 1 end
  if not nosave then save_shell(name) end
end
local function leave_game(exiting)
  if not active then return true end
  scope:begin()
  local ok,err=pcall(active.leave)
  if not ok or scope.error then
    notice='Save failed. Try again before leaving.'
    return false
  end
  active,scope,selected=nil,nil,nil
  UI.header(false);Theme.release()
  if not exiting then rotate(orient);go(back) end
  return true
end
local function launch(n)
  if blocked then return false end
  if not leave_game() then return false end
  Theme.release()
  local item=Catalogue[n]
  local ok,engine=pcall(function() return require('game_'..item.id)(rawget(_G,'__TEST') and {} or nil) end)
  if not ok then notice='Could not open '..item.name;return false end
  -- Engines are laid out for the 480x800 portrait screen.
  if S.screen~='game' then back=S.screen=='games' and 'games' or 'home' end
  rotate('portrait')
  scope=Namespace.new(item.id)
  active,selected,last=engine,n,n
  local loaded,err=pcall(engine.load,scope:context(C))
  if not loaded or scope.error then
    pcall(engine.leave);active,scope,selected=nil,nil,nil
    rotate(orient)
    notice='Could not read '..item.name..'. Your saves are still on the card.'
    return false
  end
  notice=nil;save_last();save_shell('game');return true
end
function on_load(context)
  C=context;active,scope,selected=nil,nil,nil;last=1
  notice=nil;blocked=false;held=false;UI.header(false);Theme.release()
  pages,back,saved_state,orient={},'home',nil,'portrait'
  local allowed={};for _,item in ipairs(Catalogue) do allowed[item.id]=true end
  local ok,result=pcall(Importer.run,C,Expected,allowed)
  if not ok then blocked=true;notice='Progress import needs attention. Reinstall the personal Games Hub package and try again.'
  elseif result.count>0 and not result.already then notice='Your saved progress is ready.' end
  local read,value,err=pcall(C.storage.read,C.storage,'hub.txt')
  if read and type(value)=='string' then
    local id=value:match('^id=([a-z]+)$')
    if id then for n,item in ipairs(Catalogue) do if item.id==id then last=n;break end end
    elseif tonumber(value) and Catalogue[tonumber(value)] then last=tonumber(value) end
  end
  local saved=load_shell()
  rotate(orient)
  if blocked then S.screen='blocked';S.items={};return end
  local welcome=notice
  S.screen='home';go(saved=='game' and 'home' or saved,true)
  notice=welcome
  -- The shell reopens where it was left, including an open game.
  if saved=='game' then back='home';launch(last) end
end
local function shell_draw(g)
  local W,H=size()
  if S.items and S.screen~='home' then S.page=math.max(1,math.min(S.page or 1,Shell.pages(#S.items,W,H))) end
  S.last,S.notice=last,notice
  Shell.draw(g,C,S,W,H,Shell.targets(S,W,H),Catalogue)
end
function on_draw(context,g)
  C=context
  if active then
    UI.header(true)
    local ok,err=pcall(active.draw,scope:context(C),UI.game_canvas(g))
    UI.header(false)
    if not ok then UI.error(g,C,'Game',tostring(err)) end
    g:rect(20,16,44,44,{radius=10,line_width=3})
    for row=0,2 do for col=0,2 do
      g:rect(29+col*9,25+row*9,5,5,{fill=true,radius=1})
    end end
    if notice then
      g:rect(24,112,432,76,{fill=true,color=0,radius=12})
      UI.paragraph(g,C,36,122,408,60,notice,'small')
    end
  else Theme.draw(C,g,shell_draw) end
end
local function act(t)
  local id=t.id
  if t.passive or t.disabled then return false end
  if id=='retry' then on_load(C)
  elseif id=='resume' then launch(last)
  elseif id:sub(1,4)=='tab:' then go(id:sub(5))
  elseif id=='home' then go('home')
  elseif id=='prev' then S.page=S.page-1
  elseif id=='next' then S.page=S.page+1
  elseif id=='game' then launch(t.item.game)
  elseif id=='orient' then
    orient=orient=='landscape' and 'portrait' or 'landscape'
    rotate(orient);S.items=items('settings');save_shell('settings')
  else return false end
  return true
end
function on_input(context,e)
  C=context
  if active then
    if e.type=='pointer' and (held or inside(e.x or -1,e.y or -1,20,16,44,44)) then
      if e.phase=='down' then held=true;return true end
      if e.phase=='up' then
        held=false
        if e.gesture=='tap' and inside(e.x or -1,e.y or -1,20,16,44,44) then
          leave_game()
          redraw()
        end
        return true
      end
    end
    return active.input(scope:context(C),e)
  end
  if e.type~='pointer' or e.phase~='up' or e.gesture~='tap' then return false end
  local x,y=e.x or -1,e.y or -1
  local W,H=size()
  for _,t in ipairs(Shell.targets(S,W,H)) do
    if inside(x,y,t.x,t.y,t.w,t.h) then
      if act(t) then redraw();return true end
      return false
    end
  end
  return false
end
function on_leave()
  local ok=leave_game(true);Theme.release()
  if not ok then error('Game save failed') end
end
if rawget(_G,'__TEST') then
  __TEST.api={launch=launch,go=go,
    targets=function() local W,H=size();return Shell.targets(S,W,H) end,
    per_page=function() return Shell.per_page(size()) end,
    state=function() return {screen=S.screen,page=S.page,last=last,selected=selected,blocked=blocked,
      notice=notice,engine=active,orient=orient,shell=S} end}
end
