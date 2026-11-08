-- Island Links: original static Hashi/Bridges puzzles for XTOS Licorice.
-- E-ink XTEINK X4 Pro. No animation, loops or network requirements.
local LEVELS={
  {{1,1,3},{3,1,6},{5,1,4},{1,3,2},{3,3,4},{3,5,1},{5,5,2}},
  {{1,1,2},{3,1,4},{5,1,3},{1,3,1},{5,3,2},{1,5,3},{3,5,3}},
  {{1,1,2},{3,1,3},{5,1,4},{1,3,2},{5,3,3},{1,5,1},{5,5,1}},
  {{1,1,1},{3,1,4},{5,1,4},{3,3,3},{5,3,4},{1,5,1},{3,5,2},{5,5,1}},
  {{1,1,3},{3,1,4},{5,1,4},{1,3,5},{3,3,5},{1,5,1},{3,5,2},{5,5,2}},
  {{1,1,4},{3,1,3},{5,1,1},{3,3,2},{5,3,1},{1,5,4},{3,5,6},{5,5,3}},
  {{3,1,2},{5,1,1},{1,3,1},{3,3,5},{5,3,1},{1,5,1},{3,5,5},{5,5,2}},
  {{1,1,4},{3,1,5},{5,1,4},{1,3,3},{3,3,5},{5,3,5},{1,5,2},{3,5,6},{5,5,4}},
  {{1,1,3},{3,1,1},{5,1,1},{1,3,3},{3,3,1},{5,3,2},{1,5,3},{3,5,4},{5,5,2}},
  {{1,1,4},{3,1,3},{5,1,3},{1,3,3},{3,3,2},{5,3,4},{1,5,1},{3,5,1},{5,5,1}},
  {{1,1,3},{3,1,3},{5,1,1},{1,3,2},{3,3,2},{5,3,1},{1,5,3},{3,5,4},{5,5,1}},
  {{1,1,4},{3,1,3},{5,1,1},{1,3,4},{3,3,6},{5,3,3},{1,5,3},{3,5,6},{5,5,2}},
}
local C,S,ERR,MSG=nil,nil,nil,nil
local key_ms=-1000
local OX,OY,CELL=-36,76,92
local function nodes(n)
  local p=LEVELS[n]
  if not p then error('invalid level') end
  local copy={}
  for i,a in ipairs(p) do copy[i]={x=a[1],y=a[2],need=a[3]} end
  return copy
