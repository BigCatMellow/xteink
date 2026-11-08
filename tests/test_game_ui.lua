package.path='shared/?.lua;tests/?.lua;'..package.path
local UI=require('game_ui')
local T=require('game_canvas')
local c={fonts=T.fonts()}
local function rejects(name,paint)
  local g=T.canvas();g:reset();paint(g)
  local ok=pcall(function() g:verify(name) end)
  _G.__LAYOUT=nil
  assert(not ok,'layout guard failed to catch '..name)
end
rejects('text collision',function(g)
  UI.text(g,c,30,72,'Level caption','small')
  UI.text(g,c,30,82,'UNDO','medium')
end)
rejects('Summit caption crossing buttons',function(g)
  UI.text(g,c,30,72,'Level caption','small')
  UI.button(g,c,30,82,195,42,'UNDO')
end)
rejects('off-screen text',function(g) UI.text(g,c,-5,10,'Wrong','small') end)
rejects('overlapping controls',function(g)
  UI.button(g,c,20,20,100,60,'ONE')
  UI.button(g,c,90,20,100,60,'TWO')
end)
rejects('board intrusion',function(g)
  UI.region(20,100,440,400)
  UI.text(g,c,30,90,'Wrong','small')
end)
rejects('truncated instructions',function(g)
  UI.paragraph(g,c,20,20,90,20,'This long rule cannot fit on a single line.','small')
end)
local g=T.canvas();g:reset()
UI.button(g,c,20,20,110,60,'RESTART')
UI.paragraph(g,c,20,120,200,120,'Readable wrapped instructions stay inside the allocated space.','small')
g:verify('valid layout')
-- Missing firmware measurements must still produce valid, bounded UTF-8 text.
g:reset()
UI.text(g,{},20,20,'UTF-8: café — test','small',nil,120)
g:verify('fallback metrics')
-- Opt-in rounded controls keep the established geometry and padded text audit.
local outlined={}
local original_rect=g.rect
function g:rect(x,y,w,h,options)
  outlined[#outlined+1]={x=x,y=y,w=w,h=h,options=options}
end
g:reset()
UI.button(g,c,20,20,180,68,'Check',true,{radius=12,line_width=3})
g:verify('rounded primary control')
assert(outlined[1].options.radius==12 and outlined[1].options.line_width==3)
assert(outlined[2].options.radius==8,'nested radius must account for the inset')
outlined={}
g:reset();UI.button(g,c,20,20,180,68,'Existing control');g:verify('unchanged default control')
assert(outlined[1].options.radius==0 and outlined[1].options.line_width==2)
g.rect=original_rect
-- Larger number keys and fixed clues reuse the shipped heading face.
assert(UI.font(c,'strong')==c.fonts.large,'strong text must retain native large-font metrics')
g:reset()
UI.button(g,c,20,20,98,52,'8',false,{font='strong'})
g:verify('large numeric key')
local original_text=g.text
local used_font=nil
function g:text(x,y,s,options) used_font=options.font;return original_text(self,x,y,s,options) end
g:reset();UI.text(g,c,30,30,'8','strong');g:verify('strong numeral')
assert(used_font==c.fonts.large,'numeric emphasis cannot silently become body text')
-- Shared geometry must make semantic widths real pixels and preserve gaps.
local bars={}
local raster={rect=function(_,x,y,w,h,o) bars[#bars+1]={x,y,w,h,o} end}
UI.stroke(raster,20,45,120,45,4)
UI.stroke(raster,20,55,120,55,4)
assert(bars[1][2]+bars[1][4]<bars[2][2],'parallel bridges must have a visible gap')
assert(bars[1][5].fill and bars[1][5].radius==0,'stroke width must not depend on native line options')
bars={};UI.grid(raster,6,108,9,9,52,{every=3})
local boundaries=0
for _,b in ipairs(bars) do if b[3]==4 and b[4]==468 then boundaries=boundaries+1 end end
assert(boundaries==4,'Sudoku needs outer and both box boundaries')
bars={};UI.grid(raster,16,120,8,4,56,{row_height=90})
assert(bars[1][4]==360,'rectangular number sheets must use their visible row height')
local bx,by,cell=UI.grid_geometry(7,120,568)
assert(bx==16 and by==120 and cell==64,'dense boards must use the reserved play band')
print('UI guard self-tests: collisions, clipping, board intrusion and button padding PASS')
