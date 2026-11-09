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
local function draw(label)
 local g=T.canvas();local commands=0
 for _,method in ipairs({'clear','line','rect','circle','text'}) do
  local old=g[method];g[method]=function(self,...)commands=commands+1;return old(self,...)end
 end
 if C.image then function g:image(im,x,y,opts)
  assert(not im.released and not opts)
  assert(x>=0 and y>=0 and x+im.width<=480 and y+im.height<=800,'bitmap outside screen')
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
  assert(observed[1] and observed[1].w>=assert(minimum[id]),id..': play area regressed to a cramped layout')
  for _,r in ipairs(observed) do assert(r.x>=0 and r.y>=0 and r.x+r.w<=480 and r.y+r.h<=800,id..': board outside screen') end
 end
 frames=frames+1;max_commands=math.max(max_commands,commands)
 assert(commands<950,'hub command limit')
end
for _,bitmap in ipairs({false,true}) do
 C.image=bitmap and image_backend or nil
 for _,scale in ipairs({1,1.25}) do
  C.fonts=T.fonts(scale);on_load(C)
  local pages=math.ceil(#Catalogue/A.per_page)
  for _=1,pages do tap(80,730) end
  for page=1,pages do
   eq(A.state().page,page);draw('menu '..page)
   local row=math.min(A.per_page,#Catalogue-(page-1)*A.per_page)
   assert(tap(220,188+(row-1)*88+40));eq(A.state().selected,(page-1)*A.per_page+row)
   assert(tap(35,35));eq(A.state().page,page)
   if page<pages then assert(tap(390,730)) end
  end
  for page=pages-1,1,-1 do assert(tap(80,730));eq(A.state().page,page);draw('back page '..page) end
  for n,item in ipairs(Catalogue) do
   assert(A.launch(n),item.name)
   draw(item.name..' hosted')
   eq(A.state().selected,n)
   assert(on_input(C,{type='pointer',phase='down',x=35,y=35}))
   assert(tap(35,35));assert(not A.state().selected)
   draw(item.name..' returned')
  end
  assert(tap(220,145));eq(A.state().selected,#Catalogue)
  on_leave();on_load(C);eq(A.state().last,#Catalogue)
  on_leave()
 end
end
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
