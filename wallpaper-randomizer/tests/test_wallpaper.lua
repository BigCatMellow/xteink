-- Host lifecycle tests; byte-level renderer tests live in test_xth.py.
package.path='app/?.lua;'..package.path
package.loaded.xth={compose=function(c,bytes,complete,note,options)
  assert(options and options.name=='one.xth','full preview must pass its source name to the persistent cache')
  local released=false
  local picture={draw=function(_,g) g:image({bytes=bytes},0,0);return true end,
    release=function() released=true end,
    metrics={total_ms=1234,cache_hits=25,encoded_strips=0,encode_ms=0}}
  c:after(1,function() if not released then complete(picture) end end)
  return picture
end,validate=function(bytes) return bytes~='BROKEN','Invalid XTH' end,
strip=function() return 'PNG-TILE' end}
_G.__TEST={}
local pictures={['alpha.xth']='XTH-ALPHA',['bravo.xth']='XTH-BRAVO',['charlie.XTH']='XTH-CHARLIE'}
local storage,frames={},{}
local now,enabled,disabled=1000000,0,0
local queue={}
local ctx={
  after=function(_,_,fn) queue[#queue+1]=fn end,
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
  lockscreen={set_default=function() enabled=enabled+1;return true end,
    clear_default=function() disabled=disabled+1;return true end},
  image={decode=function(_,bytes)
    assert(storage['preview-diagnostics.txt']:find('stage=decode-start',1,true))
    return {bytes=bytes,release=function() end}
  end},
  clock={millis=function() return now end,now=function() return {epoch_sec=1700000000} end},
  fonts={small={},medium={},large={}},invalidate=function() end
}
local g={clear=function() end,text=function() end,line=function() end,rect=function() end,
  image=function(_,obj,x,y) assert(x>=0 and y>=0);frames[#frames+1]=obj.bytes end}
dofile('app/lockscreen.lua')
local lock=__TEST.lock
on_load(ctx)
assert(disabled==1 and lock.current()==nil,'failed automatic renderer must remain disarmed')
on_draw(ctx,g)
assert(#frames==0,'lock entry must not attempt the failed native decoder')
assert(#lock.filenames(ctx)==3,'only flat XTH filenames accepted')
assert(lock.choose(0)==nil and lock.choose(1,nil,9,9)==1)
local previous
for _=1,100 do
  now=now+1
  local current=lock.select(ctx)
  assert(current~=previous,'no immediate repeat')
  local saved=storage['rotation.txt']
  on_tick(ctx)
  assert(storage['rotation.txt']==saved,'tick must not advance')
  previous=current
  on_leave()
end
assert(storage['diagnostics.txt']:find('interval=3600',1,true),'report host clamp truthfully')
ctx.lock.reason='timer'
local saved=storage['rotation.txt']
for _=1,5 do assert(lock.select(ctx)==previous) end
assert(storage['rotation.txt']==saved,'timer wakes neither rotate nor advance history')
ctx.lock.reason='first'
pictures={['one.xth']='XTH-ONE'}
assert(lock.select(ctx)=='one.xth')
assert(lock.select(ctx)=='one.xth')
pictures={}
local empty,message=lock.select(ctx)
assert(empty==nil and message:find('Add XTH',1,true))
pictures={['broken.xth']='BROKEN'}
pictures={['one.xth']='XTH-ONE',['two.xth']='XTH-TWO'}
_G.__TEST={}
dofile('app/index.lua')
on_load(ctx)
local main=__TEST.main
assert(#main.names()==2 and enabled==0 and disabled==2,'diagnostics disable the failed default entry')
on_input(ctx,{type='pointer',phase='up',gesture='tap',x=100,y=450})
assert(enabled==0 and main.is_building() and not main.is_preview(),'full preview builds off-screen')
assert(#queue==1)
on_input(ctx,{type='pointer',phase='up',gesture='tap',x=100,y=450})
assert(#queue==1,'repeated taps must not start competing builds')
table.remove(queue,1)()
assert(main.is_preview() and not main.is_building())
assert(storage['preview-timing.txt']:find('cache_hits=25',1,true),'completed cache metrics must reach the device log')
on_draw(ctx,g)
on_input(ctx,{type='pointer',phase='up',gesture='tap',x=200,y=200})
on_input(ctx,{type='pointer',phase='up',gesture='tap',x=100,y=540})
assert(main.is_preview());on_draw(ctx,g)
assert(storage['preview-diagnostics.txt']:find('stage=draw-ok',1,true))
on_input(ctx,{type='pointer',phase='up',gesture='tap',x=200,y=200})
on_input(ctx,{type='pointer',phase='up',gesture='tap',x=300,y=540})
assert(main.is_preview());on_draw(ctx,g)
on_input(ctx,{type='pointer',phase='up',gesture='tap',x=200,y=200})
assert(not main.is_preview())
ctx.image.decode=function() error('simulated native decode error') end
on_input(ctx,{type='pointer',phase='up',gesture='tap',x=100,y=540})
assert(not main.is_preview())
assert(storage['preview-diagnostics.txt']:find('stage=lua-error',1,true))
on_input(ctx,{type='pointer',phase='up',gesture='tap',x=100,y=450})
assert(main.is_building())
on_leave();table.remove(queue,1)()
assert(not main.is_building() and not main.is_preview(),'closing cancels pending completion')
on_load(ctx)
local Probe=require('probe')
local jpegbase=Probe.jpeg_prefix('one.xth')
storage[jpegbase..'.idx']='XTH-ONE'
storage[jpegbase..'.jpg']='\255\216\255\217'
ctx.image.decode=function(_,bytes)
  assert(bytes==storage[jpegbase..'.jpg'])
  return {width=480,height=800,release=function() end}
end
on_input(ctx,{type='pointer',phase='up',gesture='tap',x=100,y=365})
assert(main.is_preview() and not main.is_building() and #queue==0,'quick preview uses one direct decode')
assert(storage['preview-timing.txt']:find('cache_kind=jpeg100',1,true))
on_leave()
print('Wallpaper preview: async completion, cancellation, checkpoints and automatic-render guard PASS')
