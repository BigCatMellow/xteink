-- Nonogram: original picture-logic puzzles for XTEINK X4 Pro.
-- Tap cells to cycle blank -> ink -> X. Static monochrome refresh only.
local UI=require('ui')
local Pictures=require('pictures')
local TOTAL=#Pictures
local C,S,ERR,MSG=nil,nil,nil,nil
local HELP=false
local KEY_MS=-1000
local function copy(arr)
  local dst={}
  for i,v in ipairs(arr) do dst[i]=v end
  return dst
end
local function runs(seq)
  local out={}
  local count=0
  for i=1,#seq do
    if seq[i]=='#' or seq[i]==1 then count=count+1
    elseif count>0 then out[#out+1]=count;count=0 end
  end
  if count>0 then out[#out+1]=count end
  if #out==0 then out={0} end
  return out
end
local function shape(level)
  local p=Pictures[level]
  if not p then error('Missing picture') end
  local n=#p.rows
  local rows,cols={},{}
  for y=1,n do
    if #p.rows[y]~=n then error('Non-square picture') end
    local cells={}
    for x=1,n do cells[x]=p.rows[y]:sub(x,x) end
    rows[y]=runs(cells)
  end
  for x=1,n do
    local cells={}
    for y=1,n do cells[y]=p.rows[y]:sub(x,x) end
    cols[x]=runs(cells)
  end
  return {n=n,name=p.name,rows=p.rows,rowClues=rows,colClues=cols}
end
local function fresh_marks(n)
  local t={}
  for i=1,n*n do t[i]=0 end
  return t
end
local function code(marks)
  local v={}
  for i,n in ipairs(marks) do v[i]=tostring(n) end
  return table.concat(v)
end
local function decode(s,n)
  if type(s)~='string' or #s~=n*n or s:find('[^012]') then return nil end
  local a={}
  for i=1,#s do a[i]=tonumber(s:sub(i,i)) end
  return a
end
local function picture_correct(level,marks)
  local p=Pictures[level]
  local n=#p.rows
  for y=1,n do
    for x=1,n do
      local i=(y-1)*n+x
      if (marks[i]==1)~=(p.rows[y]:sub(x,x)=='#') then return false end
    end
  end
  return true
end
local function current()
  return shape(S.level)
end
local function hint_equal(a,b)
  if #a~=#b then return false end
  for i=1,#a do if a[i]~=b[i] then return false end end
  return true
end
local function counters()
  local p=current()
  local marks=S.boards[S.level]
  local rowOK,colOK=0,0
  for y=1,p.n do
    local state={}
    for x=1,p.n do state[x]=marks[(y-1)*p.n+x] end
    if hint_equal(runs(state),p.rowClues[y]) then rowOK=rowOK+1 end
  end
  for x=1,p.n do
    local state={}
    for y=1,p.n do state[y]=marks[(y-1)*p.n+x] end
    if hint_equal(runs(state),p.colClues[x]) then colOK=colOK+1 end
  end
  return rowOK,colOK
end
local function save()
  if not S or not C or not C.storage then return end
  local lines={'version=1','level='..S.level,'unlocked='..S.unlocked}
  local won={}
  for i=1,TOTAL do won[i]=S.submitted[i] and '1' or '0' end
  lines[#lines+1]='submitted='..table.concat(won)
  for i=1,TOTAL do
    lines[#lines+1]='B'..i..'='..code(S.boards[i])
    local past={}
    for j,m in ipairs(S.history[i]) do past[j]=code(m) end
    lines[#lines+1]='H'..i..'='..table.concat(past,';')
  end
  pcall(function() C.storage:write('nonogram.txt',table.concat(lines,'\n')) end)
end
local function start()
  S={level=1,unlocked=1,boards={},history={},submitted={}}
  for i=1,TOTAL do
    S.boards[i]=fresh_marks(#Pictures[i].rows)
    S.history[i]={}
    S.submitted[i]=false
  end
  MSG='Fill cells to match each run'
  HELP=false
  save()
end
local function restore()
  if not C or not C.storage then return false end
  local ok,data=pcall(function() return C.storage:read('nonogram.txt') end)
  if not ok or type(data)~='string' then return false end
  local f={}
  for k,v in data:gmatch('([%w_]+)=([^\n]*)') do f[k]=v end
  if f.version~='1' then return false end
  local level,unlocked=tonumber(f.level),tonumber(f.unlocked)
  if not level or level~=math.floor(level) or level<1 or level>TOTAL or
     not unlocked or unlocked~=math.floor(unlocked) or unlocked<level or unlocked>TOTAL or
     type(f.submitted)~='string' or #f.submitted~=TOTAL or
     f.submitted:find('[^01]') then return false end
  local loaded={level=level,unlocked=unlocked,boards={},history={},submitted={}}
  for i=1,TOTAL do
    local n=#Pictures[i].rows
    local marks=decode(f['B'..i],n)
    if not marks then return false end
    loaded.boards[i]=marks
    local hist={}
    for part in (f['H'..i] or ''):gmatch('[^;]+') do
      local snapshot=decode(part,n)
      if not snapshot or #hist>=16 then return false end
      hist[#hist+1]=snapshot
    end
    loaded.history[i]=hist
    loaded.submitted[i]=f.submitted:sub(i,i)=='1'
    if loaded.submitted[i] and not picture_correct(i,marks) then return false end
    if loaded.submitted[i] and i<TOTAL and unlocked<i+1 then return false end
  end
  S=loaded
  HELP=false;MSG=nil
  return true
end
local function visit(level)
  if not S or level<1 or level>TOTAL or level>S.unlocked then return false end
  S.level=level
  MSG=nil;HELP=false
  save()
  return true
end
local function prev() return S and visit(S.level-1) or false end
local function next_level() return S and visit(S.level+1) or false end
local function paint(x,y)
  if not S then return false end
  local p=current()
  if x<1 or x>p.n or y<1 or y>p.n or S.submitted[S.level] then return false end
  local i=(y-1)*p.n+x
  local history=S.history[S.level]
  if #history>=16 then table.remove(history,1) end
  history[#history+1]=copy(S.boards[S.level])
  local board=S.boards[S.level]
  board[i]=(board[i]+1)%3
  MSG=nil
  save()
  return true
end
local function undo()
  if not S or S.submitted[S.level] then return false end
  local past=S.history[S.level]
  if #past==0 then return false end
  S.boards[S.level]=table.remove(past)
  MSG='Last cell restored'
  save()
  return true
end
local function reset()
  if not S then return false end
  local n=S.level
  S.boards[n]=fresh_marks(#Pictures[n].rows)
  S.history[n]={}
  S.submitted[n]=false
  MSG='Fresh grid'
  save()
  return true
end
local function check()
  if not S or S.submitted[S.level] then return false end
  if picture_correct(S.level,S.boards[S.level]) then
    S.submitted[S.level]=true
    S.unlocked=math.min(TOTAL,math.max(S.unlocked,S.level+1))
    MSG='REVEALED: '..Pictures[S.level].name
  else
    MSG='Not solved - review the clues'
  end
  save()
  return true
end
local function geometry()
  local n=#Pictures[S.level].rows
  if n==5 then return 147,262,58 end
  if n==7 then return 138,247,44 end
  return 135,246,39
end
local function button(g,x,y,w,h,s)
  UI.button(g,C,x,y,w,h,s)
end
local function text(g,x,y,s,style,align,width)
  UI.text(g,C,x,y,s,style,align,width)
end
local function format_run(list)
  local result={}
  for i,v in ipairs(list) do result[i]=tostring(v) end
  return table.concat(result,' ')
end
local function help_screen(g)
  text(g,240,174,'HOW TO SOLVE','large','center',420)
  UI.paragraph(g,C,25,235,430,126,
    'Numbers give the lengths of black runs. Separate each run by a blank cell.', 'medium')
  UI.paragraph(g,C,25,369,430,110,
    'Tap a cell: blank, black, X, then clear. X means empty.', 'medium')
  UI.paragraph(g,C,25,490,430,147,
    'CHECK submits the picture. Wrong grids remain editable. Progress and UNDO are saved.', 'medium')
  button(g,75,710,330,65,'BACK TO GRID')
end
local function draw(g)
  g:clear(0)
  text(g,23,17,'NONOGRAM','large',nil,285)
  if S.level<S.unlocked and S.level<TOTAL then
    button(g,320,13,95,45,'NEXT')
  end
  button(g,425,13,35,45,HELP and 'X' or '?')
  local p=current()
  text(g,23,76,'PUZZLE '..S.level..' / '..TOTAL..'     '..p.n..' x '..p.n,'medium',nil,435)
  text(g,23,115,'NUMBERS = RUNS OF BLACK CELLS','small',nil,430)
  g:line(22,151,458,151,{line_width=2})
  if HELP then help_screen(g);return end
  local bx,by,cell=geometry()
  UI.region(bx,by,cell*p.n,cell*p.n)
  local board=S.boards[S.level]
  for x=1,p.n do
    local clue=p.colClues[x]
    local cx=bx+(x-.5)*cell
    for j=1,#clue do
      text(g,cx,219+(j-#clue)*23,tostring(clue[j]),'small','center',cell-6)
    end
  end
  for y=1,p.n do
    local cy=by+(y-1)*cell+math.floor((cell-20)/2)
    text(g,23,cy,format_run(p.rowClues[y]),'small',nil,bx-35)
  end
  for y=1,p.n do
    for x=1,p.n do
      local i=(y-1)*p.n+x
      local px=bx+(x-1)*cell
      local py=by+(y-1)*cell
      g:rect(px,py,cell,cell,{line_width=1})
      if board[i]==1 then
        g:rect(px+4,py+4,cell-8,cell-8,{fill=true})
      elseif board[i]==2 then
        g:line(px+12,py+12,px+cell-12,py+cell-12,{line_width=2})
        g:line(px+cell-12,py+12,px+12,py+cell-12,{line_width=2})
      end
    end
  end
  local rows,cols=counters()
  text(g,240,582,'ROWS '..rows..'/'..p.n..'     COLUMNS '..cols..'/'..p.n,'medium','center',420)
  text(g,240,619,MSG or 'Tap a cell: black / X / clear','small','center',424)
  text(g,240,660,S.submitted[S.level] and 'PICTURE: '..p.name or 'PICTURE HIDDEN UNTIL CHECK','small','center',425)
  button(g,21,710,101,65,S.level>1 and 'PREV' or 'START')
  button(g,133,710,101,65,'UNDO')
  button(g,245,710,101,65,'RESET')
  button(g,357,710,102,65,S.submitted[S.level] and 'DONE' or 'CHECK')
end
local function hit(x,y,bx,by,w,h)
  return x>=bx and x<bx+w and y>=by and y<by+h
end
local function tap(x,y)
  if hit(x,y,425,13,35,45) then HELP=not HELP;return true end
  if HELP then
    if hit(x,y,75,710,330,65) then HELP=false;return true end
    return false
  end
  if hit(x,y,320,13,95,45) then return next_level() end
  if hit(x,y,21,710,101,65) then return prev() end
  if hit(x,y,133,710,101,65) then return undo() end
  if hit(x,y,245,710,101,65) then return reset() end
  if hit(x,y,357,710,102,65) then return check() end
  local p=current()
  local bx,by,cell=geometry()
  if hit(x,y,bx,by,cell*p.n,cell*p.n) then
    return paint(math.floor((x-bx)/cell)+1,math.floor((y-by)/cell)+1)
  end
  return false
end
local function redraw()
  if C then pcall(function() C:invalidate() end) end
end
function on_load(context)
  C=context or ctx;ERR=nil
  local ok,e=pcall(function() if not restore() then start() end end)
  if not ok then ERR=tostring(e) end
end
function on_draw(context,g)
  if context then C=context end
  if not g then return end
  if ERR then UI.error(g,C,'NONOGRAM',ERR);return end
  local ok,e=pcall(function() draw(g) end)
  if not ok then ERR=tostring(e);UI.error(g,C,'NONOGRAM',ERR) end
end
function on_input(context,event)
  if context then C=context end
  if ERR or not S or type(event)~='table' then return false end
  local changed=false
  local ok,e=pcall(function()
    if event.type=='pointer' or event.type=='touch' then
      if event.type=='pointer' and event.phase~='up' then return end
      if event.gesture and event.gesture~='tap' and event.gesture~='double_tap' then return end
      changed=tap(tonumber(event.x) or -1,tonumber(event.y) or -1)
    elseif event.type=='key' and (not event.phase or event.phase=='down') and
       (event.key=='up' or event.key=='down') then
      local now=tonumber(event.time_ms)
      if not now and C and C.clock then
        local yes,value=pcall(function() return C.clock:millis() end)
        if yes then now=tonumber(value) end
      end
      if now and now>=KEY_MS and now-KEY_MS<230 then return end
      if now then KEY_MS=now end
      changed=event.key=='up' and prev() or next_level()
    end
  end)
  if not ok then ERR=tostring(e);changed=true end
  if changed then redraw() end
  return changed
end
function on_leave() if S then save() end end
if rawget(_G,'__TEST') then
  __TEST.api={
    pictures=Pictures,state=function() return S end,
    shape=shape,runs=runs,correct=picture_correct,paint=paint,
    check=check,reset=reset,undo=undo,visit=visit,next=next_level,
    prev=prev,geometry=geometry,counters=counters,tap=tap,restore=restore
  }
end
