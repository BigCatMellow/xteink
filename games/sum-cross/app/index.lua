-- Sum Cross: original Kakuro / Cross Sums logic for XTEINK X4 Pro.
-- Digit keypad, all-white static e-ink presentation; no animations.
local UI=require('ui')
local Theme=require('theme')
local DATA=require('puzzles')
local TOTAL=#DATA
local C,S,ERR,MSG=nil,nil,nil,nil
local HELP=false
local KEY_MS=-1000
local function grid(level)
  local p=DATA[level]
  local n=#p.rows
  local white={}
  local runs={}
  for y=1,n do
    assert(#p.rows[y]==n,'row length')
    for x=1,n do
      local i=(y-1)*n+x
      white[i]=p.rows[y]:sub(x,x)=='.'
    end
  end
  for i,goal in pairs(p.across) do
    assert(not white[i])
    local cells={}
    local x=(i-1)%n+1
    local y=math.floor((i-1)/n)+1
    for xx=x+1,n do
      local q=(y-1)*n+xx
      if not white[q] then break end
      cells[#cells+1]=q
    end
    assert(#cells>=2,'across length')
    runs[#runs+1]={type='A',sum=goal,cells=cells}
  end
  for i,goal in pairs(p.down) do
    assert(not white[i])
    local x=(i-1)%n+1
    local y=math.floor((i-1)/n)+1
    local cells={}
    for yy=y+1,n do
      local q=(yy-1)*n+x
      if not white[q] then break end
      cells[#cells+1]=q
    end
    assert(#cells>=2,'down length')
    runs[#runs+1]={type='D',sum=goal,cells=cells}
  end
  return {n=n,p=p,white=white,runs=runs}
end
local function zeros(n)
  local a={}
  for i=1,n do a[i]=0 end
  return a
end
local function clone(a)
  local t={}
  for i,v in ipairs(a) do t[i]=v end
  return t
end
local function encode(a)
  local t={}
  for i,v in ipairs(a) do t[i]=tostring(v) end
  return table.concat(t)
end
local function decode(s,g)
  if type(s)~='string' or #s~=g.n*g.n or s:find('[^0-9]') then return nil end
  local a={}
  for i=1,#s do
    a[i]=tonumber(s:sub(i,i))
    if not g.white[i] and a[i]~=0 then return nil end
  end
  return a
end
local function valid(level,values)
  local g=grid(level)
  for i,isWhite in ipairs(g.white) do
    if isWhite and (values[i]<1 or values[i]>9) then return false end
  end
  for _,run in ipairs(g.runs) do
    local total,seen=0,{}
    for _,i in ipairs(run.cells) do
      local v=values[i]
      if v==0 or seen[v] then return false end
      seen[v]=true;total=total+v
    end
    if total~=run.sum then return false end
  end
  return true
end
local function progress()
  local g=grid(S.level)
  local a=S.boards[S.level]
  local count,total=0,0
  for i,v in ipairs(a) do
    if g.white[i] then total=total+1;if v>0 then count=count+1 end end
  end
  return count,total
end
local function save()
  if not S or not C or not C.storage then return end
  local lines={'version=1','level='..S.level,'unlocked='..S.unlocked}
  for i=1,TOTAL do
    lines[#lines+1]='B'..i..'='..encode(S.boards[i])
    lines[#lines+1]='S'..i..'='..S.selected[i]
    lines[#lines+1]='W'..i..'='..(S.submitted[i] and '1' or '0')
    local hist={}
    for j,v in ipairs(S.history[i]) do hist[j]=encode(v) end
    lines[#lines+1]='H'..i..'='..table.concat(hist,';')
  end
  pcall(function() C.storage:write('sum-cross.txt',table.concat(lines,'\n')) end)
end
local function start()
  S={level=1,unlocked=1,boards={},selected={},history={},submitted={}}
  for i=1,TOTAL do
    S.boards[i]=zeros(grid(i).n^2)
    S.selected[i]=0;S.history[i]={};S.submitted[i]=false
  end
  HELP=false;MSG='Select a white square and a digit'
  save()
end
local function restore()
  if not C or not C.storage then return false end
  local ok,data=pcall(function() return C.storage:read('sum-cross.txt') end)
  if not ok or type(data)~='string' then return false end
  local f={}
  for k,v in data:gmatch('([%w_]+)=([^\n]*)') do f[k]=v end
  local lvl,u=tonumber(f.level),tonumber(f.unlocked)
  if f.version~='1' or not lvl or lvl~=math.floor(lvl) or lvl<1 or lvl>TOTAL or
     not u or u~=math.floor(u) or u<lvl or u>TOTAL then return false end
  local nextS={level=lvl,unlocked=u,boards={},selected={},history={},submitted={}}
  for i=1,TOTAL do
    local g=grid(i)
    local values=decode(f['B'..i],g)
    local select=tonumber(f['S'..i])
    local won=f['W'..i]
    if not values or not select or select~=math.floor(select) or select<0 or select>g.n*g.n or
       (select>0 and not g.white[select]) or (won~='0' and won~='1') then return false end
    if won=='1' and (not valid(i,values) or (i<TOTAL and u<i+1)) then return false end
    nextS.boards[i]=values;nextS.selected[i]=select
    nextS.submitted[i]=won=='1'
    local history={}
    for raw in (f['H'..i] or ''):gmatch('[^;]+') do
      if #history>=12 then return false end
      local a=decode(raw,g)
      if not a then return false end
      history[#history+1]=a
    end
    nextS.history[i]=history
  end
  S=nextS;HELP=false;MSG=nil;return true
end
local function visit(n)
  if not S or n<1 or n>TOTAL or n>S.unlocked then return false end
  S.level=n;MSG=nil;HELP=false;save();return true
end
local function previous() return S and visit(S.level-1) or false end
local function next_level() return S and visit(S.level+1) or false end
local function select_cell(i)
  if not S or S.submitted[S.level] or not grid(S.level).white[i] then return false end
  S.selected[S.level]=S.selected[S.level]==i and 0 or i
  MSG=S.selected[S.level]==0 and 'Selection cleared' or 'Choose a digit below'
  save();return true
end
local function digit(value)
  if not S or S.submitted[S.level] or value<0 or value>9 then return false end
  local i=S.selected[S.level]
  if i==0 then MSG='Select a white cell first';return true end
  local a=S.boards[S.level]
  if a[i]==value then return false end
  local h=S.history[S.level]
  if #h>=12 then table.remove(h,1) end
  h[#h+1]=clone(a)
  a[i]=value
  MSG=value==0 and 'Cell cleared' or 'Digit placed'
  save();return true
end
local function undo()
  if not S or S.submitted[S.level] then return false end
  local hist=S.history[S.level]
  if #hist==0 then return false end
  S.boards[S.level]=table.remove(hist)
  MSG='Last digit restored';save();return true
end
local function restart()
  if not S then return false end
  S.boards[S.level]=zeros(grid(S.level).n^2)
  S.history[S.level]={}
  S.selected[S.level]=0
  S.submitted[S.level]=false
  MSG='Fresh sums';save();return true
end
local function check()
  if not S or S.submitted[S.level] then return false end
  if valid(S.level,S.boards[S.level]) then
    S.submitted[S.level]=true
    S.unlocked=math.min(TOTAL,math.max(S.unlocked,S.level+1))
    MSG='ALL CROSS SUMS CORRECT!'
  else MSG='Not solved: review sums and repeats' end
  save();return true
end
local function geometry()
  local n=grid(S.level).n
  return UI.grid_geometry(n,112,512)
end
local function text(g,x,y,s,style,align,w) UI.text(g,C,x,y,s,style,align,w) end
local function button(g,x,y,w,h,s) UI.button(g,C,x,y,w,h,s) end
local function draw_help(g)
  text(g,240,163,'CROSS SUMS','large','center',427)
  UI.paragraph(g,C,28,224,424,113,
    'Each white run must add to its clue. A run cannot repeat a digit from 1 to 9.', 'medium')
  UI.paragraph(g,C,28,356,424,115,
    'Clue cells show DOWN at the top-right and ACROSS at the lower-left.', 'medium')
  UI.paragraph(g,C,28,488,424,120,
    'Select a white cell, then a keypad digit. CLR clears it. CHECK submits the finished puzzle.', 'medium')
  button(g,75,704,330,71,'BACK TO SUMS')
end
local function render(g)
  g:clear(0)
  text(g,21,15,'SUM CROSS','large',nil,310)
  button(g,416,12,48,48,HELP and 'X' or '?')
  if S.level<TOTAL and S.level<S.unlocked then button(g,309,12,98,43,'NEXT') end
  local gdata=grid(S.level)
  text(g,21,72,'PUZZLE '..S.level..' / '..TOTAL..'  '..gdata.n..'x'..gdata.n,'medium')
  if HELP then draw_help(g);return end
  local bx,by,cell=geometry()
  UI.region(bx,by,gdata.n*cell,gdata.n*cell)
  UI.grid(g,bx,by,gdata.n,gdata.n,cell)
  local board=S.boards[S.level]
  for y=1,gdata.n do
    for x=1,gdata.n do
      local i=(y-1)*gdata.n+x
      local px,py=bx+(x-1)*cell,by+(y-1)*cell
      if gdata.white[i] then
        if board[i]>0 then
          text(g,px+cell/2,py+math.floor((cell-24)/2),board[i],'medium','center',cell-10)
        end
        if S.selected[S.level]==i then g:rect(px+3,py+3,cell-6,cell-6,{line_width=3}) end
      else
        g:line(px+4,py+4,px+cell-4,py+cell-4,{line_width=1})
        local across=gdata.p.across[i]
        local down=gdata.p.down[i]
        if down then
          local w=UI.width(C,tostring(down),'clue_small')
          text(g,px+cell-5-w,py+4,down,'clue_small',nil,cell-10)
        end
        if across then text(g,px+5,py+cell-UI.height(C,'clue_small')-4,across,'clue_small',nil,cell-10) end
        if not across and not down then g:rect(px+3,py+3,cell-6,cell-6,{fill=true,radius=0}) end
      end
    end
  end
  local placed,total=progress()
  text(g,240,526,'FILLED '..placed..' / '..total,'medium','center',420)
  text(g,240,563,MSG or (S.submitted[S.level] and 'SOLVED' or 'Select cell, then number'),'small','center',435)
  for i=1,9 do
    local col=(i-1)%5
    local row=math.floor((i-1)/5)
    local x=15+col*93
    local y=600+row*56
    button(g,x,y,82,48,tostring(i))
  end
  button(g,387,656,82,48,'CLR')
  button(g,20,713,101,65,S.level>1 and 'PREV' or 'START')
  button(g,133,713,101,65,'UNDO')
  button(g,246,713,101,65,'RESET')
  button(g,359,713,101,65,S.submitted[S.level] and 'DONE' or 'CHECK')
end
local function hit(x,y,bx,by,w,h)return x>=bx and x<bx+w and y>=by and y<by+h end
local function tap(x,y)
  if hit(x,y,416,12,48,48) then HELP=not HELP;return true end
  if HELP then
    if hit(x,y,75,704,330,71) then HELP=false;return true end
    return false
  end
  if hit(x,y,309,12,98,43) then return next_level() end
  if hit(x,y,20,713,101,65) then return previous() end
  if hit(x,y,133,713,101,65) then return undo() end
  if hit(x,y,246,713,101,65) then return restart() end
  if hit(x,y,359,713,101,65) then return check() end
  for i=1,9 do
    local keyX=15+((i-1)%5)*93
    local keyY=600+math.floor((i-1)/5)*56
    if hit(x,y,keyX,keyY,82,48) then return digit(i) end
  end
  if hit(x,y,387,656,82,48) then return digit(0) end
  local n=grid(S.level).n
  local bx,by,cell=geometry()
  if hit(x,y,bx,by,n*cell,n*cell) then
    return select_cell(math.floor((y-by)/cell)*n+math.floor((x-bx)/cell)+1)
  end
  return false
end
local function redraw() if C then pcall(function() C:invalidate() end) end end
function on_load(ctx) Theme.release();C=ctx or context;ERR=nil
  local ok,e=pcall(function() if not restore() then start() end end)
  if not ok then ERR=tostring(e) end
end
function on_draw(ctx,g) if ctx then C=ctx end
  if not g then return end
  if ERR then UI.error(g,C,'SUM CROSS',ERR);return end
  local ok,e=pcall(function() Theme.draw(C,g,render) end)
  if not ok then ERR=tostring(e);UI.error(g,C,'SUM CROSS',ERR) end
end
function on_input(ctx,e) if ctx then C=ctx end
  if ERR or not S or type(e)~='table' then return false end
  local changed=false
  local ok,err=pcall(function()
    if e.type=='pointer' or e.type=='touch' then
      if e.type=='pointer' and e.phase~='up' then return end
      if e.gesture and e.gesture~='tap' and e.gesture~='double_tap' then return end
      changed=tap(tonumber(e.x) or -1,tonumber(e.y) or -1)
    elseif e.type=='key' and (not e.phase or e.phase=='down') and
       (e.key=='up' or e.key=='down') then
      local now=tonumber(e.time_ms)
      if not now and C and C.clock then
        local yes,v=pcall(function() return C.clock:millis() end)
        if yes then now=tonumber(v) end
      end
      if now and now>=KEY_MS and now-KEY_MS<230 then return end
      if now then KEY_MS=now end
      changed=e.key=='up' and previous() or next_level()
    end
  end)
  if not ok then ERR=tostring(err);changed=true end
  if changed then redraw() end
  return changed
end
function on_leave() Theme.release();if S then save() end end
if rawget(_G,'__TEST') then __TEST.api={
 levels=DATA,state=function()return S end,grid=grid,valid=valid,
 select=select_cell,digit=digit,undo=undo,check=check,
 restart=restart,visit=visit,next=next_level,prev=previous,
 geometry=geometry,tap=tap
} end
