-- Nonogram: original picture-logic puzzles for XTEINK X4 Pro.
-- Tap cells to cycle blank -> ink -> X. Static monochrome refresh only.
local UI=require('ui')
local Pictures=require('pictures')
local Generator=require('generator')
local Store=require('puzzle_store')
local Typefaces=require('typefaces')
local Family=require('game_style')
local TOTAL=#Pictures
local MAX=999999999
local generated=nil
local function picture(level)
  if level<=TOTAL then return Pictures[level] end
  if not generated or generated.number~=level then
    generated={number=level,puzzle=Generator.generate(level)}
  end
  return generated.puzzle
end
local C,S,ERR,MSG=nil,nil,nil,nil
local FONTSET,D=nil,nil
local FAILED_FONTSET=nil
local NEEDS_FONTS=true
local FONT_ERROR=nil
local HELP=false
local KEY_MS=-1000
-- One geometry contract for visible controls and touch. See docs/DESIGN.md.
local BUTTONS={
  help={408,20,48,48},next={352,78,104,44},
  prev={24,708,96,68},undo={132,708,96,68},
  reset={240,708,96,68},check={348,708,108,68},
  back={24,708,432,68}
}
local STYLE=Family
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
  local p=picture(level)
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
  local p=picture(level)
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
  local rowMatches,colMatches={},{}
  for y=1,p.n do
    local state={}
    for x=1,p.n do state[x]=marks[(y-1)*p.n+x] end
    rowMatches[y]=hint_equal(runs(state),p.rowClues[y])
    if rowMatches[y] then rowOK=rowOK+1 end
  end
  for x=1,p.n do
    local state={}
    for y=1,p.n do state[y]=marks[(y-1)*p.n+x] end
    colMatches[x]=hint_equal(runs(state),p.colClues[x])
    if colMatches[x] then colOK=colOK+1 end
  end
  return rowOK,colOK,rowMatches,colMatches
