-- Native static logic-grid game; puzzle banks and rules in puzzles.lua.
local UI=require('ui')
local Theme=require('theme')
local P=require('puzzles')
local Generator=require('procedural_puzzles')
local Store=require('puzzle_store')
local SIZES=Generator.sizes[P.id]
local MAX=999999999
local nonce=0
local C,S,HELP,MSG=nil,nil,false,nil
local N=#P.levels
local SAVE=P.id..'.txt'
local function clone(a) local t={} for i,v in ipairs(a) do t[i]=v end return t end
local function pack(a) return table.concat(a) end
local function level(i)
 if i<=N then return P.levels[i] end
 assert(S and S.generated and S.generated.number==i,'Generated puzzle not loaded')
 return S.generated
end
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
local function integer(v,min,max)
 local n=tonumber(v);return n and n==math.floor(n) and n>=min and n<=max and n
end
local function initial()
 local s={level=1,unlocked=1,legacyUnlocked=1,generatedMax=N,mode=1,size=SIZES[1],boards={},history={},won={}}
 for i=1,N do s.boards[i]=blank(i);s.history[i]={};s.won[i]=false end
 return s
end
local function history_text(h)
 local a={} for j,b in ipairs(h) do a[j]=pack(b) end return table.concat(a,';')
end
local function index_text(s)
 local lines={'version=2','level='..s.level,'unlocked='..s.unlocked,'legacyUnlocked='..s.legacyUnlocked,
  'generatedMax='..s.generatedMax,'size='..s.size,'mode='..s.mode}
 for i=1,N do
  lines[#lines+1]='B'..i..'='..pack(s.boards[i])
  lines[#lines+1]='W'..i..'='..(s.won[i] and '1' or '0')
  lines[#lines+1]='H'..i..'='..history_text(s.history[i])
 end
 return table.concat(lines,'\n')
end
local function record_text(p,a,h,w)
 return table.concat({'v1',p.n,p.seed,p.version,p.clues,p.answer,pack(a),w and '1' or '0',history_text(h)},'\n')
end
local function save()
 if S.level>N then
  Store.put(C.storage,'random',S.level,record_text(S.generated,S.boards[S.level],S.history[S.level],S.won[S.level]))
 end
 Store.write(C.storage,SAVE,index_text(S))
end
local function clear_generated(s)
 if s.generated then
  local i=s.generated.number;s.boards[i]=nil;s.history[i]=nil;s.won[i]=nil
  s.generated=nil
 end
end
local function load_record(i)
 local data=Store.get(C.storage,'random',i)
 assert(type(data)=='string','Missing generated puzzle record')
 local n,seed,version,clues,answer,marks,won,hist=data:match('^v1\n(%d+)\n(%d+)\n(%d+)\n([%d.]+)\n([01]+)\n([012]+)\n([01])\n(.*)$')
 n=integer(n,5,10);seed=integer(seed,1,2147483646);version=integer(version,1,1)
 assert(n and seed and version and #clues==n*n and #answer==n*n,'Invalid generated record')
 local supported=false for _,size in ipairs(SIZES) do if n==size then supported=true end end
 assert(supported,'Invalid generated size')
 for j=1,#clues do
  local ch=clues:sub(j,j)
  if P.id=='takuzu' then assert(ch=='.' or ch==answer:sub(j,j),'Invalid given')
  elseif P.id=='hitori' then assert(integer(ch,1,n),'Invalid Hitori clue')
  else assert(ch=='.' or integer(ch,0,9),'Invalid Mosaic clue') end
 end
 local p={number=i,n=n,seed=seed,version=version,clues=clues,answer=answer}
 -- Use a temporary descriptor for validation, never regenerate on restore.
 local prev=S.generated;S.generated=p
 local ok,a,h=pcall(function()
  local a=assert(decode(i,marks),'Invalid marks')
  local solution={}
  for j=1,#answer do local bit=tonumber(answer:sub(j,j));solution[j]=P.id=='takuzu' and bit+1 or (bit==1 and 1 or 2) end
  assert(valid(i,solution),'Invalid stored solution')
  assert(won=='0' or valid(i,a),'Invalid solved board')
  local h={}
  for v in hist:gmatch('[^;]+') do
   assert(#h<12,'Invalid undo count');h[#h+1]=assert(decode(i,v),'Invalid undo')
  end
  return a,h
 end)
 S.generated=prev
 if not ok then error(a,0) end
 return p,a,h,won=='1'
end
local function select_record(i,p,a,h,w)
 clear_generated(S)
 S.generated=p;S.boards[i]=a;S.history[i]=h;S.won[i]=w
 S.level=i
end
local function seed_for(number)
 nonce=nonce+1
 local ms=0
 if C.clock and type(C.clock.millis)=='function' then
  local ok,v=pcall(function()return C.clock:millis()end)
  if ok and type(v)=='number' then ms=math.floor(v)%1000000 end
 end
 return ((number%1000000)*193+ms*127+(nonce%1000000)*389)%2147483646+1
end
local function new_game(n,forced_seed,limit)
 if not S or S.generatedMax>=MAX then return false end
 local supported=false for _,size in ipairs(SIZES) do if size==n then supported=true end end
 if not supported then return false end
 local number=S.generatedMax+1
 if S.generated or S.level<=S.legacyUnlocked and S.generatedMax>N then
  if not pcall(save) then MSG='Save failed - retry New';return false end
 end
 local p
 for attempt=1,(forced_seed and 1 or 3) do
  p=Generator.generate(P.id,n,forced_seed or seed_for(number),limit)
  if p and (not S.generated or p.clues~=S.generated.clues) then break end
  p=nil
 end
 if not p then MSG='No puzzle - retry New';return false end
 p.number=number
 local a={}
 for j=1,n*n do local ch=p.clues:sub(j,j);a[j]=(P.id=='takuzu' and ch~='.') and tonumber(ch)+1 or 0 end
 -- The new board must be durable before the active pointer can change.
 -- If either write fails, keep the current session active and intact.
 local oldLevel,oldMax,oldUnlocked,oldSize=S.level,S.generatedMax,S.unlocked,S.size
 local ok=pcall(function()
  Store.put(C.storage,'random',number,record_text(p,a,{},false))
  S.level=number;S.generatedMax=number;S.unlocked=number;S.size=n
  Store.write(C.storage,SAVE,index_text(S))
 end)
 if not ok then
  S.level=oldLevel;S.generatedMax=oldMax;S.unlocked=oldUnlocked;S.size=oldSize
  MSG='Save failed - retry New';return false
 end
 select_record(number,p,a,{},false);HELP=false;MSG=nil
 return true
end
local function restore()
 local data,err=C.storage:read(SAVE)
 S=nil
 if data==nil then
  if err and err~='not_found' then error('Read failed: '..tostring(err)) end
  S=initial()
  if not new_game(SIZES[1]) then S=nil;error('No verified puzzle; reopen to retry') end
  return
 end
 local f={}
 for k,v in data:gmatch('([%w_]+)=([^\n]*)') do f[k]=v end
 assert(f.version=='1' or f.version=='2','Unsupported save version')
 local legacy=f.version=='1'
 local s=initial()
 local l=integer(f.level,1,legacy and N or MAX)
 local u=integer(f.unlocked,1,legacy and N or MAX)
 local m=integer(f.mode,1,2)
 assert(l and u and m and l<=u,'Invalid progress')
 s.level=l;s.unlocked=u;s.mode=m
 s.legacyUnlocked=legacy and u or assert(integer(f.legacyUnlocked,1,N),'Invalid legacy unlock')
 s.generatedMax=legacy and N or assert(integer(f.generatedMax,N,MAX),'Invalid generated maximum')
 assert((l<=N and l<=s.legacyUnlocked) or (l>N and l<=s.generatedMax),'Invalid current puzzle')
 assert(u==math.max(s.legacyUnlocked,s.generatedMax>N and s.generatedMax or 1),'Invalid unlock')
 if not legacy then
  s.size=assert(integer(f.size,5,10),'Invalid chosen size')
  local supported=false for _,size in ipairs(SIZES) do if s.size==size then supported=true end end
  assert(supported,'Unsupported size')
 end
 for i=1,N do
  s.boards[i]=assert(decode(i,f['B'..i]),'Invalid saved board')
  local w=f['W'..i];assert(w=='0' or w=='1','Invalid saved status')
  s.won[i]=w=='1'
  assert(not s.won[i] or (valid(i,s.boards[i]) and s.legacyUnlocked>=math.min(N,i+1)),'Invalid solved board')
  local h={};assert(f['H'..i]~=nil,'Missing undo history')
  for item in f['H'..i]:gmatch('[^;]+') do
   assert(#h<12,'Invalid undo count');h[#h+1]=assert(decode(i,item),'Invalid undo state')
  end
  s.history[i]=h
 end
 S=s
 if l>N then local p,a,h,w=load_record(l);select_record(l,p,a,h,w) end
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
  S.won[i]=true
  if i<=N then S.legacyUnlocked=math.max(S.legacyUnlocked,math.min(N,i+1));S.unlocked=math.max(S.unlocked,S.legacyUnlocked) end
  MSG='Solved'
 else MSG='Not solved yet' end
 save();return true
end
local function visit(i)
 if i<1 or i>S.unlocked or i==S.level then return false end
 if i<=N and (S.level>N or i>S.legacyUnlocked) then return false end
 if i>N and i>S.generatedMax then return false end
 local ok=pcall(save)
 if not ok then MSG='Save failed';return false end
 local p,a,h,w
 if i>N then
  local good
  good,p,a,h,w=pcall(load_record,i)
  if not good then MSG='Cannot load puzzle';return false end
 end
 local old=S.level;S.level=i
 ok=pcall(Store.write,C.storage,SAVE,index_text(S))
 if not ok then S.level=old;MSG='Save failed';return false end
 if i>N then select_record(i,p,a,h,w) else clear_generated(S);S.level=i end
 HELP=false;MSG=nil;return true
end
local function geometry() return UI.grid_geometry(level(S.level).n,94,572,468) end
local BOX={help={416,12,48,48},one={12,620,222,62},two={246,620,222,62},
 prev={12,704,106,70},undo={128,704,106,70},reset={244,704,106,70},check={360,704,108,70},
 back={76,704,328,70},new={76,630,328,60},size={12,558,456,56}}
local function hit(b,x,y) return x>=b[1] and y>=b[2] and x<b[1]+b[3] and y<b[2]+b[4] end
local function button(g,b,label,selected) UI.button(g,C,b[1],b[2],b[3],b[4],label,selected) end
local function text(g,x,y,s,role,align,w) UI.text(g,C,x,y,s,role,align,w) end
local function render(g)
 g:clear(0)
 text(g,80,14,P.name,'large',nil,326)
 button(g,BOX.help,HELP and 'X' or '?')
 if HELP then
  text(g,240,94,'How to play','large','center',440)
  UI.paragraph(g,C,22,152,436,350,P.help,'medium')
  if MSG then text(g,240,512,MSG,'small','center',440) end
  local w=math.floor(456/#SIZES)
  for k,n in ipairs(SIZES) do button(g,{12+(k-1)*w,558,w-4,56},n..'x'..n,S.size==n) end
  button(g,BOX.new,'New puzzle')
  button(g,BOX.back,'Back to grid');return
 end
 local i=S.level;local p=level(i);local n=p.n;local a=S.boards[i]
 text(g,16,66,i<=N and ('Legacy '..i..' / '..N) or ('Puzzle '..(i-N)..'  '..n..'x'..n),'small',nil,440)
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
 button(g,BOX.check,S.won[i] and 'Next' or 'Check')
end
local function tap(x,y)
 if hit(BOX.help,x,y) then HELP=not HELP;return true end
 if HELP then
  if hit(BOX.back,x,y) then HELP=false;return true end
  if hit(BOX.new,x,y) then new_game(S.size);return true end
  local w=math.floor(456/#SIZES)
  for k,n in ipairs(SIZES) do
   if hit({12+(k-1)*w,558,w-4,56},x,y) then S.size=n;save();return true end
  end
  return false
 end
 if hit(BOX.one,x,y) then return mode(1) end
 if hit(BOX.two,x,y) then return mode(2) end
 if hit(BOX.prev,x,y) then return visit(S.level-1) end
 if hit(BOX.undo,x,y) then return undo() end
 if hit(BOX.reset,x,y) then return reset() end
 if hit(BOX.check,x,y) then if S.won[S.level] then
   if S.level<N then return visit(S.level+1) end
   if S.level<S.generatedMax then return visit(S.level+1) end
   new_game(S.size);return true
  end;return check() end
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
 undo=undo,reset=reset,check=check,visit=visit,geometry=geometry,tap=tap,new=new_game,puzzle=function()return level(S.level)end}
end
do
 local guard=UI.guard{id=P.id,test=rawget(_G,'__TEST'),state=function()return S and 'level='..S.level end,
 load=on_load,draw=on_draw,input=on_input,leave=on_leave}
 on_load,on_draw,on_input,on_leave=guard.load,guard.draw,guard.input,guard.leave
end
