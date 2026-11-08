-- Rectangle Rooms: original Shikaku partition puzzles for XTEINK X4 Pro.
-- Tap opposite corners, one static e-ink redraw per accepted action.
local UI=require('ui')
local Theme=require('theme')
local Puzzles=require('puzzles')
local TOTAL=#Puzzles
local C,S,ERR,MSG=nil,nil,nil,nil
local HELP=false
local KEY_MS=-1000
local function value(ch)
  if ch=='.' then return 0 end
  if ch:match('^%d$') then return tonumber(ch) end
  return string.byte(ch)-string.byte('A')+10
end
local function grid(n)
  local p=Puzzles[n]
  if not p then error('Missing level') end
  local size=#p.rows
  local numbers={}
  local goal=0
  for y=1,size do
    if #p.rows[y]~=size then error('Non-square level') end
    for x=1,size do
      local clue=value(p.rows[y]:sub(x,x))
      if clue<0 or clue>size*size then error('Bad clue') end
      numbers[(y-1)*size+x]=clue
      if clue>0 then goal=goal+1 end
    end
  end
  return {n=size,name=p.name,nums=numbers,goal=goal}
end
local function copy(r)
  return {x=r.x,y=r.y,w=r.w,h=r.h}
end
local function encode(rooms)
  local parts={}
  for i,r in ipairs(rooms) do
    parts[i]=table.concat({r.x,r.y,r.w,r.h},'.')
  end
  return table.concat(parts,';')
end
local function occupied(rooms,x,y)
  for _,r in ipairs(rooms) do
    if x>=r.x and x<r.x+r.w and y>=r.y and y<r.y+r.h then return true end
  end
  return false
end
local function check_rect(g,rooms,r)
  local n=g.n
  if r.x<1 or r.y<1 or r.w<1 or r.h<1 or
     r.x+r.w-1>n or r.y+r.h-1>n then return false,'Outside the grid' end
  local clues,valueFound=0,0
  for y=r.y,r.y+r.h-1 do
    for x=r.x,r.x+r.w-1 do
      if occupied(rooms,x,y) then return false,'A room already occupies that cell' end
      local v=g.nums[(y-1)*n+x]
      if v>0 then clues=clues+1;valueFound=v end
    end
  end
  if clues~=1 then return false,'A room must contain one clue' end
  if r.w*r.h~=valueFound then return false,'Room area must match its number' end
  return true
