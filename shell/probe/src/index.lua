-- Diagnostic native-font baseline, not the final shell visual theme.
local UI=require('ui')
local Marker=require('marker')
local Config=require('config')
local page=1
local S,C,inventory,status,writable=nil,nil,{},'',false
local buttons={{x=24,y=568,w=432,h=58,label='Refresh inventory'},{x=24,y=642,w=432,h=58,label='Save marker'}}
buttons[3]={x=24,y=504,w=208,h=48,label='Page'}
buttons[4]={x=248,y=504,w=208,h=48,label='Next trial'}
local function member(t,k)
  local ok,v=pcall(function()return t and t[k] end)
  if ok then return v end
end
local function num(v,max)
  return type(v)=='number' and v==v and v>=0 and v<=max and v==math.floor(v) and v or nil
end
local function text(v) return v==nil and 'unknown' or tostring(v) end
local function kind(v)
  if v==nil then return 'absent' end
  local t=type(v)
  if t=='function' or t=='table' or t=='userdata' or t=='string' or t=='number' or t=='boolean' then return t end
  return 'other'
end
local function invalidate() if C and C.invalidate then C:invalidate() end end
local function refresh()
  local d,a,sys=member(C,'device'),member(C,'api'),member(C,'system')
  local model=member(d,'model')
  local known={['X4 Pro']='X4 Pro',['XTEINK X4 Pro']='X4 Pro',['XTEINK_X4_PRO']='X4 Pro',['X4']='X4',['X3']='X3'}
  inventory={hardware_model=type(model)=='string' and known[model] or nil,
    runtime_api_major=num(member(a,'major'),999),runtime_api_minor=num(member(a,'minor'),999),
    lua_version=_VERSION,system_can_open_type=kind(member(sys,'can_open')),system_open_type=kind(member(sys,'open')),
    gc_count_unit='unknown'}
  local fw=member(d,'firmware')
  if type(fw)=='number' then fw=tostring(fw) end
  if type(fw)=='string' and #fw<=64 and fw:match('^%d[%d%.]*$') then inventory.firmware_build=fw end
  local ok,usage=pcall(function()return C.storage:usage() end)
  if ok and type(usage)=='table' then
    for _,k in ipairs({'used_bytes','used_files','max_bytes','max_files'}) do
      inventory['storage_'..k]=num(usage[k],k:find('files') and 4096 or 2147483647)
    end
  end
  local good,count=pcall(collectgarbage,'count')
  if good and type(count)=='number' and count>=0 and count<=2147483647 then inventory.gc_count_raw=count end
end
local function restore()
  local ok,raw,reason=pcall(function()return C.storage:read(Marker.name) end)
  writable=false
  if not ok or (raw==nil and reason~='not_found') then status='Load failed; writes blocked';return end
  if raw~=nil then
    local parsed=Marker.decode(raw)
    if not parsed then status='Invalid marker; writes blocked';return end
    S=parsed;status='Marker loaded; changes unsaved'
  else status='No marker; changes unsaved' end
  writable=true
end
local function save()
  if not writable then status='Writes blocked; reload app';return end
  if S.sequence>=999999998 then status='Counter limit; writes blocked';writable=false;return end
  local next_state={}
  for k,v in pairs(S) do next_state[k]=v end
  next_state.sequence=S.sequence+1
  next_state.last_event='save'
  local raw=Marker.encode(next_state)
  local ok,result=pcall(function()return C.storage:write(Marker.name,raw) end)
  if not ok or result~=true then status='Save failed; reload app';writable=false;return end
  local readok,back=pcall(function()return C.storage:read(Marker.name) end)
  if not readok or back~=raw or not Marker.decode(back) then status='Readback failed; reload app';writable=false;return end
  S.sequence=next_state.sequence;S.last_event='save';status='Saved; readback verified'
end
function on_load(ctx)
  C=ctx;page=1
  S={selected_trial='dp3_manual_relaunch',sequence=0,load_count=0,tap_count=0,leave_count=0,last_event='load'}
  restore()
  if S.load_count>=999999998 then writable=false;status='Counter limit; writes blocked'
  else S.load_count=S.load_count+1 end
  S.last_event='load';refresh();invalidate()
end
function on_draw(ctx,g)
  inventory.screen_width=nil;inventory.screen_height=nil
  local ok,w,h=pcall(function()return g:size() end)
  if ok then
    inventory.screen_width=num(w,4096);inventory.screen_height=num(h,4096)
    if inventory.screen_width==0 then inventory.screen_width=nil end
    if inventory.screen_height==0 then inventory.screen_height=nil end
  end
  g:clear(0)
  UI.text(g,ctx,24,20,'Shell Probe','large')
  UI.text(g,ctx,24,64,'Manual diagnostic / native fonts','small')
  local lines={
    'Model: '..text(inventory.hardware_model),
    'Firmware: '..text(inventory.firmware_build),
    'Runtime API: '..text(inventory.runtime_api_major)..'.'..text(inventory.runtime_api_minor),
    'Screen: '..text(inventory.screen_width)..' x '..text(inventory.screen_height),
    'system.can_open: '..inventory.system_can_open_type,
    'system.open: '..inventory.system_open_type,
    'Trial: '..S.selected_trial,
    'Loads '..S.load_count..' / taps '..S.tap_count,
    'Saved sequence: '..S.sequence,
    'Leave count is memory-only: '..S.leave_count,
    status,
  }
  if page==2 then
    local extra={'Lua: '..text(inventory.lua_version),'Used bytes: '..text(inventory.storage_used_bytes),
      'Used files: '..text(inventory.storage_used_files),'Max bytes: '..text(inventory.storage_max_bytes),
      'Max files: '..text(inventory.storage_max_files),'GC raw: '..text(inventory.gc_count_raw),
      'GC unit: '..inventory.gc_count_unit}
    for i,s in ipairs(extra) do lines[i]=s end
  end
  for i,s in ipairs(lines) do UI.text(g,ctx,24,104+(i-1)*36,s,'small',nil,432) end
  for _,b in ipairs(buttons) do UI.button(g,ctx,b.x,b.y,b.w,b.h,b.label) end
  UI.paragraph(g,ctx,24,720,432,72,'Use the native Home pad to exit. Only Save writes. No navigation calls.','small')
end
function on_input(ctx,event)
  if event.type~='pointer' or event.phase~='up' or event.gesture~='tap' then return false end
  if type(event.x)~='number' or type(event.y)~='number' then return false end
  for i,b in ipairs(buttons) do
    if event.x>=b.x and event.x<b.x+b.w and event.y>=b.y and event.y<b.y+b.h then
      if S.tap_count>=999999998 then writable=false;status='Counter limit; writes blocked'
      else
        S.tap_count=S.tap_count+1;S.last_event='tap'
        if i~=2 and writable then status='Changes unsaved; press Save' end
        if i==1 then refresh()
        elseif i==2 then save()
        elseif i==3 then page=3-page
        else
          for n,id in ipairs(Config.trials) do
            if S.selected_trial==id then S.selected_trial=Config.trials[n%#Config.trials+1];break end
          end
          S.last_event='trial_selected'
        end
      end
      invalidate();return true
    end
  end
  return false
end
function on_leave()
  if S and S.leave_count<999999998 then S.leave_count=S.leave_count+1;S.last_event='leave' end
  -- No storage writes: native escape must not depend on persistence.
end
if rawget(_G,'__TEST') then
  __TEST.api={state=function()return S,status,writable end,inventory=function()return inventory end,buttons=buttons}
end
