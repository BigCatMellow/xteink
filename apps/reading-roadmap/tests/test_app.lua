-- Host-only smoke tests. Run from repo root with lua5.4.
local memory={}
local opened=0
local f={measure=function(_,s) return #s*11 end}
local ctx={
  fonts={small=f,medium=f,large=f},
  storage={read=function(_,k) return memory[k] end,write=function(_,k,v) memory[k]=v;return true end},
  reader={
    all_books=function() return {{id='bk1',title='A Knight of the Seven Kingdoms'}} end,
    books=function() return {{id='bk1',title='A Knight of the Seven Kingdoms',author='George R. R. Martin',percent=43}} end
  },
  dialog={toast=function() end}, invalidate=function() end,
  system={can_open=function(_,t) return type(t)=='table' and t.type=='book' end,open=function() opened=opened+1;return true end}
}
local canvas={clear=function() end,rect=function() end,line=function() end,text=function() end}
assert(loadfile('apps/reading-roadmap/app/index.lua'))()
assert(type(on_load)=='function' and type(on_draw)=='function' and type(on_input)=='function')
on_load(ctx)
on_draw(ctx,canvas)
local function tap(x,y)
  on_input(ctx,{type='pointer',phase='up',x=x,y=y})
  on_draw(ctx,canvas)
end
tap(90,120)  -- open detail
tap(85,610)  -- start book
assert(memory['progress.txt']:find('1\treading\tbk1',1,true),'start not saved')
assert(opened==0,'unexpected book launch')
tap(270,670) -- explicit open action
assert(opened==1,'supported book launch was not attempted')
tap(275,612) -- finished
assert(memory['progress.txt']:find('1\tdone\tbk1',1,true),'done not saved')
tap(70,670) -- link picker
tap(120,120) -- choose linked book
assert(memory['progress.txt']:find('1\tdone\tbk1',1,true),'picker damaged link')
tap(190,746) -- back
tap(230,748) -- all
on_load(ctx) -- state persists
on_draw(ctx,canvas)
assert(memory['progress.txt']:find('#roadmap1',1,true))
print('PASS: draw, reader metadata, explicit launch, status persistence, navigation')
