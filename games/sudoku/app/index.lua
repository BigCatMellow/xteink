-- Static, touch-first Sudoku for XTOS Licorice. Existing puzzles are never discarded.
local UI=require('ui')
local Theme=require('theme')
local Generator=require('generator')
local Store=require('puzzle_store')
local NAMES={'EASY','MEDIUM','HARD','BEGINNER','EXPERT'}
local ORDER={4,1,2,3,5} -- Meditation order; legacy save IDs 1..3 stay unchanged.
local NOTE_CAP={65,39,19,99,13}
local MAX=999999999
local C,S,P,ERR,MSG=nil,nil,nil,nil,nil
local HELP,MENU=false,false
local CHOICE=2
local KEY_MS=-1000
-- One geometry contract for drawing and taps. Values are device pixels.
local BOARD={x=6,y=100,cell=52,size=468}
local CONTROLS={new={242,12,76,48},check={326,12,90,48},help={424,12,48,48},
  notes={8,604,132,60},undo={8,668,132,60},erase={8,732,132,60}}
local function digit_box(n)
  return 156+(n-1)%3*106,604+math.floor((n-1)/3)*64,98,60
end
local function copy(a) local b={};for i,v in ipairs(a) do b[i]=v end;return b end
local function zeros() local a={};for i=1,81 do a[i]=0 end;return a end
local function flag(s,fallback) return s=='1' or (s==nil and fallback or false) end
local function selection_code(a)
  local found={}
  for i=1,81 do if a and a[i] then found[#found+1]=i end end
  return table.concat(found,',')
end
local function read_selection(s)
  local result={}
  if not s or s=='' then return result end
  if s:sub(1,1)==',' or s:sub(-1)==',' or s:find(',,',1,true) then return nil end
  for item in s:gmatch('[^,]+') do
    local n=tonumber(item)
    if not n or n<1 or n>81 or n~=math.floor(n) or result[n] then return nil end
    result[n]=true
  end
  return result
end
local function note_total(notes)
  local n=0
  for i=1,81 do
    for k=1,9 do if math.floor(notes[i]/2^(k-1))%2==1 then n=n+1 end end
  end
  return n
end
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
    'submitted='..(S.submitted and '1' or '0'),
    'generation='..(S.generation or 1),
    'autoClean='..(S.autoClean and '1' or '0'),
    'highlight='..(S.highlight and '1' or '0'),
    'showConflicts='..(S.showConflicts and '1' or '0'),
    'locked='..(S.locked or 0),
    'multiMode='..(S.multiMode and '1' or '0'),
    'multi='..selection_code(S.multi)},'\n')
  local ok=pcall(function()
    Store.put(C.storage,'sudoku',S.level,data)
    Store.write(C.storage,'sudoku.txt','version=1\nlevel='..S.level..'\nunlocked='..S.unlocked)
  end)
  if not ok then MSG='Save failed - keep this puzzle open' end
  return ok
end
local function fresh(level,unlocked,difficulty)
  P=Generator.generate(level,difficulty,2)
  S={level=level,unlocked=unlocked,difficulty=difficulty,generation=2,
    board=copy(P.given),notes=zeros(),
    history={},selected=0,noteMode=false,submitted=false,
    autoClean=true,highlight=true,showConflicts=true,locked=0,multiMode=false,multi={}}
