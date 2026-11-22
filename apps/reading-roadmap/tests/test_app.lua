-- Host regression: automatic reader indexing, complications and one-tap opening.
local memory, opened, toasts = {}, {}, {}
local known={
  {id='bk1',title='A Knight of the Seven Kingdoms',percent=43},
  {id='dupe-a',title='True Grit',percent=10},
  {id='dupe-b',title='True Grit',percent=0},
  {id='variant',title='The Martian Extended Edition',percent=0},
  {id='other',title='An Unrelated Book',percent=0}
}
memory['progress.txt']='#roadmap1\n3\ttodo\told-reader-id\n'
local f={measure=function(_,s)return #s*11 end}
local ctx={
  fonts={small=f,medium=f,large=f},
  storage={read=function(_,key)return memory[key] end,write=function(_,key,v)memory[key]=v;return true end},
  reader={all_books=function()return known end,books=function()return known end},
  dialog={toast=function(_,s)toasts[#toasts+1]=s end},
  invalidate=function()end,
  system={
    can_open=function(_,target)return type(target)=='table' and target.type=='book' end,
    open=function(_,target)opened[#opened+1]=target;return true end
  }
}
local displayed={}
local canvas={
 clear=function()end,rect=function()end,line=function()end,
 text=function(_,x,y,s)displayed[#displayed+1]=s end
}
assert(loadfile('apps/reading-roadmap/app/index.lua'))()
on_load(ctx)
local function draw()
  displayed={}
  on_draw(ctx,canvas)
end
local function has(s)
  for _,text in ipairs(displayed) do if text:find(s,1,true) then return true end end
  return false
end
local function tap(x,y)
  on_input(ctx,{type='pointer',phase='up',x=x,y=y})
  draw()
end
draw()
tap(100,125)
assert(#opened==1 and opened[1].id=='bk1','unique exact title should open with one tap')
tap(100,212)
assert(#opened==1 and #toasts>0,'not-indexed row must not launch a different book')
tap(435,125)
assert(#opened==1,'INFO must not launch a book')
tap(85,608)
assert(memory['progress.txt']:find('1\treading\tbk1',1,true),'reading state not persisted')
tap(275,608)
assert(memory['progress.txt']:find('1\tdone\tbk1',1,true),'finished state not persisted')
tap(200,748)
tap(416,749)
assert(has('BOOK CHECK'),'fourth tab must show issues')
assert(has('NOT INDEXED'),'unseen titles must show an index limitation')
assert(has('LINK CHANGED'),'stale saved links must be flagged')
assert(has('MULTIPLE'),'duplicate exact titles must require review')
assert(has('Opened books only'),'must not claim a whole SD-card scan')
tap(393,674)
assert(has('CHECK TITLE'),'similar titles must be suggestions, not auto links')
tap(100,121) -- issue row opens details for manual inspection
assert(has('WHY THIS BOOK'))
tap(200,746) -- back to path
tap(100,586) -- book six is a duplicate: no auto-open
assert(#opened==1,'duplicate book was silently auto selected')
-- Reader permission or API unavailable is distinct from a missing ebook.
ctx.reader=nil
on_load(ctx)
tap(416,748)
assert(has('Reader index unavailable'),'reader access failure must not imply missing books')
assert(has('NO ACCESS'),'reader access complication must be explicit')
print('PASS: unique match, duplicate, stale link, possible match, index-only limitations, controls')
