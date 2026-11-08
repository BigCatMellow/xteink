-- Ray Vault: original static atom-deduction puzzles for XTEINK X4 Pro.
-- No animation, frame loop, timers, fading, sound, or network.
local N,CELL,BX,BY=6,54,78,185
local UI=require('ui')
local Theme=require('theme')
local LEVELS={
  {16,22,29},
  {4,6,12},
  {1,10,35},
  {3,7,17},
  {0,12,20},
  {18,25,35},
  {0,2,17,30},
  {18,21,31,33},
  {14,25,27,31},
  {12,13,19,26},
  {4,9,23,33},
  {3,10,13,21},
}
local C,S,ERR,MSG,HELP=nil,nil,nil,nil,false
local last_key_ms=-1000
local function inside(x,y) return x>=0 and x<N and y>=0 and y<N end
local function idx(x,y) return y*N+x+1 end
local function atoms(n)
  local t={}
  for _,p in ipairs(LEVELS[n]) do t[p+1]=true end
  return t
end
local function has(t,x,y) return inside(x,y) and t[idx(x,y)] or false end
local function entrance(p)
  if p<=N then return p-1,-1,0,1 end
  if p<=2*N then return N,p-N-1,-1,0 end
  if p<=3*N then return p-2*N-1,N,0,-1 end
  return -1,p-3*N-1,1,0
end
local function exit_port(x,y)
  if y==-1 and x>=0 and x<N then return x+1 end
  if x==N and y>=0 and y<N then return N+y+1 end
  if y==N and x>=0 and x<N then return 2*N+x+1 end
  if x==-1 and y>=0 and y<N then return 3*N+y+1 end
  return nil
end
local function trace(a,p)
  if p<1 or p>4*N then return nil end
  local x,y,dx,dy=entrance(p)
  local seen={}
  for _=1,400 do
    local key=table.concat({x,y,dx,dy},',')
    if seen[key] then return 'LOOP' end
    seen[key]=true
    local nx,ny=x+dx,y+dy
    if not inside(nx,ny) then
      local out=exit_port(nx,ny)
      if out==p then return 'R' end
      return out
    end
    if has(a,nx,ny) then return 'H' end
    local l=has(a,nx-dy,ny+dx)
    local r=has(a,nx+dy,ny-dx)
    if (l or r) and not inside(x,y) then return 'R' end
    if l and r then dx,dy=-dx,-dy
    elseif l then dx,dy=dy,-dx
    elseif r then dx,dy=-dy,dx
    else x,y=nx,ny end
  end
  return 'LOOP'
end
local function fill(n,v)
  local t={}
  for i=1,n do t[i]=v end
  return t
end
local function guess_count()
  local total=0
  for _,m in ipairs(S.marks) do if m==1 then total=total+1 end end
  return total
end
local function correct()
  if not S then return false end
  local a=atoms(S.level)
  for i,v in ipairs(S.marks) do
    if (v==1)~=(a[i] or false) then return false end
  end
  return true
end
local function save()
  if not C or not C.storage or not S then return end
  local marks={}
  for i,v in ipairs(S.marks) do marks[i]=tostring(v) end
  local data=table.concat({
    'version=1','level='..S.level,'unlocked='..S.unlocked,
    'marks='..table.concat(marks),
    'probes='..table.concat(S.probes,','),
    'shots='..S.shots,'checks='..S.checks,
    'stage='..S.stage
  },'\n')
  pcall(function() C.storage:write('ray-vault.txt',data) end)
  pcall(function() C.storage:write('ray-vault-'..S.level..'.txt',data) end)
end
local function start(n,u)
  if n<1 or n>#LEVELS then return false end
  S={level=n,unlocked=math.max(n,u or n),marks=fill(N*N,0),
     probes=fill(4*N,'-'),shots=0,checks=0,stage='play'}
  MSG='Probe the rim; mark suspected atoms'
  HELP=false;save()
  return true