end
local function load_level(level,unlocked)
  local f=fields(Store.get(C.storage,'sudoku',level))
  local difficulty=integer(f.difficulty,1,5)
  local generation=integer(f.generation or '1',1,2)
  if f.version~='1' or not difficulty or not generation then return false end
  local board,notes=parse_board(f.board),parse_notes(f.notes)
  local selected=integer(f.selected,0,81)
  local locked=integer(f.locked or '0',0,9)
  local multi=read_selection(f.multi)
  if not board or not notes or not selected or not locked or not multi or
      (f.noteMode~='0' and f.noteMode~='1') or
      (f.submitted~='0' and f.submitted~='1') then return false end
  P=Generator.generate(level,difficulty,generation)
  if not consistent(board,notes) or (f.submitted=='1' and not solved(board)) then return false end
  local history={}
  for part in (f.history or ''):gmatch('[^;]+') do
    local b,n=part:match('^([^:]+):(.+)$')
    b,n=parse_board(b),parse_notes(n)
    if not b or not n or not consistent(b,n) or #history>=100 then return false end
    history[#history+1]={board=b,notes=n}
  end
  S={level=level,unlocked=unlocked,difficulty=difficulty,generation=generation,
    board=board,notes=notes,history=history,selected=selected,
    noteMode=f.noteMode=='1',submitted=f.submitted=='1',
    autoClean=flag(f.autoClean,true),highlight=flag(f.highlight,true),
    showConflicts=flag(f.showConflicts,true),locked=locked,
    multiMode=flag(f.multiMode,false),multi=multi}
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
  if not S or not integer(difficulty,1,5) or S.unlocked>=MAX then return false end
  if not save() then return true end
  local number=S.unlocked+1
  fresh(number,number,difficulty)
  MENU=false;HELP=false;MSG='Tap a square, then a number';CHOICE=difficulty
  save()
  return true
end
local function remember()
  if #S.history>=100 then table.remove(S.history,1) end
  S.history[#S.history+1]={board=copy(S.board),notes=copy(S.notes)}
end
local function has(mask,n) return math.floor(mask/2^(n-1))%2==1 end
local function selected_cells()
  local found={}
  if S.multiMode then
    for i=1,81 do if S.multi[i] then found[#found+1]=i end end
  elseif S.selected>0 then found[1]=S.selected end
  return found
end
local function put(n)
  if not S or S.submitted or not integer(n,1,9) then return false end
  local chosen=selected_cells()
  if S.noteMode and S.locked>0 and #chosen==0 then
    S.locked=n;MSG='NOTE '..n..': tap empty squares';save();return true
  end
  local touched={}
  for _,i in ipairs(chosen) do
    if P.given[i]==0 and (S.noteMode and S.board[i]==0 or not S.noteMode) then
      touched[#touched+1]=i
    end
  end
  if #touched==0 then return false end
  if S.noteMode then
    local current=note_total(S.notes)
    local nextCount=current
    for _,i in ipairs(touched) do nextCount=nextCount+(has(S.notes[i],n) and -1 or 1) end
    if nextCount>NOTE_CAP[S.difficulty] then
      MSG='NOTE LIMIT '..NOTE_CAP[S.difficulty];return true
    end
    remember()
    for _,i in ipairs(touched) do
      S.notes[i]=S.notes[i]+(has(S.notes[i],n) and -1 or 1)*2^(n-1)
    end
  else
    local i=S.selected
    if i==0 or P.given[i]>0 or S.board[i]==n then return false end
    remember();S.board[i]=n;S.notes[i]=0
    if S.autoClean then
      for _,j in ipairs(Generator.peers[i]) do
        if has(S.notes[j],n) then S.notes[j]=S.notes[j]-2^(n-1) end
      end
    end
  end
  MSG=nil;S.bad=nil;save();return true
end
local function erase()
  if not S or S.submitted then return false end
  local touched={}
  for _,i in ipairs(selected_cells()) do
    if P.given[i]==0 and (S.board[i]~=0 or S.notes[i]~=0) then touched[#touched+1]=i end
  end
  if #touched==0 then return false end
  remember()
  for _,i in ipairs(touched) do S.board[i]=0;S.notes[i]=0 end
  MSG=nil;S.bad=nil;save();return true
end
local function clear_notes()
  if not S or S.submitted or note_total(S.notes)==0 then return false end
  remember();S.notes=zeros();S.locked=0;MSG='All pencil notes cleared';save();return true
end
local function undo()
  if not S or S.submitted or #S.history==0 then return false end
  local h=table.remove(S.history)
  S.board=h.board;S.notes=h.notes;S.bad=nil;MSG='Last move restored';save();return true
end
local function reset()
  if not S then return false end
  S.board=copy(P.given);S.notes=zeros();S.history={};S.submitted=false
  S.selected=0;S.noteMode=false;S.locked=0;S.multi={};S.multiMode=false
  MENU=false;S.bad=nil;MSG='This puzzle restarted';save();return true
end
local function select_cell(x,y,additive)
  if not S or not integer(x,1,9) or not integer(y,1,9) then return false end
  local i=(y-1)*9+x
  if S.noteMode and S.board[i]>0 then
    S.locked=S.board[i];S.selected=0;S.multi={}
    MSG='NOTE '..S.locked..': tap empty squares';save();return true
  end
  if S.noteMode and S.locked>0 and S.board[i]==0 and P.given[i]==0 then
    S.selected=i;S.multi={[i]=true}
    local n=S.locked
    if not has(S.notes[i],n) and note_total(S.notes)>=NOTE_CAP[S.difficulty] then
      MSG='NOTE LIMIT '..NOTE_CAP[S.difficulty];return true
    end
    remember();S.notes[i]=S.notes[i]+(has(S.notes[i],n) and -1 or 1)*2^(n-1)
    MSG=nil;save();return true
  end
  if additive or S.multiMode then
    if S.multi[i] then S.multi[i]=nil
    else S.multi[i]=true end
    S.selected=i
  else
    S.selected=i;S.multi={[i]=true}
  end
  MSG=nil;save();return true
end
local function check()
  if not S or S.submitted then return false end
  local wrong,empty=0,0
  S.bad={}
  for i=1,81 do
    if S.board[i]==0 then empty=empty+1
    elseif S.board[i]~=P.solution[i] then wrong=wrong+1;S.bad[i]=true end
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
local function button(g,x,y,w,h,s,decorated,options)
  options=options or {}
  options.line_width=options.line_width or 4 -- local Sudoku-only stronger strokes
  UI.button(g,C,x,y,w,h,s,decorated,options)
end
local function control(g,key,label,marked)
  local b=CONTROLS[key];button(g,b[1],b[2],b[3],b[4],label,marked)
end
-- Seven-segment pencil digits: tiny legible ink with at most seven strokes.
-- Packaged 20px bitmap glyphs cannot fit the 3x3 pencil subcells.
local SEGMENTS={
  {1,1,1,0,1,1,1},{0,0,1,0,0,1,0},{1,0,1,1,1,0,1},
  {1,0,1,1,0,1,1},{0,1,1,1,0,1,0},{1,1,0,1,0,1,1},
  {1,1,0,1,1,1,1},{1,0,1,0,0,1,0},{1,1,1,1,1,1,1},
}
local function pencil_digit(g,x,y,n)
  local v=SEGMENTS[n]
  local function line(a,b,c,d) g:line(x+a,y+b,x+c,y+d,{line_width=2}) end
  if v[1]==1 then line(1,0,7,0) end
  if v[2]==1 then line(0,1,0,5) end
  if v[3]==1 then line(8,1,8,5) end
  if v[4]==1 then line(1,6,7,6) end
  if v[5]==1 then line(0,7,0,11) end
  if v[6]==1 then line(8,7,8,11) end
  if v[7]==1 then line(1,12,7,12) end
end
local function show_notes(g,x,y,mask)
  for n=1,9 do
    if has(mask,n) then
      pencil_digit(g,x+7+((n-1)%3)*16,y+3+math.floor((n-1)/3)*16,n)
    end
  end
end
local function highlight_geometry(i)
  if not i or i<=0 then return nil end
  local row=math.floor((i-1)/9)
  local col=(i-1)%9
  return {row=row,col=col,boxrow=math.floor(row/3)*3,boxcol=math.floor(col/3)*3}
end
local function draw_guides(g)
  if not S.highlight or S.selected==0 then return end
  local h=highlight_geometry(S.selected)
  if not h then return end
  local x,y,cell,size=BOARD.x,BOARD.y,BOARD.cell,BOARD.size
  -- Full row and column outlines produce a monochrome crosshair, never a
  -- solid fill over numbers and candidates.
  g:rect(x,y+h.row*cell,size,cell,{line_width=2})
  g:rect(x+h.col*cell,y,cell,size,{line_width=2})
  -- Brackets indicate the selected 3x3 box without extra filled panels.
  local bx,by=x+h.boxcol*cell+7,y+h.boxrow*cell+7
  local ex,ey=bx+3*cell-14,by+3*cell-14
  g:line(bx,by+12,bx,by,{line_width=2})
  g:line(bx,by,bx+12,by,{line_width=2})
  g:line(ex-12,ey,ex,ey,{line_width=2})
  g:line(ex,ey,ex,ey-12,{line_width=2})
end

local function draw_help(g)
  text(g,240,111,'HOW TO PLAY','large','center',420)
  UI.paragraph(g,C,26,158,428,85,
    'Fill each row, column and 3 by 3 box with digits 1 to 9. No repeats.', 'medium')
  UI.paragraph(g,C,26,259,428,107,
    'Tap a square, then a number. Row and column guide lines show related cells. Equal numbers are underlined.', 'medium')
  UI.paragraph(g,C,26,387,428,137,
    'NOTES shows tiny pencil digits. Tap a filled number in Notes mode to lock it; then tap empty cells to add or remove that note.', 'medium')
  UI.paragraph(g,C,26,546,428,132,
    'NEW opens difficulty and game settings. Use MULTI SELECT for several squares, CLEAR NOTES for all pencil marks, and CHECK to verify.', 'medium')
  button(g,76,710,328,62,'BACK TO GAME')
end
local function draw_menu(g)
  text(g,240,106,'NEW PUZZLE','large','center',420)
  text(g,240,157,'Difficulty','small','center',430)
  for j,difficulty in ipairs(ORDER) do
    local x,y
    if j<=3 then x=12+(j-1)*155;y=193
    else x=90+(j-4)*155;y=255 end
    button(g,x,y,146,54,NAMES[difficulty],CHOICE==difficulty,{font='small'})
  end
  button(g,76,323,328,62,'START NEW')
  button(g,24,407,210,48,'AUTO CLEAN '..(S.autoClean and 'ON' or 'OFF'))
  button(g,246,407,210,48,'HIGHLIGHT '..(S.highlight and 'ON' or 'OFF'))
  button(g,24,463,210,48,'CONFLICTS '..(S.showConflicts and 'ON' or 'OFF'))
  button(g,246,463,210,48,'MULTI '..(S.multiMode and 'ON' or 'OFF'))
  button(g,24,519,210,48,'CLEAR NOTES')
  button(g,246,519,210,48,'RESET PUZZLE')
  button(g,24,590,210,54,'PREV PUZZLE')
  button(g,246,590,210,54,'NEXT PUZZLE')
  text(g,240,656,'Current puzzle stays saved','small','center',428)
  button(g,76,710,328,62,'BACK TO GAME')
end
local function draw(g)
  g:clear(0)
  text(g,16,19,'SUDOKU','large',nil,202)
  if not HELP and not MENU then
    control(g,'new','NEW');control(g,'check',S.submitted and 'DONE' or 'CHECK')
  end
  control(g,'help',(HELP or MENU) and 'X' or '?')
  text(g,16,68,'Puzzle '..S.level,'small',nil,260)
  local difficulty=NAMES[S.difficulty]:sub(1,1)..NAMES[S.difficulty]:sub(2):lower()
  text(g,402,68,difficulty,'small','center',124)
  if HELP then draw_help(g);return end
  if MENU then draw_menu(g);return end
  local bx,by,cell,size=BOARD.x,BOARD.y,BOARD.cell,BOARD.size
  UI.region(bx,by,size,size)
  local remaining,clashes=0,0
  for i=1,81 do
    local x=bx+(i-1)%9*cell
    local y=by+math.floor((i-1)/9)*cell
    if S.selected==i or S.multiMode and S.multi[i] then
      g:rect(x+4,y+4,cell-8,cell-8,{line_width=S.selected==i and 3 or 2,radius=6})
    end
    if S.board[i]>0 then
      local role=P.given[i]>0 and 'strong' or 'clue'
      text(g,x+cell/2,y+math.floor((cell-UI.height(C,role))/2),tostring(S.board[i]),role,'center',cell-14)
    elseif S.notes[i]>0 then show_notes(g,x,y,S.notes[i]) end
    if S.board[i]==0 then remaining=remaining+1 end
    if conflicts(i) then clashes=clashes+1 end
    if S.showConflicts and (conflicts(i) or S.bad and S.bad[i]) then
      g:line(x+cell-13,y+7,x+cell-7,y+13,{line_width=3})
      g:line(x+cell-7,y+7,x+cell-13,y+13,{line_width=3})
    end
    if S.highlight and S.selected>0 and i~=S.selected and
       S.board[i]>0 and S.board[i]==S.board[S.selected] then
      g:line(x+16,y+cell-8,x+cell-16,y+cell-8,{line_width=3})
    end
  end
  UI.grid(g,bx,by,9,9,cell,{every=3,minor=2,major=5,frame=5})
  draw_guides(g)
  local status=MSG
  if not status and S.selected>0 and S.notes[S.selected]>0 then
    local values={}
    for n=1,9 do if has(S.notes[S.selected],n) then values[#values+1]=n end end
    status='NOTES: '..table.concat(values,' ')
  end
  if not status and S.noteMode and S.locked>0 then
    status='NOTE '..S.locked..'  '..note_total(S.notes)..'/'..NOTE_CAP[S.difficulty]
  end
  text(g,240,575,status or (S.submitted and 'Solved' or
    'Left '..remaining..' / Clashes '..clashes),'small','center',448)
  control(g,'notes','NOTES',S.noteMode)
  control(g,'undo','UNDO');control(g,'erase','ERASE')
  for n=1,9 do
    local marked=S.noteMode and (S.locked==n or S.selected>0 and has(S.notes[S.selected],n))
      or S.highlight and S.selected>0 and S.board[S.selected]==n
    local x,y,w,h=digit_box(n)
    button(g,x,y,w,h,tostring(n),marked,{font='strong'})
  end
end
local function hit(x,y,bx,by,w,h) return x>=bx and x<bx+w and y>=by and y<by+h end
local function tap(x,y,additive)
  local function at(key) local b=CONTROLS[key];return hit(x,y,b[1],b[2],b[3],b[4]) end
  if at('help') then
    if HELP or MENU then HELP=false;MENU=false else HELP=true end
    return true
  end
  if HELP then if hit(x,y,76,710,328,62) then HELP=false;return true end;return false end
  if MENU then
    for j,d in ipairs(ORDER) do
      local bx,by
      if j<=3 then bx=12+(j-1)*155;by=193
      else bx=90+(j-4)*155;by=255 end
      if hit(x,y,bx,by,146,54) then CHOICE=d;return true end
    end
    if hit(x,y,76,323,328,62) then return new_puzzle(CHOICE) end
    if hit(x,y,24,407,210,48) then S.autoClean=not S.autoClean;save();return true end
    if hit(x,y,246,407,210,48) then S.highlight=not S.highlight;save();return true end
    if hit(x,y,24,463,210,48) then S.showConflicts=not S.showConflicts;save();return true end
    if hit(x,y,246,463,210,48) then
      S.multiMode=not S.multiMode
      S.locked=0;S.multi=S.selected>0 and {[S.selected]=true} or {}
      save();return true
    end
    if hit(x,y,24,519,210,48) then local r=clear_notes();MENU=false;return r or true end
    if hit(x,y,246,519,210,48) then return reset() end
    if hit(x,y,24,590,210,54) then return visit(S.level-1) end
    if hit(x,y,246,590,210,54) then return visit(S.level+1) end
    if hit(x,y,76,710,328,62) then MENU=false;return true end
    return false
  end
  if at('new') then MENU=true;CHOICE=S.difficulty;return true end
  if at('check') then return check() end
  if at('notes') then
    S.noteMode=not S.noteMode;S.locked=0;MSG=nil;save();return true
  end
  if at('undo') then return undo() end
  if at('erase') then return erase() end
  for n=1,9 do
    local bx,by,w,h=digit_box(n)
    if hit(x,y,bx,by,w,h) then return put(n) end
  end
  if hit(x,y,BOARD.x,BOARD.y,BOARD.size,BOARD.size) then
    return select_cell(math.floor((x-BOARD.x)/BOARD.cell)+1,
      math.floor((y-BOARD.y)/BOARD.cell)+1,additive)
  end
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
      local x,y=tonumber(event.x) or -1,tonumber(event.y) or -1
      if event.gesture=='double_tap' and not HELP and not MENU and
          hit(x,y,BOARD.x,BOARD.y,BOARD.size,BOARD.size) then
        local n=math.floor((y-BOARD.y)/BOARD.cell)*9+
          math.floor((x-BOARD.x)/BOARD.cell)+1
        if P.given[n]==0 and S.board[n]~=0 and not S.submitted then
          changed=select_cell((n-1)%9+1,math.floor((n-1)/9)+1)
          changed=erase() or changed
        end
      else changed=tap(x,y,event.additive==true) end
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
    new=new_puzzle,visit=visit,tap=tap,conflicts=conflicts,
    clear_notes=clear_notes,note_total=function() return note_total(S.notes) end,
    guides=highlight_geometry,select_add=function(x,y) return select_cell(x,y,true) end,
    solved=function() return solved(S.board) end}
end
