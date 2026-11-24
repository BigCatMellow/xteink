-- Crown Fields: original monochrome region-placement logic for XTOS Licorice.
local UI=require('ui')
local Theme=require('theme')
local Levels=require('levels')
local C,S,ERR,MSG=nil,nil,nil,nil
local HELP=false
local MODE=2
local EXCLUDE=false
local Random=require('random_session')
local Store=require('puzzle_store')
local SIZE=5

local OLD_TOTAL=12
local KEY_MS=-1000
local TOTAL=#Levels
local function board(level)
  if level>TOTAL and S and S.generated and S.generated.number==level then return S.b end
  local rows=Levels[level].rows
  local n=#rows
  local regions={}
  for y=1,n do
    assert(#rows[y]==n,'board dimension')
    for x=1,n do regions[#regions+1]=rows[y]:sub(x,x) end
  end
  return {n=n,regions=regions}
end
local function zeros(n)
  local a={}
  for i=1,n do a[i]=0 end
  return a
end
local function clone(t)
  local a={}
  for i,v in ipairs(t) do a[i]=v end
  return a
end
local function pack(t)
  local a={}
  for i,v in ipairs(t) do a[i]=tostring(v) end
  return table.concat(a)
end
local function unpack_mask(raw,n)
  if type(raw)~='string' or #raw~=n or raw:find('[^012]') then return nil end
  local a={}
  for i=1,#raw do a[i]=tonumber(raw:sub(i,i)) end
  return a
end
local function valid_board(b,marks)
  local row,col,reg={},{},{}
  local total=0
  local prev=-9
  for y=1,b.n do
    local placed=0
    for x=1,b.n do
      local i=(y-1)*b.n+x
      if marks[i]==2 then
        placed=placed+1;total=total+1
        col[x]=(col[x] or 0)+1
        reg[b.regions[i]]=(reg[b.regions[i]] or 0)+1
        if prev~=-9 and math.abs(prev-x)==1 then return false end
        row[y]=x
      end
    end
    if placed>1 then return false end
    if placed==1 then prev=row[y] else prev=-9 end
  end
  if total~=b.n then return false end
  for x=1,b.n do
    if col[x]~=1 or reg[string.char(64+x)]~=1 or not row[x] then return false end
  end
  return true
end
local function valid(n,marks)return valid_board(board(n),marks)end
local function stats()
  local b=board(S.level)
  local a=S.marks[S.level]
  local count=0
  for _,v in ipairs(a) do if v==2 then count=count+1 end end
  return count,b.n
end
local function generated_state(p,max)
  local b={n=p.n,regions={}}
  for i=1,#p.clues do b.regions[i]=p.clues:sub(i,i) end
  local answer={}
  for i=1,#p.answer do answer[i]=p.answer:sub(i,i)=='1' and 2 or 0 end
  assert(valid_board(b,answer),'Invalid stored solution')
  local marks=assert(unpack_mask(p.marks,p.n*p.n),'Invalid marks')
  assert(not p.won or valid_board(b,marks),'Invalid solved board')
  local h={}
  for _,raw in ipairs(p.history) do h[#h+1]=assert(unpack_mask(raw,p.n*p.n),'Invalid undo') end
  local i=p.number
  return {level=i,unlocked=max,b=b,generated=p,marks={[i]=marks},submitted={[i]=p.won},history={[i]=h}}
end
local function generated_record()
  local p=S.generated
  local record={}
  for k,v in pairs(p) do record[k]=v end
  record.marks=pack(S.marks[S.level]);record.history={}
  for i,h in ipairs(S.history[S.level]) do record.history[i]=pack(h) end
  record.mode=MODE;record.won=S.submitted[S.level];record.extra=EXCLUDE
  return record
end
local function save()
  if not C or not C.storage or not S then return end
  if S.generated then Random.save(C.storage,generated_record(),S.unlocked,SIZE);return end
  local lines={'version=1','total='..TOTAL,'level='..S.level,'unlocked='..S.unlocked,'mode='..MODE,'exclude='..(EXCLUDE and '1' or '0')}
  for i=1,TOTAL do
    lines[#lines+1]='B'..i..'='..pack(S.marks[i])
    lines[#lines+1]='S'..i..'='..(S.submitted[i] and '1' or '0')
    local history={}
    for j,m in ipairs(S.history[i]) do history[j]=pack(m) end
    lines[#lines+1]='H'..i..'='..table.concat(history,';')
  end
  Store.write(C.storage,'crown-fields.txt',table.concat(lines,'\n'))
end
local function start()
  S={level=1,unlocked=1,marks={},submitted={},history={}}
  for i=1,TOTAL do
    local n=board(i).n
    S.marks[i]=zeros(n*n)
    S.submitted[i]=false
    S.history[i]={}
  end
  HELP=false;MODE=2;EXCLUDE=false;MSG=nil
  save()
end
local function restore()
  if not C or not C.storage then return false end
  local ok,raw=pcall(function() return C.storage:read('crown-fields.txt') end)
  if not ok or type(raw)~='string' then return false end
  local fields={}
  for k,v in raw:gmatch('([%w_]+)=([^\n]*)') do fields[k]=v end
  local lvl,unlock=tonumber(fields.level),tonumber(fields.unlocked)
  if fields.version~='1' or not lvl or lvl~=math.floor(lvl) or lvl<1 or lvl>TOTAL
     or not unlock or unlock~=math.floor(unlock) or unlock<lvl or unlock>TOTAL then return false end
  local savedTotal=tonumber(fields.total) or OLD_TOTAL
  if savedTotal~=math.floor(savedTotal) or savedTotal<OLD_TOTAL or savedTotal>TOTAL or unlock>savedTotal then return false end
  local nextS={level=lvl,unlocked=unlock,marks={},submitted={},history={}}
  for i=1,TOTAL do
    local n=board(i).n
    if i>savedTotal then
      nextS.marks[i]=zeros(n*n);nextS.submitted[i]=false;nextS.history[i]={}
    else
    local mask=unpack_mask(fields['B'..i],n*n)
    if not mask then return false end
    local won=fields['S'..i]
    if won~='0' and won~='1' then return false end
    if won=='1' and (not valid(i,mask) or (i<savedTotal and unlock<i+1)) then return false end
    nextS.marks[i]=mask
    nextS.submitted[i]=won=='1'
    local history={}
    for item in (fields['H'..i] or ''):gmatch('[^;]+') do
      if #history>=12 then return false end
      local m=unpack_mask(item,n*n)
      if not m then return false end
      history[#history+1]=m
    end
    nextS.history[i]=history
    end
  end
  if nextS.submitted[savedTotal] and nextS.unlocked==savedTotal then
    nextS.unlocked=math.min(TOTAL,savedTotal+1)
  end
  S=nextS;HELP=false;MSG=nil;MODE=fields.mode=='1' and 1 or 2;EXCLUDE=fields.exclude=='1'
  return true
end
local function new_game(n,forced,limit)
  local pointer=Random.pointer(C.storage,TOTAL)
  local max=pointer and pointer.max or TOTAL
  local p=Random.generate(C,'crowns',n,max+1,S and S.generated and S.generated.clues,forced,limit)
  if not p then MSG='No puzzle - retry New';return false end
  p.mode=2;p.extra=EXCLUDE
  local nextS=generated_state(p,max+1)
  local ok=pcall(function()
    if S then save() end
    Random.save(C.storage,p,max+1,n)
  end)
  if not ok then MSG='Save failed - retry New';return false end
  S=nextS;SIZE=n;MODE=p.mode;HELP=false;MSG=nil;return true
end
local function load_generated()
  local ptr=Random.pointer(C.storage,TOTAL)
  if not ptr then return false end
  assert(Random.supported('crowns',ptr.size),'Invalid selected size')
  local p=Random.read(C.storage,'crowns',ptr.level)
  S=generated_state(p,ptr.max);SIZE=ptr.size;MODE=p.mode;EXCLUDE=p.extra;MSG=nil
  return true
end
local function visit_generated(n)
  if n<=TOTAL or n>S.unlocked or n==S.level then return false end
  local ok,nextS=pcall(function()
    save()
    local p=Random.read(C.storage,'crowns',n)
    local nextS=generated_state(p,S.unlocked)
    Random.select(C.storage,n,S.unlocked,SIZE)
    return nextS
  end)
  if not ok then MSG='Cannot open puzzle';return false end
  S=nextS;MODE=S.generated.mode;EXCLUDE=S.generated.extra;MSG=nil;HELP=false;return true
end
local function visit(n)
  if not S then return false end
  if S.generated then return visit_generated(n) end
  if n<1 or n>TOTAL or n>S.unlocked then return false end
  S.level=n;MSG=nil;HELP=false;save()
  return true
end
local function prev() return S and visit(S.level-1) or false end
local function next_level()
  if S and S.generated and S.level==S.unlocked and S.submitted[S.level] then new_game(SIZE);return true end
  return S and visit(S.level+1) or false
end
local function mode(v)
  if MODE==v then return false end
  MODE=v;save();return true
end
local function mark(i,v)
  if not S or S.submitted[S.level] then return false end
  local a=S.marks[S.level]
  if not a[i] then return false end
  local h=S.history[S.level]
  if #h>=12 then table.remove(h,1) end
  h[#h+1]=clone(a)
  v=v or MODE
  a[i]=a[i]==v and 0 or v
  MSG=nil;save();return true
end
local function undo()
  if not S or S.submitted[S.level] then return false end
  local h=S.history[S.level]
  if #h==0 then return false end
  S.marks[S.level]=table.remove(h);MSG='Last mark restored';save();return true
end
local function restart()
  if not S then return false end
  local n=board(S.level).n
  S.marks[S.level]=zeros(n*n)
  S.history[S.level]={}
  S.submitted[S.level]=false
  MSG=nil;save();return true
end
local function check()
  if not S or S.submitted[S.level] then return false end
  if valid(S.level,S.marks[S.level]) then
    S.submitted[S.level]=true
    if not S.generated then S.unlocked=math.min(TOTAL,math.max(S.unlocked,S.level+1)) end
    MSG='Solved'
  else
    MSG='Check crowns and regions'
  end
  save();return true
end
local function geometry()
  local n=board(S.level).n
  return UI.grid_geometry(n,94,572,468)
end
local function text(g,x,y,s,style,align,w) UI.text(g,C,x,y,s,style,align,w) end
local function button(g,x,y,w,h,s) UI.button(g,C,x,y,w,h,s) end
local function draw_help(g)
  text(g,240,94,'How to play','large','center',436)
  UI.paragraph(g,C,22,150,436,250,'Place one crown in each row, column and region. Crowns cannot touch, even diagonally. Choose Crown or X, then tap. Tap the same mark again to clear. Check submits; Undo restores.','medium')
  if MSG then text(g,240,406,MSG,'small','center',440) end
  UI.button(g,C,22,446,436,56,'Auto exclusions: '..(EXCLUDE and 'On' or 'Off'),EXCLUDE)
  local sizes=Random.sizes.crowns;local w=math.floor(456/#sizes)
  for k,n in ipairs(sizes) do UI.button(g,C,12+(k-1)*w,530,w-3,62,n..'x'..n,SIZE==n,{font='small'}) end
  button(g,76,620,328,62,'New puzzle')
  button(g,76,704,328,70,'Back to grid')
end
local function exclusions(b,marks)
  local blocked,conflict={},{}
  for i,v in ipairs(marks) do
    if v==2 then
      local x,y=(i-1)%b.n,math.floor((i-1)/b.n)
      for j=1,#marks do if j~=i then
        local a,z=(j-1)%b.n,math.floor((j-1)/b.n)
        if x==a or y==z or b.regions[i]==b.regions[j] or (math.abs(x-a)==1 and math.abs(y-z)==1) then
          blocked[j]=true
          if marks[j]==2 then conflict[i]=true;conflict[j]=true end
        end
      end end
    end
  end
  return blocked,conflict
end
local function render(g)
  g:clear(0)
  text(g,80,14,'Crown Fields','large',nil,326)
  button(g,416,12,48,48,HELP and 'X' or '?')
  if HELP then draw_help(g);return end
  text(g,16,66,S.generated and ('Puzzle '..(S.level-TOTAL)..'  '..S.b.n..'x'..S.b.n) or ('Legacy '..S.level..' / '..TOTAL),'small',nil,440)
  local b=board(S.level)
  local bx,by,cell=geometry()
  UI.region(bx,by,b.n*cell,b.n*cell)
  UI.grid(g,bx,by,b.n,b.n,cell)
  local marks=S.marks[S.level]
  local blocked,conflict=exclusions(b,marks)
  local clashes=0
  for y=1,b.n do
    for x=1,b.n do
      local i=(y-1)*b.n+x
      local px,py=bx+(x-1)*cell,by+(y-1)*cell
      local code=b.regions[i]
      local v=marks[i]
      local cx,cy=px+cell/2,py+cell/2
      if v==1 then
        UI.stroke(g,cx-12,cy-11,cx+12,cy+11,3)
        UI.stroke(g,cx-12,cy+11,cx+12,cy-11,3)
      elseif v==2 then
        UI.stroke(g,cx-17,cy-5,cx-12,cy+12,4)
        UI.stroke(g,cx-12,cy+12,cx+12,cy+12,4)
        UI.stroke(g,cx+12,cy+12,cx+17,cy-5,4)
        UI.stroke(g,cx-17,cy-5,cx-6,cy+2,4)
        UI.stroke(g,cx-6,cy+2,cx,cy-14,4)
        UI.stroke(g,cx,cy-14,cx+6,cy+2,4)
        UI.stroke(g,cx+6,cy+2,cx+17,cy-5,4)
        if conflict[i] then
          clashes=clashes+1
          g:rect(px+5,py+5,cell-10,cell-10,{line_width=2,radius=3})
        end
      elseif EXCLUDE and blocked[i] then
        g:circle(cx,cy,3,{fill=true})
      end
      if x<b.n and code~=b.regions[i+1] then UI.stroke(g,px+cell,py,px+cell,py+cell,5) end
      if y<b.n and code~=b.regions[i+b.n] then UI.stroke(g,px,py+cell,px+cell,py+cell,5) end
    end
  end
  local crowns,target=stats()
  local status=MSG or (S.submitted[S.level] and 'Solved' or ('Crowns '..crowns..' / '..target..(clashes>0 and ' - conflict' or '')))
  text(g,240,580,status,'medium','center',440)
  UI.button(g,C,12,620,222,62,'Crown',MODE==2)
  UI.button(g,C,246,620,222,62,'X',MODE==1)
  button(g,12,704,106,70,'Prev')
  button(g,128,704,106,70,'Undo')
  button(g,244,704,106,70,'Reset')
  button(g,360,704,108,70,S.submitted[S.level] and 'Next' or 'Check')
end
local function hit(x,y,bx,by,w,h)
  return x>=bx and x<bx+w and y>=by and y<by+h
end
local function tap(x,y)
  if hit(x,y,416,12,48,48) then HELP=not HELP;return true end
  if HELP then
    if hit(x,y,76,704,328,70) then HELP=false;return true end
    if hit(x,y,22,446,436,56) then EXCLUDE=not EXCLUDE;save();return true end
    if hit(x,y,76,620,328,62) then new_game(SIZE);return true end
    local sizes=Random.sizes.crowns;local w=math.floor(456/#sizes)
    for k,n in ipairs(sizes) do
      if hit(x,y,12+(k-1)*w,530,w-3,62) then SIZE=n;save();return true end
    end
    return false
  end
  if hit(x,y,12,620,222,62) then return mode(2) end
  if hit(x,y,246,620,222,62) then return mode(1) end
  if hit(x,y,12,704,106,70) then return prev() end
  if hit(x,y,128,704,106,70) then return undo() end
  if hit(x,y,244,704,106,70) then return restart() end
  if hit(x,y,360,704,108,70) then
    if S.submitted[S.level] then
      if not S.generated and S.level==TOTAL then new_game(SIZE);return true end
      return next_level()
    end
    return check()
  end
  local b=board(S.level)
  local bx,by,cell=geometry()
  if hit(x,y,bx,by,cell*b.n,cell*b.n) then
    return mark(math.floor((y-by)/cell)*b.n+math.floor((x-bx)/cell)+1)
  end
  return false
end
local function invalidate() if C then pcall(function() C:invalidate() end) end end
function on_load(ctx) Theme.release();C=ctx or context;ERR=nil;S=nil;HELP=false;MODE=2;EXCLUDE=false;SIZE=5
  local ok,e=pcall(function()
    if load_generated() then return end
    local raw,err=C.storage:read('crown-fields.txt')
    if raw==nil and err and err~='not_found' then error(err) end
    if raw then assert(restore(),'Invalid legacy save; data retained')
    else assert(new_game(SIZE),'No verified puzzle; reopen to retry') end
  end)
  if not ok then ERR=tostring(e) end
end
function on_draw(ctx,g) if ctx then C=ctx end
  if not g then return end
  if ERR then UI.error(g,C,'CROWN FIELDS',ERR);return end
  local ok,e=pcall(function() Theme.draw(C,g,render) end)
  if not ok then ERR=tostring(e);UI.error(g,C,'CROWN FIELDS',ERR) end
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
      changed=e.key=='up' and prev() or next_level()
    end
  end)
  if not ok then ERR=tostring(err);changed=true end
  if changed then invalidate() end
  return changed
end
function on_leave() Theme.release();if S then save() end end
if rawget(_G,'__TEST') then
 __TEST.api={
   levels=Levels,board=board,valid=valid,state=function()return S end,
   mark=mark,mode=mode,undo=undo,check=check,restart=restart,visit=visit,
   next=next_level,prev=prev,geometry=geometry,tap=tap,new=new_game,start=start
 }
end

-- Crash reports: errors are saved to crash.txt and shown on a recovery screen.
do
  local guarded=UI.guard{id='crownfields',test=rawget(_G,'__TEST'),
    state=function() return S and ('level='..tostring(S.level)..' unlocked='..tostring(S.unlocked)) end,
    load=on_load,draw=on_draw,input=on_input,leave=on_leave}
  on_load,on_draw,on_input,on_leave=guarded.load,guarded.draw,guarded.input,guarded.leave
end
