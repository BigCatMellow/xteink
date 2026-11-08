-- Games Hub owns navigation; engines and their save formats come from source games.
local UI=require('ui')
local Theme=require('theme')
local Catalogue=require('catalogue')
local Namespace=require('namespace')
local Importer=require('importer')
local Expected=require('import_expected')
local C,active,scope,selected=nil,nil,nil,nil
local page,last,notice,blocked=1,1,nil,false
local held=false
local function redraw() if C then C:invalidate() end end
local function inside(x,y,a,b,w,h) return x>=a and y>=b and x<a+w and y<b+h end
local function save_last()
  local ok,value,err=pcall(C.storage.write,C.storage,'hub.txt',tostring(last))
  if not ok or value==false or (value==nil and err) then notice='Could not remember your last game' end
end
local function leave_game()
  if not active then return true end
  scope:begin()
  local ok,err=pcall(active.leave)
  if not ok or scope.error then
    notice='Save failed. Try again before leaving.'
    return false
  end
  active,scope,selected=nil,nil,nil
  UI.header(false);Theme.release()
  return true
end
local function launch(n)
  if blocked then return false end
  if not leave_game() then return false end
  Theme.release()
  local item=Catalogue[n]
  local ok,engine=pcall(function() return require('game_'..item.id)(rawget(_G,'__TEST') and {} or nil) end)
  if not ok then notice='Could not open '..item.name;return false end
  scope=Namespace.new(item.id)
  active,selected,last=engine,n,n
  local loaded,err=pcall(engine.load,scope:context(C))
  if not loaded or scope.error then
    pcall(engine.leave);active,scope,selected=nil,nil,nil
    notice='Could not read '..item.name..'. Your saves are still on the card.'
    return false
  end
  notice=nil;save_last();return true
end
function on_load(context)
  C=context;active,scope,selected=nil,nil,nil;page,last=1,1
  notice=nil;blocked=false;held=false;UI.header(false);Theme.release()
  local allowed={};for _,item in ipairs(Catalogue) do allowed[item.id]=true end
  local ok,result=pcall(Importer.run,C,Expected,allowed)
  if not ok then blocked=true;notice='Progress import needs attention. Reinstall the personal Games Hub package and try again.'
  elseif result.count>0 and not result.already then notice='Your saved progress is ready.' end
  local read,value,err=pcall(C.storage.read,C.storage,'hub.txt')
  if read and tonumber(value) and Catalogue[tonumber(value)] then last=tonumber(value);page=math.floor((last-1)/4)+1 end
end
local function menu(g)
  g:clear(0)
  UI.text(g,C,24,24,'Games Hub','large')
  UI.text(g,C,24,68,#Catalogue..' games / one update','small')
  if blocked then
    UI.paragraph(g,C,24,150,432,350,notice,'medium')
    UI.button(g,C,24,696,432,72,'Retry import')
    return
  end
  UI.button(g,C,24,112,432,64,'Resume '..Catalogue[last].name)
  for row=1,4 do
    local n=(page-1)*4+row;local item=Catalogue[n]
    if item then
      local y=200+(row-1)*108
      g:rect(24,y,432,92,{radius=12,line_width=2})
      UI.text(g,C,44,y+14,item.name,'control',nil,390)
      UI.text(g,C,44,y+54,item.description,'small',nil,390)
    end
  end
  UI.text(g,C,240,650,'Page '..page..' of '..math.ceil(#Catalogue/4),'small','center',260)
  UI.button(g,C,24,696,128,72,'Prev')
  UI.button(g,C,328,696,128,72,'Next')
  if notice then UI.text(g,C,240,674,notice,'small','center',432) end
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
  else Theme.draw(C,g,menu) end
end
function on_input(context,e)
  C=context
  if active then
    if e.type=='pointer' and (held or inside(e.x or -1,e.y or -1,20,16,44,44)) then
      if e.phase=='down' then held=true;return true end
      if e.phase=='up' then
        held=false
        if e.gesture=='tap' and inside(e.x or -1,e.y or -1,20,16,44,44) then
          if leave_game() then notice=nil;page=math.floor((last-1)/4)+1 end
          redraw()
        end
        return true
      end
    end
    return active.input(scope:context(C),e)
  end
  if e.type~='pointer' or e.phase~='up' or e.gesture~='tap' then return false end
  local x,y=e.x or -1,e.y or -1
  if blocked then
    if inside(x,y,24,696,432,72) then on_load(C);redraw();return true end
    return false
  end
  if inside(x,y,24,112,432,64) then launch(last)
  elseif inside(x,y,24,200,432,416) then
    local row=math.floor((y-200)/108)+1
    local n=(page-1)*4+row
    if (y-200)%108<92 and Catalogue[n] then launch(n) else return false end
  elseif inside(x,y,24,696,128,72) then page=math.max(1,page-1)
  elseif inside(x,y,328,696,128,72) then page=math.min(math.ceil(#Catalogue/4),page+1)
  else return false end
  redraw();return true
end
function on_leave()
  local ok=leave_game();Theme.release()
  if not ok then error('Game save failed') end
end
if rawget(_G,'__TEST') then
  __TEST.api={launch=launch,state=function() return {page=page,last=last,selected=selected,blocked=blocked,notice=notice,engine=active} end}
end
