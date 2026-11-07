-- Native 480x800 XTH reader. Files remain XTH on the card. Small in-memory
-- grayscale PNG strips bridge the pixels to Licorice's image blitter; these
-- are never saved, resized, dithered, or JPEG-compressed.
local X = {width=480, height=800, tile_height=16}
local byte, char, concat = string.byte, string.char, table.concat
local crc_table = {}
for n=0,255 do
  local c=n
  for _=1,8 do c=(c>>1) ~ ((c&1)~=0 and 0xedb88320 or 0) end
  crc_table[n]=c
end

local function u32(n) return string.pack('>I4',n) end
local function chunk(kind,data)
  local content=kind..data
  local crc=0xffffffff
  for i=1,#content do crc=(crc>>8) ~ crc_table[(crc ~ byte(content,i)) & 255] end
  return u32(#data)..content..u32(crc ~ 0xffffffff)
end

function X.validate(raw)
  if type(raw)~='string' or #raw~=96022 or raw:sub(1,4)~='XTH\0' then
    return nil,'Expected an uncompressed 480 x 800 XTH'
  end
  local w,h,mode,compression,size=string.unpack('<I2I2BBI4',raw,5)
  if w~=480 or h~=800 or mode~=0 or compression~=0 or size~=96000 then
    return nil,'Unsupported XTH dimensions or encoding'
  end
  return true
end

-- XTH first plane is bit 1, second plane bit 0. Native indices are
-- 0=white, 1=dark gray, 2=light gray, 3=black (not a linear ramp).
local shades={[0]=char(255),char(85),char(170),char(0)}
function X.strip(raw,y0,height)
  local rows={}
  local a,b=1,0 -- Adler32 over PNG filter bytes and pixel bytes.
  for y=y0,y0+height-1 do
    local row={char(0)} -- PNG filter type None.
    b=(b+a)%65521
    local mask=0x80 >> (y%8)
    local offset=23 + y//8
    for x=0,479 do
      local pos=offset+(479-x)*100
      local value=((byte(raw,pos)&mask)~=0 and 2 or 0)
        + ((byte(raw,pos+48000)&mask)~=0 and 1 or 0)
      local pixel=shades[value]
      row[x+2]=pixel
      a=(a+byte(pixel))%65521
      b=(b+a)%65521
    end
    rows[#rows+1]=concat(row)
  end
  local pixels=concat(rows)
  -- One DEFLATE stored block, wrapped in zlib. Each strip is below 65535 B.
  local zlib=char(0x78,0x01,0x01)..string.pack('<I2I2',#pixels,0xffff-#pixels)
    ..pixels..u32((b<<16)|a)
  local header=u32(480)..u32(height)..char(8,0,0,0,0)
  return '\137PNG\r\n\26\n'..chunk('IHDR',header)..chunk('IDAT',zlib)..chunk('IEND','')
end

-- Build off-screen in short callbacks. At most one decoded strip stays alive;
-- its pixels are copied into one reusable layer before that strip is released.
function X.compose(ctx,raw,complete,note)
  local valid,err=X.validate(raw)
  if not valid then return nil,err end
  if not ctx.image then return nil,'Image blitter unavailable' end
  if not ctx.layers or not ctx.after then return nil,'Layer or scheduler API unavailable' end
  note=note or function() end
  note('layer-create-start','480x800')
  local good,layer,why=pcall(function() return ctx.layers:create(480,800) end)
  if not good or not layer then return nil,'Cannot create wallpaper layer: '..tostring(why or layer) end
  local pending,y,disposed,ready=nil,0,false,false
  local picture={}
  function picture:release()
    disposed=true
    if pending then pcall(function() pending:release() end);pending=nil end
    if layer then pcall(function() layer:release() end);layer=nil end
    raw=nil;ready=false
  end
  function picture:draw(g)
    if disposed then return nil,'Preview was released' end
    if not ready then return nil,'Preview is still building' end
    note('layer-display-start','480x800')
    local result,why=g:image(layer,0,0)
    if (result==nil or result==false) and why then return nil,tostring(why) end
    note('layer-display-returned','480x800')
    return true
  end
  local function failed(message)
    note('compose-error',message)
    picture:release()
    complete(nil,tostring(message))
  end
  local step
  local function schedule()
    local ok,message=pcall(function() ctx:after(1,step) end)
    if not ok then failed(message);return false end
    return true
  end
  step=function()
    if disposed then return end
    local ok,message=pcall(function()
      -- Retain the last strip until its layer draw has returned and a fresh
      -- callback begins. Do not release objects while a draw queues them.
      if pending then pending:release();pending=nil end
      if y>=800 then
        raw=nil;ready=true
        note('compose-ready','50 strips, one retained layer')
        complete(picture)
        return
      end
      if ctx.budget then pcall(function() ctx.budget:extend() end) end
      note('strip-encode-start',y)
      local png=X.strip(raw,y,math.min(X.tile_height,800-y))
      note('strip-decode-start',y)
      local image,decode_error=ctx.image:decode(png)
      if not image then error('Strip '..y..': '..tostring(decode_error)) end
      pending=image
      note('strip-copy-start',y)
      local copied,copy_error=layer:draw(function(g)
        if y==0 then g:clear(0) end
        local result,why=g:image(image,0,y)
        if (result==nil or result==false) and why then error(tostring(why)) end
      end)
      if (copied==nil or copied==false) and copy_error then error(tostring(copy_error)) end
      y=y+X.tile_height
      schedule()
    end)
    if not ok then failed(message) end
  end
  if not schedule() then return nil,'Cannot schedule wallpaper build' end
  return picture
end

return X
