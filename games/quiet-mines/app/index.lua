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
  MSG='Hint: '..found.kind:lower()..' row '..row..', column '..col
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
    MSG=nil
    save();return true
  end
  if tiles[i]==1 then MSG='Switch to Flag to clear this flag';return true end
  if revealed(n)==0 and i~=1 then MSG='Open the marked S first';return true end
  record()
  if b.mines[i] then
    S.failed[n]=true;MSG='Mine! Reset this field'
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
  MSG=nil
  if solved(n,tiles) then
    -- Generated fields unlock only after New archives their layout.
    if n<TOTAL then S.unlocked=math.min(MAX,math.max(S.unlocked,n+1)) end
    MSG='Field cleared!'
  end
  save();return true
end
local function mode()
  if not S then return false end
  S.mode=S.mode=='OPEN' and 'FLAG' or 'OPEN'
  HINTED=0
  MSG=nil;save();return true
end
local function undo()
  if not S or S.failed[S.level] or solved(S.level,S.marks[S.level]) then return false end
  local hist=S.history[S.level]
  if #hist==0 then return false end
  S.marks[S.level]=table.remove(hist);HINTED=0;MSG=nil
  save();return true
end
local function restart()
  if not S then return false end
  S.marks[S.level]=blank(board(S.level).n^2)
  S.history[S.level]={};S.failed[S.level]=false
  S.mode='OPEN';HINTED=0
  MSG='Open S to begin';save();return true
end
-- One geometry contract for drawing and touch. The field takes the full
-- 468px width; spare height goes to the status lines and larger keys.
local BUTTONS={new={320,20,96,48},help={424,20,50,48},
  prev={6,668,88,82},flag={101,668,88,82},hint={196,668,88,82},
  undo={291,668,88,82},reset={386,668,88,82},
  difficulty={75,610,330,54},back={75,684,330,62}}
local function geometry()
  local n=board(S.level).n
  return UI.grid_geometry(n,114,582,468)
end
local function text(g,x,y,s,style,align,w) UI.text(g,C,x,y,s,style,align,w) end
local function button(g,key,s,marked)
  local b=BUTTONS[key];UI.button(g,C,b[1],b[2],b[3],b[4],s,marked)
end
local DIFFICULTY={'Easy','Normal','Hard'}
local function draw_help(g)
  text(g,240,110,'How to play','large','center',425)
  UI.paragraph(g,C,28,160,424,126,
    'Open safe squares. Numbers tell how many mines touch that square, including diagonals.', 'body')
  UI.paragraph(g,C,28,298,424,126,
    'Open S first on a random field. Every accepted field has a no-guess route. Flag marks mines.', 'body')
  UI.paragraph(g,C,28,436,424,96,
    'Opening a mine loses that field. Reset restarts it. Hint finds a certain move.', 'body')
  text(g,240,552,'Field '..S.level..'  -  New uses this level','small','center',424)
  button(g,'difficulty','Difficulty: '..DIFFICULTY[S.difficulty])
  button(g,'back','Back to field')
end
-- Small monochrome symbols drawn from rectangles and strokes only.
local function mine_icon(g,cx,cy,r)
  for _,d in ipairs({{1,0},{0,1},{1,1},{1,-1}}) do
    local k=d[1]~=0 and d[2]~=0 and math.floor(r*.8) or r+3
    g:line(cx-d[1]*k,cy-d[2]*k,cx+d[1]*k,cy+d[2]*k,{line_width=1})
  end
  g:rect(cx-r+2,cy-r+2,2*r-3,2*r-3,{fill=true,radius=r-2})
end
local function flag_icon(g,cx,cy)
  UI.stroke(g,cx-8,cy-13,cx-8,cy+12,3)
  UI.stroke(g,cx-13,cy+13,cx-1,cy+13,2)
  for k=0,15 do
    local h=math.max(1,math.floor((16-k)*15/16))
    g:rect(cx-7+k,cy-13+math.floor((15-h)/2),1,h,{fill=true,radius=0})
  end