end
local function decode(encoded,g)
  if type(encoded)~='string' then return nil end
  local result={}
  if encoded=='' then return result end
  for part in encoded:gmatch('[^;]+') do
    local a,b,c,d=part:match('^(%d+)%.(%d+)%.(%d+)%.(%d+)$')
    if not a then return nil end
    local r={x=tonumber(a),y=tonumber(b),w=tonumber(c),h=tonumber(d)}
    if not check_rect(g,result,r) then return nil end
    result[#result+1]=r
  end
  if #result>g.goal then return nil end
  return result
end
local function covered(rooms)
  local total=0
  for _,r in ipairs(rooms) do total=total+r.w*r.h end
  return total
end
local function done(n)
  local index=n or S.level
  return covered(S.rooms[index])==grid(index).n^2
end
local function save()
  if not S or not C or not C.storage then return end
  local lines={'version=1','level='..S.level,'unlocked='..S.unlocked}
  for i=1,TOTAL do
    lines[#lines+1]='R'..i..'='..encode(S.rooms[i])
    lines[#lines+1]='P'..i..'='..S.picks[i]
  end
  pcall(function() C.storage:write('rectangle-rooms.txt',table.concat(lines,'\n')) end)
end
local function start()
  S={level=1,unlocked=1,rooms={},picks={}}
  for i=1,TOTAL do S.rooms[i]={};S.picks[i]=0 end
  HELP=false;MSG='Choose two opposite corners'
  save()
end
local function restore()
  if not C or not C.storage then return false end
  local ok,data=pcall(function() return C.storage:read('rectangle-rooms.txt') end)
  if not ok or type(data)~='string' then return false end
  local f={}
  for k,v in data:gmatch('([%w_]+)=([^\n]*)') do f[k]=v end
  if f.version~='1' then return false end
  local n,u=tonumber(f.level),tonumber(f.unlocked)
  if not n or n~=math.floor(n) or n<1 or n>TOTAL or
     not u or u~=math.floor(u) or u<n or u>TOTAL then return false end
  local rooms,picks={},{}
  for i=1,TOTAL do
    local g=grid(i)
    local arr=decode(f['R'..i],g)
    local pick=tonumber(f['P'..i])
    if not arr or not pick or pick~=math.floor(pick) or pick<0 or pick>g.n*g.n then return false end
    if pick>0 then
      local x=(pick-1)%g.n+1
      local y=math.floor((pick-1)/g.n)+1
      if occupied(arr,x,y) then return false end
    end
    if covered(arr)==g.n*g.n and i<TOTAL and u<i+1 then return false end
    rooms[i]=arr;picks[i]=pick
  end
  S={level=n,unlocked=u,rooms=rooms,picks=picks}
  HELP=false;MSG=nil
  return true
end
local function visit(n)
  if not S or n<1 or n>TOTAL or n>S.unlocked then return false end
  S.level=n;HELP=false;MSG=nil
  save()
  return true
end
local function previous() return S and visit(S.level-1) or false end
local function next_level() return S and visit(S.level+1) or false end
local function set_cell(x,y)
  if not S then return false end
  local g=grid(S.level)
  if x<1 or x>g.n or y<1 or y>g.n or done() then return false end
  local rooms=S.rooms[S.level]
  if occupied(rooms,x,y) then MSG='That cell already belongs to a room';return true end
  local index=(y-1)*g.n+x
  local prior=S.picks[S.level]
  if prior==0 then
    S.picks[S.level]=index
    MSG='Now tap the opposite corner'
    save();return true
  end
  if prior==index then
    S.picks[S.level]=0;MSG='Selection cancelled';save();return true
  end
  local px=(prior-1)%g.n+1
  local py=math.floor((prior-1)/g.n)+1
  local x0,y0=math.min(px,x),math.min(py,y)
  local r={x=x0,y=y0,w=math.abs(px-x)+1,h=math.abs(py-y)+1}
  S.picks[S.level]=0
  local valid,why=check_rect(g,rooms,r)
  if not valid then MSG=why;save();return true end
  rooms[#rooms+1]=r
  MSG='Room added'
  if done() then
    S.unlocked=math.min(TOTAL,math.max(S.unlocked,S.level+1))
    MSG='ALL ROOMS COMPLETE!'
  end
  save()
  return true
end
local function undo()
  if not S then return false end
  if S.picks[S.level]~=0 then
    S.picks[S.level]=0;MSG='Selection cancelled';save();return true
  end
  local rooms=S.rooms[S.level]
  if #rooms==0 then return false end
  table.remove(rooms)
  MSG='Last room removed';save();return true
end
local function restart()
  if not S then return false end
  S.rooms[S.level]={}
  S.picks[S.level]=0
  MSG='Fresh grid';save();return true
end
local function geometry(n)
  local cell=(n==5 and 62 or n==6 and 54 or 47)
  return math.floor((480-n*cell)/2),190,cell
end
local function text(g,x,y,s,style,align,width) UI.text(g,C,x,y,s,style,align,width) end
local function button(g,x,y,w,h,s) UI.button(g,C,x,y,w,h,s) end
local function draw_help(g)
  text(g,240,166,'HOW TO DIVIDE','large','center',424)
  UI.paragraph(g,C,27,228,426,115,
    'Divide the grid into rectangles. Each rectangle contains exactly one number.', 'medium')
  UI.paragraph(g,C,27,352,426,108,
    'The number is its rectangle area. Tap two opposite corners to draw a room.', 'medium')
  UI.paragraph(g,C,27,478,426,114,
    'Rooms cannot overlap. Cover every cell to win. UNDO or RESET a mistake.', 'medium')
  button(g,74,700,332,73,'BACK TO GRID')
end
local function render(g)
  g:clear(0)
  text(g,22,17,'RECTANGLE ROOMS','large',nil,360)
  button(g,417,13,43,45,HELP and 'X' or '?')
  text(g,22,75,'PUZZLE '..S.level..' / '..TOTAL,'medium')
  text(g,22,117,'ONE NUMBER IN EVERY ROOM','small',nil,425)
  g:line(22,155,458,155,{line_width=2})
  if HELP then draw_help(g);return end
  local gdata=grid(S.level)
  local bx,by,cell=geometry(gdata.n)
  UI.region(bx,by,cell*gdata.n,cell*gdata.n)
  for y=1,gdata.n do
    for x=1,gdata.n do
      local px=bx+(x-1)*cell
      local py=by+(y-1)*cell
      g:rect(px,py,cell,cell,{line_width=2})
      local i=(y-1)*gdata.n+x
      local clue=gdata.nums[i]
      if clue>0 then
        text(g,px+cell/2,py+math.floor((cell-24)/2),tostring(clue),
             gdata.n==7 and 'small' or 'medium','center',cell-10)
      end
    end
  end
  for _,r in ipairs(S.rooms[S.level]) do
    local x=bx+(r.x-1)*cell
    local y=by+(r.y-1)*cell
    g:rect(x+2,y+2,cell*r.w-4,cell*r.h-4,{line_width=3})
  end
  local pick=S.picks[S.level]
  if pick>0 then
    local x=(pick-1)%gdata.n
    local y=math.floor((pick-1)/gdata.n)
    g:rect(bx+x*cell+6,by+y*cell+6,cell-12,cell-12,{line_width=2})
  end
  local rooms=S.rooms[S.level]
  text(g,240,556,'ROOMS '..#rooms..'/'..gdata.goal..'   CELLS '..covered(rooms)..'/'..gdata.n*gdata.n,
       'medium','center',432)
  text(g,240,605,MSG or 'Tap two opposite corners','small','center',432)
  text(g,240,643,done() and 'PUZZLE SOLVED' or 'Every number is a rectangle area',
       'small','center',430)
  button(g,20,702,104,73,S.level>1 and 'PREV' or 'START')
  button(g,132,702,104,73,'UNDO')
  button(g,244,702,104,73,'RESET')
  if S.level<TOTAL and S.level<S.unlocked then
    button(g,356,702,104,73,'NEXT')
  elseif done() then
    text(g,408,729,'DONE','small','center',95)
  end
end
local function hit(x,y,bx,by,w,h)
  return x>=bx and x<bx+w and y>=by and y<by+h
end
local function tap(x,y)
  if hit(x,y,417,13,43,45) then HELP=not HELP;return true end
  if HELP then
    if hit(x,y,74,700,332,73) then HELP=false;return true end
    return false
  end
  if hit(x,y,20,702,104,73) then return previous() end
  if hit(x,y,132,702,104,73) then return undo() end
  if hit(x,y,244,702,104,73) then return restart() end
  if hit(x,y,356,702,104,73) then return next_level() end
  local g=grid(S.level)
  local bx,by,cell=geometry(g.n)
  if hit(x,y,bx,by,cell*g.n,cell*g.n) then
    return set_cell(math.floor((x-bx)/cell)+1,math.floor((y-by)/cell)+1)
  end
  return false
end
local function refresh()
  if C then pcall(function() C:invalidate() end) end
end
function on_load(context)
  Theme.release()
  C=context or ctx;ERR=nil
  local ok,e=pcall(function() if not restore() then start() end end)
  if not ok then ERR=tostring(e) end
end
function on_draw(context,g)
  if context then C=context end
  if not g then return end
  if ERR then UI.error(g,C,'RECTANGLE ROOMS',ERR);return end
  local ok,e=pcall(function() Theme.draw(C,g,render) end)
  if not ok then ERR=tostring(e);UI.error(g,C,'RECTANGLE ROOMS',ERR) end
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
        local yes,val=pcall(function() return C.clock:millis() end)
        if yes then now=tonumber(val) end
      end
      if now and now>=KEY_MS and now-KEY_MS<230 then return end
      if now then KEY_MS=now end
      changed=event.key=='up' and previous() or next_level()
    end
  end)
  if not ok then ERR=tostring(e);changed=true end
  if changed then refresh() end
  return changed
end
function on_leave() Theme.release(); if S then save() end end
if rawget(_G,'__TEST') then
  __TEST.api={
    puzzles=Puzzles,state=function() return S end,
    grid=grid,check_rect=check_rect,covered=covered,
    set_cell=set_cell,undo=undo,restart=restart,
    next=next_level,prev=previous,visit=visit,
    done=done,geometry=geometry,tap=tap,restore=restore
  }
end