end
local function restore(filename,expected)
  if not C or not C.storage then return false end
  local ok,data=pcall(function() return C.storage:read(filename or 'ray-vault.txt') end)
  if not ok or type(data)~='string' then return false end
  local f={}
  for k,v in data:gmatch('([%w_]+)=([^\n]*)') do f[k]=v end
  if f.version~='1' then return false end
  local n,u=tonumber(f.level),tonumber(f.unlocked)
  local shots,checks=tonumber(f.shots),tonumber(f.checks)
  if not n or n~=math.floor(n) or n<1 or n>#LEVELS or
     not u or u~=math.floor(u) or u<n or u>#LEVELS or
     not shots or shots~=math.floor(shots) or shots<0 or shots>24 or
     not checks or checks~=math.floor(checks) or checks<0 or checks>9999 or
     (f.stage~='play' and f.stage~='won') then return false end
  if expected and n~=expected then return false end
  if not f.marks or #f.marks~=N*N or f.marks:find('[^012]') then return false end
  local m={}
  for i=1,N*N do m[i]=tonumber(f.marks:sub(i,i)) end
  local p={}
  for v in (f.probes or ''):gmatch('[^,]+') do p[#p+1]=v end
  if #p~=4*N then return false end
  for _,v in ipairs(p) do
    if v~='-' and v~='H' and v~='R' and
       (not tonumber(v) or tonumber(v)<1 or tonumber(v)>4*N) then return false end
  end
  S={level=n,unlocked=u,marks=m,probes=p,shots=shots,
     checks=checks,stage=f.stage}
  -- A correct arrangement is still an ordinary in-progress save until CHECK
  -- is pressed. Only a claimed win requires a correct arrangement.
  if S.stage=='won' and not correct() then return false end
  MSG=nil;HELP=false
  return true
end
local function visit(n)
  local unlocked=S.unlocked
  save()
  if restore('ray-vault-'..n..'.txt',n) then
    S.unlocked=math.max(unlocked,S.unlocked)
    save()
  else start(n,unlocked) end
  return true
end
local function fire(port)
  if not S or S.stage~='play' or type(port)~='number' or
     port<1 or port>4*N or S.probes[port]~='-' then return false end
  local result=trace(atoms(S.level),port)
  if not result or result=='LOOP' then MSG='Ray error';return false end
  S.shots=S.shots+1
  if type(result)=='number' then
    local label=tostring(S.shots)
    S.probes[port]=label;S.probes[result]=label
    MSG='Matching numbers show entry and exit'
  else
    S.probes[port]=result
    MSG=result=='H' and 'H = absorbed by an atom' or 'R = reflected'
  end
  save()
  return true
end
local function mark(x,y)
  if not S or S.stage~='play' or not inside(x,y) then return false end
  local i=idx(x,y)
  S.marks[i]=(S.marks[i]+1)%3
  MSG=nil;save();return true
end
local function check()
  if not S or S.stage~='play' then return false end
  if guess_count()~=#LEVELS[S.level] then
    MSG='Mark exactly '..#LEVELS[S.level]..' atoms'
    return true
  end
  S.checks=S.checks+1
  if correct() then
    S.stage='won'
    S.unlocked=math.min(#LEVELS,math.max(S.unlocked,S.level+1))
    MSG='VAULT OPEN — ALL ATOMS FOUND!'
  else MSG='Not correct: check the ray clues' end
  save();return true
end
local function clear()
  if not S or S.stage~='play' then return false end
  S.marks=fill(N*N,0)
  MSG='Guesses cleared; ray readings saved'
  save();return true
end
local function next_level()
  if not S or S.level>=#LEVELS or
     (S.level>=S.unlocked and S.stage~='won') then return false end
  return visit(S.level+1)
end
local function prev()
  if not S or S.level==1 then return false end
  return visit(S.level-1)
end
local function text(g,x,y,s,style,align)
  UI.text(g,C,x,y,s,style,align)
end
local function centered(g,x,y,s,style) text(g,x,y,s,style,'center') end
local function button(g,x,y,w,h,label)
  UI.button(g,C,x,y,w,h,label)
end
local function port_pos(port)
  if port<=N then return BX+(port-0.5)*CELL,BY-23 end
  if port<=2*N then return BX+N*CELL+23,BY+(port-N-0.5)*CELL end
  if port<=3*N then return BX+(port-2*N-0.5)*CELL,BY+N*CELL+23 end
  return BX-23,BY+(port-3*N-0.5)*CELL
end
local function draw_help(g)
  centered(g,240,147,'HOW TO SOLVE','large')
  for _,y in ipairs({202,338,474}) do g:rect(24,y,110,112,{line_width=1}) end
  text(g,38,210,'HIT','small')
  g:circle(42,266,6);g:line(48,266,105,266,{line_width=2});g:circle(110,266,8,{line_width=3})
  UI.paragraph(g,C,150,210,300,104,'H: a head-on atom absorbs the ray. A direct hit takes priority.','small')
  text(g,38,346,'RETURN','small')
  g:circle(42,402,6);g:line(48,402,103,402,{line_width=2})
  g:line(55,402,63,394);g:line(55,402,63,410)
  g:circle(110,386,7);g:circle(110,418,7)
  UI.paragraph(g,C,150,346,300,104,'R: ray returns to entry. Two side atoms, or an atom beside the entrance, reflect it.','small')
  text(g,38,482,'BEND','small')
  g:circle(42,530,6);g:line(48,530,84,530,{line_width=2})
  g:line(84,530,84,568,{line_width=2});g:circle(84,574,6);g:circle(100,514,7)
  UI.paragraph(g,C,150,482,300,104,'One side atom bends a ray 90 degrees away. Matching numbers pair its two ports.','small')
  UI.paragraph(g,C,24,614,432,48,'Tap cells: atom / X / clear. Mark the required atoms, then CHECK.','small','center')
  button(g,65,683,350,70,'BACK')
end
local function draw(g)
  g:clear(0)
  text(g,24,15,'RAY VAULT','large')
  text(g,24,57,'LEVEL '..S.level..'/12   ATOMS '..#LEVELS[S.level],'medium')
  button(g,384,13,72,43,'?')
  g:line(24,109,456,109)
  if HELP then draw_help(g);return end
  UI.region(BX-43,BY-43,N*CELL+86,N*CELL+86)
  for row=0,N-1 do
    for col=0,N-1 do
      local i=idx(col,row)
      local x,y=BX+col*CELL,BY+row*CELL
      g:rect(x,y,CELL,CELL,{line_width=2})
      if S.marks[i]==1 then
        g:circle(x+27,y+27,13,{line_width=3})
        g:circle(x+27,y+27,5,{fill=true})
      elseif S.marks[i]==2 then
        g:line(x+14,y+14,x+40,y+40,{line_width=2})
        g:line(x+40,y+14,x+14,y+40,{line_width=2})
      end
    end
  end
  for port=1,4*N do
    local x,y=port_pos(port)
    g:circle(x,y,15,{line_width=2})
    local label=S.probes[port]
    centered(g,x,y-9,label=='-' and '.' or label,'small')
  end
  centered(g,240,572,'GUESSES '..guess_count()..'/'..#LEVELS[S.level]..'   PROBES '..S.shots,'medium')
  UI.paragraph(g,C,24,614,432,48,MSG or (S.stage=='won' and 'VAULT OPEN' or 'Tap the rim to probe'),'small','center')
  button(g,18,684,107,71,S.level>1 and 'PREV' or 'LEVEL 1')
  button(g,137,684,104,71,'CLEAR')
  button(g,253,684,105,71,'CHECK')
  if S.level<#LEVELS and (S.stage=='won' or S.level<S.unlocked) then
    button(g,371,684,91,71,'NEXT')
  elseif S.stage=='won' then centered(g,413,717,'DONE','small') end
end
local function hit(x,y,a,b,w,h) return x>=a and x<a+w and y>=b and y<b+h end
local function tap(x,y)
  if hit(x,y,384,13,72,43) then HELP=not HELP;return true end
  if HELP then
    if hit(x,y,65,683,350,70) then HELP=false;return true end
    return false
  end
  if hit(x,y,18,684,107,71) then return prev() end
  if hit(x,y,137,684,104,71) then return clear() end
  if hit(x,y,253,684,105,71) then return check() end
  if hit(x,y,371,684,91,71) then return next_level() end
  for port=1,4*N do
    local a,b=port_pos(port)
    if (x-a)^2+(y-b)^2<=20*20 then return fire(port) end
  end
  if hit(x,y,BX,BY,N*CELL,N*CELL) then
    return mark(math.floor((x-BX)/CELL),math.floor((y-BY)/CELL))
  end
  return false
end
local function invalidate()
  if C then pcall(function() C:invalidate() end) end
end
function on_load(c)
  Theme.release()
  C=c or ctx;ERR=nil
  local ok,e=pcall(function() if not restore() then start(1,1) end end)
  if not ok then ERR=tostring(e) end
end
function on_draw(c,g)
  if c then C=c end
  if not g then return end
  if ERR then
    UI.error(g,C,'RAY VAULT',ERR)
    return
  end
  local ok,e=pcall(function() Theme.draw(C,g,draw) end)
  if not ok then ERR=tostring(e) end
end
function on_input(c,e)
  if c then C=c end
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
      if now and now>=last_key_ms and now-last_key_ms<230 then return end
      if now then last_key_ms=now end
      if e.key=='up' then changed=prev() else changed=next_level() end
    end
  end)
  if not ok then ERR=tostring(err);changed=true end
  if changed then invalidate() end
  return changed
end
function on_leave() Theme.release(); if S then save() end end
if rawget(_G,'__TEST') then
  __TEST.api={
    levels=LEVELS,atoms=atoms,trace=trace,pos=port_pos,
    start=start,restore=restore,fire=fire,mark=mark,check=check,
    clear=clear,next=next_level,prev=prev,
    correct=correct,state=function() return S end,tap=tap
  }
end
