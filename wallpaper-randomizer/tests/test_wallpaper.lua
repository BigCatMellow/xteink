_G.__TEST = {}
local pictures = {
  ['alpha.jpg']='JPEG-ALPHA',
  ['bravo.jpeg']='JPEG-BRAVO',
  ['charlie.JPG']='JPEG-CHARLIE',
}
local storage={}
local now=1000000
local frames, enabled = {}, 0
local function list_files()
  local out={}
  for name in pairs(pictures) do out[#out+1]={name=name} end
  out[#out+1]={name='note.txt'}
  out[#out+1]={name='../bad.jpg'}
  return out
end
local ctx={
  files={
    list=function() return list_files() end,
    read=function(_,name) return pictures[name] end
  },
  storage={
    list=function() return {'rotation.txt','nope.png'} end,
    read=function(_,name) return storage[name] end,
    write=function(_,name,value) storage[name]=value end
  },
  image={
    decode=function(_,bytes)
      assert(type(bytes)=='string' and bytes:match('^JPEG'))
      return {bytes=bytes,release=function() end}
    end
  },
  lock={set_interval=function(_,seconds) assert(seconds==31536000) end},
  lockscreen={set_default=function() enabled=enabled+1;return true end},
  clock={
    millis=function() return now end,
    now=function() return {epoch_sec=1700000000} end
  },
  fonts={small={},medium={},large={}},
  invalidate=function() end
}
local g={
  clear=function() end,
  text=function() end,
  line=function() end,
  rect=function() end,
  image=function(_,obj,x,y)
    assert(x==0 and y==0)
    frames[#frames+1]=obj.bytes
  end
}
dofile('app/lockscreen.lua')
local lock=__TEST.lock
assert(#lock.filenames(ctx)==3,'three valid jpgs')
assert(lock.choose(0)==nil)
assert(lock.choose(1,nil,9,9)==1)
assert(lock.choose(2,1,1,0)==2)
assert(lock.choose(2,2,1,0)==1)
for i=1,80 do
  now=now+1
  on_load(ctx)
  local name=lock.current()
  assert(pictures[name], 'image must be valid')
  on_draw(ctx,g)
  assert(frames[#frames]==pictures[name],'full screen JPEG should draw')
  on_leave()
  assert(storage['rotation.txt']:find('last='..name,1,true),'save current')
end

-- Actually check consecutive filenames across independent sessions.
local previous=nil
for i=1,100 do
  now=now+2
  on_load(ctx)
  local current=lock.current()
  if previous then assert(current~=previous,'no immediate repeat') end
  previous=current
end

-- Two-image decks must alternate.
pictures={['alpha.jpg']='JPEG-ALPHA',['bravo.jpeg']='JPEG-BRAVO'}
previous=nil
for i=1,20 do
  on_load(ctx)
  local current=lock.current()
  if previous then assert(current~=previous,'two image alternation') end
  previous=current
end

-- With one image repeated display is unavoidable; with zero, show an instruction.
pictures={['one.jpg']='JPEG-ONE'}
on_load(ctx);assert(lock.current()=='one.jpg')
on_load(ctx);assert(lock.current()=='one.jpg')
pictures={}
on_load(ctx)
assert(lock.current()==nil)
assert(lock.error():find('No JPG',1,true),'helpful empty-folder message')
on_draw(ctx,g)

-- Main app scans, explicitly enables via a tap (never automatically), and previews JPGs.
pictures={['one.jpg']='JPEG-ONE',['two.jpg']='JPEG-TWO'}
_G.__TEST={}
dofile('app/index.lua')
on_load(ctx)
local main=__TEST.main
assert(#main.names()==2)
assert(enabled==0,'no permission request on launch')
on_input(ctx,{type='pointer',phase='up',gesture='tap',x=100,y=450})
assert(enabled==1,'user approved enable action')
on_input(ctx,{type='pointer',phase='up',gesture='tap',x=300,y=540})
assert(main.is_preview(),'preview opens')
on_draw(ctx,g)
on_input(ctx,{type='pointer',phase='up',gesture='tap',x=200,y=200})
assert(not main.is_preview(),'preview closes on tap')
print('Wallpaper Randomizer: rotation, no repeats, image rendering and opt-in checks passed')
