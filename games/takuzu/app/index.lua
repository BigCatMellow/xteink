-- Native static logic-grid game; puzzle banks and rules in puzzles.lua.
local UI=require('ui')
local Theme=require('theme')
local P=require('puzzles')
local C,S,HELP,MSG=nil,nil,false,nil
local N=#P.levels
local SAVE=P.id..'.txt'
local function clone(a) local t={} for i,v in ipairs(a) do t[i]=v end return t end
local function pack(a) return table.concat(a) end
local function level(i) return P.levels[i] end
local function blank(i)
 local p=level(i);local a={}
 for j=1,p.n*p.n do
  local ch=p.clues:sub(j,j)
  a[j]=(P.id=='takuzu' and ch~='.') and tonumber(ch)+1 or 0
 end
 return a
end
local function decode(i,s)
 local p=level(i)
 if type(s)~='string' or #s~=p.n*p.n or s:find('[^012]') then return nil end
 local a={}
 for j=1,#s do
  local v=tonumber(s:sub(j,j))
  if P.id=='takuzu' and p.clues:sub(j,j)~='.' and v~=tonumber(p.clues:sub(j,j))+1 then return nil end
  a[j]=v
 end
 return a
end
local function neighbors(n,i,wide)
 local x,y=(i-1)%n+1,math.floor((i-1)/n)+1;local t={}
 for dy=-1,1 do for dx=-1,1 do
  if (wide or math.abs(dx)+math.abs(dy)==1) and x+dx>=1 and x+dx<=n and y+dy>=1 and y+dy<=n then
   t[#t+1]=(y+dy-1)*n+x+dx
  end
 end end
 return t
end
local function valid(i,a)
 local p=level(i);local n=p.n
 for j=1,n*n do if a[j]==0 then return false end end
 if P.id=='takuzu' then
  for axis=1,2 do
   local seen={}
   for line=1,n do
    local z,ones={},0
    for j=1,n do
     local k=axis==1 and (line-1)*n+j or (j-1)*n+line
     local v=a[k];z[j]=v
     if v==2 then ones=ones+1 end
     if j>=3 and z[j-1]==v and z[j-2]==v then return false end
    end
    local key=pack(z)
    if ones~=n/2 or seen[key] then return false end
    seen[key]=true
   end
  end
  return true
 elseif P.id=='mosaic' then
  for j=1,n*n do
   local v=tonumber(p.clues:sub(j,j))
   if v then
    local count=0
    for _,k in ipairs(neighbors(n,j,true)) do if a[k]==1 then count=count+1 end end
    if count~=v then return false end
   end
  end
  return true
 end
 local start,total=nil,0
 for j=1,n*n do
  if a[j]==1 then
   for _,k in ipairs(neighbors(n,j,false)) do if a[k]==1 then return false end end
  else start=start or j;total=total+1 end
 end
 for axis=1,2 do for line=1,n do
  local seen={}
  for j=1,n do
   local k=axis==1 and (line-1)*n+j or (j-1)*n+line
   local v=p.clues:sub(k,k)
   if a[k]~=1 then if seen[v] then return false end;seen[v]=true end
  end
 end end
 if not start then return false end
 local q,seen={start},{[start]=true};local head=1
 while head<=#q do
  for _,k in ipairs(neighbors(n,q[head],false)) do
   if a[k]~=1 and not seen[k] then seen[k]=true;q[#q+1]=k end
  end
  head=head+1
 end
 return #q==total
end
local function fresh()
 S={level=1,unlocked=1,mode=1,boards={},history={},won={}}
 for i=1,N do S.boards[i]=blank(i);S.history[i]={};S.won[i]=false end
end
local function save()
 local lines={'version=1','level='..S.level,'unlocked='..S.unlocked,'mode='..S.mode}
 for i=1,N do
  lines[#lines+1]='B'..i..'='..pack(S.boards[i])
  lines[#lines+1]='W'..i..'='..(S.won[i] and '1' or '0')
  local h={}
  for j,a in ipairs(S.history[i]) do h[j]=pack(a) end
  lines[#lines+1]='H'..i..'='..table.concat(h,';')
 end
 local ok,err=C.storage:write(SAVE,table.concat(lines,'\n'))
 if ok==false or (ok==nil and err) then error('Save failed: '..tostring(err)) end
end
local function integer(v,min,max)
 local n=tonumber(v);return n and n==math.floor(n) and n>=min and n<=max and n
end
local function restore()
 local data,err=C.storage:read(SAVE)
 if data==nil then
  if err and err~='not_found' then error('Read failed: '..tostring(err)) end
  fresh();save();return
 end
 local f={}
 for k,v in data:gmatch('([%w_]+)=([^\n]*)') do f[k]=v end
 assert(f.version=='1','Unsupported save version')
 local l,u,m=integer(f.level,1,N),integer(f.unlocked,1,N),integer(f.mode,1,2)
 assert(l and u and m and l<=u,'Invalid progress')
 local s={level=l,unlocked=u,mode=m,boards={},history={},won={}}
 for i=1,N do
  s.boards[i]=assert(decode(i,f['B'..i]),'Invalid saved board')
  local w=f['W'..i];assert(w=='0' or w=='1','Invalid saved status')
  s.won[i]=w=='1'
  assert(not s.won[i] or (valid(i,s.boards[i]) and u>=math.min(N,i+1)),'Invalid solved board')
  local h={};assert(f['H'..i]~=nil,'Missing undo history')
  for item in f['H'..i]:gmatch('[^;]+') do
   assert(#h<12,'Invalid undo count')
   h[#h+1]=assert(decode(i,item),'Invalid undo state')
  end
  s.history[i]=h
 end
 S=s
end
local function mode(v) if v==S.mode then return false end;S.mode=v;save();return true end
local function paint(j)
 local i=S.level;local p=level(i);local a=S.boards[i]
 if not a[j] or S.won[i] or (P.id=='takuzu' and p.clues:sub(j,j)~='.') then return false end
 local h=S.history[i];if #h>=12 then table.remove(h,1) end
 h[#h+1]=clone(a)
 a[j]=a[j]==S.mode and 0 or S.mode;MSG=nil;save();return true
end
local function undo()
 local i=S.level;local h=S.history[i]
 if S.won[i] or #h==0 then return false end
 S.boards[i]=table.remove(h);MSG=nil;save();return true
end
local function reset()
 local i=S.level;S.boards[i]=blank(i);S.history[i]={};S.won[i]=false;MSG=nil;save();return true
end
local function check()
 local i=S.level
 if S.won[i] then return false end
 if valid(i,S.boards[i]) then
  S.won[i]=true;S.unlocked=math.max(S.unlocked,math.min(N,i+1));MSG='Solved'
 else MSG='Not solved yet' end
 save();return true
end
local function visit(i)
 if i<1 or i>S.unlocked or i==S.level then return false end
 S.level=i;HELP=false;MSG=nil;save();return true
end
local function geometry() return UI.grid_geometry(level(S.level).n,94,572,468) end
local BOX={help={416,12,48,48},one={12,620,222,62},two={246,620,222,62},
 prev={12,704,106,70},undo={128,704,106,70},reset={244,704,106,70},check={360,704,108,70},
 back={76,704,328,70}}
local function hit(b,x,y) return x>=b[1] and y>=b[2] and x<b[1]+b[3] and y<b[2]+b[4] end
local function button(g,b,label,selected) UI.button(g,C,b[1],b[2],b[3],b[4],label,selected) end
local function text(g,x,y,s,role,align,w) UI.text(g,C,x,y,s,role,align,w) end
local function render(g)
 g:clear(0)
 text(g,80,14,P.name,'large',nil,326)
 button(g,BOX.help,HELP and 'X' or '?')
 if HELP then
  text(g,240,94,'How to play','large','center',440)
  UI.paragraph(g,C,22,152,436,480,P.help,'medium')
  button(g,BOX.back,'Back to grid');return
 end
 local i=S.level;local p=level(i);local n=p.n;local a=S.boards[i]
 text(g,16,60,'Puzzle '..i..' / '..N,'small',nil,300)
 local bx,by,t=geometry()
 UI.region(bx,by,n*t,n*t);UI.grid(g,bx,by,n,n,t)
 local marked=0
 for j=1,n*n do
  local x,y=bx+((j-1)%n)*t,by+math.floor((j-1)/n)*t
  local cx,cy=x+t/2,y+t/2
  local v=a[j];local ch=p.clues:sub(j,j)
  if v~=0 then marked=marked+1 end
  if P.id=='takuzu' then
   if v~=0 then
    local role=ch=='.' and 'digit_light' or 'digit'
    text(g,cx,cy-UI.height(C,role)/2,tostring(v-1),role,'center',t-8)
    if ch~='.' then g:rect(x+5,y+5,5,5,{fill=true,radius=0}) end
   end
  else
   if v==1 then
    if ch=='.' then g:rect(x+4,y+4,t-8,t-8,{fill=true,radius=2})
    else
     -- Thick inset border keeps fixed digits black on white.
     g:rect(x+4,y+4,t-8,t-8,{line_width=5,radius=2})
    end
   elseif v==2 then
    if ch=='.' then
     UI.stroke(g,cx-9,cy-9,cx+9,cy+9,2);UI.stroke(g,cx-9,cy+9,cx+9,cy-9,2)
    else g:circle(x+8,y+8,3,{fill=true}) end
   end
   if ch~='.' then
    local role=t>=52 and 'clue' or 'clue_small'
    text(g,cx,cy-UI.height(C,role)/2,ch,role,'center',t-14)
   end
  end
 end
 text(g,240,580,MSG or (S.won[i] and 'Solved' or 'Marked '..marked..' / '..n*n),'medium','center',440)
 button(g,BOX.one,P.modes[1],S.mode==1);button(g,BOX.two,P.modes[2],S.mode==2)
 button(g,BOX.prev,'Prev');button(g,BOX.undo,'Undo');button(g,BOX.reset,'Reset')
 button(g,BOX.check,S.won[i] and (i<N and 'Next' or 'Done') or 'Check')
end
local function tap(x,y)
 if hit(BOX.help,x,y) then HELP=not HELP;return true end
 if HELP then if hit(BOX.back,x,y) then HELP=false;return true end;return false end
 if hit(BOX.one,x,y) then return mode(1) end
 if hit(BOX.two,x,y) then return mode(2) end
 if hit(BOX.prev,x,y) then return visit(S.level-1) end
 if hit(BOX.undo,x,y) then return undo() end
 if hit(BOX.reset,x,y) then return reset() end
 if hit(BOX.check,x,y) then if S.won[S.level] then return visit(S.level+1) end;return check() end
 local bx,by,t=geometry();local n=level(S.level).n
 if x>=bx and y>=by and x<bx+n*t and y<by+n*t then
  return paint(math.floor((y-by)/t)*n+math.floor((x-bx)/t)+1)
 end
 return false
end
local KEY_MS=-1000
function on_load(ctx) Theme.release();C=ctx;HELP=false;MSG=nil;KEY_MS=-1000;restore() end
function on_draw(ctx,g) C=ctx or C;if g then Theme.draw(C,g,render) end end
function on_input(ctx,e)
 C=ctx or C
 if type(e)~='table' then return false end
 local changed=false
 if (e.type=='pointer' and e.phase=='up' or e.type=='touch') and (not e.gesture or e.gesture=='tap' or e.gesture=='double_tap') then
  changed=tap(tonumber(e.x) or -1,tonumber(e.y) or -1)
 elseif e.type=='key' and (not e.phase or e.phase=='down') and (e.key=='up' or e.key=='down') then
  local now=tonumber(e.time_ms)
  if not now and C.clock then local ok,v=pcall(function()return C.clock:millis()end);if ok then now=tonumber(v)end end
  if now and now>=KEY_MS and now-KEY_MS<230 then return false end
  if now then KEY_MS=now end
  changed=visit(S.level+(e.key=='up' and -1 or 1))
 end
 if changed then C:invalidate() end
 return changed
end
function on_leave() Theme.release();if S then save() end end
if rawget(_G,'__TEST') then
 __TEST.api={levels=P.levels,state=function()return S end,valid=valid,paint=paint,mode=mode,
 undo=undo,reset=reset,check=check,visit=visit,geometry=geometry,tap=tap}
end
do
 local guard=UI.guard{id=P.id,test=rawget(_G,'__TEST'),state=function()return S and 'level='..S.level end,
 load=on_load,draw=on_draw,input=on_input,leave=on_leave}
 on_load,on_draw,on_input,on_leave=guard.load,guard.draw,guard.input,guard.leave
end
