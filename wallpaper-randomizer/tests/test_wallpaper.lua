-- End-to-end host checks for sleep selection, app controls and measured layout.
package.path='app/?.lua;'..package.path
package.loaded.xth={validate=function(raw)
  return type(raw)=='string' and raw:sub(1,4)=='XTH-', 'Invalid XTH'
end}
local W=require('wallpaper')
local P=require('probe')
local Canvas=dofile('../tests/game_canvas.lua')
local function entry(path)
  _G.__TEST={}
  dofile(path)
  return {load=on_load,draw=on_draw,tick=on_tick,input=on_input,leave=on_leave,resume=on_resume,
    test=__TEST.lock or __TEST.main}
end
local function add(disk,name)
  disk[name]='XTH-'..name
  local base=P.jpeg_prefix(name)
  disk[base..'.idx']=disk[name]
  disk[base..'.jpg']='\255\216'..name..'\255\217'
end
local function runtime(disk)
  local stats={decodes=0,alive=0,peak=0,draws=0,enables=0,disables=0,writes={},intervals={}}
  local c={disk=disk,active=false,confirm='approve',time=2147483647}
  local function list()
    local out={'../bad.xth','sub/bad.xth','has space.xth','legacy.jpg',false,{}}
    for name in pairs(disk) do out[#out+1]={name=name} end
    return out
  end
  c.files={list=list,read=function(_,name) return disk[name] end}
  c.storage={list=list,read=function(_,name) return disk[name] end,
    write=function(_,name,value)
      if name=='rotation.txt' and c.fail_history then return nil,'quota exceeded' end
      disk[name]=value;stats.writes[name]=(stats.writes[name] or 0)+1
    end}
  c.lock={reason='first',interval_sec=3600,set_interval=function(_,seconds)
    assert(seconds==3600);stats.intervals[#stats.intervals+1]=seconds
  end}
  c.lockscreen={
    is_default=function() return c.active end,
    set_default=function()
      stats.enables=stats.enables+1
      if c.confirm=='fail' then return nil,'request failed' end
      if c.confirm=='approve' then c.active=true end
      return true
    end,
    clear_default=function()
      stats.disables=stats.disables+1
      if c.fail_disable then return nil,'request failed' end
      c.active=false;return true
    end
  }
  c.image={decode=function(_,bytes)
    stats.decodes=stats.decodes+1
    if bytes:find('BROKEN',1,true) then return nil,'native rejected JPEG' end
    stats.alive=stats.alive+1;stats.peak=math.max(stats.peak,stats.alive)
    local released=false
    return {width=480,height=800,bytes=bytes,release=function()
      assert(not released);released=true;stats.alive=stats.alive-1
    end}
  end}
  c.clock={millis=function() return c.time end,now=function() return {epoch_sec=1794078000} end}
  c.gc={collect=function() end};c.budget={extend=function() end}
  c.layers={create=function() error('sleep must never allocate a PNG compositor layer') end}
  c.after=function() error('sleep must never enqueue strip callbacks') end
  c.fonts=Canvas.fonts();c.invalidate=function() end
  local g={clear=function() end,text=function() end,line=function() end,rect=function() end,
    image=function(_,image,x,y)
      assert(x==0 and y==0);stats.draws=stats.draws+1;stats.last=image.bytes
      if c.fail_draw then return nil,'native draw rejected' end
    end}
  return c,stats,g
end
local function tap(app,c,x,y)
  return app.input(c,{type='pointer',phase='up',gesture='tap',x=x,y=y})
end
local disk={}
for _,name in ipairs({'alpha.xth','bravo.xth','charlie.XTH'}) do add(disk,name) end
disk['unprepared.xth']='XTH-NEEDS-PREPARATION'
local c,stats,g=runtime(disk)
local names,missing=W.scan(c)
assert(#names==3 and missing==1,'only complete, flat prepared sets are eligible')
local truncated=runtime(disk)
truncated.files.list=function() return {'alpha.xth'} end
truncated.storage.list=truncated.files.list
truncated.storage.exists=function(_,name) return disk[name]~=nil end
assert(#W.scan(truncated)==1,'capped directory listings must not hide prepared JPEGs')
assert(W.choose(0,nil,1,0)==nil and W.choose(1,nil,1,0)==1)
for n=2,16 do
  for last=1,n do
    for _,seq in ipairs({0,1,8388592,99999999}) do
      for _,tick in ipairs({-2147483648,0,1794078000,2147483647}) do
        local i=W.choose(n,last,seq,tick)
        assert(i>=1 and i<=n and i~=last and i==math.floor(i))
      end
    end
  end
end
local previous
for i=1,100 do
  c.time=c.time-1;c.lock.reason='first'
  local lock=entry('app/lockscreen.lua')
  local before=disk['rotation.txt']
  lock.load(c)
  assert(disk['rotation.txt']==before,'loading alone must not advance successful history')
  local current=lock.test.current()
  assert(current~=previous,'a new sleep must avoid the previous usable image')
  lock.draw(c,g)
  assert(W.history(c).last==current and W.history(c).sequence==i)
  local saved=disk['rotation.txt']
  local writes=stats.writes['rotation.txt']
  local decoded=stats.decodes
  lock.draw(c,g);lock.tick(c);lock.tick(c)
  assert(disk['rotation.txt']==saved and stats.writes['rotation.txt']==writes)
  assert(stats.decodes==decoded,'redraw/ticks must reuse the one decoded image')
  assert(disk['diagnostics.txt']:find('status=rendered',1,true))
  lock.leave();assert(stats.alive==0);previous=current
end
assert(stats.peak==1 and stats.disables==0,'sleep must not disable itself or retain many images')
assert(not disk['preview-diagnostics.txt'] and not disk['preview-timing.txt'],'sleep must not run verbose preview probes')

-- A fresh timer session must render the saved frame without selection/history writes.
local saved=disk['rotation.txt']
local history_writes=stats.writes['rotation.txt']
for _,reason in ipairs({'timer','timer','resume','timer'}) do
  c.lock.reason=reason
  local lock=entry('app/lockscreen.lua');lock.load(c);lock.draw(c,g)
  assert(lock.test.current()==previous and disk['rotation.txt']==saved)
  assert(stats.writes['rotation.txt']==history_writes)
  lock.leave();assert(stats.alive==0)
end
assert(disk['diagnostics.txt']:find('interval=3600',1,true))

-- Neither failed draws nor failed decoding may advance the deck.
c.lock.reason='first';c.fail_draw=true
local lock=entry('app/lockscreen.lua');lock.load(c);lock.draw(c,g);lock.leave()
assert(disk['rotation.txt']==saved and stats.alive==0)
assert(disk['diagnostics.txt']:find('status=draw-error',1,true))
c.fail_draw=false;c.fail_history=true
local lock=entry('app/lockscreen.lua');lock.load(c);lock.draw(c,g);lock.leave()
assert(disk['rotation.txt']==saved and stats.alive==0)
assert(disk['diagnostics.txt']:find('status=rendered-history-error',1,true))
c.fail_history=false

-- Empty/single/malformed collections, a stale source, and a bad alternative.
local one={};add(one,'one.xth')
local sc,ss,sg=runtime(one)
for i=1,2 do
  local lock=entry('app/lockscreen.lua');lock.load(sc);lock.draw(sc,sg)
  assert(W.history(sc).last=='one.xth' and W.history(sc).sequence==i)
  lock.leave()
end
local old=one['rotation.txt']
one['one.xth']='XTH-REPLACED-SAME-NAME'
sc.lock.reason='timer'
local lock=entry('app/lockscreen.lua');lock.load(sc);lock.draw(sc,sg);lock.leave()
assert(one['rotation.txt']==old,'a stale timer image must never pick a replacement')
assert(one['diagnostics.txt']:find('status=load-error',1,true))
one['one.xth']='XTH-one.xth'
add(one,'broken.xth')
one[P.jpeg_prefix('broken.xth')..'.jpg']='\255\216BROKEN\255\217'
sc.lock.reason='first'
local lock=entry('app/lockscreen.lua');lock.load(sc);lock.draw(sc,sg);lock.leave()
assert(W.history(sc).last=='one.xth','a bad alternative must not prevent the remaining good image')
local empty,es,eg=runtime({})
empty.lock.reason='timer'
local lock=entry('app/lockscreen.lua');lock.load(empty);lock.draw(empty,eg);lock.leave()
assert(es.decodes==0 and not empty.disk['rotation.txt'])
Canvas.check(empty,lock.draw,'empty sleep fallback')
empty.disk['rotation.txt']='sequence='..string.rep('9',400)..'\nlast=../../bad.xth\n'
assert(W.history(empty).sequence==0,'malformed huge history counter must be bounded')
assert(W.history(empty).last==nil,'invalid saved filenames must not reach the file API')

-- Main app: preserve enabled state; preview never changes the sleep deck.
c.lock.reason='first';c.active=true
local main=entry('app/index.lua');main.load(c)
assert(c.active and stats.disables==0,'opening the app must preserve enablement')
Canvas.check(c,main.draw,'enabled settings')
local saved=disk['rotation.txt']
tap(main,c,100,370);assert(main.test.is_preview());main.draw(c,g)
local first_preview=stats.last
tap(main,c,200,200);tap(main,c,100,370);main.draw(c,g)
assert(stats.last~=first_preview and disk['rotation.txt']==saved)
tap(main,c,200,200)
assert(stats.alive==0)
tap(main,c,100,290)
assert(not c.active and stats.disables==1)
Canvas.check(c,main.draw,'disabled settings')
tap(main,c,100,290)
assert(c.active and stats.enables==1 and stats.alive==0)
main.leave();main.load(c)
assert(c.active and stats.disables==1,'relaunch must preserve the firmware default')
tap(main,c,300,450);Canvas.check(c,main.draw,'help screen')
tap(main,c,100,700)
-- Touch down and non-tap gestures must not toggle.
main.input(c,{type='pointer',phase='down',x=100,y=290})
main.input(c,{type='pointer',phase='up',gesture='swipe_up',x=100,y=290})
assert(c.active)
c.fail_disable=true;tap(main,c,100,290)
assert(c.active and main.test.status():find('Could not disable',1,true))
Canvas.check(c,main.draw,'disable error')
c.fail_disable=false;tap(main,c,100,290)
c.confirm='deferred';tap(main,c,100,290)
assert(not c.active)
Canvas.check(c,main.draw,'system approval pending')
c.active=true;main.resume(c);Canvas.check(c,main.draw,'approved system prompt')
tap(main,c,100,290)
c.confirm='cancel';tap(main,c,100,290);main.resume(c)
assert(not c.active,'cancelled system confirmation must never claim enabled')
Canvas.check(c,main.draw,'cancelled system prompt')
c.confirm='fail';tap(main,c,100,290)
assert(not c.active);Canvas.check(c,main.draw,'failed system prompt')
c.lockscreen=nil;main.load(c);tap(main,c,100,290)
Canvas.check(c,main.draw,'unsupported controls')
main.leave()

-- Rescan exposes newly prepared frames; empty/error screens remain measured.
local ec,ee=runtime({})
local main=entry('app/index.lua');main.load(ec)
Canvas.check(ec,main.draw,'no images')
tap(main,ec,100,290);assert(ee.enables==0)
tap(main,ec,100,370);Canvas.check(ec,main.draw,'preview unavailable')
add(ec.disk,'new.xth');tap(main,ec,100,450)
assert(#main.test.names()==1);Canvas.check(ec,main.draw,'rescanned images')
tap(main,ec,100,370);assert(main.test.is_preview());main.leave()
assert(ee.alive==0)
print('Sleep wallpaper: 100 new sleeps, fixed timer frames, transactional history, failures, controls and measured layouts PASS')
