-- Static, touch-first Sudoku for XTOS Licorice. Existing puzzles are never discarded.
local UI=require('ui')
local Theme=require('theme')
local Generator=require('generator')
local Store=require('puzzle_store')
local NAMES={'EASY','MEDIUM','HARD'}
local MAX=999999999
local C,S,P,ERR,MSG=nil,nil,nil,nil,nil
local HELP,MENU=false,false
local CHOICE=2
local KEY_MS=-1000
-- One geometry contract for drawing and taps. Values are device pixels.
local BOARD={x=6,y=108,cell=52,size=468}
local CONTROLS={new={242,12,76,48},check={326,12,90,48},help={424,12,48,48},
  notes={8,626,132,52},undo={8,682,132,52},erase={8,738,132,52}}
local function digit_box(n)
  return 156+(n-1)%3*106,626+math.floor((n-1)/3)*56,98,52
end
local function copy(a) local b={};for i,v in ipairs(a) do b[i]=v end;return b end
local function zeros() local a={};for i=1,81 do a[i]=0 end;return a end
local function board_code(a) return table.concat(a) end
local function notes_code(a)
  local masks={}
  for i,v in ipairs(a) do masks[i]=string.format('%.0f',v) end
  return table.concat(masks,',')
end
local function parse_board(s)
  if type(s)~='string' or #s~=81 or s:find('[^0-9]') then return nil end
  local a={};for i=1,81 do a[i]=tonumber(s:sub(i,i)) end;return a
