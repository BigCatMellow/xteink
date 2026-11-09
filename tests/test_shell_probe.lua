package.path='dist/shell-probe/app/?.lua;tests/?.lua;'..package.path
local T=require('game_canvas')
local Marker=require('marker')
local files,reads,writes,mode={},0,0,nil
local storage={}
function storage:read(name)
  assert(name==Marker.name);reads=reads+1
  if mode=='readfail' then return nil,'io_failure' end
  if mode=='readthrow' then error('private error must not be displayed') end
  if mode=='readback' and writes>0 then return 'bad' end
  return files[name],files[name]==nil and 'not_found' or nil
end
function storage:write(name,raw)
  assert(name==Marker.name and #raw<=2048);writes=writes+1
  if mode=='writefail' then return nil,'quota' end
  if mode=='writethrow' then error('private error must not be displayed') end
  files[name]=raw;return true
end
function storage:usage() return {used_bytes=0,used_files=0,max_bytes=134217728,max_files=512} end
local calls=0
local ctx={storage=storage,fonts=T.fonts(),invalidate=function(self)assert(self.storage==storage)end,
 device={model='X4 Pro',firmware='26110201',id_for_app='DO_NOT_CAPTURE'},api={major=2,minor=18},
 system={can_open=function()calls=calls+1;error('must not invoke')end,open=function()calls=calls+1;error('must not invoke')end}}
_G.__TEST={};dofile('dist/shell-probe/app/index.lua')
local A=__TEST.api
local function state()return A.state()end
local function tap(x,y,phase,gesture)
 return on_input(ctx,{type='pointer',phase=phase or 'up',gesture=gesture or 'tap',x=x,y=y})
end
local frames=0
local function draw(label)
 for _,scale in ipairs({1,1.25}) do
  ctx.fonts=T.fonts(scale)
  local g=T.canvas();function g:size()return 480,800 end
  local count=0
  for _,name in ipairs({'clear','line','rect','circle','text'})do
   local original=g[name];g[name]=function(self,...)count=count+1;return original(self,...)end
  end
  g:reset();on_draw(ctx,g);g:verify(label);assert(count<100);frames=frames+1
 end
end
local function load()on_load(ctx);assert(writes==0,'automatic load write')end
load();assert(state().load_count==1);draw('new marker')
assert(not tap(50,580,'down'));assert(not tap(50,580,'up','long'))
assert(not tap(23,580));assert(not tap(456,580));assert(not tap(50,626))
assert(state().tap_count==0)
assert(tap(24,568));assert(state().tap_count==1 and writes==0)
assert(tap(455,699));assert(writes==1 and state().sequence==1)
local saved=files[Marker.name];assert(Marker.decode(saved));draw('saved')
on_leave();assert(writes==1 and state().leave_count==1)
writes=0;load();assert(state().load_count==2 and state().tap_count==2 and state().leave_count==0)
assert(files[Marker.name]==saved);draw('reloaded')
assert(not tap(232,510));assert(not tap(247,510));assert(not tap(250,552))
tap(30,510);draw('inventory page 2');tap(250,510);assert(state().selected_trial=='dp3_sleep_01')
assert(writes==0);tap(50,660);local selected=state().selected_trial;assert(writes==1)
writes=0;load();assert(state().selected_trial==selected);draw('selected trial reloaded')
for _,failure in ipairs({'readfail','readthrow'})do
 mode=failure;writes=0;load();tap(50,660);assert(writes==0);draw(failure)
 local _,status,writable=A.state();assert(not writable and status:find('blocked'))
end
for _,bad in ipairs({'bad',string.rep('x',2049),saved:gsub('"sequence":1','"sequence":99999999999'),saved:gsub('xteinkshellprobe','wrong')}) do
 mode=nil;files[Marker.name]=bad;writes=0;load();tap(50,660);assert(writes==0);draw('malformed')
end
for _,failure in ipairs({'writefail','writethrow','readback'})do
 mode=nil;files[Marker.name]=saved;writes=0;load();mode=failure
 tap(50,660);assert(state().sequence==1);local _,message,allowed=A.state();assert(not allowed and message:find('failed'))
 local previous=writes;tap(50,660);assert(writes==previous,'failed save silently retried');draw(failure)
end
mode=nil;files[Marker.name]=saved;writes=0;load()
ctx.device.model='X4 Pro serial SECRET';ctx.device.firmware='SECRET';tap(50,580)
assert(A.inventory().hardware_model==nil and A.inventory().firmware_build==nil)
assert(A.inventory().id_for_app==nil);assert(calls==0)
ctx.system.open=coroutine.create(function()end);tap(50,580);assert(A.inventory().system_open_type=='other')
local g=T.canvas();g:reset();on_draw(ctx,g);g:verify('unknown size');assert(A.inventory().screen_width==nil)
function g:size()return 0,0 end
g:reset();on_draw(ctx,g);g:verify('invalid size');assert(A.inventory().screen_width==nil and A.inventory().screen_height==nil)
ctx.device=nil;ctx.api=nil;ctx.system=nil;tap(50,580);draw('absent optional capabilities')
assert(A.inventory().hardware_model==nil and A.inventory().runtime_api_major==nil)
assert(A.inventory().system_can_open_type=='absent' and A.inventory().system_open_type=='absent')
on_leave();assert(writes==0)
print('Shell Probe: persistence, read/write/readback failures, privacy, tap boundaries and '..frames..' guarded frames PASS')
