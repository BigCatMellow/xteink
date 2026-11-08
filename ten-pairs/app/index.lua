-- Ten Pairs: original static Numberama / Number Match style game.
-- 8 columns, no automatic motion. Tap two digits to remove.
local UI=require('ui')
local DATA=require('boards')
local C,S,ERR,MSG=nil,nil,nil,nil
local HELP=false
local KEY_MS=-1000
local TOTAL=#DATA
local MAX=88
local function initial(n)
  local a={}
  for i=1,#DATA[n].digits do a[i]=tonumber(DATA[n].digits:sub(i,i)) end
  return a
end
local function encode(a)
  local t={}
  for i,v in ipairs(a) do t[i]=tostring(v) end
  return table.concat(t)
end
local function parse(s)
  if type(s)~='string' or #s<32 or #s>MAX or s:find('[^0-9]') then return nil end
  local t={}
  for i=1,#s do t[i]=tonumber(s:sub(i,i)) end
  return t
end
local function clone(a)
  local t={}
  for i,v in ipairs(a) do t[i]=v end
  return t
end
local function remaining(tiles)
  local n=0
  for _,v in ipairs(tiles) do if v>0 then n=n+1 end end
  return n
end
local function complete(n)
  return remaining(S.boards[n or S.level])==0
end
local function match_value(a,b)
  return a>0 and b>0 and (a==b or a+b==10)
end
local function pair_ok(tiles,i,j)
  if not tiles[i] or not tiles[j] or i==j or
     not match_value(tiles[i],tiles[j]) then return false end
  local lo,hi=math.min(i,j),math.max(i,j)
  local adjacent=true
  for p=lo+1,hi-1 do if tiles[p]~=0 then adjacent=false;break end end
  if adjacent then return true end
  local x1,y1=(i-1)%8+1,math.floor((i-1)/8)
  local x2,y2=(j-1)%8+1,math.floor((j-1)/8)
  local dx,dy=x2-x1,y2-y1
  local steps=math.max(math.abs(dx),math.abs(dy))
  if not (dx==0 or dy==0 or math.abs(dx)==math.abs(dy)) then return false end
  local vx=dx==0 and 0 or dx/math.abs(dx)
  local vy=dy==0 and 0 or dy/math.abs(dy)
  for s=1,steps-1 do
    local k=(y1+s*vy)*8+x1+s*vx
    if not tiles[k] or tiles[k]~=0 then return false end
  end
  return true
