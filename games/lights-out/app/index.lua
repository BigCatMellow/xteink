-- Lights Out for XTOS Licorice, ported from research/lights-out.html (PR #29).
-- Screen-first layout: the board owns the top 704px, one bottom bar holds the
-- move counter, Undo (Next when solved) and Menu; everything else is on the menu.
local UI=require('ui')
local Theme=require('theme')
local SIZES={
  {key='classic',label='Classic',cols=5,rows=5},
  {key='tall',label='Tall',cols=5,rows=7},
  {key='large',label='Large',cols=6,rows=9},
  {key='huge',label='Huge',cols=7,rows=10}}
local BY_KEY={}
for i,s in ipairs(SIZES) do BY_KEY[s.key]=i end
local SAVE='lights-out.txt'
local HISTORY_MAX=100
local GAP=3
local C,S,ERR,MSG=nil,nil,nil,nil
local MENU=false
local HINT=0          -- tile index of a shown hint, 0 for none
local SOLUTION=nil    -- cached {code=board,presses=...} for "Show solution"
-- One geometry contract for drawing and touch.
local AREA={x=0,y=0,w=480,h=704}
local BAR={counter={8,712,216,80},undo={232,712,116,80},menu={356,712,116,80}}
local MENU_BOX={
  size1={20,104,216,82},size2={244,104,216,82},size3={20,194,216,82},size4={244,194,216,82},
  restart={20,316,440,54},hint={20,378,440,54},solution={20,440,440,54},
  resume={20,716,440,64}}
local function layout_for_host()
  -- Inside the Games Hub the board starts below the Hub's reserved return key.
  if C and C.xteink_hub_embedded then AREA.y=66;AREA.h=638 else AREA.y=0;AREA.h=704 end
end
local function size() return SIZES[S.size] end

-- Pure rules -------------------------------------------------------------
local function press(board,i,cols,rows)
  local r,c=math.floor((i-1)/cols),(i-1)%cols
  board[i]=1-board[i]
  if r>0 then board[i-cols]=1-board[i-cols] end
  if r+1<rows then board[i+cols]=1-board[i+cols] end
  if c>0 then board[i-1]=1-board[i-1] end
  if c+1<cols then board[i+1]=1-board[i+1] end
  return board
end
local function all_off(board)
  for i=1,#board do if board[i]~=0 then return false end end
  return true
end
local function copy(a) local b={};for i=1,#a do b[i]=a[i] end;return b end
-- Every solution is fixed by its first-row presses ("light chasing"): try all
-- 2^cols first rows, chase each light down a row, keep those that clear the
-- last row, and take the fewest presses. 128 tries at most; no matrix needed.
local function solve(board,cols,rows)
  local n=cols*rows
  local best,bestCount=nil,n+1
  for mask=0,math.floor(2^cols)-1 do
    local b,p,count=copy(board),{},0
    for i=1,n do p[i]=0 end
    for c=1,cols do
      if math.floor(mask/2^(c-1))%2==1 then p[c]=1;count=count+1;press(b,c,cols,rows) end
    end
    for i=cols+1,n do
      if b[i-cols]==1 then p[i]=1;count=count+1;press(b,i,cols,rows) end
    end
    local clear=true
    for i=n-cols+1,n do if b[i]~=0 then clear=false;break end end
    if clear and count<bestCount then best,bestCount=p,count end
  end
  if not best then return nil end
  return {presses=best,count=bestCount}
end
local seeded=false
local function random_bit()
  if not seeded then
    seeded=true
    local now=0
    if C and C.clock and type(C.clock.millis)=='function' then
      local ok,v=pcall(function() return C.clock:millis() end)
      if ok and type(v)=='number' then now=math.floor(v)%2147483647 end
    end
    pcall(math.randomseed,now)
  end
  return math.random(0,1)
end
local function generate(cols,rows,source,exclude)
  source=source or random_bit
  local n=cols*rows
  for _=1,200 do
    local board={}
    for i=1,n do board[i]=0 end
    for i=1,n do if source()==1 then press(board,i,cols,rows) end end
    if not all_off(board) then
      local s=solve(board,cols,rows)
      if s and s.count>=4 and table.concat(board)~=exclude then return board,s.count end
    end
  end
  return nil,'No puzzle - retry'
end

-- Saves ------------------------------------------------------------------
local function code(board) return table.concat(board) end
local function parse(s,n)
  if type(s)~='string' or #s~=n or s:find('[^01]') then return nil end
  local b={}
  for i=1,n do b[i]=s:byte(i)-48 end
  return b
end
local function save()
  if not S or not C or not C.storage then return true end
  local past={}
  for i,h in ipairs(S.history) do past[i]=code(h.board)..':'..h.moves end
  local data=table.concat({'version=1','size='..size().key,'initial='..code(S.initial),
    'board='..code(S.board),'moves='..S.moves,'show='..(S.show and '1' or '0'),
    'history='..table.concat(past,';')},'\n')
  local ok=pcall(function()
    local success,err=C.storage:write(SAVE,data)
    if success==false or (success==nil and err) then error(tostring(err)) end
  end)
  if not ok then MSG='Save failed - keep this puzzle open' end
  return ok
end
local function new_game(index,source)
  local sz=SIZES[index]
  local old=S
  local exclude=old and old.size==index and code(old.initial) or nil
  local board,par=generate(sz.cols,sz.rows,source,exclude)
  if not board then MSG='No puzzle - retry';return false end
  local show=S and S.show or false
  S={size=index,initial=board,board=copy(board),par=par,moves=0,history={},won=false,show=show}
  if not save() then S=old;return false end
  MENU=false;HINT=0;SOLUTION=nil;MSG=nil
  return true
end
local function restore()
  if not C or not C.storage then return false end
  local ok,data=pcall(function() return C.storage:read(SAVE) end)
  if not ok or type(data)~='string' then return false end
  local f={}
  for k,v in data:gmatch('([%w_]+)=([^\n]*)') do f[k]=v end
  local index=BY_KEY[f.size or '']
  if f.version~='1' or not index then return false end
  local sz=SIZES[index];local n=sz.cols*sz.rows
  local initial,board=parse(f.initial,n),parse(f.board,n)
  local moves=tonumber(f.moves)
  if not initial or not board or not moves or moves<0 or moves%1~=0 then return false end
  local first=solve(initial,sz.cols,sz.rows)
  if not first or first.count<4 or not solve(board,sz.cols,sz.rows) then return false end
  local history={}
  for item in (f.history or ''):gmatch('[^;]+') do
    local b,m=item:match('^([01]+):(%d+)$')
    local hb=parse(b,n)
    if hb and #history<HISTORY_MAX then history[#history+1]={board=hb,moves=tonumber(m)} end
  end
  S={size=index,initial=initial,board=board,par=first.count,moves=moves,history=history,
    won=all_off(board),show=f.show=='1'}
  return true
end

-- Actions ----------------------------------------------------------------
local function tap_tile(i)
  if S.won then return false end
  local sz=size()
  S.history[#S.history+1]={board=copy(S.board),moves=S.moves}
  if #S.history>HISTORY_MAX then table.remove(S.history,1) end
  press(S.board,i,sz.cols,sz.rows)
  S.moves=S.moves+1;HINT=0;MSG=nil
  S.won=all_off(S.board)
  save();return true
end
local function undo()
  local last=table.remove(S.history)
  if not last then return false end
  S.board=last.board;S.moves=last.moves;S.won=all_off(S.board);HINT=0;MSG=nil
  save();return true
end
local function restart()
  S.board=copy(S.initial);S.moves=0;S.history={};S.won=false;HINT=0;MSG=nil;MENU=false
  save();return true
end
local function solution()
  local c=code(S.board)
  if not SOLUTION or SOLUTION.code~=c then
    local sz=size()
    local s=solve(S.board,sz.cols,sz.rows)
    SOLUTION={code=c,presses=s and s.presses}
  end
  return SOLUTION.presses
end
local function hint()
  HINT=0;MENU=false
  if S.won then return true end
  local p=solution()
  if p then for i=1,#p do if p[i]==1 then HINT=i;break end end end
  return true
end
local function toggle_solution() S.show=not S.show;HINT=0;save();return true end

-- Drawing ----------------------------------------------------------------
local function text(g,x,y,s,font,align,w) UI.text(g,C,x,y,s,font,align,w) end
local function button(g,box,label,marked,options)
  UI.button(g,C,box[1],box[2],box[3],box[4],label,marked,options)
end
local function tile_geometry()
  local sz=size()
  local iw,ih=AREA.w-6,AREA.h-6
  local tile=math.floor(math.min((iw-(sz.cols-1)*GAP)/sz.cols,(ih-(sz.rows-1)*GAP)/sz.rows))
  local w=sz.cols*tile+(sz.cols-1)*GAP
  local h=sz.rows*tile+(sz.rows-1)*GAP
  local x=AREA.x+math.floor((AREA.w-w)/2)
  local y=AREA.y+math.floor((AREA.h-h)/2)
  return x,y,tile
end
local function draw_tile(g,x,y,t,on,ring)
  if on then
    if ring then
      -- A white ring inside a dark tile: dark outer band, white gap, dark core.
      g:rect(x,y,t,t,{line_width=6,radius=10})
      g:rect(x+10,y+10,t-20,t-20,{fill=true,radius=4})
    else
      g:rect(x,y,t,t,{fill=true,radius=10})
    end
  else
    g:rect(x,y,t,t,{line_width=2,radius=10})
    if ring then g:rect(x+6,y+6,t-12,t-12,{line_width=4,radius=5}) end
  end
end
local function draw_menu(g)
  text(g,20,24,'Menu','title',nil,300)
  text(g,22,80,'NEW GAME','small',nil,300)
  for i,sz in ipairs(SIZES) do
    button(g,MENU_BOX['size'..i],sz.label..'  '..sz.cols..' x '..sz.rows,i==S.size,{font='small'})
  end
  text(g,22,292,'THIS PUZZLE','small',nil,300)
  button(g,MENU_BOX.restart,'Restart puzzle')
  button(g,MENU_BOX.hint,S.won and 'Solved - no hint needed' or 'Show hint')
  button(g,MENU_BOX.solution,'Show solution: '..(S.show and 'On' or 'Off'),S.show)
  text(g,22,502,MSG or ('Par: '..S.par..' presses'),'body',nil,436)
  text(g,22,540,'HOW TO PLAY','small',nil,300)
  UI.paragraph(g,C,22,564,436,146,
    'Tap a tile to flip it and the tiles above, below, left and right. Turn every tile white. Par is the fewest presses.','small')
  button(g,MENU_BOX.resume,'Resume')
end
local function draw(g)
  g:clear(0)
  layout_for_host()
  if MENU then draw_menu(g);return end
  local sz=size()
  local x0,y0,t=tile_geometry()
  -- Frame of the play area, open at the top like the HTML reference.
  g:rect(AREA.x,AREA.y-12,AREA.w,AREA.h+12,{line_width=3,radius=12})
  UI.region(x0,y0,sz.cols*t+(sz.cols-1)*GAP,sz.rows*t+(sz.rows-1)*GAP)
  local ring=nil
  if S.show and not S.won and HINT==0 then ring=solution() end
  for i=1,sz.cols*sz.rows do
    local c,r=(i-1)%sz.cols,math.floor((i-1)/sz.cols)
    draw_tile(g,x0+c*(t+GAP),y0+r*(t+GAP),t,S.board[i]==1,i==HINT or (ring and ring[i]==1))
  end
  local cx,cy,cw,ch=BAR.counter[1],BAR.counter[2],BAR.counter[3],BAR.counter[4]
  if MSG then
    UI.paragraph(g,C,cx+4,cy+6,cw-4,ch-6,MSG,'small')
  elseif S.won then
    text(g,cx+4,cy+10,'Solved in '..S.moves,'large',nil,cw-4)
    text(g,cx+4,cy+48,'par '..S.par,'body',nil,cw-4)
  else
    text(g,cx+12,cy+math.floor((ch-UI.height(C,'title'))/2),tostring(S.moves),'title',nil,cw-12)
  end
  if S.won then button(g,BAR.undo,'Next',true)
  else button(g,BAR.undo,'Undo',false) end
  button(g,BAR.menu,'Menu')
end
local function hit(x,y,b) return x>=b[1] and x<b[1]+b[3] and y>=b[2] and y<b[2]+b[4] end
local function tap(x,y)
  layout_for_host()
  if MENU then
    for i=1,#SIZES do if hit(x,y,MENU_BOX['size'..i]) then new_game(i);return true end end
    if hit(x,y,MENU_BOX.restart) then return restart() end
    if hit(x,y,MENU_BOX.hint) then return hint() end
    if hit(x,y,MENU_BOX.solution) then return toggle_solution() end
    if hit(x,y,MENU_BOX.resume) then MENU=false;return true end
    return false
  end
  if hit(x,y,BAR.menu) then MENU=true;HINT=0;return true end
  if hit(x,y,BAR.undo) then
    if S.won then new_game(S.size);return true end
    return undo()
  end
  local sz=size()
  local x0,y0,t=tile_geometry()
  local c,r=math.floor((x-x0)/(t+GAP)),math.floor((y-y0)/(t+GAP))
  if c<0 or r<0 or c>=sz.cols or r>=sz.rows then return false end
  -- Taps in the 3px gaps between tiles do nothing.
  if (x-x0)-c*(t+GAP)>=t or (y-y0)-r*(t+GAP)>=t then return false end
  return tap_tile(r*sz.cols+c+1)
end

-- Host callbacks -----------------------------------------------------------
local function redraw() if C then pcall(function() C:invalidate() end) end end
function on_load(context)
  Theme.release()
  C=context or ctx;S=nil;ERR=nil;MENU=false;HINT=0;SOLUTION=nil;MSG=nil
  layout_for_host()
  local ok,e=pcall(function() if not restore() then assert(new_game(1),'No verified puzzle - reopen to retry') end end)
  if not ok then ERR=tostring(e) end
end
function on_draw(context,g)
  if context then C=context end
  if not g then return end
  if ERR then UI.error(g,C,'LIGHTS OUT',ERR);return end
  local ok,e=pcall(function() Theme.draw(C,g,draw) end)
  if not ok then ERR=tostring(e);UI.error(g,C,'LIGHTS OUT',ERR) end
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
    end
  end)
  if not ok then ERR=tostring(e);changed=true end
  if changed then redraw() end
  return changed
end
function on_leave() Theme.release(); if S then save() end end
if rawget(_G,'__TEST') then
  __TEST.api={state=function() return S end,sizes=SIZES,solve=solve,press=press,
    generate=generate,new=new_game,tap=tap,tap_tile=tap_tile,undo=undo,restart=restart,
    hint=hint,hinted=function() return HINT end,toggle_solution=toggle_solution,
    geometry=tile_geometry,bar=BAR,menu=MENU_BOX,area=AREA,
    open_menu=function() MENU=true;return true end}
end

-- Crash reports: errors are saved to crash.txt and shown on a recovery screen.
do
  local guarded=UI.guard{id='lightsout',test=rawget(_G,'__TEST'),
    state=function() return S and ('size='..tostring(S.size)..' moves='..tostring(S.moves)..' menu='..tostring(MENU)) end,
    load=on_load,draw=on_draw,input=on_input,leave=on_leave}
  on_load,on_draw,on_input,on_leave=guarded.load,guarded.draw,guarded.input,guarded.leave
end
