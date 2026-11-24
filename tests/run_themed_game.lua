-- Replay the existing gameplay suite with actual bitmap metrics and image bounds.
-- Run inside any active game directory: lua ../../tests/run_themed_game.lua
package.path='app/?.lua;../../tests/?.lua;'..package.path
local T=require('game_canvas')
local native_canvas=T.canvas
local decoded,released,max_commands,frames=0,0,0,0
-- DEVICE_IMAGES=1 models the reader: at most 8 decoded pictures alive (then
-- decode answers nil,'limit_exceeded'), plus ctx.layers for off-screen drawing.
local DEVICE=os.getenv('DEVICE_IMAGES')=='1'
local LIVE_LIMIT,live,max_live,layers_made,layers_freed=8,0,0,0,0
local image_backend={decode=function(_,raw)
  if DEVICE and live>=LIVE_LIMIT then return nil,'limit_exceeded' end
  decoded=decoded+1;live=live+1;max_live=math.max(max_live,live)
  local function u32(i) local a,b,c,d=raw:byte(i,i+3);return ((a*256+b)*256+c)*256+d end
  local im={width=u32(17),height=u32(21)}
  function im:release() assert(not self.released);self.released=true;released=released+1;live=live-1 end
  return im
end}
local layer_backend={create=function(_,w,h)
  layers_made=layers_made+1
  local layer={width=w,height=h,layer=true}
  function layer:draw(fn)
    assert(not self.released,'drawing into a released layer')
    local lg={clear=function() end}
    function lg:image(im,x,y)
      assert(not im.released,'released picture drawn into a layer')
      assert(x>=0 and y>=0 and x+im.width<=w and y+im.height<=h,'picture larger than its layer')
    end
    fn(lg)
  end
  function layer:release() assert(not self.released);self.released=true;layers_freed=layers_freed+1 end
  return layer
end}
function T.canvas()
  local g=native_canvas()
  local reset=g.reset
  local count,current,pending=0,nil,nil
  function g:reset()
    reset(self);count=0;current=nil;pending=nil
    local audit=_G.__LAYOUT
    _G.__LAYOUT=function(kind,box)
      audit(kind,box)
      if kind=='button' then pending=box
      elseif kind=='shade' then current=box
      elseif kind=='text' then
        if pending then
          assert(not box.s:find('...',1,true),'control label truncated: '..pending.s)
          pending=nil
        end
        current=box
      end
    end
  end
  for _,method in ipairs({'clear','line','rect','circle','text'}) do
    local old=g[method]
    g[method]=function(self,...) count=count+1;return old(self,...) end
  end
  function g:image(im,x,y,options)
    count=count+1
    assert(not im.released,'released font or shade image used')
    assert(options==nil,'font images cannot use cropping or scaling')
    assert(current and x>=current.x and y>=current.y and x+im.width<=current.x+current.w and y+im.height<=current.y+current.h,
      'glyph ink crosses its measured bounds: '..tostring(current and current.s))
  end
  local verify=g.verify
  function g:verify(label)
    verify(self,label)
    max_commands=math.max(max_commands,count);frames=frames+1
    assert(count<950,label..': drawing approaches firmware command limit: '..count)
    local theme=require('theme')
    local active,reason=theme.state()
    if __TEST.api.typefaces then active,reason=__TEST.api.typefaces() end
    assert(active and not reason,label..': bitmap theme fell back: '..tostring(reason))
  end
  return g
end
local old_dofile=dofile
function dofile(path)
  local result=old_dofile(path)
  if path=='app/index.lua' then
    local load=on_load
    function on_load(c) c.image=image_backend;if DEVICE then c.layers=layer_backend end;return load(c) end
  end
  return result
end
dofile('tests/test_game.lua')
on_leave()
assert(decoded==released,'font images leaked across gameplay relaunches: '..decoded..' / '..released)
if DEVICE then
  assert(layers_made==layers_freed,'font layers leaked: '..layers_made..' / '..layers_freed)
  assert(max_live<=3,'too many decoded pictures alive at once: '..max_live)
  print('DEVICE IMAGES: '..frames..' frames in bitmap font, '..layers_made..' glyph layers, max '..max_live..' live decodes')
else
  print('BITMAP FAMILY: '..frames..' audited frames, max '..max_commands..' commands; all '..decoded..' decoded images released')
end
