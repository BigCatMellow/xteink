package.path='games/games-hub/app/?.lua;tests/?.lua;'..package.path
local T=require('game_canvas')
local Namespace=require('namespace')
local Importer=require('importer')
local Catalogue=require('catalogue')
local saves={}
local fail,readfail,decoded,released=nil,nil,0,0
local storage={}
function storage:read(key) if key==readfail then return nil,'io_error' end;return saves[key],saves[key]==nil and 'not_found' or nil end
function storage:write(key,value) if fail then return nil,'quota' end;saves[key]=value;return true end
function storage:list() local out={};for k in pairs(saves) do out[#out+1]=k end;return out end
function storage:usage() return {max_files=512,max_bytes=134217728} end
local C={storage=storage,fonts=T.fonts(),invalidate=function() end,clock={millis=function()return 10000 end}}
local image_backend={}
function image_backend:decode(raw)
  decoded=decoded+1
  local function u32(i) local a,b,c,d=raw:byte(i,i+3);return ((a*256+b)*256+c)*256+d end
  local im={width=u32(17),height=u32(21)}
  function im:release() assert(not self.released);self.released=true;released=released+1 end
  return im
end
local function eq(a,b) assert(a==b,tostring(a)..' ~= '..tostring(b)) end
local a,b=Namespace.new('nonogram'),Namespace.new('sudoku')
local ca,cb=a:context(C),b:context(C)
ca.storage:write('same.txt','picture');cb.storage:write('same.txt','numbers')
eq(ca.storage:read('same.txt'),'picture');eq(cb.storage:read('same.txt'),'numbers')
eq(#ca.storage:list(),1);eq(ca.storage:list()[1],'same.txt')
assert(not pcall(ca.storage.write,ca.storage,'../escape','x'))
fail=true;ca.storage:write('same.txt','lost');assert(a.error);fail=nil
ca.storage:write('same.txt','new');assert(a.error,'later success cannot mask an earlier failure')
a:begin();assert(not a.error)
readfail='nonogram--same.txt';assert(not pcall(ca.storage.read,ca.storage,'same.txt'))
assert(not pcall(ca.storage.write,ca.storage,'same.txt','lost'));eq(saves['nonogram--same.txt'],'new');readfail=nil
saves={}
local allowed={nonogram=true,sudoku=true}
local payload='HUBSAVES1\nnonogram--a.txt\t0003\t610062\nsudoku--a.txt\t0\t\n'
C.package={read=function()return payload end}
local expected={id='snapshot1',count=2}
eq(Importer.run(C,false,allowed).count,0)
fail=true;assert(not pcall(Importer.run,C,expected,allowed));eq(saves['hub-import.txt'],nil);fail=nil
-- Retry after a partial import: existing hub progress wins, even if different.
saves['nonogram--a.txt']='existing'
eq(Importer.run(C,expected,allowed).count,1)
eq(saves['nonogram--a.txt'],'existing');eq(saves['sudoku--a.txt'],'')
eq(saves['hub-import.txt'],'snapshot1');assert(Importer.run(C,expected,allowed).already)
for _,bad in ipairs({'bad','HUBSAVES1\nunknown--a.txt\t0\t\n','HUBSAVES1\nnonogram--a.txt\t5\t61\n',payload..'sudoku--a.txt\t0\t\n'}) do
 C.package.read=function()return bad end
 assert(not pcall(Importer.run,C,{id='other',count=2},allowed),'malformed import accepted')
end
C.package=nil
assert(pcall(Importer.run,C,expected,allowed)) -- Receipt makes a consumed import independent of package data.
saves={};assert(not pcall(Importer.run,C,expected,allowed),'missing personal seed must block')
_G.__TEST={}
dofile('games/games-hub/app/index.lua')
local A=__TEST.api
local function tap(x,y)
 return on_input(C,{type='pointer',phase='up',gesture='tap',x=x,y=y})
end
local frames,max_commands=0,0
local function dims() if C.screen then return C.screen.width,C.screen.height end;return 480,800 end
local function draw(label)
 local W,H=dims()
 local g=T.canvas(W,H);local commands=0
 for _,method in ipairs({'clear','line','rect','circle','text'}) do
  local old=g[method];g[method]=function(self,...)commands=commands+1;return old(self,...)end
 end
 if C.image then function g:image(im,x,y,opts)
  assert(not im.released and not opts)
  assert(x>=0 and y>=0 and x+im.width<=W and y+im.height<=H,'bitmap outside screen')
  commands=commands+1
 end end
 g:reset()
 local observed={}
 local audit=_G.__LAYOUT
 _G.__LAYOUT=function(kind,box) if kind=='region' then observed[#observed+1]=box end;audit(kind,box) end
 on_draw(C,g);g:verify(label)
 local selected=A.state().selected
 if selected then
  local minimum={linelift=440,summitputt=420,linkgrid=440,inkrunes=440,lanternlogic=440,rayvault=430,
   islandlinks=410,oddityhunt=440,wordhunt=410,nonogram=336,wordbridge=440,rectrooms=440,sudoku=468,
   crownfields=440,tenpairs=440,quietmines=440,sumcross=395}
  local id=Catalogue[selected].id
  assert(W==480 and H==800,id..': engines must run on the portrait screen')
  assert(observed[1] and observed[1].w>=assert(minimum[id]),id..': play area regressed to a cramped layout')
  for _,r in ipairs(observed) do assert(r.x>=0 and r.y>=0 and r.x+r.w<=480 and r.y+r.h<=800,id..': board outside screen') end
 else
  for _,t in ipairs(A.targets()) do
   assert(t.x>=0 and t.y>=0 and t.x+t.w<=W and t.y+t.h<=H,label..': target '..t.id..' outside screen')
  end
 end
 frames=frames+1;max_commands=math.max(max_commands,commands)
 assert(commands<950,'hub command limit')
end
-- Shell navigation always taps the centre of a drawn target, so hitboxes and
-- drawing come from the same layout. Gaps between targets must not act.
local function target(id,nth)
 local k=0
 for _,t in ipairs(A.targets()) do if t.id==id then k=k+1;if k==(nth or 1) then return t end end end
end
local function press(id,nth)
 local t=assert(target(id,nth),'missing target '..id)
 return tap(t.x+math.floor(t.w/2),t.y+math.floor(t.h/2))
end
local function rows() local n=0;for _,t in ipairs(A.targets()) do if t.item then n=n+1 end end;return n end
local function rotating(enabled)
 if not enabled then C.screen=nil;return end
 C.screen={width=480,height=800}
 function C.screen:set_orientation(o)
  assert(o=='portrait' or o=='landscape','unsupported orientation '..tostring(o))
  if o=='landscape' then self.width,self.height=800,480 else self.width,self.height=480,800 end
 end
end
local LONG='The Extraordinarily Long and Winding Chronicle of an Overly Verbose Title That Never Ends'
local BOOKS={}
for i=1,11 do BOOKS[i]={id=i,title=i==1 and LONG or 'Book number '..i,author=i%3==0 and '' or 'Author Name '..i,percent=i*9%101,finished=i==4} end
local reader={}
function reader:current() return {title=LONG,author='A Very Prolific Author With A Long Name',percent=38} end
function reader:summary() return {streak_days=5,today_sec=1200} end
function reader:books() return BOOKS end
C.device={firmware='26110201'}
function C.device:battery() return {percent=82,charging=false} end
for _,bitmap in ipairs({false,true}) do
 C.image=bitmap and image_backend or nil
 for _,scale in ipairs({1,1.25}) do
  for _,rotate in ipairs({false,true}) do
   C.fonts=T.fonts(scale);C.reader=reader;rotating(rotate);saves['shell.txt']=nil
   local tag=(bitmap and 'bitmap ' or '')..scale..(rotate and ' rotating' or '')
   on_load(C);eq(A.state().screen,'home');draw('home '..tag)
   local orientations=rotate and {'portrait','landscape'} or {'portrait'}
   for _,o in ipairs(orientations) do
    tag=tag..' '..o
    -- Library: display-only rows, paged; rows never act and paging stops at the ends.
    assert(press('tab:library'));eq(A.state().screen,'library')
    while A.state().page>1 do assert(press('prev')) end
    assert(not press('prev'),'disabled previous acted')
    assert(not press('book'),'display-only book row acted')
    local seen=0
    repeat
     draw('library '..A.state().page..' '..tag);seen=seen+rows()
     local more=not target('next').disabled
     if more then assert(press('next')) end
    until not more
    eq(seen,#BOOKS);assert(not press('next'),'disabled next acted')
    assert(press('home'));eq(A.state().screen,'home')
    -- Games: every row opens its engine, and the grid button returns to the same page.
    assert(press('tab:games'));eq(A.state().screen,'games')
    while A.state().page>1 do assert(press('prev')) end
    local opened=0
    repeat
     local page=A.state().page
     draw('games '..page..' '..tag)
     local first,below=target('game'),nil
     for _,t in ipairs(A.targets()) do if t.item and t.y>first.y then below=below or t end end
     if below then assert(not tap(first.x+10,first.y+first.h+4),'gap between rows acted') end
     for nth=1,rows() do
      local n=target('game',nth).item.game
      assert(press('game',nth));eq(A.state().selected,n);opened=opened+1
      eq(dims(),480)
      assert(tap(35,35));assert(not A.state().selected);eq(A.state().screen,'games');eq(A.state().page,page)
      eq(dims(),o=='landscape' and 800 or 480)
     end
     local more=not target('next').disabled
     if more then assert(press('next')) end
    until not more
    eq(opened,#Catalogue)
    if o=='portrait' and not rotate then
     for n,item in ipairs(Catalogue) do
      assert(A.launch(n),item.name);draw(item.name..' hosted '..tag);eq(A.state().selected,n)
      assert(on_input(C,{type='pointer',phase='down',x=35,y=35}))
      assert(tap(35,35));assert(not A.state().selected);draw(item.name..' returned '..tag)
     end
    end
    assert(press('home'))
    -- Home resumes the last game and returns to Home.
    assert(press('resume'));eq(A.state().selected,A.state().last);draw('resumed '..tag)
    assert(tap(35,35));eq(A.state().screen,'home');draw('home again '..tag)
    assert(press('tab:settings'));eq(A.state().screen,'settings');draw('settings '..tag)
    if rotate then
     assert(press('orient'));eq(A.state().orient,o=='portrait' and 'landscape' or 'portrait')
     draw('settings turned '..tag);assert(press('home'))
    else
     assert(not press('info'),'passive settings row acted');assert(press('home'))
    end
   end
   -- The shell reopens where it was left: orientation, screen and an open game.
   assert(press('tab:settings'));on_leave()
   on_load(C);eq(A.state().screen,'settings');eq(A.state().orient,'portrait')
   assert(press('home'));assert(press('resume'));local open=A.state().selected
   on_leave();on_load(C);eq(A.state().selected,open);draw('reopened game '..tag)
   assert(tap(35,35));eq(A.state().screen,'home');on_leave()
  end
 end
end
-- Reading data is optional and every reader failure stays on screen as text.
C.screen=nil;C.fonts=T.fonts(1)
C.reader=nil;on_load(C);draw('no reader');assert(press('tab:library'));draw('no reader library');on_leave()
local broken={}
function broken:current() error('io') end
function broken:summary() error('io') end
function broken:books() return {{title=nil},'bad',{title='Kept',percent='x'}} end
C.reader=broken;function C.device:battery() error('io') end
saves['shell.txt']=nil;on_load(C);draw('broken reader');assert(press('tab:library'));eq(rows(),1);draw('broken library');on_leave()
local empty={}
function empty:current() return nil end
function empty:books() return {} end
C.reader=empty;C.device=nil;saves['shell.txt']=nil;on_load(C);draw('nothing read');assert(press('tab:library'));eq(rows(),0);draw('empty library');on_leave()
C.reader=nil;saves['shell.txt']=nil
-- A failed shell-state write is reported without blocking navigation.
on_load(C);fail=true;assert(press('tab:games'));assert(A.state().notice);draw('shell save failed');fail=nil;assert(press('home'));on_leave()
-- Legacy numeric resumes remain readable; new resumes use stable game IDs.
saves['hub.txt']='13';on_load(C);eq(A.state().last,13)
assert(A.launch(#Catalogue));eq(saves['hub.txt'],'id='..Catalogue[#Catalogue].id)
on_leave();on_load(C);eq(A.state().last,#Catalogue);on_leave()
-- Failed saving holds the current engine open; a successful retry can leave.
on_load(C);assert(A.launch(10));fail=true;assert(tap(35,35));eq(A.state().selected,10)
fail=nil;assert(tap(35,35));assert(not A.state().selected)
-- A read error never becomes an empty board written over a valid record.
local old=saves['nonogram--nonogram.txt']
readfail='nonogram--nonogram.txt';assert(not A.launch(10));eq(saves[readfail],old);readfail=nil
on_leave()
-- An unfinished picture and its undo stack survive switches and a hub relaunch.
on_load(C);assert(A.launch(10))
local puzzle=A.state().engine.api
puzzle.paint(1,1)
local marks=puzzle.state().boards[puzzle.state().level][1]
assert(tap(35,35));assert(A.launch(13));assert(tap(35,35));assert(A.launch(10))
puzzle=A.state().engine.api;eq(puzzle.state().boards[puzzle.state().level][1],marks)
assert(puzzle.undo());on_leave();on_load(C);assert(A.launch(10))
eq(A.state().engine.api.state().boards[puzzle.state().level][1],(marks+2)%3)
on_leave()
-- Actual hub startup blocks on a missing required seed, and Retry recovers.
package.loaded.import_expected={id='personal-ui',count=0}
_G.__TEST={};dofile('games/games-hub/app/index.lua');A=__TEST.api
on_load(C);assert(A.state().blocked);assert(not A.launch(1));draw('blocked import')
C.package={read=function()return 'HUBSAVES1\n' end}
assert(tap(200,730));assert(not A.state().blocked);on_leave()
eq(decoded,released)
print('Games Hub: isolation, '..#Catalogue..'-game switching/relaunch, save errors, import/retry, '..frames..' frames, max '..max_commands..' commands; all '..decoded..' font images released PASS')
