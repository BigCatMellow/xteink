-- Word Hunt: classic word search plus Find the Fox for XTEINK X4 Pro.
-- One tap for the first letter, one for the last. No animation or drag.
local UI=require('ui')
local Theme=require('theme')
local P=require('puzzles')
local Generator=require('generator')
local Store=require('puzzle_store')
local MODES={'classic','fox'}
local TOTAL={#P.classic,#P.fox}
local MAX=999999999
local generated={}
local C,S,ERR,MSG=nil,nil,nil,nil
local HELP=false
local KEY_MS=-1000
local function bit(i) return math.floor(2^(i-1)) end
local function has(m,i) return math.floor(m/bit(i))%2==1 end
local function copyfill(n,value)
  local r={}
  for i=1,n do r[i]=value end
  return r
end
local function encode(v,n)
  local out={}
  for i=1,n or #v do out[i]=tostring(v[i]) end
  return table.concat(out,',')
end
local function decode(s,n,max)
  if type(s)~='string' or not s:match('^%d+[,%d]*$') then return nil end
  local result={}
  for v in s:gmatch('[^,]+') do
    local num=tonumber(v)
    if not num or num~=math.floor(num) or num<0 or num>max then return nil end
    result[#result+1]=num
  end
  if #result~=n then return nil end
  return result
end
local function level()
  local m,n=S.mode,S.levels[S.mode]
  if n<=TOTAL[m] then return P[MODES[m]][n] end
  if not generated[m] or generated[m].number~=n then
    generated[m]={number=n,puzzle=Generator.generate(m,n)}
  end
  return generated[m].puzzle
end
local function count()
  local total=0
  for i=1,#level().words do
    if has(S.found[S.mode][S.levels[S.mode]],i) then total=total+1 end
  end
  return total
end
local function complete()
  return S and count()==#level().words
end
local function save()
  if not S or not C or not C.storage then return true end
  local data=table.concat({
    'version=2','mode='..S.mode,
    'levels='..encode(S.levels),'unlocked='..encode(S.unlocked),
    'foundC='..encode(S.found[1],TOTAL[1]),'foundF='..encode(S.found[2],TOTAL[2]),
    'hintsC='..encode(S.hints[1],TOTAL[1]),'hintsF='..encode(S.hints[2],TOTAL[2]),
    'revealedC='..encode(S.revealed[1],TOTAL[1]),'revealedF='..encode(S.revealed[2],TOTAL[2])
  },'\n')
  local ok=pcall(function()
    for m=1,2 do
      local n=S.levels[m]
      if n>TOTAL[m] then
        Store.put(C.storage,'search-'..m,n,table.concat({S.found[m][n],S.hints[m][n],S.revealed[m][n]},','))
      end
    end
    Store.write(C.storage,'word-hunt.txt',data)
  end)
  if not ok then MSG='Save failed - keep this puzzle open' end
  return ok
end
local function load_generated(state,m,n)
  if n<=TOTAL[m] then return end
  local found,hints,revealed=0,0,0
  if C and C.storage then
    local data=Store.get(C.storage,'search-'..m,n)
    local values=decode(data,3,15)
    if values and values[1]<=(m==1 and 15 or 1) and values[2]<=2 and values[3]<=(m==1 and 4 or 1) and
       (values[3]==0 or (values[2]>0 and not has(values[1],values[3]))) then
      found,hints,revealed=values[1],values[2],values[3]
    end
  end
  local old=state.levels[m]
  if old>TOTAL[m] then
    state.found[m][old]=nil;state.hints[m][old]=nil;state.revealed[m][old]=nil
  end
  state.found[m][n]=found;state.hints[m][n]=hints;state.revealed[m][n]=revealed
end
local function initialize()
  S={mode=1,levels={1,1},unlocked={1,1},found={},hints={},revealed={},selected=nil}
  for mode=1,2 do
    S.found[mode]=copyfill(TOTAL[mode],0)
    S.hints[mode]=copyfill(TOTAL[mode],0)
    S.revealed[mode]=copyfill(TOTAL[mode],0)
  end
  MSG='Tap the first and last letter'
  HELP=false
  save()
end
local function restore()
  if not C or not C.storage then return false end
  local ok,data=pcall(function()
    local data,err=C.storage:read('word-hunt.txt')
    if not data and err and err~='not_found' then error('Save read failed') end
    return data
  end)
  if not ok then error('Could not read saved progress') end
  if type(data)~='string' then return false end
  local f={}
  for k,v in data:gmatch('([%w_]+)=([^\n]*)') do f[k]=v end
  if f.version~='1' and f.version~='2' then return false end
  local mode=tonumber(f.mode)
  local limit=f.version=='1' and math.max(TOTAL[1],TOTAL[2]) or MAX
  local levels=decode(f.levels,2,limit)
  local unlocked=decode(f.unlocked,2,limit)
  if not mode or mode~=math.floor(mode) or mode<1 or mode>2 or not levels or not unlocked then return false end
  local result={
    mode=mode,levels=levels,unlocked=unlocked,
    found={},hints={},revealed={},selected=nil
  }
  for m=1,2 do
    if levels[m]<1 or unlocked[m]<levels[m] then return false end
    local suffix=m==1 and 'C' or 'F'
    result.found[m]=decode(f['found'..suffix],TOTAL[m],m==1 and 15 or 1)
    result.hints[m]=decode(f['hints'..suffix],TOTAL[m],2)
    result.revealed[m]=decode(f['revealed'..suffix],TOTAL[m],m==1 and 4 or 1)
    if not result.found[m] or not result.hints[m] or not result.revealed[m] then return false end
    for i=1,TOTAL[m] do
      local target=result.revealed[m][i]
      if target>0 and (result.hints[m][i]==0 or has(result.found[m][i],target)) then return false end
      local all=(m==1 and 15 or 1)
      if result.found[m][i]==all and i<TOTAL[m] and unlocked[m]<i+1 then return false end
    end
    if result.found[m][TOTAL[m]]==(m==1 and 15 or 1) then
      unlocked[m]=math.max(unlocked[m],TOTAL[m]+1)
    end
    load_generated(result,m,levels[m])
  end
  S=result;MSG=nil;HELP=false
  return true
end
local function visit(newLevel)
  local m=S.mode
  if newLevel<1 or newLevel>MAX or newLevel~=math.floor(newLevel) or newLevel>S.unlocked[m] then return false end
  if not save() then return true end
  local old=S.levels[m]
  if newLevel>TOTAL[m] then load_generated(S,m,newLevel) end
  if old>TOTAL[m] and old~=newLevel then
    S.found[m][old]=nil;S.hints[m][old]=nil;S.revealed[m][old]=nil
  end
  S.levels[m]=newLevel
  S.selected=nil
  MSG=nil;HELP=false
  save()
  return true
end
local function next_level() return S and visit(S.levels[S.mode]+1) or false end
local function prev_level() return S and visit(S.levels[S.mode]-1) or false end
local function set_mode(m)
  if not S or m<1 or m>2 or m==S.mode then return false end
  S.mode=m;S.selected=nil;HELP=false
  MSG=m==2 and 'Find the only FOX' or 'Find the four listed words'
  save()
  return true
end
local function restart()
  if not S then return false end
  local m,n=S.mode,S.levels[S.mode]
  S.found[m][n]=0
  S.hints[m][n]=0
  S.revealed[m][n]=0
  S.selected=nil
  MSG='Fresh search'
  save()
  return true
end
local function hint()
  if not S or complete() then return false end
  local m,n=S.mode,S.levels[S.mode]
  if S.revealed[m][n]>0 then
    MSG='The starting letter is ringed'
    return true
  end
  if S.hints[m][n]>=2 then
    MSG='No hints remaining'
    return true
  end
  for i=1,#level().words do
    if not has(S.found[m][n],i) then
      S.revealed[m][n]=i
      S.hints[m][n]=S.hints[m][n]+1
      MSG='Find the double-ringed start'
      save()
      return true
    end
  end
  return false
end
local function valid_path(wordpath,word,x1,y1,x2,y2)
  local sx,sy,dx,dy=wordpath[1],wordpath[2],wordpath[3],wordpath[4]
  local ex,ey=sx+(#word-1)*dx,sy+(#word-1)*dy
  return (x1==sx and y1==sy and x2==ex and y2==ey) or
         (x1==ex and y1==ey and x2==sx and y2==sy)
end
local function select_cell(x,y)
  if not S then return false end
  local puzzle=level()
  if x<1 or y<1 or x>puzzle.n or y>puzzle.n or complete() then return false end
  if not S.selected then
    S.selected={x,y}
    MSG='Now tap the last letter'
    return true
  end
  local old=S.selected
  S.selected=nil
  if old[1]==x and old[2]==y then
    MSG='Selection cancelled'
    return true
  end
  local m,n=S.mode,S.levels[S.mode]
  for i,word in ipairs(puzzle.words) do
    if not has(S.found[m][n],i) and valid_path(puzzle.paths[i],word,old[1],old[2],x,y) then
      S.found[m][n]=S.found[m][n]+bit(i)
      if S.revealed[m][n]==i then S.revealed[m][n]=0 end
      MSG='Found '..word..'!'
      if complete() then
        S.unlocked[m]=math.min(MAX,math.max(S.unlocked[m],n+1))
        MSG='Puzzle completed!'
      end
      save()
      return true
    end
  end
  MSG='No listed word there'
  return true
end
local function geometry()
  local n=level().n
  local cell=n==13 and 30 or 46
  return math.floor((480-cell*n)/2),n==13 and 151 or 160,cell
end
local function button(g,x,y,w,h,label)
  UI.button(g,C,x,y,w,h,label)
end
local function text(g,x,y,label,style,align,width)
  UI.text(g,C,x,y,label,style,align,width)
end
local function draw_help(g)
  text(g,240,152,'HOW TO SEARCH','large','center',420)
  UI.paragraph(g,C,28,219,424,120,
    'Tap the first and last letters. Words can run in any of eight directions.', 'medium')
  UI.paragraph(g,C,28,341,424,90,
    'FOX: find one straight FOX among F, O and X. Read either direction.', 'medium')
  UI.paragraph(g,C,28,449,424,169,
    'HINT rings a start cell. Two hints per puzzle. RESET only clears the current grid; both modes save independently.', 'medium')
  UI.paragraph(g,C,28,625,424,68,
    'After eight boards, NEXT generates more. Earlier puzzles stay saved.', 'small')
  button(g,72,704,336,68,'BACK TO GAME')
end
local function render(g)
  g:clear(0)
  text(g,22,17,'WORD HUNT','large',nil,210)
  button(g,250,13,89,45,'WORDS')
  button(g,349,13,68,45,'FOX')
  button(g,427,13,31,45,HELP and 'X' or '?')
  if S.mode==1 then g:line(266,61,323,61,{line_width=3})
  else g:line(360,61,404,61,{line_width=3}) end
  local p=level()
  text(g,24,78,(S.mode==1 and 'WORDS ' or 'FOX ')..S.levels[S.mode]..'  '..p.title,'medium',nil,433)
  g:line(24,118,456,118,{line_width=2})
  if HELP then draw_help(g);return end
  local bx,by,cell=geometry()
  UI.region(bx,by,p.n*cell,p.n*cell)
  g:rect(bx,by,cell*p.n,cell*p.n,{line_width=3})
  local m,n=S.mode,S.levels[S.mode]
  local found=S.found[m][n]
  local marked={}
  for i,word in ipairs(p.words) do
    if has(found,i) then
      local a=p.paths[i]
      for j=0,#word-1 do
        local xx,yy=a[1]+j*a[3],a[2]+j*a[4]
        marked[(yy-1)*p.n+xx]=true
      end
    end
  end
  for y=1,p.n do
    for x=1,p.n do
      local px=bx+(x-1)*cell
      local py=by+(y-1)*cell
      local cx=px+cell/2
      local cy=py+cell/2
      local ch=p.rows[y]:sub(x,x)
      text(g,cx,py+(p.n==13 and 4 or 10),ch,p.n==13 and 'small' or 'medium','center',cell-5)
      if marked[(y-1)*p.n+x] then
        g:circle(cx,cy,p.n==13 and 12 or 17,{line_width=1})
      end
      if S.selected and S.selected[1]==x and S.selected[2]==y then
        g:rect(px+2,py+2,cell-4,cell-4,{line_width=2})
      end
    end
  end
  local revealed=S.revealed[m][n]
  if revealed>0 then
    local path=p.paths[revealed]
    local cx=bx+(path[1]-.5)*cell
    local cy=by+(path[2]-.5)*cell
    g:circle(cx,cy,p.n==13 and 14 or 19,{line_width=2})
    g:circle(cx,cy,p.n==13 and 17 or 22,{line_width=1})
  end
  if S.mode==1 then
    for i,word in ipairs(p.words) do
      local x=i%2==1 and 24 or 248
      local y=i<=2 and 554 or 602
      g:rect(x,y,208,39,{line_width=1})
      g:rect(x+10,y+8,22,22,{line_width=2})
      if has(found,i) then
        g:line(x+14,y+18,x+20,y+25,{line_width=2})
        g:line(x+20,y+25,x+28,y+13,{line_width=2})
      end
      text(g,x+43,y+6,word,'medium',nil,155)
    end
  else
    text(g,240,559,'FIND THE FOX','large','center',400)
    text(g,240,604,complete() and 'FOX FOUND' or 'ONE FOX IS HIDDEN','medium','center',410)
  end
  text(g,240,656,MSG or 'Tap two letters to select a word','small','center',432)
  local status='FOUND '..count()..'/'..#p.words..'    HINTS '..S.hints[m][n]..'/2'
  text(g,240,681,status,'small','center',430)
  button(g,20,713,100,65,S.levels[m]>1 and 'PREV' or 'START')
  button(g,132,713,100,65,'RESET')
  button(g,244,713,100,65,'HINT')
  if S.levels[m]<S.unlocked[m] then
    button(g,356,713,104,65,'NEXT')
  elseif complete() then
    text(g,409,733,'DONE','small','center',90)
  end
end
local function hit(x,y,bx,by,w,h)
  return x>=bx and x<bx+w and y>=by and y<by+h
end
local function tap(x,y)
  if hit(x,y,250,13,89,45) then return set_mode(1) end
  if hit(x,y,349,13,68,45) then return set_mode(2) end
  if hit(x,y,427,13,31,45) then HELP=not HELP;return true end
  if HELP then
    if hit(x,y,72,704,336,68) then HELP=false;return true end
    return false
  end
  if hit(x,y,20,713,100,65) then return prev_level() end
  if hit(x,y,132,713,100,65) then return restart() end
  if hit(x,y,244,713,100,65) then return hint() end
  if hit(x,y,356,713,104,65) then return next_level() end
  local p=level()
  local bx,by,cell=geometry()
  if hit(x,y,bx,by,cell*p.n,cell*p.n) then
    return select_cell(math.floor((x-bx)/cell)+1,math.floor((y-by)/cell)+1)
  end
  return false
end
local function redraw()
  if C then pcall(function() C:invalidate() end) end
end
function on_load(context)
  Theme.release()
  C=context or ctx;S=nil;ERR=nil;KEY_MS=-1000
  local ok,e=pcall(function() if not restore() then initialize() end end)
  if not ok then ERR=tostring(e) end
end
function on_draw(context,g)
  if context then C=context end
  if not g then return end
  if ERR then UI.error(g,C,'WORD HUNT',ERR);return end
  local ok,e=pcall(function() Theme.draw(C,g,render) end)
  if not ok then ERR=tostring(e);UI.error(g,C,'WORD HUNT',ERR) end
end
function on_input(context,e)
  if context then C=context end
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
        local good,value=pcall(function() return C.clock:millis() end)
        if good then now=tonumber(value) end
      end
      if now and now>=KEY_MS and now-KEY_MS<230 then return end
      if now then KEY_MS=now end
      if e.key=='up' then changed=prev_level() else changed=next_level() end
    end
  end)
  if not ok then ERR=tostring(err);changed=true end
  if changed then redraw() end
  return changed
end
function on_leave() Theme.release(); if S then save() end end
if rawget(_G,'__TEST') then
  __TEST.api={
    data=P,state=function() return S end,select=select_cell,tap=tap,
    visit=visit,mode=set_mode,reset=restart,hint=hint,
    next=next_level,prev=prev_level,complete=complete,
    count=count,geometry=geometry,restore=restore,puzzle=level
  }
end
