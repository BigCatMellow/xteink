-- Predict CHECK results on a real card: lua tests/predict.lua FIXTURE.lua
-- FIXTURE comes from tools/card_from_tree.py TREE --card ROOT --predict FIXTURE.lua and lists
-- every book as if it had been opened once (the reader's best case).
local fixture=assert(arg[1],'usage: predict.lua FIXTURE.lua')
local known=dofile(fixture)
local f={measure=function(_,s)return #s*11 end}
local displayed={}
local ctx={fonts={small=f,medium=f,large=f},
  storage={read=function()return nil end,write=function()return true end},
  reader={all_books=function()return known end,books=function()return {} end},
  dialog={toast=function()end},invalidate=function()end}
local canvas={clear=function()end,rect=function()end,line=function()end,
  text=function(_,x,y,s)displayed[#displayed+1]=s end}
assert(loadfile('apps/reading-roadmap/app/index.lua'))()
on_load(ctx)
local function draw() displayed={}; on_draw(ctx,canvas) end
local function tap(x,y) on_input(ctx,{type='pointer',phase='up',x=x,y=y}); draw() end
local function has(s) for _,t in ipairs(displayed) do if t:find(s,1,true) then return true end end end
draw()
tap(416,749)
print(displayed[2])
local CODES={['LINK CHANGED']=1,MULTIPLE=1,['CHECK TITLE']=1,['NOT OPENED YET']=1,['NOT INDEXED']=1,['NOT ON CARD']=1}
for _=1,10 do
  for i,t in ipairs(displayed) do
    if CODES[t] then print(string.format('  %-3s %-15s %-38s %s',displayed[i-2],t,displayed[i-1],displayed[i+1])) end
  end
  if not has('NEXT >') then break end
  tap(393,674)
end
