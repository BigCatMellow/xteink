-- Reading Roadmap X4 Pro host regression: row opens book, Info manages state.
local memory, opened, toasts = {}, {}, {}
local known={
  {id='bk1',title='A Knight of the Seven Kingdoms',author='George R. R. Martin',percent=43},
  {id='bk-other',title='An Unrelated Book',author='Other Author',percent=0},
}
local f={measure=function(_,str) return #str*11 end}
local ctx={
  fonts={small=f,medium=f,large=f},
  storage={read=function(_,k)return memory[k] end,write=function(_,k,v)memory[k]=v;return true end},
  reader={
    all_books=function()return known end,
    books=function()return known end
  },
  dialog={toast=function(_,msg)toasts[#toasts+1]=msg end},
  invalidate=function()end,
  system={
    can_open=function(_,target)return type(target)=='table' and target.type=='book' end,
    open=function(_,target)opened[#opened+1]=target;return true end
  }
}
local canvas={clear=function()end,rect=function()end,line=function()end,text=function()end}
assert(loadfile('apps/reading-roadmap/app/index.lua'))()
on_load(ctx)
local function draw() on_draw(ctx,canvas) end
local function tap(x,y)
  on_input(ctx,{type='pointer',phase='up',x=x,y=y})
  draw()
end
draw()
-- Primary row hit: already-known book opens with a single tap, no detail page.
tap(100,125)
assert(#opened==1 and opened[1].id=='bk1','row tap must request native book launch')
-- Second row isn't in the reader: open the link picker, then return safely.
tap(100,212)
assert(#opened==1,'unlinked row must not launch a different book')
tap(110,744) -- Back from picker
assert(#opened==1)
-- Info target is separate from main row: does not launch.
tap(435,125)
assert(#opened==1,'Info must not launch the book')
tap(90,608) -- Start via Info
assert(memory['progress.txt']:find('1\treading\tbk1',1,true),'reading state not saved')
tap(270,608) -- Finish via Info
assert(memory['progress.txt']:find('1\tdone\tbk1',1,true),'finished state not saved')
tap(200,749) -- back to list
tap(100,125) -- done book still opens
assert(#opened==2 and opened[2].id=='bk1')
-- Selecting a reader item in the picker saves the link and tries to open it.
tap(100,212) -- row 2 unlinked
tap(100,118) -- first reader item
assert(memory['progress.txt']:find('2\ttodo\tbk1',1,true),'picked book not persisted')
assert(#opened==3,'picker should attempt reader handoff after linking')
-- A book absent from Bookshelf cannot be silently launched.
known={}
on_load(ctx)
draw()
tap(100,306) -- third row, no reader books available
assert(#opened==3)
assert(#toasts>0,'missing-book feedback absent')
print('PASS: direct row open, separated Info target, first-time link, safe fallback, durable status')
