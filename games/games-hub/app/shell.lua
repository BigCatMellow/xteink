-- Shell screens: Home, Library, Games and Settings. Layout follows the user's
-- CrossPoint X4 Pro preview (shell/docs/DESIGN.md). One target list owns both
-- drawing and hit testing, so a tap always lands on what is drawn.
local UI=require('ui')
local Shell={}
local M,HEAD,NAV,STATUS,ROW,GAP=18,52,76,34,92,10

local function observe(kind,box)
  local audit=rawget(_G,'__LAYOUT')
  if audit then audit(kind,box) end
end
local function rule(g,x,y,w,h) g:rect(x,y,w,h,{fill=true,radius=0}) end
local function frame(g,x,y,w,h) g:rect(x,y,w,h,{line_width=1,radius=0}) end
local function chevron(g,x,y,dir)
  -- 6x12 vector chevron; dir=1 points right, -1 left.
  local tip=x+(dir>0 and 6 or 0);local base=x+(dir>0 and 0 or 6)
  g:line(base,y,tip,y+6,{line_width=2});g:line(tip,y+6,base,y+12,{line_width=2})
end
-- Greedy word wrap that truncates the final line instead of dropping words.
local function wrap(c,s,name,w,limit)
  local lines,line={},''
  for word in tostring(s):gmatch('%S+') do
    local candidate=line=='' and word or line..' '..word
    if line~='' and UI.width(c,candidate,name)>w and #lines<limit-1 then
      lines[#lines+1]=line;line=word
    else line=candidate end
  end
  if line~='' then lines[#lines+1]=line end
  return lines
end
local function lines(g,c,x,y,w,s,name,limit)
  local step=UI.height(c,name)+2
  local list=wrap(c,s,name,w,limit)
  for i,l in ipairs(list) do UI.text(g,c,x,y+(i-1)*step,l,name,nil,w) end
  return y+#list*step
end

function Shell.grid(W,H,top,bottom)
  local cols=W>=700 and 2 or 1
  local cw=math.floor((W-2*M-(cols-1)*M)/cols)
  local rows=math.max(1,math.floor((bottom-top+GAP)/(ROW+GAP)))
  return {cols=cols,rows=rows,per=cols*rows,w=cw,top=top}
end
local function cell(grid,i)
  local r,col=math.floor((i-1)/grid.cols),(i-1)%grid.cols
  return M+col*(grid.w+M),grid.top+r*(ROW+GAP),grid.w,ROW
end
local function list_bounds(W,H) return HEAD+58,H-NAV-STATUS end
function Shell.per_page(W,H)
  local top,bottom=list_bounds(W,H)
  return Shell.grid(W,H,top,bottom).per
end
function Shell.pages(count,W,H) return math.max(1,math.ceil(count/Shell.per_page(W,H))) end

-- Every interactive or bounded element for the current screen.
function Shell.targets(S,W,H)
  local t={}
  local function add(id,x,y,w,h,extra)
    local item=extra or {};item.id,item.x,item.y,item.w,item.h=id,x,y,w,h;t[#t+1]=item
  end
  if S.screen=='blocked' then add('retry',M,H-NAV-M,W-2*M,NAV);return t end
  if S.screen=='home' then
    local top,bottom=HEAD+M,H-NAV-STATUS
    if W>=700 then
      local rw=math.floor((W-3*M)*0.58)
      add('reading',M,top,rw,bottom-top,{passive=true})
      add('resume',2*M+rw,top,W-3*M-rw,bottom-top)
    else
      local gh=150
      add('reading',M,top,W-2*M,bottom-top-M-gh,{passive=true})
      add('resume',M,bottom-gh,W-2*M,gh)
    end
    local tabs={{'library','Library'},{'games','Games'},{'settings','Settings'}}
    local tw=math.floor(W/#tabs)
    for i,tab in ipairs(tabs) do
      local x=(i-1)*tw
      add('tab:'..tab[1],x,H-NAV,i==#tabs and W-x or tw,NAV,{label=tab[2],icon=tab[1]})
    end
    return t
  end
  add('home',M,8,128,36)
  local top,bottom=list_bounds(W,H)
  local grid=Shell.grid(W,H,top,bottom)
  local items=S.items or {}
  local first=((S.page or 1)-1)*grid.per
  for slot=1,grid.per do
    local n=first+slot;local item=items[n]
    if item then
      local x,y,w,h=cell(grid,slot)
      add(item.id or 'item',x,y,w,h,{item=item,index=n,passive=item.passive})
    end
  end
  if S.screen~='settings' then
    local half=math.floor(W/2)
    add('prev',0,H-NAV,half,NAV,{disabled=(S.page or 1)<=1})
    add('next',half,H-NAV,W-half,NAV,{disabled=first+grid.per>=#items})
  end
  return t
end

local function battery(g,c,S,W)
  if not S.battery then return end
  local label=tostring(S.battery)..'%'
  local tw=UI.width(c,label,'small')
  local x=W-M-tw
  UI.text(g,c,x,14,label,'small',nil,tw)
  local bx=x-34
  frame(g,bx,18,24,14);rule(g,bx+24,22,3,6)
  local fill=math.max(0,math.min(20,math.floor(20*S.battery/100+0.5)))
  if fill>0 then rule(g,bx+2,20,fill,10) end
  if S.charging then g:line(bx+14,20,bx+9,26,{line_width=2});g:line(bx+9,26,bx+15,26,{line_width=2});g:line(bx+15,26,bx+10,31,{line_width=2}) end
end
local function header(g,c,S,W,targets)
  rule(g,0,HEAD,W,1)
  battery(g,c,S,W)
  if S.screen=='home' then UI.text(g,c,M,14,'Home','small',nil,200);return end
  for _,t in ipairs(targets) do if t.id=='home' then
    UI.button(g,c,t.x,t.y,t.w,t.h,'Home',false,{radius=0,line_width=1,font='small'})
    chevron(g,t.x+14,t.y+12,-1)
  end end
end
local ICONS={}
function ICONS.library(g,x,y)
  frame(g,x,y+3,7,19);frame(g,x+9,y,8,22);frame(g,x+19,y+5,6,17)
end
function ICONS.games(g,x,y)
  for r=0,2 do for col=0,2 do g:rect(x+2+col*8,y+2+r*8,5,5,{fill=true,radius=1}) end end
end
function ICONS.settings(g,x,y)
  g:circle(x+13,y+11,5,{line_width=1})
  for _,d in ipairs({{0,-1},{0,1},{-1,0},{1,0},{-0.7,-0.7},{0.7,0.7},{-0.7,0.7},{0.7,-0.7}}) do
    g:line(x+13+math.floor(d[1]*8),y+11+math.floor(d[2]*8),x+13+math.floor(d[1]*11),y+11+math.floor(d[2]*11),{line_width=2})
  end
end
local function tab(g,c,t,W,last)
  if t.x==0 then rule(g,0,t.y,W,1) end
  if not last then rule(g,t.x+t.w-1,t.y+14,1,t.h-28) end
  UI.region(t.x,t.y+1,t.w,t.h-1)
  ICONS[t.icon](g,t.x+math.floor(t.w/2)-13,t.y+12)
  UI.text(g,c,t.x+t.w/2,t.y+42,t.label,'small','center',t.w-12)
end
local function footer(g,c,t,W)
  if t.id=='prev' then rule(g,0,t.y,W,1);rule(g,t.x+t.w-1,t.y+14,1,t.h-28) end
  if t.disabled then return end
  UI.region(t.x,t.y+1,t.w,t.h-1)
  local label=t.id=='prev' and 'Previous' or 'Next'
  local lw=UI.width(c,label,'small')
  local cx=t.x+math.floor(t.w/2)
  local lx=cx-math.floor((lw+18)/2)
  if t.id=='prev' then chevron(g,lx,t.y+32,-1);UI.text(g,c,lx+18,t.y+27,label,'small',nil,lw)
  else UI.text(g,c,lx,t.y+27,label,'small',nil,lw);chevron(g,lx+lw+12,t.y+32,1) end
end
-- Bitmap glyphs cover ASCII; map common typographic marks so a title keeps
-- one face instead of falling back to the native font for the whole line.
local MARKS={['\226\128\152']="'",['\226\128\153']="'",['\226\128\156']='"',['\226\128\157']='"',
  ['\226\128\147']='-',['\226\128\148']='-',['\226\128\166']='...',['\194\160']=' '}
function Shell.clean(s)
  s=tostring(s or '')
  for from,to in pairs(MARKS) do s=s:gsub(from,to) end
  return (s:gsub('%s+',' '):gsub('^ ',''):gsub(' $',''))
end
local function stat(g,c,x,y,w,value,label)
  UI.text(g,c,x,y,value,'control',nil,w)
  UI.text(g,c,x,y+UI.height(c,'control')+2,label,'small',nil,w)
end
local function reading(g,c,S,t)
  frame(g,t.x,t.y,t.w,t.h);UI.region(t.x,t.y,t.w,t.h)
  local x,w=t.x+20,t.w-40
  local y=t.y+20
  UI.text(g,c,x,y,'READING NOW','small',nil,w)
  y=y+UI.height(c,'small')+12
  local book=S.current
  if not S.reader then
    y=lines(g,c,x,y,w,'Reading details unavailable','control',2)+6
    lines(g,c,x,y,w,'This firmware did not share reading statistics with the shell.','small',4)
    return
  end
  if not book then
    y=lines(g,c,x,y,w,'No book open yet','control',2)+6
    lines(g,c,x,y,w,'The book you read in the reader appears here.','small',3)
    return
  end
  y=lines(g,c,x,y,w,Shell.clean(book.title)~='' and Shell.clean(book.title) or 'Untitled','control',t.h>=360 and 3 or 2)+2
  local author=Shell.clean(book.author)
  if author~='' then y=lines(g,c,x,y,w,author,'small',1) end
  local bottom=t.y+t.h-20
  local hint_y=bottom-UI.height(c,'small')
  UI.text(g,c,x,hint_y,'Continue in the reader','small',nil,w)
  local bar_y=hint_y-22
  frame(g,x,bar_y,w,10)
  local pct=math.max(0,math.min(100,math.floor((tonumber(book.percent) or 0)+0.5)))
  local fill=math.floor((w-4)*pct/100)
  if fill>0 then rule(g,x+2,bar_y+2,fill,6) end
  local row_y=bar_y-8-UI.height(c,'small')
  if row_y<=y+8 then return end
  local half=math.floor(w/2)
  UI.text(g,c,x,row_y,pct..'% read','small',nil,half)
  -- Reading statistics fill the space between the title and progress.
  local stats={}
  if S.streak and S.streak>0 then stats[#stats+1]={S.streak==1 and '1 day' or S.streak..' days','reading streak'} end
  if S.today and S.today>0 then stats[#stats+1]={S.today..' min','read today'} end
  local block=UI.height(c,'control')+2+UI.height(c,'small')
  local sy=math.floor((y+row_y-block)/2)
  if #stats>0 and sy>=y+12 and sy+block<=row_y-12 then
    rule(g,x,sy-12,w,1)
    local sw=math.floor(w/#stats)
    for i,st in ipairs(stats) do stat(g,c,x+(i-1)*sw,sy,sw-8,st[1],st[2]) end
  elseif S.streak and S.streak>0 then
    -- Short cards keep the streak beside the progress figure.
    local streak=S.streak==1 and '1-day streak' or S.streak..'-day streak'
    local sw=math.min(UI.width(c,streak,'small'),half-8)
    UI.text(g,c,x+w-sw,row_y,streak,'small',nil,sw)
  end
end
local function resume(g,c,S,t,game)
  frame(g,t.x,t.y,t.w,t.h);UI.region(t.x,t.y,t.w,t.h)
  local x,w=t.x+20,t.w-56
  local y=t.y+20
  UI.text(g,c,x,y,'CONTINUE PLAYING','small',nil,w)
  y=y+UI.height(c,'small')+10
  y=lines(g,c,x,y,w,game.name,'control',t.h>=200 and 2 or 1)+2
  if y+UI.height(c,'small')<=t.y+t.h-16 then lines(g,c,x,y,w,game.description,'small',t.h>=200 and 3 or 1) end
  chevron(g,t.x+t.w-28,t.y+math.floor(t.h/2)-6,1)
end
local function row(g,c,t)
  local item=t.item
  if item.passive then rule(g,t.x,t.y+t.h-1,t.w,1) else frame(g,t.x,t.y,t.w,t.h) end
  UI.region(t.x,t.y,t.w,t.h)
  local w=t.w-(item.passive and 8 or 52)
  local x=t.x+(item.passive and 4 or 16)
  UI.text(g,c,x,t.y+14,Shell.clean(item.title),'medium',nil,w)
  if item.meta then UI.text(g,c,x,t.y+52,Shell.clean(item.meta),'small',nil,w) end
  if not item.passive then chevron(g,t.x+t.w-26,t.y+40,1) end
end

function Shell.draw(g,c,S,W,H,targets,catalogue)
  g:clear(0)
  if S.screen=='blocked' then
    UI.text(g,c,M,24,'Games Hub','large',nil,W-2*M)
    UI.paragraph(g,c,M,90,W-2*M,H-90-NAV-2*M,S.notice or '','medium')
    local t=targets[1];UI.button(g,c,t.x,t.y,t.w,t.h,'Retry import')
    return
  end
  header(g,c,S,W,targets)
  if S.screen~='home' then
    local titles={library='Books',games='Games',settings='Settings'}
    UI.text(g,c,M,HEAD+14,titles[S.screen],'large',nil,W-2*M)
  end
  local tab_count=0
  for _,t in ipairs(targets) do if t.id:sub(1,4)=='tab:' then tab_count=tab_count+1 end end
  local seen_tab=0
  for _,t in ipairs(targets) do
    if t.id=='reading' then reading(g,c,S,t)
    elseif t.id=='resume' then resume(g,c,S,t,catalogue[S.last])
    elseif t.id:sub(1,4)=='tab:' then seen_tab=seen_tab+1;tab(g,c,t,W,seen_tab==tab_count)
    elseif t.id=='prev' or t.id=='next' then footer(g,c,t,W)
    elseif t.item then row(g,c,t) end
  end
  if S.screen~='home' and S.items and #S.items==0 then
    local top=list_bounds(W,H)
    UI.paragraph(g,c,M,top,W-2*M,120,S.empty or '','small')
  end
  if S.notice then
    local y=H-NAV-STATUS+6
    UI.text(g,c,W/2,y,S.notice,'small','center',W-2*M)
  end
end
return Shell
