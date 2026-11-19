-- Inter as whole PNG glyphs: no TTF loader and no image cropping.
-- Glyphs are decoded on first use, so a screen holds only the images it shows.
local Data=require('font_data')
local Typefaces={}
local aliases={small='small',medium='medium',large='large',body='medium',clue='medium',clue_small='small',
  clue_large='medium',digit='large',digit_light='large',title='large'}
local function supported(role,s)
  for i=1,#s do if not role.glyphs[s:byte(i)] then return false end end
  return true
end
local function bytes(hex)
  return (hex:gsub('..',function(pair) return string.char(tonumber(pair,16)) end))
end
-- Guide shading is independent of the glyph set: it still draws when the
-- bitmap fonts fall back to the system font.
local shades,shade_context={},nil
function Typefaces.shade(context,size)
  if shade_context~=context then Typefaces.release_shades();shade_context=context end
  local cached=shades[size]
  if cached~=nil then return cached or nil end
  local hex=Data.shades and Data.shades[size]
  local im=false
  if hex and context and context.image and type(context.image.decode)=='function' then
    local ok,decoded=pcall(function() return context.image:decode(bytes(hex)) end)
    if ok and decoded then im=decoded end
  end
  shades[size]=im
  return im or nil
end
function Typefaces.release_shades()
  for _,im in pairs(shades) do
    if im then pcall(function() im:release() end) end
  end
  shades={};shade_context=nil
end
-- Keep the last bitmap-font failure on the card for diagnosis (one small file).
function Typefaces.report(context,reason)
  if not context or not context.storage or type(context.storage.write)~='function' then return end
  pcall(function() context.storage:write('font-status.txt',tostring(reason)) end)
end
function Typefaces.open(context)
  if not context or not context.image or type(context.image.decode)~='function' then
    return nil,'Image decoding unavailable'
  end
  local result={fonts={},images={},count=0,decoded_pixels=0}
  function result:release()
    for _,im in pairs(self.images) do pcall(function() im:release() end) end
    self.images={};self.count=0
    self.released=true
  end
  function result:image(index)
    local im=self.images[index]
    if im then return im end
    assert(not self.released,'Font images were released')
    local item=Data.images[index]
    local ok,decoded=pcall(function() return context.image:decode(bytes(item[3])) end)
    if not ok or not decoded then error('Font image decoding failed: '..index) end
    local sized,valid=pcall(function()
      return (not decoded.width or decoded.width==item[1]) and (not decoded.height or decoded.height==item[2])
    end)
    if not sized or not valid then
      pcall(function() decoded:release() end)
      error('Font image dimensions changed: '..index)
    end
    self.images[index]=decoded;self.count=self.count+1
    self.decoded_pixels=self.decoded_pixels+item[1]*item[2]
    return decoded
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
          local ok,err=g:image(result:image(glyph[4]),x+glyph[2],y+glyph[3])
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
