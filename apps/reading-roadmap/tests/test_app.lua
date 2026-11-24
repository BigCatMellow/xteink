-- Host regression for the 211-book list: save migration, reader matching (incl. junk metadata),
-- complications, one-tap open, tracking, up-next paging and persistence.
local APP='apps/reading-roadmap/app/index.lua'
local memory, opened, toasts = {}, {}, {}
local known={
  {id='bk1',title='[Murderbot Diaries 01] All Systems Red',percent=43},  -- book 1, series tag
  {id='dupe-a',title='True Grit',last_date='2026-11-02'},                -- book 2, two copies
  {id='dupe-b',title='True Grit',last_date='2026-11-20'},
  {id='dcc',title='Dungeon Crawler Carl'},                               -- book 3
  {id='martian',title='The Martian: A Novel',author='Andy Weir'},       -- book 8 (but saved link is stale)
  {id='chron',title='The Martian Chronicles',author='Ray Bradbury'},    -- other author: no match
  {id='variant',title='Good Omens Extended Edition'},                   -- book 6, similar only
  {id='rum',title='Thompson, Hunter S',author='The Rum Diary'},         -- book 207, title/author swapped
  {id='lono',title='Thompson, Hunter S',author='The Curse of Lono'},    -- book 209, swapped
  {id='rebecca',title='Microsoft Word - Daphne Du Maurier   Rebecca'},  -- book 111, file's own junk title
  {id='none',title='none'},                                             -- junk shared by many files
  {id='dune',title='Dune',author='Frank Herbert'},                       -- book 61
  {id='atreides',title='Dune: House Atreides',author='Brian Herbert; Kevin J. Anderson'},  -- prequel
}
-- Old 33-book save (#roadmap1, positional IDs): 2=All Systems Red, 3=The Thin Man (not in the
-- new list), 10=The Martian (link no longer exists).
memory['progress.txt']='#roadmap1\n2\tdone\tbk1\n3\treading\t\n10\ttodo\tgone-id\n'
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
local function start()  -- a fresh app process, like relaunching on the device
  assert(loadfile(APP))()
  on_load(ctx)
end
local function draw() displayed={}; on_draw(ctx,canvas) end
local function has(s)
  for _,t in ipairs(displayed) do if t:find(s,1,true) then return true end end
  return false
