-- Poppins/Inter as whole PNG glyphs: no TTF loader and no image cropping.
local Data=require('font_data')
local Typefaces={}
local aliases={small='small',medium='medium',large='large',body='medium',clue='medium',clue_small='small'}
local function supported(role,s)
  for i=1,#s do if not role.glyphs[s:byte(i)] then return false end end
  return true
end
function Typefaces.open(context)
  if not context or not context.image or type(context.image.decode)~='function' then
    return nil,'Image decoding unavailable'
  end
  local result={fonts={},images={},decoded_pixels=0}
  function result:release()
    for _,im in ipairs(self.images) do pcall(function() im:release() end) end
    self.images={}
    self.released=true
  end
  for index,item in ipairs(Data.images) do
    local raw=item[3]:gsub('..',function(pair) return string.char(tonumber(pair,16)) end)
    local ok,im=pcall(function() return context.image:decode(raw) end)
    if not ok or not im then result:release();return nil,'Font image decoding failed' end
    result.images[index]=im
    result.decoded_pixels=result.decoded_pixels+item[1]*item[2]
    local sized,valid=pcall(function()
      return (not im.width or im.width==item[1]) and (not im.height or im.height==item[2])
    end)
    if not sized or not valid then
      result:release();return nil,'Font image dimensions changed'
    end
  end
  for name,role in pairs(Data.roles) do
    local font={name=role.name,line_height=role.line_height,
      native=context.fonts and context.fonts[aliases[name]]}
    function font:measure(s)
      if not supported(role,s) then
        if self.native then return self.native:measure(s) end
        return #s*math.floor(self.line_height*.6)
      end
      local width=0
      for i=1,#s do width=width+role.glyphs[s:byte(i)][1] end
      return width
    end
    function font:paint(g,x,y,s)
      if not supported(role,s) then return false end
      assert(not result.released,'Font images were released')
      for i=1,#s do
        local glyph=role.glyphs[s:byte(i)]
        if glyph[4]>0 then
          local ok,err=g:image(result.images[glyph[4]],x+glyph[2],y+glyph[3])
          if ok==false or (ok==nil and err) then error('Font image draw failed: '..tostring(err)) end
        end
        x=x+glyph[1]
      end
      return true
    end
    result.fonts[name]=font
  end
  return result
end
return Typefaces
