-- ODDITY HUNT: original illustrated seek-and-find game for XTEINK X4 Pro.
-- Static black-and-white drawing; no animations, update loop or timers.
local UI=require('ui')
local Theme=require('theme')
local Scenes=require('scenes')
local Art=require('art')
local TOTAL=#Scenes.LEVELS
local TARGETS=5
local ALL_FOUND=31
local C,S,ERR,MSG=nil,nil,nil,nil
local HELP=false
local last_key_ms=-1000

local function filled(n,value)
  local out={}
  for i=1,n do out[i]=value end
  return out
end
local function bit(i) return math.floor(2^(i-1)) end
local function has(mask,i) return math.floor(mask/bit(i))%2==1 end
local function found_count(mask)
  local count=0
  for i=1,TARGETS do if has(mask,i) then count=count+1 end end
  return count
end
local function scene_found(level)
  return S.progress[level]==ALL_FOUND
end
local function encode(values)
  local strings={}
  for i,v in ipairs(values) do strings[i]=tostring(math.floor(v)) end
  return table.concat(strings,',')
end
local function decode(text,max)
  if type(text)~='string' or text=='' then return nil end
  local values={}
  for value in text:gmatch('[^,]+') do
    local n=tonumber(value)
    if n==nil or n~=math.floor(n) or n<0 or n>max then return nil end
    values[#values+1]=n
  end
  if #values~=TOTAL then return nil end
  return values
end
local function save()
  if not S or not C or not C.storage then return end
  local data=table.concat({
    'version=1',
    'level='..S.level,
    'unlocked='..S.unlocked,
    'progress='..encode(S.progress),
    'misses='..encode(S.misses),
    'hints='..encode(S.hints),
    'revealed='..encode(S.revealed)
  },'\n')
  pcall(function() C.storage:write('oddity-hunt.txt',data) end)
end
local function start()
  S={
    level=1,unlocked=1,
    progress=filled(TOTAL,0),
    misses=filled(TOTAL,0),
    hints=filled(TOTAL,0),
    revealed=filled(TOTAL,0)
  }
  S.scene=Scenes.build(1)
  HELP=false
  MSG='Find five objects in the drawing'
  save()
end
local function restore()
  if not C or not C.storage then return false end
  local ok,text=pcall(function() return C.storage:read('oddity-hunt.txt') end)
  if not ok or type(text)~='string' then return false end
  local fields={}
  for key,value in text:gmatch('([%w_]+)=([^\n]*)') do fields[key]=value end
  if fields.version~='1' then return false end
  local level,unlocked=tonumber(fields.level),tonumber(fields.unlocked)
  if not level or level~=math.floor(level) or level<1 or level>TOTAL or
     not unlocked or unlocked~=math.floor(unlocked) or
     unlocked<level or unlocked>TOTAL then return false end
  local progress=decode(fields.progress,ALL_FOUND)
  local misses=decode(fields.misses,9999)
  local hints=decode(fields.hints,2)
  local revealed=decode(fields.revealed,TARGETS)
  if not progress or not misses or not hints or not revealed then return false end
  for i=1,TOTAL do
    if progress[i]==ALL_FOUND and i<TOTAL and unlocked<i+1 then return false end
    if revealed[i]>0 and has(progress[i],revealed[i]) then return false end
    if hints[i]==0 and revealed[i]>0 then return false end
  end
  S={
    level=level,unlocked=unlocked,progress=progress,misses=misses,
    hints=hints,revealed=revealed
  }
  S.scene=Scenes.build(level)
  MSG=nil
  HELP=false
  return true
end
local function visit(n)
  if not S or n<1 or n>TOTAL or n>S.unlocked then return false end
  S.level=n
  S.scene=Scenes.build(n)
  MSG=nil
  HELP=false
  save()
  return true
end
local function previous() return S and visit(S.level-1) or false end
local function next_level()
  return S and visit(S.level+1) or false
end
local function reset()
  if not S then return false end
  local n=S.level
  S.progress[n]=0
  S.misses[n]=0
  S.hints[n]=0
  S.revealed[n]=0
  MSG='Fresh search'
  save()
  return true
end
local function hint()
  if not S then return false end
  local n=S.level
  if scene_found(n) then return false end
  if S.revealed[n]~=0 then
    MSG='Follow the double ring'
    return true
  end
  if S.hints[n]>=2 then
    MSG='No hints left on this shelf'
    return true
  end
  for i=1,TARGETS do
    if not has(S.progress[n],i) then
      S.revealed[n]=i
      S.hints[n]=S.hints[n]+1
      MSG='One hidden item is ringed'
      save()
      return true
    end
  end
  return false
end
local function pick(slot)
  if not S then return false end
  local object=S.scene.objects[slot]
  if not object or scene_found(S.level) then return false end
  local target=object.target
  if target==0 then
    S.misses[S.level]=math.min(9999,S.misses[S.level]+1)
    MSG='Not one of the five objects'
    save()
    return true
  end
  if has(S.progress[S.level],target) then return false end
  S.progress[S.level]=S.progress[S.level]+bit(target)
  if S.revealed[S.level]==target then S.revealed[S.level]=0 end
  MSG='Found '..Scenes.KINDS[object.kind]..'!'
  if scene_found(S.level) then
    S.unlocked=math.min(TOTAL,math.max(S.unlocked,S.level+1))
    MSG='All five found - shelf complete!'
  end
  save()
  return true
end
local function touch_object(x,y)
  local chosen=nil
  local best=24*24
  for i,object in ipairs(S.scene.objects) do
    local dx,dy=x-object.x,y-object.y
    local d=dx*dx+dy*dy
    if d<best then chosen,best=i,d end
  end
  return chosen and pick(chosen) or false
end
local function text(g,x,y,message,style,align,width)
  UI.text(g,C,x,y,message,style,align,width)
end
local function button(g,x,y,w,h,label)
  UI.button(g,C,x,y,w,h,label)
end
local function chip(g,x,y,label,checked)
  g:rect(x,y,140,40,{line_width=1})
  g:rect(x+8,y+10,20,20,{line_width=2})
  if checked then
    g:line(x+11,y+20,x+16,y+26,{line_width=2})
    g:line(x+16,y+26,x+25,y+13,{line_width=2})
  end
  text(g,x+34,y+10,label,'small',nil,102)
end
local function help_screen(g)
  text(g,240,154,'HOW TO HUNT','large','center',360)
  UI.paragraph(g,C,28,211,424,122,
    'Search each shelf for the five named objects. Tap the pictured object, not the word.', 'medium')
  UI.paragraph(g,C,28,352,424,110,
    'A found object receives a circle and a check mark on your list. No countdown or moving objects.', 'medium')
  UI.paragraph(g,C,28,479,424,110,
    'HINT outlines one missing object. Two hints per scene. RETRY only resets this shelf.', 'medium')
  button(g,77,702,326,68,'BACK TO SHELF')
end
local function draw(g)
  g:clear(0)
  text(g,24,15,'ODDITY HUNT','large',nil,345)
  button(g,398,12,58,46,HELP and 'X' or '?')
  text(g,25,60,'SCENE '..S.level..'/'..TOTAL..'  '..S.scene.name,'medium',nil,424)
  text(g,25,99,MSG or 'Five objects are hidden here','small',nil,425)
  g:line(23,126,457,126,{line_width=2})
  if HELP then help_screen(g);return end

  UI.region(18,137,444,414)
  g:rect(18,137,444,414,{line_width=3})
  for i=0,4 do
    local lineY=204+i*70
    g:line(24,lineY,456,lineY,{line_width=1})
  end
  local mask=S.progress[S.level]
  for _,object in ipairs(S.scene.objects) do
    Art.draw(g,object.kind,object.x,object.y,object.slot)
    if object.target>0 and has(mask,object.target) then
      g:circle(object.x,object.y,25,{line_width=2})
    elseif S.revealed[S.level]==object.target and object.target>0 then
      g:circle(object.x,object.y,24,{line_width=2})
      g:circle(object.x,object.y,27,{line_width=1})
    end
  end
  local labels=S.scene.targets
  for i=1,TARGETS do
    local x=i<=3 and 24+(i-1)*146 or 97+(i-4)*147
    local y=i<=3 and 559 or 612
    chip(g,x,y,Scenes.KINDS[labels[i]],has(mask,i))
  end
  local status='FOUND '..found_count(mask)..'/5   MISSES '..S.misses[S.level]..
     '   HINTS '..S.hints[S.level]..'/2'
  text(g,240,664,status,'small','center',430)
  button(g,20,707,100,67,S.level>1 and 'PREV' or 'START')
  button(g,133,707,100,67,'RETRY')
  button(g,246,707,100,67,'HINT')
  if S.level<TOTAL and S.level<S.unlocked then
    button(g,359,707,101,67,'NEXT')
  elseif scene_found(S.level) then
    text(g,409,730,'DONE','small','center',91)
  end
end
local function hit(x,y,bx,by,w,h)
  return x>=bx and x<bx+w and y>=by and y<by+h
end
local function tap(x,y)
  if hit(x,y,398,12,58,46) then HELP=not HELP;return true end
  if HELP then
    if hit(x,y,77,702,326,68) then HELP=false;return true end
    return false
  end
  if hit(x,y,20,707,100,67) then return previous() end
  if hit(x,y,133,707,100,67) then return reset() end
  if hit(x,y,246,707,100,67) then return hint() end
  if hit(x,y,359,707,101,67) then return next_level() end
  if hit(x,y,18,137,444,414) then return touch_object(x,y) end
  return false
end
local function refresh()
  if C then pcall(function() C:invalidate() end) end
end
function on_load(context)
  Theme.release()
  C=context or ctx
  ERR=nil
  local ok,e=pcall(function() if not restore() then start() end end)
  if not ok then ERR=tostring(e) end
end
function on_draw(context,g)
  if context then C=context end
  if not g then return end
  if ERR then UI.error(g,C,'ODDITY HUNT',ERR);return end
  local ok,e=pcall(function() Theme.draw(C,g,draw) end)
  if not ok then ERR=tostring(e);UI.error(g,C,'ODDITY HUNT',ERR) end
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
      if now and now>=last_key_ms and now-last_key_ms<230 then return end
      if now then last_key_ms=now end
      if event.key=='up' then changed=previous() else changed=next_level() end
    end
  end)
  if not ok then ERR=tostring(e);changed=true end
  if changed then refresh() end
  return changed
end
function on_leave() Theme.release(); if S then save() end end

if rawget(_G,'__TEST') then
  __TEST.api={
    levels=Scenes.LEVELS,kinds=Scenes.KINDS,build=Scenes.build,
    state=function() return S end,
    pick=pick,tap=tap,hint=hint,reset=reset,
    prev=previous,next=next_level,visit=visit,
    found=has,found_count=found_count,
    done=function() return scene_found(S.level) end,
    restore=restore,touch=touch_object
  }
end