end
local function saved(s) return memory['progress.txt']:find(s,1,true)~=nil end
local function tap(x,y) on_input(ctx,{type='pointer',phase='up',x=x,y=y}); draw() end
local function row(n) return 200,86+(n-1)*91+40 end
local function box(n) return 38,86+(n-1)*91+40 end
local PATH,DONE,CHECK,NEXT={80,749},{240,749},{400,749},{393,674}
local function last_toast() return toasts[#toasts] or '' end
local CODES={['LINK CHANGED']=1,MULTIPLE=1,['CHECK TITLE']=1,['NOT OPENED YET']=1,['NOT INDEXED']=1,['NOT ON CARD']=1}
local function issues()  -- {title -> code} plus order, read off every CHECK page
  tap(CHECK[1],CHECK[2])
  local map,order={},{}
  for _=1,60 do
    for i,t in ipairs(displayed) do
      if CODES[t] then map[displayed[i-1]]=t; order[#order+1]=t end
    end
    if not has('NEXT >') then break end
    tap(NEXT[1],NEXT[2])
  end
  tap(PATH[1],PATH[2])
  return map,order
end

start(); draw()
assert(has('Reading Roadmap') and has('1 / 211 read'),'211-book header with migrated finished book')

-- Save migration: positional v1 IDs move to title keys; unknown books are kept verbatim.
tap(box(2)); tap(box(2))  -- force a save (tick and untick True Grit)
assert(memory['progress.txt']:sub(1,10)=='#roadmap2\n','saved in the keyed format')
assert(saved('\nallsystemsred\tdone\tbk1\n'),'v1 book 2 -> All Systems Red, link kept')
assert(saved('\nv1:3\treading\t\n'),'a book missing from the new list keeps its progress row')

-- Matching rules on the new list
local m,order=issues()
assert(m['All Systems Red']==nil,'linked book has no issue')
assert(m['Dungeon Crawler Carl']==nil,'unique exact title auto-links')
assert(m['The Rum Diary']==nil and m['The Curse of Lono']==nil,'title/author swapped metadata still matches')
assert(m['The Martian Chronicles']==nil,'Bradbury links to his own book, not The Martian')
assert(m['Rebecca']==nil,"the file's own junk metadata title (baked alias) matches")
assert(m['The Martian']=='LINK CHANGED','stale migrated link is flagged, not silently replaced')
assert(m['True Grit']=='MULTIPLE','duplicate copies require a choice')
assert(m['Good Omens']=='CHECK TITLE','similar titles are suggestions, not auto links')
assert(m['Holes']=='NOT OPENED YET','listed file the reader has not opened')
assert(m['Dune']==nil,'the whole-title match beats "Dune: House Atreides"')
for _,code in ipairs(order) do assert(code~='NOT ON CARD','every listed book has a card path') end
assert(order[1]=='LINK CHANGED' and order[#order]=='NOT OPENED YET','fixable issues first')
tap(CHECK[1],CHECK[2])
assert(has('7 / 211 identified'),'identified count')
assert(has('card list of'),'footer names the card list it relies on')
tap(PATH[1],PATH[2])

-- One-tap open and routing
tap(row(1)); assert(#opened==1 and opened[1].id=='bk1','linked book opens with one tap')
tap(row(3)); assert(#opened==2 and opened[2].id=='dcc','auto-linked book opens')
tap(435,125); assert(#opened==2 and has('Book 1 of 211'),'INFO opens details, never the book')
tap(240,608); assert(saved('\nallsystemsred\treading\tbk1\n'),'READING persists by key')
tap(390,608); assert(saved('\nallsystemsred\tdone\tbk1\n'),'FINISHED persists')
tap(90,608); assert(saved('\nallsystemsred\ttodo\tbk1\n'),'a finished book can go back to To read')
tap(200,750)  -- BACK TO LIST
-- Row checkbox: one tap marks read, a second tap undoes it; it never opens the book.
tap(box(5)); assert(saved('\npriest\tdone\t\n') and #opened==2,'checkbox marks finished')
assert(has('1 / 211 read') and has('Finished'),'header count and row state follow the checkbox')
tap(box(5)); assert(not saved('\npriest\t'),'second tap unmarks (default rows are not stored)')
tap(box(1)); tap(box(1)); assert(saved('\nallsystemsred\treading\tbk1\n'),'unticking a book with reader progress returns to Reading')
tap(row(2)); assert(#opened==2 and has('LINK A BOOK'),'duplicate opens the picker, not a guess')
assert(displayed[3]=='True Grit' and displayed[4]=='MATCH  |  Last read 2026-11-20','newest candidate first')
tap(100,87+40)
assert(#opened==3 and opened[3].id=='dupe-b','picked copy opens')
tap(NEXT[1],NEXT[2]); tap(row(3))  -- page 2, book 9
assert(#opened==3 and last_toast():find('Books > Children and Fairy Tales > Standalone',1,true),'not opened yet: say where it is')

-- Up next skips optional rereads; the path opens on the page holding it.
memory['progress.txt']='#roadmap2\nallsystemsred\tdone\t\ntruegrit\tdone\t\ndungeoncrawlercarl\tdone\t\nthehauntingoftramcar015\tdone\t\n'
start(); draw()
assert(has('Optional reread') and has('Up next  |  Neil Gaiman'),'reread 5 is optional; 6 is up next')
memory['progress.txt']=memory['progress.txt']..'goodomens\tdone\t\nthemaltesefalcon\tdone\t\nthemartian\tdone\t\n'
start(); draw()
assert(has('Holes') and has('Up next') and has('2 / 36'),'path opens on the page with the next book')

-- Persistence across a relaunch (regression: gsub count was saved into the link field)
memory['progress.txt']='#roadmap2\ntruegrit\ttodo\tdupe-b\nv1:3\treading\t\n'
start(); draw()
tap(row(2)); assert(opened[#opened].id=='dupe-b','link survives relaunch')
tap(box(4)); assert(saved('\nv1:3\treading\t\n') and saved('\ntruegrit\ttodo\tdupe-b\n'),'rows survive later saves')
m=issues()
assert(m['True Grit']==nil,'saved links do not become LINK CHANGED after relaunch')

-- Long titles keep every word: the last line carries the remainder, shortened.
f.measure=function(_,s)return #s*22 end
start(); draw(); tap(NEXT[1],NEXT[2])
local ok=false
for _,t in ipairs(displayed) do if t:find('^Holistic') and t:find('%.%.%.$') then ok=true end end
assert(ok,'second title line keeps the remainder with an ellipsis')
f.measure=function(_,s)return #s*11 end

-- Reader permission or API unavailable is distinct from a missing ebook.
ctx.reader=nil
start(); draw()
tap(CHECK[1],CHECK[2])
assert(has('Reader index unavailable'),'reader access failure must not imply missing books')
assert(has('NO ACCESS') or has('Reader access unavailable'),'reader access complication must be explicit')
print('PASS: 211-book list, save migration, matching incl. junk metadata, routing, tracking, persistence')
