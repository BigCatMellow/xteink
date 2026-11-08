-- Crown Fields: original monochrome region-placement logic for XTOS Licorice.
local UI=require('ui')
local Levels=require('levels')
local C,S,ERR,MSG=nil,nil,nil,nil
local HELP=false
local KEY_MS=-1000
local TOTAL=#Levels
local function board(level)
  local rows=Levels[level].rows
  local n=#rows
  local regions={}
  for y=1,n do
    assert(#rows[y]==n,'board dimension')
    for x=1,n do regions[#regions+1]=rows[y]:sub(x,x) end
  end
  return {n=n,regions=regions}
end
local function zeros(n)
  local a={}
  for i=1,n do a[i]=0 end
  return a
end
local function clone(t)
  local a={}
  for i,v in ipairs(t) do a[i]=v end
  return a
end
local function pack(t)
  local a={}
  for i,v in ipairs(t) do a[i]=tostring(v) end
  return table.concat(a)
end
local function unpack_mask(raw,n)
  if type(raw)~='string' or #raw~=n or raw:find('[^012]') then return nil end
  local a={}
  for i=1,#raw do a[i]=tonumber(raw:sub(i,i)) end
  return a
end
local function valid(n,marks)
  local b=board(n)
  local row,col,reg={},{},{}
  local total=0
  local prev=-9
  for y=1,b.n do
    local placed=0
    for x=1,b.n do
      local i=(y-1)*b.n+x
      if marks[i]==2 then
        placed=placed+1;total=total+1
        col[x]=(col[x] or 0)+1
        reg[b.regions[i]]=(reg[b.regions[i]] or 0)+1
        if prev~=-9 and math.abs(prev-x)==1 then return false end
        row[y]=x
      end
    end
    if placed>1 then return false end
    if placed==1 then prev=row[y] else prev=-9 end
  end
  if total~=b.n then return false end
  for x=1,b.n do
    if col[x]~=1 or reg[string.char(64+x)]~=1 or not row[x] then return false end
  end
  return true
end
local function stats()
  local b=board(S.level)
  local a=S.marks[S.level]
  local count=0
  for _,v in ipairs(a) do if v==2 then count=count+1 end end
  return count,b.n
end
local function save()
  if not C or not C.storage or not S then return end
  local lines={'version=1','level='..S.level,'unlocked='..S.unlocked}
  for i=1,TOTAL do
    lines[#lines+1]='B'..i..'='..pack(S.marks[i])
    lines[#lines+1]='S'..i..'='..(S.submitted[i] and '1' or '0')
    local history={}
    for j,m in ipairs(S.history[i]) do history[j]=pack(m) end
    lines[#lines+1]='H'..i..'='..table.concat(history,';')
  end
  pcall(function() C.storage:write('crown-fields.txt',table.concat(lines,'\n')) end)
end
local function start()
  S={level=1,unlocked=1,marks={},submitted={},history={}}
  for i=1,TOTAL do
    local n=board(i).n
    S.marks[i]=zeros(n*n)
    S.submitted[i]=false
    S.history[i]={}
  end
  HELP=false;MSG='Tap: X / crown / clear'
  save()
end
local function restore()
  if not C or not C.storage then return false end
  local ok,raw=pcall(function() return C.storage:read('crown-fields.txt') end)
  if not ok or type(raw)~='string' then return false end
  local fields={}
  for k,v in raw:gmatch('([%w_]+)=([^\n]*)') do fields[k]=v end
  local lvl,unlock=tonumber(fields.level),tonumber(fields.unlocked)
  if fields.version~='1' or not lvl or lvl~=math.floor(lvl) or lvl<1 or lvl>TOTAL
     or not unlock or unlock~=math.floor(unlock) or unlock<lvl or unlock>TOTAL then return false end
  local nextS={level=lvl,unlocked=unlock,marks={},submitted={},history={}}
  for i=1,TOTAL do
    local n=board(i).n
    local mask=unpack_mask(fields['B'..i],n*n)
    if not mask then return false end
    local won=fields['S'..i]
    if won~='0' and won~='1' then return false end
    if won=='1' and (not valid(i,mask) or (i<TOTAL and unlock<i+1)) then return false end
    nextS.marks[i]=mask
    nextS.submitted[i]=won=='1'
    local history={}
    for item in (fields['H'..i] or ''):gmatch('[^;]+') do
      if #history>=12 then return false end
      local m=unpack_mask(item,n*n)
      if not m then return false end
      history[#history+1]=m
    end
    nextS.history[i]=history
  end
  S=nextS;HELP=false;MSG=nil
  return true
end
local function visit(n)
  if not S or n<1 or n>TOTAL or n>S.unlocked then return false end
  S.level=n;MSG=nil;HELP=false;save()
  return true
end
local function prev() return S and visit(S.level-1) or false end
local function next_level() return S and visit(S.level+1) or false end
local function mark(i)
  if not S or S.submitted[S.level] then return false end
  local a=S.marks[S.level]
  if not a[i] then return false end
  local h=S.history[S.level]
  if #h>=12 then table.remove(h,1) end
  h[#h+1]=clone(a)
  a[i]=(a[i]+1)%3
  MSG=nil;save();return true
end
local function undo()
  if not S or S.submitted[S.level] then return false end
  local h=S.history[S.level]
  if #h==0 then return false end
  S.marks[S.level]=table.remove(h);MSG='Last mark restored';save();return true
end
local function restart()
  if not S then return false end
  local n=board(S.level).n
  S.marks[S.level]=zeros(n*n)
  S.history[S.level]={}
  S.submitted[S.level]=false
  MSG='Fresh region grid';save();return true
end
local function check()
  if not S or S.submitted[S.level] then return false end
  if valid(S.level,S.marks[S.level]) then
    S.submitted[S.level]=true
    S.unlocked=math.min(TOTAL,math.max(S.unlocked,S.level+1))
    MSG='ALL REGIONS SOLVED!'
  else
    MSG='Check row, column, region and touching'
  end
  save();return true
end
local function geometry()
  local n=board(S.level).n
  local cell=n==5 and 70 or n==6 and 59 or 50
  return math.floor((480-cell*n)/2),187,cell
end
local function text(g,x,y,s,style,align,w) UI.text(g,C,x,y,s,style,align,w) end
local function button(g,x,y,w,h,s) UI.button(g,C,x,y,w,h,s) end
local function draw_help(g)
  text(g,240,165,'ONE IN EVERY REGION','large','center',430)
  UI.paragraph(g,C,28,234,424,107,
    'Place one crown in each row, each column, and each lettered region.', 'medium')
  UI.paragraph(g,C,28,360,424,109,
    'Crowns must never touch, even at a diagonal corner. Region letters replace colors.', 'medium')
  UI.paragraph(g,C,28,497,424,105,
    'Tap cells: X, crown, clear. Submit with CHECK. Use UNDO for mistakes.', 'medium')
  button(g,76,703,328,68,'BACK TO GRID')
end
local function render(g)
  g:clear(0)
  text(g,22,17,'CROWN FIELDS','large',nil,340)
  button(g,421,13,39,45,HELP and 'X' or '?')
  if S.level<TOTAL and S.level<S.unlocked then button(g,313,13,96,45,'NEXT') end
  text(g,22,75,'PUZZLE '..S.level..' / '..TOTAL,'medium')
  text(g,22,117,'REGIONS ARE LETTERED A TO G','small',nil,438)
  g:line(22,151,458,151,{line_width=2})
  if HELP then draw_help(g);return end
  local b=board(S.level)
  local bx,by,cell=geometry()
  UI.region(bx,by,b.n*cell,b.n*cell)
  for y=1,b.n do
    for x=1,b.n do
      local i=(y-1)*b.n+x
      local px,py=bx+(x-1)*cell,by+(y-1)*cell
      local code=b.regions[i]
      g:rect(px,py,cell,cell,{line_width=1})
      text(g,px+7,py+5,code,'small',nil,22)
      local v=S.marks[S.level][i]
      local cx,cy=px+cell/2,py+cell/2+3
      if v==1 then
        g:line(cx-12,cy-11,cx+12,cy+11,{line_width=3})
        g:line(cx-12,cy+11,cx+12,cy-11,{line_width=3})
      elseif v==2 then
        g:line(cx-17,cy-5,cx-12,cy+12,{line_width=3})
        g:line(cx-12,cy+12,cx+12,cy+12,{line_width=3})
        g:line(cx+12,cy+12,cx+17,cy-5,{line_width=3})
        g:line(cx-17,cy-5,cx-6,cy+2,{line_width=3})
        g:line(cx-6,cy+2,cx,cy-14,{line_width=3})
        g:line(cx,cy-14,cx+6,cy+2,{line_width=3})
        g:line(cx+6,cy+2,cx+17,cy-5,{line_width=3})
      end
      if x<b.n and code~=b.regions[i+1] then
        g:line(px+cell,py,px+cell,py+cell,{line_width=4})
      end
      if y<b.n and code~=b.regions[i+b.n] then
        g:line(px,py+cell,px+cell,py+cell,{line_width=4})
      end
    end
  end
  local crowns,target=stats()
  text(g,240,577,'CROWNS '..crowns..' / '..target,'medium','center',430)
  text(g,240,621,MSG or (S.submitted[S.level] and 'SOLVED' or 'Place crowns and press CHECK'),
       'small','center',438)
  text(g,240,661,'One crown per row / column / region','small','center',430)
  button(g,20,705,100,69,S.level>1 and 'PREV' or 'START')
  button(g,133,705,100,69,'UNDO')
  button(g,246,705,100,69,'RESET')
  button(g,359,705,101,69,S.submitted[S.level] and 'DONE' or 'CHECK')
end
local function hit(x,y,bx,by,w,h)
  return x>=bx and x<bx+w and y>=by and y<by+h
end
local function tap(x,y)
  if hit(x,y,421,13,39,45) then HELP=not HELP;return true end
  if HELP then
    if hit(x,y,76,703,328,68) then HELP=false;return true end
    return false
  end
  if hit(x,y,313,13,96,45) then return next_level() end
  if hit(x,y,20,705,100,69) then return prev() end
  if hit(x,y,133,705,100,69) then return undo() end
  if hit(x,y,246,705,100,69) then return restart() end
  if hit(x,y,359,705,101,69) then return check() end
  local b=board(S.level)
  local bx,by,cell=geometry()
  if hit(x,y,bx,by,cell*b.n,cell*b.n) then
    return mark(math.floor((y-by)/cell)*b.n+math.floor((x-bx)/cell)+1)
  end
  return false
end
local function invalidate() if C then pcall(function() C:invalidate() end) end end
function on_load(ctx) C=ctx or context;ERR=nil
  local ok,e=pcall(function() if not restore() then start() end end)
  if not ok then ERR=tostring(e) end
end
function on_draw(ctx,g) if ctx then C=ctx end
  if not g then return end
  if ERR then UI.error(g,C,'CROWN FIELDS',ERR);return end
  local ok,e=pcall(function() render(g) end)
  if not ok then ERR=tostring(e);UI.error(g,C,'CROWN FIELDS',ERR) end
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
      changed=e.key=='up' and prev() or next_level()
    end
  end)
  if not ok then ERR=tostring(err);changed=true end
  if changed then invalidate() end
  return changed
end
function on_leave() if S then save() end end
if rawget(_G,'__TEST') then
 __TEST.api={
   levels=Levels,board=board,valid=valid,state=function()return S end,
   mark=mark,undo=undo,check=check,restart=restart,visit=visit,
   next=next_level,prev=prev,geometry=geometry,tap=tap
 }
end
