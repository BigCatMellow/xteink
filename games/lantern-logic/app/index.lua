-- Lantern Logic: original minimalist Akari / Light Up for XTOS Licorice.
-- E-ink X4 Pro portrait 480x800. Each touch causes one static redraw.
local LEVELS={
{size=5,rows={".2.#.","2....",".1.1.",".....","...00"}},
{size=5,rows={"1....","#....","#0..2",".1...","....."}},
{size=5,rows={".02..",".1...","...2.","..#..","0.#.."}},
{size=5,rows={".....","..#.1","..2..","1.#..","....."}},
{size=5,rows={".....","..00.",".1...","..3..","....."}},
{size=6,rows={"....1.","......",".1..2.","2##1..","..#.1.",".#...#"}},
{size=6,rows={".2....",".....0","...#.#",".#1...",".##.4.","..##.#"}},
{size=6,rows={"..0.#.",".#..##",".#....","....2#","......","....#1"}},
{size=6,rows={"1.....",".#....","......","....2.",".3....",".....1"}},
{size=6,rows={"..0..1","......","..3..#","1.....",".....#","....#."}},
{size=6,rows={"..1...","....4.","..#..#","1..###","..#...",".....1"}},
{size=7,rows={"...2...","..#....","0.0...1",".....1.","..#....","..0..##","...#.#."}},
{size=7,rows={"#......","..1.0..","#....1.","..0.#..","1.#....",".#.#..1","...#0.."}},
{size=7,rows={"0......",".#...00","..#.1.1",".......","###....","...#1.#",".3..#.."}},
{size=7,rows={"#...#..","#0....2","..#...#",".......","..#....","11.....","#..2.1."}},
{size=7,rows={"##.#...","...#...",".2.#.2.","...#..2","..1....","#.1...0","1.....#"}},
{size=8,rows={".2......","...1....","#.#..#..","..#1...0","...10...","#..##.21","........",".#..#.##"}},
{size=8,rows={"..##..#.","#....3..","1.......","#...#.#.","....1#2.",".....1..",".....#..",".0..2..#"}},
{size=8,rows={"........","2.......","...0....","...1.3..","#..0...#",".......#","..12....",".#......"}},
{size=8,rows={"........","0.1.....","....1...","....1.1.",".1...##.",".#..1..#","2.#...#.","#...3..."}},
{size=9,rows={".#.##....","...#.1..2","1.#...#3.","#....3..#","....#.##.",".2...3...","....#...#","..#......",".3.#...2."}},
{size=9,rows={"....#.##.","1#.......","2....#1..","..0.##..#",".....#...","...#.1.##","#.#.1#...",".2....1#.","...0#.##1"}},
{size=9,rows={"..0.....#","........#","01.3.1...","..#.#.#2.","...2##...","...0...#.",".1#...#11",".0#.....#","....1...."}},
{size=9,rows={".1...#..1","..#..2...","..2......","....0..0.","#........",".##1#0.1.",".1.....#.","#2.......","...#...1#"}},
{size=10,rows={".###1#..##","#....#2...","##.02.....","#....2....","....3#...#",".1....##1#",".0.#.2....","...#....0#","1.........","........2."}},
{size=10,rows={"........##",".01.#.#2..","....0#..2.","......#.#.","....2#.2#.","#1.#.###1.","....1.##.#","...#......",".1##...2..",".0...0#..."}},
{size=10,rows={"..#0....#.",".#........","....1..1.#",".....1.#..","..#......3",".4.##.....","..4.#..1#.","...#....0#","...2.....#",".#........"}},
{size=10,rows={"..#.#..#..","...2...#..","#..0.....1","....#2...1","..0.......","....#.#..0","1..1..0..#",".#2.......",".#.....0..","0......0.1"}},
}
local D={{0,-1},{1,0},{0,1},{-1,0}}
local UI=require('ui')
local Theme=require('theme')
local C,S,ERR,MSG=nil,nil,nil,nil
local key_ms=-1000
local MODE=1
local HELP=false
local function idx(x,y,n) return (y-1)*n+x end
local function inside(x,y,n) return x>=1 and x<=n and y>=1 and y<=n end
local function wall(v) return v~='.' end
local function parse(n)
  local p=LEVELS[n]
  if not p then error('invalid level') end
  local a={}
  for y=1,p.size do
    local row=p.rows[y]
    if not row or #row~=p.size then error('bad authored puzzle width') end
    for x=1,p.size do
      local ch=row:sub(x,x)
      if not ch:match('^[%.#01234]$') then error('bad clue') end
      a[#a+1]=ch
    end
  end
  return {n=p.size,tiles=a}
end
local function serialize(m)
  local s={}
  for i,v in ipairs(m) do s[i]=tostring(v) end
  return table.concat(s)
end
local function decode(text,b)
  if type(text)~='string' or #text~=#b.tiles or text:find('[^012]') then return nil end
  local out={}
  for i=1,#b.tiles do
    local v=tonumber(text:sub(i,i))
    if wall(b.tiles[i]) and v~=0 then return nil end
    out[i]=v
  end
  return out
end
local function lit_and_conflicts(b,m)
  local n=b.n
  local lit={}
  local conflicts=0
  for i,v in ipairs(m) do
    if v==1 then
      lit[i]=true
      local x=(i-1)%n+1
      local y=math.floor((i-1)/n)+1
      for _,d in ipairs(D) do
        local a,c=x+d[1],y+d[2]
        while inside(a,c,n) do
          local j=idx(a,c,n)
          if wall(b.tiles[j]) then break end
          if m[j]==1 then conflicts=conflicts+1 end
          lit[j]=true
          a,c=a+d[1],c+d[2]
        end
      end
    end
  end
  return lit,conflicts/2
end
local function inspect(b,m)
  local lit,conflicts=lit_and_conflicts(b,m)
  local dark,bad,clues=0,0,0
  for i,ch in ipairs(b.tiles) do
    if ch=='.' then
      if not lit[i] then dark=dark+1 end
    elseif ch~='#' then
      clues=clues+1
      local x=(i-1)%b.n+1
      local y=math.floor((i-1)/b.n)+1
      local lamps=0
      for _,d in ipairs(D) do
        local a,c=x+d[1],y+d[2]
        if inside(a,c,b.n) and m[idx(a,c,b.n)]==1 then lamps=lamps+1 end
      end
      if lamps~=tonumber(ch) then bad=bad+1 end
    end
  end
  return dark,conflicts,bad,clues,lit
end
local function complete(b,m)
  local dark,conflicts,bad=inspect(b,m)
  return dark==0 and conflicts==0 and bad==0
end
local function save()
  if not S or not C or not C.storage then return end
  local hist={}
  for _,h in ipairs(S.history) do hist[#hist+1]=serialize(h) end
  local data=table.concat({
    'version=1',
    'level='..S.level,
    'unlocked='..S.unlocked,
    'marks='..serialize(S.marks),
    'history='..table.concat(hist,';'),
    'mode='..MODE
  },'\n')
  pcall(function() C.storage:write('lantern-logic.txt',data) end)
  pcall(function() C.storage:write('lantern-logic-'..S.level..'.txt',data) end)
end
local function start(n,unlocked)
  local b=parse(n)
  local marks={}
  for i=1,#b.tiles do marks[i]=0 end
  S={level=n,unlocked=math.max(n,unlocked or n),b=b,marks=marks,history={}}
  MSG=nil
  save()
end
local function restore(filename,expected)
  if not C or not C.storage then return false end
  local ok,s=pcall(function() return C.storage:read(filename or 'lantern-logic.txt') end)
  if not ok or type(s)~='string' then return false end
  local f={}
  for k,v in s:gmatch('([%w_]+)=([^\n]*)') do f[k]=v end
  if f.version~='1' then return false end
  local n,u=tonumber(f.level),tonumber(f.unlocked)
  if not n or n~=math.floor(n) or n<1 or n>#LEVELS or
     not u or u~=math.floor(u) or u<n or u>#LEVELS then return false end
  if expected and n~=expected then return false end
  local b=parse(n)
  local marks=decode(f.marks,b)
  if not marks then return false end
  local hist={}
  for state in (f.history or ''):gmatch('[^;]+') do
    local h=decode(state,b)
    if not h or #hist>=24 then return false end
    hist[#hist+1]=h
  end
  S={level=n,unlocked=u,b=b,marks=marks,history=hist}
  MSG=nil;MODE=f.mode=='2' and 2 or 1
  return true
end
local function visit(n)
  local unlocked=S.unlocked
  save()
  if restore('lantern-logic-'..n..'.txt',n) then
    S.unlocked=math.max(unlocked,S.unlocked)
    save()
  else start(n,unlocked) end
  return true
end
local function mode(v)
  if MODE==v then return false end
  MODE=v;save();return true
end
local function choose(x,y,v)
  if not S or not inside(x,y,S.b.n) then return false end
  local i=idx(x,y,S.b.n)
  if wall(S.b.tiles[i]) or complete(S.b,S.marks) then return false end
  if #S.history>=24 then table.remove(S.history,1) end
  local prev={}
  for j,v in ipairs(S.marks) do prev[j]=v end
  S.history[#S.history+1]=prev
  v=v or MODE
  S.marks[i]=S.marks[i]==v and 0 or v
  if complete(S.b,S.marks) then
    S.unlocked=math.min(#LEVELS,math.max(S.unlocked,S.level+1))
    MSG='Solved'
  else MSG=nil end
  save()
  return true
end
local function undo()
  if not S or #S.history==0 then return false end
  S.marks=table.remove(S.history)
  MSG='Last mark restored'
  save()
  return true
end
local function reset()
  if not S then return false end
  start(S.level,S.unlocked)
  return true
end
local function previous()
  if not S or S.level==1 then return false end
  visit(S.level-1)
  return true
end
local function next_level()
  if not S or S.level>=#LEVELS or
     (S.level>=S.unlocked and not complete(S.b,S.marks)) then return false end
  visit(S.level+1)
  return true
end
local function font(which)
  return C and C.fonts and C.fonts[which or 'medium']
end
local function put(g,x,y,s,which,align)
  UI.text(g,C,x,y,s,which,align)
end
local function centered(g,x,y,s,which) put(g,x,y,s,which,'center') end
local function button(g,x,y,w,h,s)
  UI.button(g,C,x,y,w,h,s)
end
local function position(n)
  return UI.grid_geometry(n,94,572,468)
end
local function draw(g)
  g:clear(0)
  UI.text(g,C,80,14,'Akari','large',nil,326)
  button(g,416,12,48,48,HELP and 'X' or '?')
  if HELP then
    UI.text(g,C,240,94,'How to play','large','center',436)
    UI.paragraph(g,C,22,150,436,430,'Place bulbs on white squares to light every white cell along rows and columns. Walls block light. Bulbs must never see each other. A numbered wall needs that many bulbs touching its four sides. Select Bulb or X, then tap a cell. A small dot means lit; brackets mark conflicting bulbs. Tap the same mark to clear.','medium')
    button(g,76,704,328,70,'Back to grid')
    return
  end
  UI.text(g,C,16,66,'Puzzle '..S.level..' / '..#LEVELS,'small',nil,300)
  local b,m=S.b,S.marks
  local bx,by,cell=position(b.n)
  UI.region(bx,by,b.n*cell,b.n*cell)
  UI.grid(g,bx,by,b.n,b.n,cell)
  local dark,conflicts,bad,clues,lit=inspect(b,m)
  for y=1,b.n do
    for x=1,b.n do
      local i=idx(x,y,b.n)
      local ch=b.tiles[i]
      local px,py=bx+(x-1)*cell,by+(y-1)*cell
      local cx,cy=px+cell/2,py+cell/2
      if wall(ch) then
        g:rect(px+3,py+3,cell-6,cell-6,{line_width=3})
        if ch=='#' then
          g:line(px+8,py+8,px+cell-8,py+cell-8,{line_width=2})
          g:line(px+cell-8,py+8,px+8,py+cell-8,{line_width=2})
        else
          centered(g,cx,cy-16,ch,'strong')
          local nearby=0
          for _,d in ipairs(D) do
            local a,q=x+d[1],y+d[2]
            if inside(a,q,b.n) and m[idx(a,q,b.n)]==1 then nearby=nearby+1 end
          end
          if nearby==tonumber(ch) then
            -- A small check under a satisfied clue, without covering its digit.
            g:line(px+cell-17,py+9,px+cell-12,py+14,{line_width=2})
            g:line(px+cell-12,py+14,px+cell-5,py+5,{line_width=2})
          elseif nearby>tonumber(ch) then
            g:line(px+6,py+cell-7,px+cell-6,py+cell-7,{line_width=3})
          end
        end
      elseif m[i]==1 then
        g:circle(cx,cy,12,{line_width=3})
        g:circle(cx,cy,5,{fill=true})
        g:line(cx-19,cy,cx-15,cy)
        g:line(cx+15,cy,cx+19,cy)
        g:line(cx,cy-19,cx,cy-15)
        g:line(cx,cy+15,cx,cy+19)
        -- Corner brackets flag this bulb if another bulb sees it.
        local clash=false
        for _,d in ipairs(D) do
          local a,q=x+d[1],y+d[2]
          while inside(a,q,b.n) and not wall(b.tiles[idx(a,q,b.n)]) do
            if m[idx(a,q,b.n)]==1 then clash=true;break end
            a,q=a+d[1],q+d[2]
          end
        end
        if clash then
          g:line(px+5,py+15,px+5,py+5,{line_width=2})
          g:line(px+5,py+5,px+15,py+5,{line_width=2})
          g:line(px+cell-15,py+cell-5,px+cell-5,py+cell-5,{line_width=2})
          g:line(px+cell-5,py+cell-5,px+cell-5,py+cell-15,{line_width=2})
        end
      elseif m[i]==2 then
        g:line(cx-11,cy-11,cx+11,cy+11,{line_width=2})
        g:line(cx+11,cy-11,cx-11,cy+11,{line_width=2})
        if lit[i] then g:circle(px+9,py+9,2,{fill=true}) end
      elseif lit[i] then
        -- Small corner dot indicates illumination, not a gray fill.
        g:circle(px+11,py+11,2,{fill=true})
      end
    end
  end
  local status=complete(b,m) and 'Solved' or (conflicts>0 and 'Bulbs conflict: '..math.floor(conflicts) or ('Dark '..dark..' / Clues '..bad))
  UI.text(g,C,240,580,status,'medium','center',440)
  UI.button(g,C,12,620,222,62,'Bulb',MODE==1)
  UI.button(g,C,246,620,222,62,'X',MODE==2)
  button(g,12,704,106,70,'Prev')
  button(g,128,704,106,70,'Undo')
  button(g,244,704,106,70,'Reset')
  if S.level<#LEVELS and (complete(b,m) or S.level<S.unlocked) then
    button(g,360,704,108,70,'Next')
  elseif complete(b,m) then
    button(g,360,704,108,70,'Done')
  end
end
local function hit(x,y,a,b,w,h)
  return x>=a and x<a+w and y>=b and y<b+h
end
local function tap(x,y)
  if hit(x,y,416,12,48,48) then HELP=not HELP;return true end
  if HELP then
    if hit(x,y,76,704,328,70) then HELP=false;return true end
    return false
  end
  if hit(x,y,12,620,222,62) then return mode(1) end
  if hit(x,y,246,620,222,62) then return mode(2) end
  if hit(x,y,12,704,106,70) then return previous() end
  if hit(x,y,128,704,106,70) then return undo() end
  if hit(x,y,244,704,106,70) then return reset() end
  if hit(x,y,360,704,108,70) then return next_level() end
  local a,b,cell=position(S.b.n)
  if hit(x,y,a,b,cell*S.b.n,cell*S.b.n) then
    return choose(math.floor((x-a)/cell)+1,math.floor((y-b)/cell)+1)
  end
  return false
end
local function refresh()
  if C then pcall(function() C:invalidate() end) end
end
function on_load(c)
  Theme.release()
  C=c or ctx;ERR=nil;HELP=false;MODE=1
  local ok,e=pcall(function() if not restore() then start(1,1) end end)
  if not ok then ERR=tostring(e) end
end
function on_draw(c,g)
  if c then C=c end
  if not g then return end
  if ERR then
    UI.error(g,C,'LANTERN LOGIC',ERR)
    return
  end
  local ok,e=pcall(function() Theme.draw(C,g,draw) end)
  if not ok then ERR=tostring(e) end
end
function on_input(c,e)
  if c then C=c end
  if ERR or not S or type(e)~='table' then return false end
  local change=false
  local ok,err=pcall(function()
    if e.type=='pointer' or e.type=='touch' then
      if e.type=='pointer' and e.phase~='up' then return end
      if e.gesture and e.gesture~='tap' and e.gesture~='double_tap' then return end
      change=tap(tonumber(e.x) or -1,tonumber(e.y) or -1)
    elseif e.type=='key' and (not e.phase or e.phase=='down') and
      (e.key=='up' or e.key=='down') then
      local now=tonumber(e.time_ms)
      if not now and C and C.clock then
        local yes,value=pcall(function() return C.clock:millis() end)
        if yes then now=tonumber(value) end
      end
      if now and now>=key_ms and now-key_ms<225 then return end
      if now then key_ms=now end
      if e.key=='up' then change=previous() else change=next_level() end
    end
  end)
  if not ok then ERR=tostring(err);change=true end
  if change then refresh() end
  return change
end
function on_leave() Theme.release(); if S then save() end end
if rawget(_G,'__TEST') then
  __TEST.api={
    levels=LEVELS,parse=parse,complete=complete,inspect=inspect,
    start=start,restore=restore,choose=choose,undo=undo,
    reset=reset,next=next_level,prev=previous,
    state=function() return S end,position=position,
    decode=decode,mode=mode,tap=tap
  }
end

-- Crash reports: errors are saved to crash.txt and shown on a recovery screen.
do
  local guarded=UI.guard{id='lanternlogic',test=rawget(_G,'__TEST'),
    state=function() return S and ('level='..tostring(S.level)..' unlocked='..tostring(S.unlocked)) end,
    load=on_load,draw=on_draw,input=on_input,leave=on_leave}
  on_load,on_draw,on_input,on_leave=guarded.load,guarded.draw,guarded.input,guarded.leave
end
