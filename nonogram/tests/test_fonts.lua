-- Real baked metrics, glyph bounds, image reuse and native failure paths.
package.path='app/?.lua;../tests/?.lua;'..package.path
local T=require('game_canvas')
local UI=require('ui')
local Data=require('font_data')
local Typefaces=require('typefaces')
_G.__TEST={}
dofile('app/index.lua')
local A=__TEST.api
local records={}
local decoded,released=0,0
local fail_decode,bad_size=nil,nil
local ctx={fonts=T.fonts(),storage={read=function(_,n) return records[n] end,
  write=function(_,n,v) records[n]=v end},invalidate=function() end}
ctx.image={decode=function(_,raw)
  decoded=decoded+1
  if fail_decode==decoded then return nil,'invalid_image' end
  assert(raw:sub(1,8)=='\137PNG\13\10\26\10','glyphs must be native-decodable PNGs')
  local function u32(i)
    local a,b,c,d=raw:byte(i,i+3);return ((a*256+b)*256+c)*256+d
  end
  local im={width=u32(17),height=u32(21)}
  if bad_size==decoded then im.width=im.width+1 end
  function im:release()
    assert(not self.released,'image released more than once')
    self.released=true;released=released+1
  end
  return im
end}
local max_commands,max_images=0,0
local function frame(label)
  local g=T.canvas()
  g:reset()
  local audit=_G.__LAYOUT
  local text=nil
  _G.__LAYOUT=function(kind,box) audit(kind,box);if kind=='text' then text=box end end
  local commands,images,native=0,0,0
  for _,method in ipairs({'clear','rect','line','circle'}) do
    local old=g[method]
    g[method]=function(self,... ) commands=commands+1;return old(self,...) end
  end
  local old_text=g.text
  function g:text(... ) native=native+1;commands=commands+1;return old_text(self,...) end
  function g:image(im,x,y,options)
    assert(not im.released,'released glyph reused')
    assert(options==nil,'runtime glyph images must not be cropped or rescaled')
    assert(text,'glyph emitted without a measured text region')
    assert(x>=text.x and y>=text.y and x+im.width<=text.x+text.w and y+im.height<=text.y+text.h,
      label..': glyph exceeds measured ink bounds for '..text.s)
    commands=commands+1;images=images+1
  end
  on_draw(ctx,g)
  g:verify(label)
  assert(A.typefaces(),label..': expected bitmap renderer')
  assert(native==0,label..': known game labels unexpectedly fell back to native text')
  max_commands=math.max(max_commands,commands);max_images=math.max(max_images,images)
end

on_load(ctx)
A.state().unlocked=999999999
frame('font first frame')
assert(decoded==#Data.images,'each glyph image decoded exactly once')
frame('font unchanged frame')
assert(decoded==#Data.images,'redraw must reuse images')
local fonts=A.typefaces()
assert(fonts.fonts.large.name=='Poppins-SemiBold')
assert(fonts.fonts.medium.name=='Poppins-Medium')
assert(fonts.fonts.small.name=='Inter' and fonts.fonts.body.name=='Inter')
for _,role in ipairs({'clue','clue_small'}) do
  local width=fonts.fonts[role]:measure('0')
  for n=1,9 do assert(fonts.fonts[role]:measure(tostring(n))==width,'tabular numeric advances') end
end
for _,level in ipairs({1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,42,999999999}) do
  assert(A.visit(level));A.reset()
  frame('bitmap blank '..level)
  A.paint(1,1);A.paint(1,1);A.check()
  frame('bitmap marks and incorrect CHECK '..level)
  A.reset()
  local p=A.shape(level)
  for y=1,p.n do for x=1,p.n do if p.rows[y]:sub(x,x)=='#' then A.paint(x,y) end end end
  frame('bitmap correct before CHECK '..level)
  A.check();frame('bitmap submitted '..level)
end
A.tap(443,34);frame('bitmap help');A.tap(443,34)
assert(decoded==#Data.images,'level visits must not grow the glyph cache')
assert(#fonts.images<=384 and fonts.decoded_pixels*3<=256*1024,'bounded decoded pixel cache')
assert(max_commands<700,'drawing must stay comfortably below the host command limit')

-- An unsupported character falls back as a whole string, with native measurements.
local fallback_g=T.canvas();fallback_g:reset()
local images,native=0,0
fallback_g.image=function() images=images+1 end
local old=fallback_g.text
function fallback_g:text(x,y,s,opt)
  native=native+1;assert(opt.font==ctx.fonts.small);return old(self,x,y,s,opt)
end
assert(fonts.fonts.small:measure('caf\195\169')==ctx.fonts.small:measure('caf\195\169'))
UI.text(fallback_g,fonts,24,20,'caf\195\169','small',nil,200)
fallback_g:verify('unsupported Unicode native fallback')
assert(images==0 and native==1,'do not mix native and bitmap glyphs within a label')
on_leave();assert(released==#Data.images,'leave releases every cached image')
on_load(ctx);frame('font relaunch')
assert(decoded==#Data.images*2,'relaunch rebuilds exactly one image cache')
on_leave();assert(released==decoded)

-- A failed decode releases already-created images and preserves usable native UI.
decoded,released=0,0;fail_decode=10
on_load(ctx)
T.check(ctx,on_draw,'decode failure falls back')
local active,reason=A.typefaces()
assert(not active and reason and decoded==10 and released==9)
T.check(ctx,on_draw,'decode failure remains stable')
assert(decoded==10,'do not retry all glyph decodes on each frame')
on_leave()
decoded,released=0,0;fail_decode=nil;bad_size=10
local failed=Typefaces.open(ctx)
assert(not failed and decoded==10 and released==10,'bad image dimensions clean up every owned image')
bad_size=nil

-- A draw failure keeps earlier queued image references alive until leave.
decoded,released=0,0
on_load(ctx)
local bad_canvas=T.canvas();bad_canvas:reset()
local attempted=0
function bad_canvas:image()
  attempted=attempted+1
  if attempted==3 then return nil,'invalid_argument' end
end
on_draw(ctx,bad_canvas)
_G.__LAYOUT=nil -- earlier partial pixels are erased by the fallback's clear.
active,reason=A.typefaces()
assert(not active and reason and attempted==3 and released==0)
T.check(ctx,on_draw,'draw failure native fallback')
assert(decoded==#Data.images,'draw failure must not repeatedly allocate images')
on_leave();assert(released==decoded)

-- Some older hosts can decode images but cannot draw them on the app canvas.
decoded,released=0,0
on_load(ctx)
T.check(ctx,on_draw,'missing canvas image method')
active,reason=A.typefaces()
assert(not active and reason=='Image drawing unavailable')
assert(decoded==#Data.images and released==decoded)
T.check(ctx,on_draw,'missing canvas image method remains native')
assert(decoded==#Data.images)
on_leave()

print('Nonogram bitmap fonts: bounds, roles, cache/release, Unicode/decode/draw fallbacks PASS; max '..max_commands..' commands, '..max_images..' glyphs/frame')