end
local function links(points)
  local result={}
  for i,first in ipairs(points) do
    for j=i+1,#points do
      local b=points[j]
      if first.x==b.x or first.y==b.y then
        local clear=true
        for k,q in ipairs(points) do
          if k~=i and k~=j then
            if first.x==b.x and q.x==first.x and
              q.y>math.min(first.y,b.y) and q.y<math.max(first.y,b.y) then clear=false end
            if first.y==b.y and q.y==first.y and
              q.x>math.min(first.x,b.x) and q.x<math.max(first.x,b.x) then clear=false end
          end
        end
        if clear then result[#result+1]={a=i,b=j} end
      end
    end
  end
  return result
end
local function crosses(p,e,f)
  local a,b=p[e.a],p[e.b]
  local c,d=p[f.a],p[f.b]
  if a.y==b.y and c.x==d.x then
    return c.x>math.min(a.x,b.x) and c.x<math.max(a.x,b.x) and
      a.y>math.min(c.y,d.y) and a.y<math.max(c.y,d.y)
  elseif a.x==b.x and c.y==d.y then
    return a.x>math.min(c.x,d.x) and a.x<math.max(c.x,d.x) and
      c.y>math.min(a.y,b.y) and c.y<math.max(a.y,b.y)
  end
  return false
end
local function fresh_weights(edges)
  local t={}
  for i=1,#edges do t[i]=0 end
  return t
end
local function code(weights)
  local r={}
  for i,v in ipairs(weights) do r[i]=tostring(v) end
  return table.concat(r)
end
local function decode(value,n)
  if type(value)~='string' or #value~=n or value:find('[^012]') then return nil end
  local r={}
  for i=1,#value do r[i]=tonumber(value:sub(i,i)) end
  return r
end
local function stats(p,edges,weights)
  local mismatch,active,crossings=0,0,0
  local joined={}
  for i=1,#p do joined[i]={} end
  for i,q in ipairs(p) do
    local degree=0
    for k,e in ipairs(edges) do
      if e.a==i or e.b==i then degree=degree+weights[k] end
    end
    if degree~=q.need then mismatch=mismatch+1 end
  end
  for i,e in ipairs(edges) do
    if weights[i]>0 then
      active=active+1
      joined[e.a][#joined[e.a]+1]=e.b
      joined[e.b][#joined[e.b]+1]=e.a
      for j=i+1,#edges do
        if weights[j]>0 and crosses(p,e,edges[j]) then crossings=crossings+1 end
      end
    end
  end
  local queue={1}
  local seen={[1]=true}
  local k=1
  while k<=#queue do
    local at=queue[k];k=k+1
    for _,nextnode in ipairs(joined[at]) do
      if not seen[nextnode] then seen[nextnode]=true;queue[#queue+1]=nextnode end
    end
  end
  local connected=#queue==#p
  return mismatch,active,crossings,connected
end
local function solved()
  if not S then return false end
  local mismatch,_,crossings,connected=stats(S.points,S.edges,S.weights)
  return mismatch==0 and crossings==0 and connected
end
local function save()
  if not C or not C.storage or not S then return end
  local hist={}
  for _,w in ipairs(S.history) do hist[#hist+1]=code(w) end
  local data=table.concat({
    'version=1','level='..S.level,'unlocked='..S.unlocked,
    'weights='..code(S.weights),'history='..table.concat(hist,';')
  },'\n')
  pcall(function() C.storage:write('island-links.txt',data) end)
  pcall(function() C.storage:write('island-links-'..S.level..'.txt',data) end)
end
local function start(n,u)
  if n<1 or n>#LEVELS then return false end
  local p=nodes(n)
  local edges=links(p)
  S={level=n,unlocked=math.max(n,u or n),points=p,edges=edges,
     weights=fresh_weights(edges),history={}}
  MSG='Tap a link: one / two / none'
  save()
  return true
end
local function restore(filename,expected)
  if not C or not C.storage then return false end
  local ok,data=pcall(function() return C.storage:read(filename or 'island-links.txt') end)
  if not ok or type(data)~='string' then return false end
  local f={}
  for k,v in data:gmatch('([%w_]+)=([^\n]*)') do f[k]=v end
  if f.version~='1' then return false end
  local n,u=tonumber(f.level),tonumber(f.unlocked)
  if not n or n~=math.floor(n) or n<1 or n>#LEVELS or
     not u or u~=math.floor(u) or u<n or u>#LEVELS then return false end
  if expected and n~=expected then return false end
  local p=nodes(n)
  local edges=links(p)
  local weights=decode(f.weights,#edges)
  if not weights then return false end
  local hist={}
  for state in (f.history or ''):gmatch('[^;]+') do
    local w=decode(state,#edges)
    if not w or #hist>=24 then return false end
    hist[#hist+1]=w
  end
  S={level=n,unlocked=u,points=p,edges=edges,weights=weights,history=hist}
  MSG=nil
  return true
end
local function visit(n)
  local unlocked=S.unlocked
  save()
  if restore('island-links-'..n..'.txt',n) then
    S.unlocked=math.max(unlocked,S.unlocked)
    save()
  else start(n,unlocked) end
  return true
end
local function change(k)
  if not S or not S.edges[k] or solved() then return false end
  if #S.history>=24 then table.remove(S.history,1) end
  local copy={}
  for i,v in ipairs(S.weights) do copy[i]=v end
  S.history[#S.history+1]=copy
  S.weights[k]=(S.weights[k]+1)%3
  if solved() then
    S.unlocked=math.min(#LEVELS,math.max(S.unlocked,S.level+1))
    MSG='ALL ISLANDS CONNECTED!'
  else MSG=nil end
  save();return true
end
local function undo()
  if not S or #S.history==0 then return false end
  S.weights=table.remove(S.history)
  MSG='Last link restored'
  save();return true
end
local function reset()
  if not S then return false end
  return start(S.level,S.unlocked)
end
local function previous()
  if not S or S.level==1 then return false end
  return visit(S.level-1)
end
local function next_level()
  if not S or S.level>=#LEVELS or
    (S.level>=S.unlocked and not solved()) then return false end
  return visit(S.level+1)
end
local function font(which)
  return C and C.fonts and C.fonts[which or 'medium']
end
local UI=require('ui')
local Theme=require('theme')
local function put(g,x,y,s,which,align)
  UI.text(g,C,x,y,s,which,align)
end
local function centered(g,x,y,s,which) put(g,x,y,s,which,'center') end
local function button(g,x,y,w,h,s)
  UI.button(g,C,x,y,w,h,s)
end
local function pos(q) return OX+CELL*q.x,OY+CELL*q.y end
local function segment(g,p,q,offset)
  local x1,y1=pos(p);local x2,y2=pos(q)
  if y1==y2 then
    local a,b=math.min(x1,x2)+23,math.max(x1,x2)-23
    UI.stroke(g,a,y1+offset,b,y1+offset,4)
  else
    local a,b=math.min(y1,y2)+23,math.max(y1,y2)-23
    UI.stroke(g,x1+offset,a,x1+offset,b,4)
  end
end
local function draw(g)
  g:clear(0)
  put(g,22,17,'ISLAND LINKS','large')
  put(g,22,59,'PUZZLE '..S.level..' / '..#LEVELS,'medium')
  g:line(22,105,458,105)
  UI.region(OX+CELL-24,OY+CELL-24,4*CELL+48,4*CELL+48)
  for i,e in ipairs(S.edges) do
    local a,b=S.points[e.a],S.points[e.b]
    if S.weights[i]==0 then
      local x1,y1=pos(a);local x2,y2=pos(b)
      local cx,cy=(x1+x2)/2,(y1+y2)/2
      if y1==y2 then
        UI.stroke(g,cx-9,cy,cx+9,cy,2)
      else UI.stroke(g,cx,cy-9,cx,cy+9,2) end
    elseif S.weights[i]==1 then segment(g,a,b,0)
    else segment(g,a,b,-5);segment(g,a,b,5) end
  end
  for _,p in ipairs(S.points) do
    local x,y=pos(p)
    g:circle(x,y,21,{line_width=3})
    centered(g,x,y-16,tostring(p.need),'strong')
  end
  local mismatch,linksCount,cross,connected=stats(S.points,S.edges,S.weights)
  if solved() then centered(g,240,569,'NETWORK COMPLETE!','medium')
  else centered(g,240,569,'NUMBERS LEFT '..mismatch..'   CROSSES '..cross,'medium') end
  UI.paragraph(g,C,24,609,432,48,MSG or 'Connect every island into one network','small','center')
  button(g,22,684,103,72,S.level>1 and 'PREV' or 'START')
  button(g,133,684,104,72,'UNDO')
  button(g,245,684,104,72,'RESET')
  if S.level<#LEVELS and (solved() or S.level<S.unlocked) then
    button(g,357,684,101,72,'NEXT')
  elseif solved() then centered(g,411,717,'DONE','small') end
end
local function hit(x,y,a,b,w,h) return x>=a and x<a+w and y>=b and y<b+h end
local function touch(x,y)
  if hit(x,y,22,684,103,72) then return previous() end
  if hit(x,y,133,684,104,72) then return undo() end
  if hit(x,y,245,684,104,72) then return reset() end
  if hit(x,y,357,684,101,72) then return next_level() end
  local best=nil
  local distance=17
  for k,e in ipairs(S.edges) do
    local a,b=S.points[e.a],S.points[e.b]
    local x1,y1=pos(a);local x2,y2=pos(b)
    local d=nil
    if y1==y2 and x>math.min(x1,x2)+24 and x<math.max(x1,x2)-24 then
      d=math.abs(y-y1)
    elseif x1==x2 and y>math.min(y1,y2)+24 and y<math.max(y1,y2)-24 then
      d=math.abs(x-x1)
    end
    if d and d<distance then best=k;distance=d end
  end
  if best then return change(best) end
  return false
end
local function refresh()
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
    UI.error(g,C,'ISLAND LINKS',ERR)
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
      changed=touch(tonumber(e.x) or -1,tonumber(e.y) or -1)
    elseif e.type=='key' and (not e.phase or e.phase=='down') and
      (e.key=='up' or e.key=='down') then
      local now=tonumber(e.time_ms)
      if not now and C and C.clock then
        local yes,val=pcall(function() return C.clock:millis() end)
        if yes then now=tonumber(val) end
      end
      if now and now>=key_ms and now-key_ms<225 then return end
      if now then key_ms=now end
      if e.key=='up' then changed=previous() else changed=next_level() end
    end
  end)
  if not ok then ERR=tostring(err);changed=true end
  if changed then refresh() end
  return changed
end
function on_leave() Theme.release(); if S then save() end end
if rawget(_G,'__TEST') then
  __TEST.api={
    levels=LEVELS,nodes=nodes,links=links,crosses=crosses,stats=stats,
    start=start,restore=restore,change=change,undo=undo,reset=reset,
    next=next_level,prev=previous,
    state=function() return S end,solved=solved,pos=pos,touch=touch
  }
end