end
local function render(g)
  g:clear(0)
  text(g,6,22,'Minesweeper','title',nil,300)
  button(g,'new','New')
  button(g,'help',HELP and 'X' or '?')
  local b=board(S.level)
  if HELP then draw_help(g);return end
  local tiles=S.marks[S.level]
  local safe=b.n*b.n-b.total
  mine_icon(g,22,90,13)
  text(g,46,75,'Mines '..(b.total-marked(S.level)),'large',nil,180)
  g:rect(244,77,26,26,{line_width=1,radius=4})
  text(g,282,75,'Safe '..(safe-revealed(S.level)),'large',nil,190)
  local bx,by,cell=geometry()
  UI.region(bx,by,cell*b.n,cell*b.n)
  for y=1,b.n do
    for x=1,b.n do
      local i=(y-1)*b.n+x
      local px,py=bx+(x-1)*cell,by+(y-1)*cell
      local cx,cy=px+math.floor(cell/2),py+math.floor(cell/2)
      local v=tiles[i]
      if HINTED==i and not S.failed[S.level] then UI.shade(g,px,py,cell) end
      if v~=2 then
        -- Closed squares are small raised keys, like the controls: a 1px
        -- rounded outline with a 2px lower edge. Opened squares stay flat.
        g:rect(px+5,py+5,cell-9,cell-9,{line_width=0,radius=4})
        g:rect(px+7,py+cell-4,cell-13,1,{fill=true,radius=0})
      end
      if v==0 then
        if S.failed[S.level] and b.mines[i] then
          mine_icon(g,cx,cy,math.floor(cell/4))
        elseif i==1 and revealed(S.level)==0 then
          text(g,cx,py+math.floor((cell-UI.height(C,'body'))/2),'S','body','center',cell-12)
        end
      elseif v==1 then
        flag_icon(g,cx,cy)
      elseif b.mines[i] then
        mine_icon(g,cx,cy,math.floor(cell/4))
        g:rect(px+4,py+4,cell-8,cell-8,{line_width=2,radius=3})
      else
        local count=nearby(b,i)
        if count>0 then
          text(g,cx,py+math.floor((cell-UI.height(C,'strong'))/2),count,'strong','center',cell-8)
        else
          -- An opened empty square keeps a small dot, so it differs from a closed one.
          g:rect(cx-2,cy-2,4,4,{fill=true,radius=0})
        end
      end
    end
  end
  UI.grid(g,bx,by,b.n,b.n,cell,{minor=2,frame=3})
  -- Progress always stays visible; messages and the mode use their own line.
  text(g,8,594,'Safe '..revealed(S.level)..' / '..safe,'body',nil,220)
  local flags='Flags '..marked(S.level)..' / '..b.total
  local fw=math.min(UI.width(C,flags,'body'),220)
  text(g,472-fw,594,flags,'body',nil,220)
  local status=MSG or (S.failed[S.level] and 'Mine found - Reset this field'
    or solved(S.level,tiles) and 'Field cleared'
    or S.mode=='FLAG' and 'Flag mode: tap squares to mark mines'
    or 'Open mode: tap a square to open it')
  text(g,240,632,status,'small','center',464)
  button(g,'prev','Prev')
  button(g,'flag','Flag',S.mode=='FLAG')
  button(g,'hint','Hint',HINTED>0)
  button(g,'undo','Undo')
  button(g,'reset','Reset')
end
local function hit(x,y,bx,by,w,h)return x>=bx and x<bx+w and y>=by and y<by+h end
local function at(key,x,y) local b=BUTTONS[key];return hit(x,y,b[1],b[2],b[3],b[4]) end
local function tap(x,y)
  if at('help',x,y) then HELP=not HELP;return true end
  if at('new',x,y) then return new_game() end
  if HELP then
    if at('back',x,y) then HELP=false;return true end
    if at('difficulty',x,y) then return cycle_difficulty() end
    return false
  end
  if at('prev',x,y) then return prev() end
  if at('flag',x,y) then return mode() end
  if at('hint',x,y) then return hint() end
  if at('undo',x,y) then return undo() end
  if at('reset',x,y) then return restart() end
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
 solved=solved,geometry=geometry,tap=tap,hint=hint,infer_hint=infer_hint,controls=BUTTONS,
 hinted=function()return HINTED end
} end