end
local function save()
  if not S or not C or not C.storage then return true end
  local lines={'version=2','level='..S.level,'unlocked='..S.unlocked}
  local won={}
  for i=1,TOTAL do won[i]=S.submitted[i] and '1' or '0' end
  lines[#lines+1]='submitted='..table.concat(won)
  for i=1,TOTAL do
    lines[#lines+1]='B'..i..'='..code(S.boards[i])
    local past={}
    for j,m in ipairs(S.history[i]) do past[j]=code(m) end
    lines[#lines+1]='H'..i..'='..table.concat(past,';')
  end
  local ok=pcall(function()
    if S.level>TOTAL then
      local past={}
      for j,m in ipairs(S.history[S.level]) do past[j]=code(m) end
      local data=table.concat({code(S.boards[S.level]),S.submitted[S.level] and '1' or '0',table.concat(past,';')},'\n')
      Store.put(C.storage,'pattern',S.level,data)
    end
    Store.write(C.storage,'nonogram.txt',table.concat(lines,'\n'))
  end)
  if not ok then MSG='Save failed - keep this puzzle open' end
  return ok
end
local function load_generated(state,level)
  if level<=TOTAL then return end
  local n=#picture(level).rows
  local marks,submitted,hist=fresh_marks(n),false,{}
  if C and C.storage then
    local data=Store.get(C.storage,'pattern',level)
    if type(data)=='string' then
      local b,won,past=data:match('^([^\n]+)\n([01])\n(.*)$')
      local decoded=decode(b,n)
      local valid=decoded~=nil
      for part in (past or ''):gmatch('[^;]+') do
        local snapshot=decode(part,n)
        if not snapshot or #hist>=16 then valid=false;break end
        hist[#hist+1]=snapshot
      end
      if valid and won and (won=='0' or picture_correct(level,decoded)) then
        marks=decoded;submitted=won=='1'
      else hist={} end
    end
  end
  state.boards[level]=marks;state.history[level]=hist;state.submitted[level]=submitted
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
  local ok,data=pcall(function()
    local data,err=C.storage:read('nonogram.txt')
    if not data and err and err~='not_found' then error('Save read failed') end
    return data
  end)
  if not ok then error('Could not read saved progress') end
  if type(data)~='string' then return false end
  local f={}
  for k,v in data:gmatch('([%w_]+)=([^\n]*)') do f[k]=v end
  if f.version~='1' and f.version~='2' then return false end
  local level,unlocked=tonumber(f.level),tonumber(f.unlocked)
  local limit=f.version=='1' and TOTAL or MAX
  if not level or level~=math.floor(level) or level<1 or level>limit or
     not unlocked or unlocked~=math.floor(unlocked) or unlocked<level or unlocked>limit or
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
  if loaded.submitted[TOTAL] then loaded.unlocked=math.max(unlocked,TOTAL+1) end
  load_generated(loaded,level)
  S=loaded
  HELP=false;MSG=nil
  return true
end
local function visit(level)
  if not S or level<1 or level>MAX or level~=math.floor(level) or level>S.unlocked then return false end
  if not save() then return true end
  if level>TOTAL then load_generated(S,level) end
  if S.level>TOTAL and S.level~=level then
    S.boards[S.level]=nil;S.history[S.level]=nil;S.submitted[S.level]=nil
  end
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
  S.boards[n]=fresh_marks(#picture(n).rows)
  S.history[n]={}
  S.submitted[n]=false
  MSG='Fresh grid'
  save()
  return true
end
local function display_name(name)
  return name:sub(1,1)..name:sub(2):lower()
end
local function check()
  if not S or S.submitted[S.level] then return false end
  if picture_correct(S.level,S.boards[S.level]) then
    S.submitted[S.level]=true
    S.unlocked=math.min(MAX,math.max(S.unlocked,S.level+1))
    MSG='Revealed: '..display_name(picture(S.level).name)
  else
    MSG='Not solved: review the clues'
  end
  save()
  return true
end
local function geometry()
  local p=current()
  local n=p.n
  local cell=n==5 and 68 or n==7 and 48 or 44
  local font=n==5 and 'clue' or 'clue_small'
  local widest,maxColumn=0,0
  for _,clue in ipairs(p.rowClues) do
    local values={};for i,v in ipairs(clue) do values[i]=tostring(v) end
    widest=math.max(widest,UI.width(D or C,table.concat(values,' '),font))
  end
  for _,clue in ipairs(p.colClues) do maxColumn=math.max(maxColumn,#clue) end
  local gutter=widest+16
  local height=UI.height(D or C,font)
  local clueArea=14+height+(maxColumn-1)*(height+6)
  -- Center the complete clue + board object in the 128..584 puzzle band.
  local x=math.floor((480-(n*cell+gutter))/2)+gutter
  local y=128+math.floor((456-(n*cell+clueArea))/2)+clueArea
  return x,y,cell,gutter,clueArea
end
local function button(g,key,label,primary,enabled)
  local b=BUTTONS[key]
  UI.button(g,D or C,b[1],b[2],b[3],b[4],label,false,{
    radius=STYLE.control_radius,line_width=enabled==false and STYLE.inactive_stroke or primary and STYLE.primary_stroke or STYLE.control_stroke
  })
end
local function text(g,x,y,s,style,align,width)
  UI.text(g,D or C,x,y,s,style,align,width)
end
local function format_run(list)
  local result={}
  for i,v in ipairs(list) do result[i]=tostring(v) end
  return table.concat(result,' ')
end
local function help_screen(g)
  text(g,240,164,'How to solve','large','center',432)
  UI.paragraph(g,D or C,24,222,432,118,
    'Each number is a run of filled cells. Leave at least one empty cell between runs.', 'body')
  UI.paragraph(g,D or C,24,350,432,120,
    'Tap a cell to cycle: filled, X, clear. X marks a cell you know is empty.', 'body')
  UI.paragraph(g,D or C,24,484,432,116,
    'Check reveals a solved picture. Undo and Reset affect this puzzle. Every board keeps your progress.', 'body')
  UI.paragraph(g,D or C,24,614,432,72,
    'Ticks mean a line matches its clues. More patterns follow picture 12.', 'small')
  button(g,'back','Back to puzzle',true)
end
local function tick(g,x,y)
  g:line(x,y+3,x+3,y+6,{line_width=3})
  g:line(x+3,y+6,x+8,y,{line_width=3})
end
local function draw(g)
  g:clear(0)
  -- A small tile mark supplies identity; the puzzle remains the dominant shape.
  g:rect(24,26,32,32,{radius=6,line_width=2})
  for _,a in ipairs({{1,0},{0,1},{1,1},{2,1},{1,2}}) do
    g:rect(30+a[1]*7,32+a[2]*7,5,5,{fill=true,radius=1})
  end
  text(g,72,25,'Nonogram','large',nil,312)
  button(g,'help',HELP and 'X' or '?')
  local p=current()
  text(g,24,89,'Puzzle '..S.level,'small',nil,230)
  text(g,274,89,p.n..' x '..p.n,'small',nil,66)
  if not HELP and not S.submitted[S.level] and S.level<S.unlocked then
    button(g,'next','Next')
  end
  if HELP then help_screen(g);return end
  local bx,by,cell=geometry()
  UI.region(bx,by,cell*p.n,cell*p.n)
  local board=S.boards[S.level]
  local rows,cols,rowMatches,colMatches=counters()
  local clueFont=p.n==5 and 'clue' or 'clue_small'
  local clueHeight=UI.height(D or C,clueFont)
  for x=1,p.n do
    local clue=p.colClues[x]
    local cx=bx+(x-.5)*cell
    for j=1,#clue do
      text(g,cx,by-14-clueHeight+(j-#clue)*(clueHeight+6),tostring(clue[j]),clueFont,'center',cell-8)
    end
    if colMatches[x] then tick(g,cx-4,by-10) end
  end
  for y=1,p.n do
    local cy=by+(y-1)*cell+math.floor((cell-clueHeight)/2)
    local label=format_run(p.rowClues[y])
    text(g,bx-16-UI.width(D or C,label,clueFont),cy,label,clueFont,nil,bx-40)
    if rowMatches[y] then tick(g,bx-12,by+(y-.5)*cell-3) end
  end
  for y=1,p.n do
    for x=1,p.n do
      local i=(y-1)*p.n+x
      local px=bx+(x-1)*cell
      local py=by+(y-1)*cell
      if board[i]==1 then
        g:rect(px+5,py+5,cell-10,cell-10,{fill=true,radius=STYLE.ink_radius})
      elseif board[i]==2 then
        local inset=math.floor(cell*.32)
        g:line(px+inset,py+inset,px+cell-inset,py+cell-inset,{line_width=STYLE.mark_stroke})
        g:line(px+cell-inset,py+inset,px+inset,py+cell-inset,{line_width=STYLE.mark_stroke})
      end
    end
  end
  for i=1,p.n-1 do
    local weight=i==5 and STYLE.frame_stroke or STYLE.grid_stroke
    UI.stroke(g,bx+i*cell,by,bx+i*cell,by+p.n*cell,weight)
    UI.stroke(g,bx,by+i*cell,bx+p.n*cell,by+i*cell,weight)
  end
  g:rect(bx,by,cell*p.n,cell*p.n,{line_width=STYLE.frame_stroke,radius=STYLE.board_radius})
  text(g,24,608,'Rows '..rows..' / '..p.n,'small',nil,200)
  text(g,264,608,'Columns '..cols..' / '..p.n,'small',nil,192)
  g:line(24,640,456,640,{line_width=1})
  local won=S.submitted[S.level]
  local status=MSG or (won and 'Revealed: '..display_name(p.name) or 'Tap a cell: fill / X / clear')
  text(g,240,660,status,'small','center',432)
  button(g,'prev','Prev',false,S.level>1)
  button(g,'undo','Undo',false,not won and #S.history[S.level]>0)
  button(g,'reset','Reset')
  button(g,'check',won and (S.level<S.unlocked and 'Next' or 'Done') or 'Check',true,not won or S.level<S.unlocked)
end
local function hit(x,y,bx,by,w,h)
  return x>=bx and x<bx+w and y>=by and y<by+h
end
local function control_hit(key,x,y)
  local b=BUTTONS[key]
  return hit(x,y,b[1],b[2],b[3],b[4])
end
local function tap(x,y)
  if control_hit('help',x,y) then HELP=not HELP;return true end
  if HELP then
    if control_hit('back',x,y) then HELP=false;return true end
    return false
  end
  if control_hit('next',x,y) and not S.submitted[S.level] then return next_level() end
  if control_hit('prev',x,y) then return prev() end
  if control_hit('undo',x,y) then return undo() end
  if control_hit('reset',x,y) then return reset() end
  if control_hit('check',x,y) then
    if S.submitted[S.level] then return next_level() else return check() end
  end
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
  if FONTSET then FONTSET:release() end
  if FAILED_FONTSET then FAILED_FONTSET:release();FAILED_FONTSET=nil end
  FONTSET=nil;D=nil;NEEDS_FONTS=true;FONT_ERROR=nil
  C=context or ctx;S=nil;ERR=nil;KEY_MS=-1000
  local ok,e=pcall(function() if not restore() then start() end end)
  if not ok then ERR=tostring(e) end
end
function on_draw(context,g)
  if context then C=context end
  if not g then return end
  if ERR then UI.error(g,C,'NONOGRAM',ERR);return end
  if NEEDS_FONTS then
    NEEDS_FONTS=false
    local ok,fonts,reason=pcall(function() return Typefaces.open(C) end)
    if ok then FONTSET=fonts;FONT_ERROR=reason else FONT_ERROR=tostring(fonts) end
    if not FONTSET and C and C.image then MSG='System fonts active' end
  end
  if FONTSET and type(g.image)~='function' then
    FONT_ERROR='Image drawing unavailable'
    FONTSET:release();FONTSET=nil;MSG='System fonts active'
  end
  D=FONTSET or C
  local ok,e=pcall(function() draw(g) end)
  if not ok and D==FONTSET then
    FONT_ERROR=tostring(e)
    -- Keep images alive until leave: earlier commands in this frame may own them.
    FAILED_FONTSET=FONTSET;FONTSET=nil;D=C
    MSG='System fonts active'
    ok,e=pcall(function() draw(g) end)
  end
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
      if event.key=='up' then changed=prev() else changed=next_level() end
    end
  end)
  if not ok then ERR=tostring(e);changed=true end
  if changed then redraw() end
  return changed
end
function on_leave()
  if S then save() end
  if FONTSET then FONTSET:release();FONTSET=nil end
  if FAILED_FONTSET then FAILED_FONTSET:release();FAILED_FONTSET=nil end
  D=nil;NEEDS_FONTS=true
end
if rawget(_G,'__TEST') then
  __TEST.api={
    pictures=Pictures,state=function() return S end,
    shape=shape,runs=runs,correct=picture_correct,paint=paint,
    check=check,reset=reset,undo=undo,visit=visit,next=next_level,
    prev=prev,geometry=geometry,counters=counters,tap=tap,restore=restore,
    controls=BUTTONS,style=STYLE,
    typefaces=function() return FONTSET,FONT_ERROR end
  }
end
