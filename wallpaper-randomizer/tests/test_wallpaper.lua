-- Host lifecycle tests; byte-level renderer tests live in test_xth.py.
package.path='app/?.lua;'..package.path
package.loaded.xth={open=function(_,bytes)
  if bytes=='BROKEN' then return nil,'Invalid XTH' end
  return {draw=function(_,g) g:image({bytes=bytes},0,0);return true end,release=function() end}
end}
_G.__TEST={}
local pictures={['alpha.xth']='XTH-ALPHA',['bravo.xth']='XTH-BRAVO',['charlie.XTH']='XTH-CHARLIE'}
local storage,frames={},{}
local now,enabled=1000000,0
local ctx={
  files={
    list=function()
      local out={'note.txt','../bad.xth','legacy.jpg','legacy.png'}
      for name in pairs(pictures) do out[#out+1]={name=name} end
      return out
    end,
    read=function(_,name) return pictures[name] or storage[name] end
  },
  storage={list=function() return {'rotation.txt'} end,
    read=function(_,name) return storage[name] end,
    write=function(_,name,value) storage[name]=value end},
  lock={reason='first',interval_sec=3600,set_interval=function(_,seconds) assert(seconds==31536000) end},
  lockscreen={set_default=function() enabled=enabled+1;return true end},
  clock={millis=function() return now end,now=function() return {epoch_sec=1700000000} end},
  fonts={small={},medium={},large={}},invalidate=function() end
}
local g={clear=function() end,text=function() end,line=function() end,rect=function() end,
  image=function(_,obj,x,y) assert(x==0 and y==0);frames[#frames+1]=obj.bytes end}
dofile('app/lockscreen.lua')
local lock=__TEST.lock
assert(#lock.filenames(ctx)==3,'only flat XTH filenames accepted')
assert(lock.choose(0)==nil and lock.choose(1,nil,9,9)==1)
local previous
for _=1,100 do
  now=now+1
  on_load(ctx)
  local current=lock.current()
  assert(current~=previous,'no immediate repeat')
  on_draw(ctx,g)
  assert(frames[#frames]==pictures[current],'selected XTH rendered')
  on_draw(ctx,g)
  assert(lock.current()==current,'redraw must not advance')
  on_tick(ctx)
  assert(lock.current()==current,'tick must not advance')
  previous=current
  on_leave()
end
assert(storage['diagnostics.txt']:find('interval=3600',1,true),'report host clamp truthfully')
ctx.lock.reason='timer'
local saved=storage['rotation.txt']
for _=1,5 do on_load(ctx);assert(lock.current()==previous);on_leave() end
assert(storage['rotation.txt']==saved,'timer wakes neither rotate nor advance history')
ctx.lock.reason='first'
pictures={['one.xth']='XTH-ONE'}
on_load(ctx);assert(lock.current()=='one.xth');on_leave()
on_load(ctx);assert(lock.current()=='one.xth');on_leave()
pictures={}
on_load(ctx);assert(lock.current()==nil and lock.error():find('Add XTH',1,true));on_draw(ctx,g)
pictures={['broken.xth']='BROKEN'}
on_load(ctx);assert(lock.error()=='Invalid XTH');on_draw(ctx,g)
pictures={['one.xth']='XTH-ONE',['two.xth']='XTH-TWO'}
_G.__TEST={}
dofile('app/index.lua')
on_load(ctx)
local main=__TEST.main
assert(#main.names()==2 and enabled==0,'enable is opt-in')
on_input(ctx,{type='pointer',phase='up',gesture='tap',x=100,y=450})
assert(enabled==1)
on_input(ctx,{type='pointer',phase='up',gesture='tap',x=300,y=540})
assert(main.is_preview());on_draw(ctx,g)
on_input(ctx,{type='pointer',phase='up',gesture='tap',x=200,y=200})
assert(not main.is_preview())
print('XTH wallpaper: rotation, timer stability, preview, diagnostics and error checks passed')