end
local function parse_notes(s)
  if type(s)~='string' or s=='' or s:sub(1,1)==',' or s:sub(-1)==',' or s:find(',,',1,true) then return nil end
  local a={}
  for item in s:gmatch('[^,]+') do
    -- Accept the exact integral decimals written by older Lua 5.4/5.5 builds.
    if not item:match('^%d+$') and not item:match('^%d+%.0+$') then return nil end
    local n=tonumber(item)
    if n<0 or n>511 or n~=math.floor(n) then return nil end
    a[#a+1]=n
  end
  return #a==81 and a or nil
end
local function fields(data)
  local f={}
  if type(data)=='string' then for k,v in data:gmatch('([%w_]+)=([^\n]*)') do f[k]=v end end
  return f
end
local function integer(n,lo,hi)
  n=tonumber(n)
  return n and n==math.floor(n) and n>=lo and n<=hi and n or nil
end
local function solved(board)
  for i=1,81 do if board[i]~=P.solution[i] then return false end end
  return true
end
local function consistent(board,notes)
  for i=1,81 do
    if P.given[i]>0 and board[i]~=P.given[i] then return false end
    if board[i]>0 and notes[i]~=0 then return false end
  end
  return true
end
local function read(name)
  if not C or not C.storage then return nil end
  local data,err=C.storage:read(name)
  if not data and err and err~='not_found' then error('Cannot read saved progress') end
  return data
end
local function save()
  if not S or not C or not C.storage then return true end
  local past={}
  for i,h in ipairs(S.history) do past[i]=board_code(h.board)..':'..notes_code(h.notes) end
  local data=table.concat({'version=1','difficulty='..S.difficulty,
    'board='..board_code(S.board),'notes='..notes_code(S.notes),'history='..table.concat(past,';'),
    'selected='..S.selected,'noteMode='..(S.noteMode and '1' or '0'),
    'submitted='..(S.submitted and '1' or '0')},'\n')
  local ok=pcall(function()
    Store.put(C.storage,'sudoku',S.level,data)
    Store.write(C.storage,'sudoku.txt','version=1\nlevel='..S.level..'\nunlocked='..S.unlocked)
  end)
  if not ok then MSG='Save failed - keep this puzzle open' end
  return ok
end
local function fresh(level,unlocked,difficulty)
  P=Generator.generate(level,difficulty)
  S={level=level,unlocked=unlocked,difficulty=difficulty,board=copy(P.given),notes=zeros(),
    history={},selected=0,noteMode=false,submitted=false}
end
local function load_level(level,unlocked)
  local f=fields(Store.get(C.storage,'sudoku',level))
  local difficulty=integer(f.difficulty,1,3)
  if f.version~='1' or not difficulty then return false end
  local board,notes=parse_board(f.board),parse_notes(f.notes)
  local selected=integer(f.selected,0,81)
  if not board or not notes or not selected or (f.noteMode~='0' and f.noteMode~='1') or
      (f.submitted~='0' and f.submitted~='1') then return false end
  P=Generator.generate(level,difficulty)
  if not consistent(board,notes) or (f.submitted=='1' and not solved(board)) then return false end
  local history={}
  for part in (f.history or ''):gmatch('[^;]+') do
    local b,n=part:match('^([^:]+):(.+)$')
    b,n=parse_board(b),parse_notes(n)
    if not b or not n or not consistent(b,n) or #history>=32 then return false end
    history[#history+1]={board=b,notes=n}
  end
  S={level=level,unlocked=unlocked,difficulty=difficulty,board=board,notes=notes,
    history=history,selected=selected,noteMode=f.noteMode=='1',submitted=f.submitted=='1'}
  return true
end
local function visit(level)
  if not S or not integer(level,1,S.unlocked) then return false end
  if not save() then return true end
  local old=P
  if not load_level(level,S.unlocked) then P=old;MSG='Could not open saved puzzle';return true end
  HELP=false;MENU=false;MSG=nil;CHOICE=S.difficulty
  return true
end
local function new_puzzle(difficulty)
  if not S or not integer(difficulty,1,3) or S.unlocked>=MAX then return false end
  if not save() then return true end
  local number=S.unlocked+1
  fresh(number,number,difficulty)
  MENU=false;HELP=false;MSG='Tap a square, then a number';CHOICE=difficulty
  save()
  return true
end
local function remember()
  if #S.history>=32 then table.remove(S.history,1) end
  S.history[#S.history+1]={board=copy(S.board),notes=copy(S.notes)}
end
local function has(mask,n) return math.floor(mask/2^(n-1))%2==1 end
local function put(n)
  local i=S and S.selected or 0
  if i==0 or P.given[i]>0 or S.submitted or not integer(n,1,9) then return false end
  if S.noteMode then
    if S.board[i]>0 then MSG='Erase the value before adding notes';return true end
    remember()
    S.notes[i]=S.notes[i]+(has(S.notes[i],n) and -1 or 1)*2^(n-1)
  else
    if S.board[i]==n then return false end
    remember();S.board[i]=n;S.notes[i]=0
    for _,j in ipairs(Generator.peers[i]) do
      if has(S.notes[j],n) then S.notes[j]=S.notes[j]-2^(n-1) end
    end
  end
  MSG=nil;save();return true
end
local function erase()
  local i=S and S.selected or 0
  if i==0 or P.given[i]>0 or S.submitted or (S.board[i]==0 and S.notes[i]==0) then return false end
  remember();S.board[i]=0;S.notes[i]=0;MSG=nil;save();return true
end
local function undo()
  if not S or S.submitted or #S.history==0 then return false end
  local h=table.remove(S.history)
  S.board=h.board;S.notes=h.notes;MSG='Last move restored';save();return true
end
local function reset()
  if not S then return false end
  S.board=copy(P.given);S.notes=zeros();S.history={};S.submitted=false
  S.selected=0;S.noteMode=false;MENU=false;MSG='This puzzle restarted';save();return true
end
local function select_cell(x,y)
  if not S or not integer(x,1,9) or not integer(y,1,9) then return false end
  S.selected=(y-1)*9+x;MSG=nil;save();return true
end
local function check()
  if not S or S.submitted then return false end
  local wrong,empty=0,0
  for i=1,81 do
    if S.board[i]==0 then empty=empty+1
    elseif S.board[i]~=P.solution[i] then wrong=wrong+1 end
  end
  if wrong>0 then MSG=wrong..' incorrect '..(wrong==1 and 'value' or 'values')
  elseif empty>0 then MSG='Correct so far: '..empty..' empty'
  else S.submitted=true;MSG='Solved! NEW opens another puzzle' end
  save();return true
end
local function conflicts(i)
  if S.board[i]==0 then return false end
  for _,j in ipairs(Generator.peers[i]) do if S.board[j]==S.board[i] then return true end end
  return false
end
local function text(g,x,y,s,font,align,width) UI.text(g,C,x,y,s,font,align,width) end
local function button(g,x,y,w,h,s,decorated,options) UI.button(g,C,x,y,w,h,s,decorated,options) end
local function control(g,key,label,marked)
  local b=CONTROLS[key];button(g,b[1],b[2],b[3],b[4],label,marked)
end
local function draw_help(g)
  text(g,240,155,'HOW TO PLAY','large','center',420)
  UI.paragraph(g,C,26,215,428,125,'Fill each row, column and 3 by 3 box with 1 to 9. Each number appears once.', 'medium')
  UI.paragraph(g,C,26,350,428,155,'Tap a square, then a number. Bold numbers are fixed clues. A corner X marks a clash. CHECK verifies your entries.', 'medium')
  UI.paragraph(g,C,26,515,428,155,'NOTES toggles pencil marks. A dot shows notes in a square; select it to read them below. UNDO also restores cleaned notes.', 'medium')
  button(g,76,710,328,62,'BACK TO GAME')
end
local function draw_menu(g)
  text(g,240,155,'NEW PUZZLE','large','center',420)
  text(g,240,200,'Choose how many clues to start with','small','center',430)
  for i,name in ipairs(NAMES) do button(g,22+(i-1)*150,241,136,52,name,i==CHOICE) end
  button(g,76,322,328,62,'START NEW')
  text(g,240,407,'Your current puzzle stays saved','small','center',428)
  button(g,24,456,210,58,'PREV PUZZLE')
  button(g,246,456,210,58,'NEXT PUZZLE')
  button(g,76,550,328,62,'RESET THIS PUZZLE')
  text(g,240,641,'Page keys also revisit saved puzzles','small','center',430)
  button(g,76,710,328,62,'BACK TO GAME')
end
local function draw(g)
  g:clear(0)
  text(g,16,19,'SUDOKU','large',nil,202)
  if not HELP and not MENU then
    control(g,'new','NEW');control(g,'check',S.submitted and 'DONE' or 'CHECK')
  end
  control(g,'help',(HELP or MENU) and 'X' or '?')
  text(g,16,74,'Puzzle '..S.level,'small',nil,260)
  local difficulty=NAMES[S.difficulty]:sub(1,1)..NAMES[S.difficulty]:sub(2):lower()
  text(g,402,74,difficulty,'small','center',124)
  if HELP then draw_help(g);return end
  if MENU then draw_menu(g);return end
  local bx,by,cell,size=BOARD.x,BOARD.y,BOARD.cell,BOARD.size
  UI.region(bx,by,size,size)
  local remaining,clashes=0,0
  for i=1,81 do
    local x=bx+(i-1)%9*cell
    local y=by+math.floor((i-1)/9)*cell
    if S.selected==i then g:rect(x+4,y+4,cell-8,cell-8,{line_width=2,radius=6}) end
    if S.board[i]>0 then
      local role=P.given[i]>0 and 'strong' or 'clue'
      text(g,x+cell/2,y+math.floor((cell-UI.height(C,role))/2),tostring(S.board[i]),role,'center',cell-14)
    elseif S.notes[i]>0 then g:circle(x+cell/2,y+cell/2,3,{fill=true}) end
    if S.board[i]==0 then remaining=remaining+1 end
    if conflicts(i) then
      clashes=clashes+1
      g:line(x+cell-13,y+7,x+cell-7,y+13,{line_width=2})
      g:line(x+cell-7,y+7,x+cell-13,y+13,{line_width=2})
    end
  end
  UI.grid(g,bx,by,9,9,cell,{every=3})
  local status=MSG
  if not status and S.selected>0 and S.notes[S.selected]>0 then
    local values={}
    for n=1,9 do if has(S.notes[S.selected],n) then values[#values+1]=n end end
    status='NOTES: '..table.concat(values,' ')
  end
  text(g,240,590,status or (S.submitted and 'Solved' or 'Left '..remaining..' / Clashes '..clashes),'small','center',448)
  control(g,'notes','NOTES',S.noteMode)
  control(g,'undo','UNDO');control(g,'erase','ERASE')
  for n=1,9 do
    local marked=S.noteMode and S.selected>0 and has(S.notes[S.selected],n)
    local x,y,w,h=digit_box(n)
    button(g,x,y,w,h,tostring(n),marked,{font='strong'})
  end
end
local function hit(x,y,bx,by,w,h) return x>=bx and x<bx+w and y>=by and y<by+h end
local function tap(x,y)
  local function at(key) local b=CONTROLS[key];return hit(x,y,b[1],b[2],b[3],b[4]) end
  if at('help') then
    if HELP or MENU then HELP=false;MENU=false else HELP=true end
    return true
  end
  if HELP then if hit(x,y,76,710,328,62) then HELP=false;return true end;return false end
  if MENU then
    for i=1,3 do if hit(x,y,22+(i-1)*150,241,136,52) then CHOICE=i;return true end end
    if hit(x,y,76,322,328,62) then return new_puzzle(CHOICE) end
    if hit(x,y,24,456,210,58) then return visit(S.level-1) end
    if hit(x,y,246,456,210,58) then return visit(S.level+1) end
    if hit(x,y,76,550,328,62) then return reset() end
    if hit(x,y,76,710,328,62) then MENU=false;return true end
    return false
  end
  if at('new') then MENU=true;CHOICE=S.difficulty;return true end
  if at('check') then return check() end
  if at('notes') then S.noteMode=not S.noteMode;MSG=nil;save();return true end
  if at('undo') then return undo() end
  if at('erase') then return erase() end
  for n=1,9 do local bx,by,w,h=digit_box(n);if hit(x,y,bx,by,w,h) then return put(n) end end
  if hit(x,y,BOARD.x,BOARD.y,BOARD.size,BOARD.size) then return select_cell(math.floor((x-BOARD.x)/BOARD.cell)+1,math.floor((y-BOARD.y)/BOARD.cell)+1) end
  return false
end
local function redraw() if C then pcall(function() C:invalidate() end) end end
function on_load(context)
  Theme.release()
  C=context or ctx;S=nil;ERR=nil;HELP=false;MENU=false;MSG=nil;KEY_MS=-1000
  local ok,e=pcall(function()
    local f=fields(read('sudoku.txt'))
    local level,unlocked=integer(f.level,1,MAX),integer(f.unlocked,1,MAX)
    if f.version~='1' or not level or not unlocked or level>unlocked or not load_level(level,unlocked) then fresh(1,1,2);save() end
    CHOICE=S.difficulty
  end)
  if not ok then ERR=tostring(e) end
end
function on_draw(context,g)
  if context then C=context end
  if not g then return end
  if ERR then UI.error(g,C,'SUDOKU',ERR);return end
  local ok,e=pcall(function() Theme.draw(C,g,draw) end)
  if not ok then ERR=tostring(e);UI.error(g,C,'SUDOKU',ERR) end
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
    elseif event.type=='key' and (not event.phase or event.phase=='down') and (event.key=='up' or event.key=='down') and not HELP and not MENU then
      local now=tonumber(event.time_ms)
      if not now and C and C.clock then local good,t=pcall(function() return C.clock:millis() end);if good then now=tonumber(t) end end
      if now and now>=KEY_MS and now-KEY_MS<230 then return end
      if now then KEY_MS=now end
      if event.key=='up' then changed=visit(S.level-1) else changed=visit(S.level+1) end
    end
  end)
  if not ok then ERR=tostring(e);changed=true end
  if changed then redraw() end
  return changed
end
function on_leave() Theme.release(); if S then save() end end
if rawget(_G,'__TEST') then
  __TEST.api={state=function() return S end,puzzle=function() return P end,
    select=select_cell,put=put,erase=erase,undo=undo,reset=reset,check=check,
    geometry=BOARD,controls=CONTROLS,digit_box=digit_box,
    new=new_puzzle,visit=visit,tap=tap,conflicts=conflicts,solved=function() return solved(S.board) end}
end
