-- Reusable screen occupancy inspection of measured UI regions and touch areas.
-- Empty white pixels are not treated as defects by themselves.
local Screen={}
local Canvas=require('game_canvas')
local function summary(elements)
 local regions,buttons,text,all={},{},{},{}
 for _,e in ipairs(elements) do
  local b=e.box
  assert(b.x>=0 and b.y>=0 and b.x+b.w<=480 and b.y+b.h<=800,
    'UI element outside physical screen: '..tostring(b.s or e.kind))
  if e.kind=='region' then regions[#regions+1]=b
  elseif e.kind=='button' then buttons[#buttons+1]=b
  else text[#text+1]=b end
  all[#all+1]={lo=b.y,hi=b.y+b.h}
 end
 table.sort(all,function(a,b) return a.lo<b.lo end)
 local far,largest=nil,{pixels=0,start=0,finish=0}
 for _,span in ipairs(all) do
  if far and span.lo>far and span.lo-far>largest.pixels then
   largest={pixels=span.lo-far,start=far,finish=span.lo}
  end
  far=math.max(far or 0,span.hi)
 end
 local number_keys={}
 for _,b in ipairs(buttons) do
  if tostring(b.s):match('^[1-9]$') then number_keys[#number_keys+1]=b end
 end
 return {regions=regions,buttons=buttons,text=text,
   largest_gap=largest,number_keys=number_keys}
end
function Screen.occupancy(ctx,draw,label)
 local prev=ctx.fonts
 local reports={}
 for _,scale in ipairs({1,1.25}) do
  ctx.fonts=Canvas.fonts(scale)
  local g=Canvas.canvas()
  g:reset()
  local audit=_G.__LAYOUT
  assert(type(audit)=='function')
  local elements={}
  _G.__LAYOUT=function(kind,box)
   audit(kind,box)
   if kind=='region' or kind=='button' or kind=='text' then
    elements[#elements+1]={kind=kind,box={
      x=box.x,y=box.y,w=box.w,h=box.h,s=box.s}}
   end
  end
  draw(ctx,g)
  local report=summary(elements)
  g:verify(label..' font scale '..scale)
  reports[#reports+1]=report
 end
 ctx.fonts=prev
 return reports
end
return Screen