end
local function save()
  if not S or not C or not C.storage then return end
  local lines={'version=1','level='..S.level,'unlocked='..S.unlocked}
  for i=1,TOTAL do
    lines[#lines+1]='B'..i..'='..encode(S.boards[i])
    lines[#lines+1]='S'..i..'='..S.selected[i]
    lines[#lines+1]='Q'..i..'='..S.hintsUsed[i]
    local hist={}
    for j,v in ipairs(S.history[i]) do hist[j]=encode(v) end
    lines[#lines+1]='H'..i..'='..table.concat(hist,';')
  end
  pcall(function() C.storage:write('ten-pairs.txt',table.concat(lines,'\n')) end)
end
local function start()
  S={level=1,unlocked=1,boards={},selected={},history={},hintsUsed={},hintPair={}}
  for i=1,TOTAL do
    S.boards[i]=initial(i);S.selected[i]=0;S.history[i]={}
    S.hintsUsed[i]=0;S.hintPair[i]=nil
  end
  MSG='Find equal digits or a sum of ten'
  HELP=false;save()
end
local function restore()
  if not C or not C.storage then return false end
  local ok,raw=pcall(function() return C.storage:read('ten-pairs.txt') end)
  if not ok or type(raw)~='string' then return false end
  local f={}
  for k,v in raw:gmatch('([%w_]+)=([^\n]*)') do f[k]=v end
  local level,unlocked=tonumber(f.level),tonumber(f.unlocked)
  if f.version~='1' or not level or level~=math.floor(level) or level<1 or level>TOTAL
     or not unlocked or unlocked~=math.floor(unlocked) or unlocked<level or unlocked>TOTAL then return false end
  local candidate={level=level,unlocked=unlocked,boards={},selected={},history={},hintsUsed={},hintPair={}}
  for i=1,TOTAL do
    local board=parse(f['B'..i])
    local select=tonumber(f['S'..i])
    local hints=tonumber(f['Q'..i])
    if not board or not select or select~=math.floor(select) or select<0 or select>#board or
       (select>0 and board[select]==0) or not hints or hints~=math.floor(hints)
       or hints<0 or hints>2 then return false end
    local old={}
    for item in (f['H'..i] or ''):gmatch('[^;]+') do
      if #old>=10 then return false end
      local prev=parse(item)
      if not prev then return false end
      old[#old+1]=prev
    end
    if remaining(board)==0 and i<TOTAL and unlocked<i+1 then return false end
    candidate.boards[i]=board;candidate.selected[i]=select
    candidate.hintsUsed[i]=hints;candidate.history[i]=old
  end
  S=candidate;HELP=false;MSG=nil;return true
end
local function visit(n)
  if not S or n<1 or n>TOTAL or n>S.unlocked then return false end
  S.level=n;MSG=nil;HELP=false;save();return true
end
local function next_level() return S and visit(S.level+1) or false end
local function previous() return S and visit(S.level-1) or false end
local function record()
  local h=S.history[S.level]
  if #h>=10 then table.remove(h,1) end
  h[#h+1]=clone(S.boards[S.level])
end
local function pick(i)
  if not S or complete() then return false end
  local tiles=S.boards[S.level]
  if not tiles[i] or tiles[i]==0 then return false end
  local first=S.selected[S.level]
  if first==0 then S.selected[S.level]=i;MSG='Select the matching digit';save();return true end
  S.selected[S.level]=0
  if i==first then MSG='Selection cancelled';save();return true end
  if not pair_ok(tiles,i,first) then MSG='Not a reachable pair';save();return true end
  record()
  tiles[i]=0;tiles[first]=0
  S.hintPair[S.level]=nil
  MSG=complete() and 'ALL NUMBERS CLEARED!' or 'Pair removed'
  if complete() then S.unlocked=math.min(TOTAL,math.max(S.unlocked,S.level+1)) end
  save();return true
end
local function undo()
  if not S then return false end
  if S.selected[S.level]>0 then
    S.selected[S.level]=0;MSG='Selection cancelled';save();return true
  end
  local hist=S.history[S.level]
  if #hist==0 then return false end
  S.boards[S.level]=table.remove(hist)
  S.hintPair[S.level]=nil
  MSG='Previous board restored';save();return true
end
local function add()
  if not S or complete() then return false end
  local old=S.boards[S.level]
  local left={}
  for _,v in ipairs(old) do if v>0 then left[#left+1]=v end end
  if #old+#left>MAX then MSG='Board full; undo or reset';return true end
  record()
  for _,v in ipairs(left) do old[#old+1]=v end
  S.selected[S.level]=0;S.hintPair[S.level]=nil
  MSG='Remaining numbers appended'
  save();return true
end
local function hint()
  if not S or complete() then return false end
  if S.hintPair[S.level] then MSG='Ringed digits are a pair';return true end
  if S.hintsUsed[S.level]>=2 then MSG='No hints left';return true end
  local t=S.boards[S.level]
  for i=1,#t do
    if t[i]>0 then
      for j=i+1,#t do
        if pair_ok(t,i,j) then
          S.hintPair[S.level]={i,j}
          S.hintsUsed[S.level]=S.hintsUsed[S.level]+1
          MSG='A reachable pair is ringed';save();return true
        end
      end
    end
  end
  MSG='No pair left: ADD the numbers'
  return true
end
local function restart()
  if not S then return false end
  S.boards[S.level]=initial(S.level)
  S.selected[S.level]=0;S.history[S.level]={}
  S.hintsUsed[S.level]=0;S.hintPair[S.level]=nil
  MSG='Fresh number sheet';save();return true
end
local function geometry() return 80,165,40 end
local function text(g,x,y,s,style,align,w) UI.text(g,C,x,y,s,style,align,w) end
local function button(g,x,y,w,h,s) UI.button(g,C,x,y,w,h,s) end
local function draw_help(g)
  text(g,240,156,'MATCH NUMBERS','large','center',428)
  UI.paragraph(g,C,28,214,424,110,
    'Tap two equal digits, or two that sum to ten. Empty squares do not block a match.', 'medium')
  UI.paragraph(g,C,28,343,424,124,
    'Pairs connect along straight rows, columns, diagonals or reading order across lines.', 'medium')
  UI.paragraph(g,C,28,485,424,138,
    'ADD copies remaining digits to new rows. UNDO restores a move. Clear every digit to win.', 'medium')
  button(g,74,704,332,70,'BACK TO SHEET')
end
local function render(g)
  g:clear(0)
  text(g,20,15,'TEN PAIRS','large',nil,295)
  button(g,421,12,39,43,HELP and 'X' or '?')
  if S.level<TOTAL and S.level<S.unlocked then button(g,311,12,98,43,'NEXT') end
  local t=S.boards[S.level]
  text(g,20,73,'SHEET '..S.level..' / '..TOTAL,'medium')
  text(g,20,113,'MATCH SAME OR SUM TO 10','small')
  g:line(20,150,460,150,{line_width=2})
  if HELP then draw_help(g);return end
  local bx,by,cell=geometry()
  local rows=math.ceil(#t/8)
  UI.region(bx,by,8*cell,rows*cell)
  for i,v in ipairs(t) do
    local x=(i-1)%8
    local y=math.floor((i-1)/8)
    local px,py=bx+x*cell,by+y*cell
    g:rect(px,py,cell,cell,{line_width=1})
    if v>0 then
      text(g,px+cell/2,py+9,tostring(v),'medium','center',cell-6)
      if S.selected[S.level]==i then g:rect(px+4,py+4,cell-8,cell-8,{line_width=2}) end
      local hintPair=S.hintPair[S.level]
      if hintPair and (hintPair[1]==i or hintPair[2]==i) then
        g:circle(px+cell/2,py+cell/2,17,{line_width=2})
      end
    end
  end
  text(g,240,624,'REMAINING '..remaining(t)..'  /  '..#t,'medium','center',420)
  text(g,240,662,MSG or 'Select a matching pair','small','center',434)
  button(g,12,708,84,66,S.level>1 and 'PREV' or 'START')
  button(g,105,708,84,66,'UNDO')
  button(g,198,708,84,66,'ADD')
  button(g,291,708,84,66,'HINT')
  button(g,384,708,84,66,'RESET')
end
local function hit(x,y,bx,by,w,h) return x>=bx and x<bx+w and y>=by and y<by+h end
local function tap(x,y)
  if hit(x,y,421,12,39,43) then HELP=not HELP;return true end
  if HELP then
    if hit(x,y,74,704,332,70) then HELP=false;return true end
    return false
  end
  if hit(x,y,311,12,98,43) then return next_level() end
  if hit(x,y,12,708,84,66) then return previous() end
  if hit(x,y,105,708,84,66) then return undo() end
  if hit(x,y,198,708,84,66) then return add() end
  if hit(x,y,291,708,84,66) then return hint() end
  if hit(x,y,384,708,84,66) then return restart() end
  local bx,by,cell=geometry()
  if hit(x,y,bx,by,320,math.ceil(#S.boards[S.level]/8)*cell) then
    return pick(math.floor((y-by)/cell)*8+math.floor((x-bx)/cell)+1)
  end
  return false
end
local function redraw() if C then pcall(function() C:invalidate() end) end end
function on_load(ctx) C=ctx or context;ERR=nil
  local ok,e=pcall(function() if not restore() then start() end end)
  if not ok then ERR=tostring(e) end
end
function on_draw(ctx,g) if ctx then C=ctx end
  if not g then return end
  if ERR then UI.error(g,C,'TEN PAIRS',ERR);return end
  local ok,e=pcall(function() render(g) end)
  if not ok then ERR=tostring(e);UI.error(g,C,'TEN PAIRS',ERR) end
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
function on_leave() if S then save() end end
if rawget(_G,'__TEST') then __TEST.api={
 levels=DATA,state=function()return S end,can=pair_ok,pick=pick,add=add,
 hint=hint,undo=undo,restart=restart,visit=visit,next=next_level,
 prev=previous,complete=complete,geometry=geometry,tap=tap
} end
