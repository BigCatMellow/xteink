package.path='shared/?.lua;games/nonogram/app/?.lua;tests/?.lua;'..package.path
local Theme=require('game_theme')
local UI=require('ui')
local T=require('game_canvas')
local shapes={}
local raw={rect=function(_,x,y,w,h,o) shapes[#shapes+1]={x=x,y=y,w=w,h=h,o=o} end,
  line=function(_,x,y,xx,yy,o) shapes[#shapes+1]={x=x,y=y,xx=xx,yy=yy,o=o} end,
  circle=function(_,x,y,r,o) shapes[#shapes+1]={x=x,y=y,r=r,o=o} end}
local canvas=Theme.canvas(raw)
local original={line_width=3}
canvas:line(10,20,70,20,original)
canvas:line(90,20,150,20,original)
assert(shapes[1].xx==70 and shapes[2].x==90,'thicker rods must preserve the interrupted-line gap')
assert(shapes[1].o.line_width==4 and original.line_width==3,'style cannot mutate shared drawing options')
canvas:line(20,45,120,45,{line_width=3})
canvas:line(20,55,120,55,{line_width=3})
assert(shapes[4].y-shapes[3].y==10 and shapes[3].o.line_width<10,'double bridges remain two separate lines')
canvas:rect(24,708,108,68,{line_width=2,radius=12})
assert(shapes[5].x==24 and shapes[5].y==708 and shapes[5].w==108 and shapes[5].h==68,
  'rounding must not move a visible control away from its touch box')
assert(shapes[5].o.radius==12 and shapes[5].o.line_width==3)
canvas:rect(100,200,44,44,{line_width=1})
assert(shapes[6].o.radius==nil,'connected grid cells retain straight corners')
local ctx={fonts=T.fonts()}
local g=T.canvas();g:reset()
Theme.draw(ctx,g,function(c)
  UI.button(c,ctx,20,20,108,68,'CHECK')
  UI.paragraph(c,ctx,20,110,400,100,'Rounded controls keep their original targets and readable labels.','small')
end)
g:verify('themed native fallback')
local before=UI.font(ctx,'medium')
assert(not pcall(Theme.draw,ctx,g,function() error('fixture') end))
assert(UI.font(ctx,'medium')==before,'failed renders cannot leak the active font context')
Theme.release()
print('Game theme: semantic line gaps, double bridges, rounded targets, square grid cells and scoped fallback PASS')
