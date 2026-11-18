-- Quiet Mines: procedurally generated no-guess Minesweeper for X4 Pro.
-- Legacy fields remain only for compatibility with saved games.
local UI=require('ui')
local Theme=require('theme')
local LEVELS=require('legacy_levels')
local Generator=require('generator')
local Store=require('puzzle_store')
local TOTAL=#LEVELS
local MAX=999999999
local C,S,ERR,MSG=nil,nil,nil,nil
local HELP=false
local HINTED=0
local KEY_MS=-1000
local function board(level)
  if level>TOTAL then
    if S and S.generated and S.generated.level==level then return S.generated.board end
    error('Generated field was not loaded')
  end
  local p=LEVELS[level]
  local t={}
  for _,i in ipairs(p.mines) do t[i]=true end
  return {n=p.n,mines=t,total=#p.mines}
end
local function blank(n)
  local r={}
  for i=1,n do r[i]=0 end
  return r
end
local function copy(a)
  local r={}
  for i,v in ipairs(a) do r[i]=v end
  return r
end
local function encode(a)
  local s={}
  for i,v in ipairs(a) do s[i]=tostring(v) end
  return table.concat(s)
end
local function decode(s,n)
  if type(s)~='string' or #s~=n or s:find('[^012]') then return nil end
  local a={}
  for i=1,n do a[i]=tonumber(s:sub(i,i)) end
  return a
end
local function neighbors(n,i)
  local x=(i-1)%n+1
  local y=math.floor((i-1)/n)+1
  local list={}
  for dy=-1,1 do
    for dx=-1,1 do
      if dx~=0 or dy~=0 then
        local xx,yy=x+dx,y+dy
        if xx>=1 and yy>=1 and xx<=n and yy<=n then list[#list+1]=(yy-1)*n+xx end
      end
    end
  end
  return list
end
local function nearby(b,i)
  local k=0
  for _,j in ipairs(neighbors(b.n,i)) do if b.mines[j] then k=k+1 end end
  return k
end
local function solved(level,marks)
  local b=board(level)
  for i=1,b.n*b.n do
    if not b.mines[i] and marks[i]~=2 then return false end
  end
  return true
end
-- Keep original 24 maps unchanged. New boards have explicit mine layouts
-- stored in a 64-shard archive, so they survive generator updates.
local function seed_for(level,salt)
  local ms=0
  if C and C.clock and type(C.clock.millis)=='function' then
    local ok,v=pcall(function() return C.clock:millis() end)
    if ok and type(v)=='number' then ms=math.floor(v) end
  end
  return (level*48271+(ms%2147483646)*131071+salt*389)%2147483646+1
end
local function new_field(level,difficulty)
  for salt=0,7 do
    local seed=seed_for(level,salt)
    local p=Generator.generate(seed,difficulty)
    if p then
      local mines={}
      for _,i in ipairs(p.mines) do mines[i]=true end
      S.generated={level=level,difficulty=difficulty,seed=seed,
        positions=p.mines,board={n=p.n,mines=mines,total=#p.mines}}
      S.marks[level]=blank(p.n*p.n)
      S.failed[level]=false;S.history[level]={}
      return true
    end
  end
  return false
end
local function load_field(level)
  if not C or not C.storage then return false end
  local data=Store.get(C.storage,'mines',level)
  if type(data)~='string' then return false end
  local diff,seed,n,raw,marks,failed,hist=
    data:match('^v2\n(%d+)\n(%d+)\n(%d+)\n([%d,]+)\n([012]+)\n([01])\n(.*)$')
  diff,seed,n=tonumber(diff),tonumber(seed),tonumber(n)
  local cfg=diff and Generator.settings[diff]
  if not cfg or n~=cfg.n or not seed or seed<1 or seed>2147483646 then return false end
  local positions,mines={},{}
  for part in raw:gmatch('%d+') do
    local i=tonumber(part)
    if i<1 or i>n*n or mines[i] then return false end
    positions[#positions+1]=i;mines[i]=true
  end
  if #positions~=cfg.mines or mines[1] or mines[2] or mines[n+1] or mines[n+2] then return false end
  local decoded=decode(marks,n*n)
  if not decoded then return false end
  for i,v in ipairs(decoded) do
    if v==2 and mines[i] and failed~='1' then return false end
  end
  local past={}
  for part in (hist or ''):gmatch('[^;]+') do
    if #past>=10 then return false end
    local previous=decode(part,n*n)
    if not previous then return false end
    past[#past+1]=previous
  end
  S.generated={level=level,difficulty=diff,seed=seed,
    positions=positions,board={n=n,mines=mines,total=#positions}}
  S.marks[level]=decoded;S.failed[level]=failed=='1';S.history[level]=past
  return true
end
local function save()
  if not S or not C or not C.storage then return true end
  local lines={'version=1','level='..S.level,'unlocked='..S.unlocked,
    'mode='..S.mode,'difficulty='..(S.difficulty or 2)}
  for i=1,TOTAL do
    lines[#lines+1]='B'..i..'='..encode(S.marks[i])
    lines[#lines+1]='F'..i..'='..(S.failed[i] and '1' or '0')
    local past={}
    for j,m in ipairs(S.history[i]) do past[j]=encode(m) end
    lines[#lines+1]='H'..i..'='..table.concat(past,';')
  end
  local ok=pcall(function()
    if S.level>TOTAL then
      local g=S.generated
      assert(g and g.level==S.level)
      local past={}
      for j,m in ipairs(S.history[S.level]) do past[j]=encode(m) end
      Store.put(C.storage,'mines',S.level,
        table.concat({'v2',g.difficulty,g.seed,g.board.n,
          table.concat(g.positions,','),encode(S.marks[S.level]),
          S.failed[S.level] and '1' or '0',table.concat(past,';')},'\n'))
    end
    Store.write(C.storage,'quiet-mines.txt',table.concat(lines,'\n'))
  end)
  if not ok then MSG='Save failed - keep this field open' end
  return ok
end
local function start()
  S={level=TOTAL+1,unlocked=TOTAL+1,mode='OPEN',difficulty=2,
    marks={},failed={},history={}}
  for i=1,TOTAL do
    S.marks[i]=blank(board(i).n^2)
    S.failed[i]=false;S.history[i]={}
  end
  assert(new_field(S.level,S.difficulty),'Could not generate a no-guess field')
  HELP=false;HINTED=0;MSG='New random field: open S'
  save()
end
local function restore()
  if not C or not C.storage then return false end
  local ok,data=pcall(function() return C.storage:read('quiet-mines.txt') end)
  if not ok or type(data)~='string' then return false end
  local f={}
  for k,v in data:gmatch('([%w_]+)=([^\n]*)') do f[k]=v end
  local lvl,u=tonumber(f.level),tonumber(f.unlocked)
  if f.version~='1' or (f.mode~='OPEN' and f.mode~='FLAG') or
     not lvl or lvl~=math.floor(lvl) or lvl<1 or lvl>MAX or
     not u or u~=math.floor(u) or u<lvl or u>MAX then return false end
  local difficulty=tonumber(f.difficulty or '2')
  if not difficulty or not Generator.settings[difficulty] then return false end
  local r={level=lvl,unlocked=u,mode=f.mode,difficulty=difficulty,
    marks={},failed={},history={}}
  -- Version 1 saves had twelve levels. Append new fields without resetting
  -- completed and unfinished boards, flags, mode, or per-field undo.
  local legacy=f.B13==nil
  for i=1,TOTAL do
    local b=board(i)
    local absent=i>12 and legacy and f['B'..i]==nil and
      f['F'..i]==nil and f['H'..i]==nil
    local t=absent and blank(b.n*b.n) or decode(f['B'..i],b.n*b.n)
    local failed=absent and '0' or f['F'..i]
    if not t or (failed~='0' and failed~='1') then return false end
    for j,v in ipairs(t) do if v==2 and b.mines[j] and failed=='0' then return false end end
    local hist={}
    for v in (f['H'..i] or ''):gmatch('[^;]+') do
      if #hist>=10 then return false end
      local old=decode(v,b.n*b.n)
      if not old then return false end
      hist[#hist+1]=old
    end
    if solved(i,t) and i<TOTAL and u<i+1 then
      if legacy and i==12 and u==12 then
        u=13;r.unlocked=u
      else return false end
    end
    r.marks[i]=t;r.failed[i]=failed=='1';r.history[i]=hist
  end
  S=r
  if lvl>TOTAL and not load_field(lvl) then
    error('Cannot load saved generated field; progress has not been overwritten')
  end
  HELP=false;HINTED=0;MSG=nil;return true
end
local function visit(n)
  if not S or n<1 or n>MAX or n>S.unlocked or n~=math.floor(n) then return false end
  if not save() then return true end
  local old=S.level
  if n>TOTAL and n~=old and not load_field(n) then
    MSG='Could not load saved field';return true
  end
  if old>TOTAL and n~=old then
    S.marks[old]=nil;S.failed[old]=nil;S.history[old]=nil
  end
  S.level=n;MSG=nil;HELP=false;HINTED=0
  save();return true
end
local function next_level()return S and visit(S.level+1) or false end
local function prev()
  -- Generated games never lead back to the old fixed-field campaign.
  if not S or S.level==TOTAL+1 then return false end
  return visit(S.level-1)
end
local function new_game()
  if not S or S.unlocked>=MAX then return false end
  if not save() then return true end
  local old=S.level
  local number=math.max(TOTAL,S.unlocked)+1
  if not new_field(number,S.difficulty) then
    MSG='No verified field found - retry New';return true
  end
  if old>TOTAL then
    S.marks[old]=nil;S.failed[old]=nil;S.history[old]=nil
  end
  S.level=number;S.unlocked=number;S.mode='OPEN'
  HELP=false;HINTED=0;MSG='New random field: open S'
  save();return true
end
local function cycle_difficulty()
  S.difficulty=S.difficulty%3+1
  MSG=({'Easy','Normal','Hard'})[S.difficulty]..' for next New'
  save();return true
end
local function record()
  local hist=S.history[S.level]
  if #hist>=10 then table.remove(hist,1) end
  hist[#hist+1]=copy(S.marks[S.level])
end
local function marked(level)
  local count=0
  for _,v in ipairs(S.marks[level]) do if v==1 then count=count+1 end end
  return count
end
local function revealed(level)
  local count=0
  for _,v in ipairs(S.marks[level]) do if v==2 then count=count+1 end end
  return count
end
-- Reason only from visible numbered cells and the player's flag assumptions.
-- Direct 0/all rules come first; subset differences handle harder fields.
-- No unrevealed mine positions are consulted.
local function infer_hint(level,marks)
  local b=board(level)
  local constraints={}
  for i=1,b.n*b.n do
    if marks[i]==2 then
      local hidden,need={},nearby(b,i)
      for _,j in ipairs(neighbors(b.n,i)) do
        if marks[j]==1 then need=need-1
        elseif marks[j]==0 then hidden[#hidden+1]=j end
      end
      if need<0 or need>#hidden then return nil,'Check your flags' end
      if #hidden>0 then
        local lookup={}
        for _,j in ipairs(hidden) do lookup[j]=true end
        constraints[#constraints+1]={hidden=hidden,need=need,lookup=lookup}
      end
    end
  end
  for _,c in ipairs(constraints) do
    if c.need==0 then return {index=c.hidden[1],kind='OPEN',rule='number'} end
    if c.need==#c.hidden then return {index=c.hidden[1],kind='FLAG',rule='number'} end
  end
  for _,a in ipairs(constraints) do
    for _,bigger in ipairs(constraints) do
      if #a.hidden<#bigger.hidden then
        local subset=true
        for _,j in ipairs(a.hidden) do
          if not bigger.lookup[j] then subset=false;break end
        end
        if subset then
          local extra={}
          for _,j in ipairs(bigger.hidden) do
            if not a.lookup[j] then extra[#extra+1]=j end
          end
          local difference=bigger.need-a.need
          if difference==0 then
            return {index=extra[1],kind='OPEN',rule='overlap'}
          elseif difference==#extra then
            return {index=extra[1],kind='FLAG',rule='overlap'}
          end
        end
      end
    end
  end
  return nil,'No certain move; check flags'
end
local function hint()
  if not S or S.failed[S.level] or solved(S.level,S.marks[S.level]) then return false end
  if revealed(S.level)==0 then MSG='Open S first';return true end
  local found,reason=infer_hint(S.level,S.marks[S.level])
  if not found then HINTED=0;MSG=reason;return true end
  HINTED=found.index
  local n=board(S.level).n
  local row=math.floor((HINTED-1)/n)+1
  local col=(HINTED-1)%n+1
  MSG='Hint: '..found.kind..' R'..row..' C'..col..' ('..found.rule..')'
  return true
end
local function apply(i)
  if not S then return false end
  local n=S.level
  local b=board(n)
  local tiles=S.marks[n]
  if i<1 or i>#tiles or S.failed[n] or solved(n,tiles) or tiles[i]==2 then return false end
  HINTED=0
  if S.mode=='FLAG' then
    record()
    tiles[i]=tiles[i]==1 and 0 or 1
    MSG=tiles[i]==1 and 'Flag placed' or 'Flag removed'
    save();return true
  end
  if tiles[i]==1 then MSG='Switch to FLAG to clear this marker';return true end
  if revealed(n)==0 and i~=1 then MSG='Open the marked S first';return true end
  record()
  if b.mines[i] then
    S.failed[n]=true;MSG='MINE! Reset this field'
    save();return true
  end
  local queue={i}
  local at=1
  while at<=#queue do
    local p=queue[at];at=at+1
    if tiles[p]==0 and not b.mines[p] then
      tiles[p]=2
      if nearby(b,p)==0 then
        for _,j in ipairs(neighbors(b.n,p)) do
          if tiles[j]==0 and not b.mines[j] then queue[#queue+1]=j end
        end
      end
    end
  end
  MSG='Area revealed'
  if solved(n,tiles) then
    -- Generated fields unlock only after New archives their layout.
    if n<TOTAL then S.unlocked=math.min(MAX,math.max(S.unlocked,n+1)) end
    MSG='FIELD CLEARED!'
  end
  save();return true
end
local function mode()
  if not S then return false end
  S.mode=S.mode=='OPEN' and 'FLAG' or 'OPEN'
  HINTED=0
  MSG='Mode: '..S.mode;save();return true
end
local function undo()
  if not S or S.failed[S.level] or solved(S.level,S.marks[S.level]) then return false end
  local hist=S.history[S.level]
  if #hist==0 then return false end
  S.marks[S.level]=table.remove(hist);HINTED=0;MSG='Last action restored'
  save();return true
end
local function restart()
  if not S then return false end
  S.marks[S.level]=blank(board(S.level).n^2)
  S.history[S.level]={};S.failed[S.level]=false
  S.mode='OPEN';HINTED=0
  MSG='Open S to begin';save();return true
end
local function geometry()
  local n=board(S.level).n
  return UI.grid_geometry(n,118,586,460)
end
local function text(g,x,y,s,style,align,w) UI.text(g,C,x,y,s,style,align,w) end
local function button(g,x,y,w,h,s,marked)
  -- Two restrained offset strokes create a tactile shadow, not a second box.
  g:rect(x+3,y+h+1,w-4,1,{fill=true,radius=0})
  g:rect(x+w+1,y+3,1,h-4,{fill=true,radius=0})
  UI.button(g,C,x,y,w,h,s,false,{line_width=marked and 5 or 3})
end
local function draw_help(g)
  text(g,240,163,'QUIET MINES','large','center',425)
  UI.paragraph(g,C,28,230,424,110,
    'Open safe squares. Numbers tell how many mines touch that square, including diagonals.', 'medium')
  UI.paragraph(g,C,28,358,424,111,
    'Open S first on a random field. Every accepted field has a no-guess route. FLAG marks mines.', 'medium')
  UI.paragraph(g,C,28,488,424,115,
    'Opening a mine loses that field. RESET restarts. All numbers appear at once; no animation.', 'medium')
  button(g,75,706,330,69,'BACK TO FIELD')
end
local function render(g)
  g:clear(0)
  text(g,23,15,'QUIET MINES','large',nil,320)
  button(g,416,12,48,48,HELP and 'X' or '?')
  button(g,308,12,101,46,'New')
  local b=board(S.level)
  text(g,23,76,(S.level<=TOTAL and 'SAVED '..S.level
    or 'FIELD '..(S.level-TOTAL))..'   MINES '..b.total,'medium',nil,320)
  button(g,348,76,116,40,({'Easy','Normal','Hard'})[S.difficulty])
  if HELP then draw_help(g);return end
  local bx,by,cell=geometry()
  UI.region(bx,by,cell*b.n,cell*b.n)
  -- Equal-sized Mines tiles have no 5x5 subregions: one clean shared grid.
  UI.grid(g,bx,by,b.n,b.n,cell,{minor=2,frame=4})
  local tiles=S.marks[S.level]
  for y=1,b.n do
    for x=1,b.n do
      local i=(y-1)*b.n+x
      local px,py=bx+(x-1)*cell,by+(y-1)*cell
      local v=tiles[i]
      if v==0 then
        -- One-pixel right/bottom bevel distinguishes unopened tiles from
        -- revealed blanks without the previous distracting inner squares.
        g:rect(px+3,py+cell-4,cell-6,1,{fill=true,radius=0})
        g:rect(px+cell-4,py+3,1,cell-6,{fill=true,radius=0})
        if i==1 and revealed(S.level)==0 then
          text(g,px+cell/2,py+math.floor((cell-20)/2),'S','small','center',cell-12)
        end
      elseif v==1 then
        local cx=px+cell/2
        g:line(cx-11,py+cell-13,cx-11,py+13,{line_width=3})
        g:line(cx-11,py+13,cx+12,py+21,{line_width=2})
        g:line(cx+12,py+21,cx-11,py+30,{line_width=2})
      elseif b.mines[i] then
        text(g,px+cell/2,py+math.floor((cell-24)/2),'*','large','center',cell-8)
      else
        local count=nearby(b,i)
        if count>0 then text(g,px+cell/2,py+math.floor((cell-24)/2),count,'medium','center',cell-8) end
      end
      if HINTED==i and not S.failed[S.level] then
        g:rect(px+6,py+6,cell-12,cell-12,{line_width=3,radius=3})
      end
      if S.failed[S.level] and b.mines[i] and v==0 then
        g:circle(px+cell/2,py+cell/2,10,{line_width=2})
        g:line(px+cell/2-8,py+cell/2-8,px+cell/2+8,py+cell/2+8)
      end
    end
  end
  local safe=b.n*b.n-b.total
  text(g,24,600,'SAFE '..revealed(S.level)..' / '..safe,'medium',nil,200)
  text(g,260,600,'FLAGS '..marked(S.level)..' / '..b.total,'medium',nil,210)
  text(g,240,650,MSG or (S.failed[S.level] and 'Mine found'
    or solved(S.level,tiles) and 'Field cleared'
    or S.mode=='FLAG' and 'Flag mode: mark mines'
    or 'Open mode: reveal safe squares'),'small','center',440)
  button(g,8,710,85,66,S.level>1 and S.level~=TOTAL+1 and 'Prev' or 'Start')
  button(g,102,710,85,66,S.mode=='FLAG' and 'Open' or 'Flag',S.mode=='FLAG')
  button(g,196,710,85,66,'Hint',HINTED>0)
  button(g,290,710,85,66,'Undo')
  button(g,384,710,88,66,'Reset')
end
local function hit(x,y,bx,by,w,h)return x>=bx and x<bx+w and y>=by and y<by+h end
local function tap(x,y)
  if hit(x,y,416,12,48,48) then HELP=not HELP;return true end
  if HELP then
    if hit(x,y,75,706,330,69) then HELP=false;return true end
    return false
  end
  if hit(x,y,308,12,101,46) then return new_game() end
  if hit(x,y,348,76,116,40) then return cycle_difficulty() end
  if hit(x,y,8,710,85,66) then return prev() end
  if hit(x,y,102,710,85,66) then return mode() end
  if hit(x,y,196,710,85,66) then return hint() end
  if hit(x,y,290,710,85,66) then return undo() end
  if hit(x,y,384,710,88,66) then return restart() end
  local b=board(S.level)
  local bx,by,cell=geometry()
  if hit(x,y,bx,by,cell*b.n,cell*b.n) then
    return apply(math.floor((y-by)/cell)*b.n+math.floor((x-bx)/cell)+1)
  end
  return false
end
local function redraw() if C then pcall(function() C:invalidate() end) end end
function on_load(ctx) Theme.release();C=ctx or context;ERR=nil;HINTED=0
  local ok,e=pcall(function() if not restore() then start() end end)
  if not ok then ERR=tostring(e) end
end
function on_draw(ctx,g) if ctx then C=ctx end
  if not g then return end
  if ERR then UI.error(g,C,'QUIET MINES',ERR);return end
  local ok,e=pcall(function() Theme.draw(C,g,render) end)
  if not ok then ERR=tostring(e);UI.error(g,C,'QUIET MINES',ERR) end
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
  if changed then redraw() end
  return changed
end
function on_leave() Theme.release();if S then save() end end
if rawget(_G,'__TEST') then __TEST.api={
 legacy_levels=LEVELS,board=board,neighbors=neighbors,nearby=nearby,
 state=function()return S end,apply=apply,mode=mode,undo=undo,
 restart=restart,visit=visit,next=next_level,prev=prev,
 new=new_game,difficulty=cycle_difficulty,
 solved=solved,geometry=geometry,tap=tap,hint=hint,infer_hint=infer_hint,
 hinted=function()return HINTED end
} end
