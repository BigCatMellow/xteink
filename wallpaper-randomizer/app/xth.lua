-- Native 480x800 XTH reader. Originals remain XTH on the card. Small lossless
-- grayscale PNG strips bridge the pixels to Licorice's image blitter and may
-- be cached in bounded app-storage bundles. No resizing or dithering.
local X = {width=480, height=800, tile_height=32}
local Cache=require('cache')
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
local shades={[0]=255,85,170,0}
local characters={[0]=char(0),[85]=char(85),[170]=char(170),[255]=char(255)}
local cache,cache_count={},0
local function eight_pixels(first,second)
  local key=(first<<8)|second
  local values=cache[key]
  if values then return values end
  values={}
  for k=0,7 do
    local mask=128>>k
    local level=((first&mask)~=0 and 2 or 0)+((second&mask)~=0 and 1 or 0)
    values[k+1]=shades[level]
  end
  -- Bounded cache: a noisy input must not grow a 65536-entry Lua table.
  if cache_count>=256 then cache={};cache_count=0 end
  cache[key]=values;cache_count=cache_count+1
  return values
end
function X.strip(raw,y0,height)
  assert(y0>=0 and height>0 and y0+height<=800,'Invalid strip bounds')
  local rows={}
  local a,b=1,0 -- Adler32 over PNG filter bytes and pixel bytes.
  -- Each pair of XTH bytes contains eight vertical pixels. Read it once,
  -- rather than re-reading both planes eight times, and transpose that block.
  for group_y=(y0//8)*8,y0+height-1,8 do
    local first_bit=math.max(0,y0-group_y)
    local last_bit=math.min(7,y0+height-1-group_y)
    local block,sums,weights={},{},{}
    for k=first_bit,last_bit do block[k]={char(0)};sums[k]=0;weights[k]=0 end
    local offset=23+group_y//8
    for x=0,479 do
      local pos=offset+(479-x)*100
      local values=eight_pixels(byte(raw,pos),byte(raw,pos+48000))
      for k=first_bit,last_bit do
        local value=values[k+1]
        block[k][x+2]=characters[value]
        sums[k]=sums[k]+value
        weights[k]=weights[k]+sums[k]
      end
    end
    for k=first_bit,last_bit do
      -- Combine a whole row's Adler contribution. All intermediate sums stay
      -- below 63 million, safe for the reader's 32-bit Lua integers.
      b=(b+481*a+weights[k])%65521
      a=(a+sums[k])%65521
      rows[#rows+1]=concat(block[k])
    end
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
function X.compose(ctx,raw,complete,note,options)
  local valid,err=X.validate(raw)
  if not valid then return nil,err end
  if not ctx.image then return nil,'Image blitter unavailable' end
  if not ctx.layers or not ctx.after then return nil,'Layer or scheduler API unavailable' end
  local function now()
    local ok,value=pcall(function() return ctx.clock:millis() end)
    return ok and tonumber(value) or 0
  end
  local started=now()
  local initial_cache_ms=0
  local disk_cache
  if options and options.name then
    if X.tile_height~=Cache.tile then return nil,'Wallpaper cache strip size mismatch' end
    local ok,value,why=pcall(function() return Cache.open(ctx,options.name,raw) end)
    if not ok or not value then return nil,'Cannot open wallpaper cache: '..tostring(why or value) end
    disk_cache=value
    initial_cache_ms=math.max(0,now()-started)
  end
  note=note or function() end
  note('layer-create-start','480x800')
  local good,layer,why=pcall(function() return ctx.layers:create(480,800) end)
  if not good or not layer then
    if disk_cache then disk_cache:release() end
    return nil,'Cannot create wallpaper layer: '..tostring(why or layer)
  end
  local pending,y,disposed,ready=nil,0,false,false
  local metrics={layer_ms=math.max(0,now()-started-initial_cache_ms),encode_ms=0,decode_ms=0,copy_ms=0,
    queue_ms=0,cache_ms=initial_cache_ms,cache_hits=0,encoded_strips=0,strips=0,total_ms=0}
  local scheduled=started
  local picture={metrics=metrics}
  function picture:release()
    disposed=true
    if pending then pcall(function() pending:release() end);pending=nil end
    if layer then pcall(function() layer:release() end);layer=nil end
    if disk_cache then disk_cache:release();disk_cache=nil end
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
    scheduled=now()
    local ok,message=pcall(function() ctx:after(1,step) end)
    if not ok then failed(message);return false end
    return true
  end
  step=function()
    if disposed then return end
    metrics.queue_ms=metrics.queue_ms+math.max(0,now()-scheduled)
    local ok,message=pcall(function()
      -- Retain the last strip until its layer draw has returned and a fresh
      -- callback begins. Do not release objects while a draw queues them.
      if pending then pending:release();pending=nil end
      if y>=800 then
        if disk_cache then
          local tick=now();disk_cache:finish();disk_cache=nil
          metrics.cache_ms=metrics.cache_ms+math.max(0,now()-tick)
        end
        raw=nil;ready=true
        metrics.total_ms=math.max(0,now()-started)
        note('compose-ready',metrics.strips..' strips, one retained layer')
        complete(picture)
        return
      end
      if ctx.budget then pcall(function() ctx.budget:extend() end) end
      local tick=now()
      local png
      if disk_cache then
        png=disk_cache:get(y)
        metrics.cache_ms=metrics.cache_ms+math.max(0,now()-tick)
      end
      if png then
        metrics.cache_hits=metrics.cache_hits+1
      else
        tick=now()
        note('strip-encode-start',y)
        png=X.strip(raw,y,math.min(X.tile_height,800-y))
        metrics.encode_ms=metrics.encode_ms+math.max(0,now()-tick)
        metrics.encoded_strips=metrics.encoded_strips+1
        if disk_cache then
          tick=now();disk_cache:put(y,png)
          metrics.cache_ms=metrics.cache_ms+math.max(0,now()-tick)
        end
      end
      note('strip-decode-start',y)
      tick=now()
      local image,decode_error=ctx.image:decode(png)
      metrics.decode_ms=metrics.decode_ms+math.max(0,now()-tick)
      if not image then
        if disk_cache then disk_cache:invalidate() end
        error('Strip '..y..': '..tostring(decode_error))
      end
      pending=image
      note('strip-copy-start',y)
      tick=now()
      local copied,copy_error=layer:draw(function(g)
        if y==0 then g:clear(0) end
        local result,why=g:image(image,0,y)
        if (result==nil or result==false) and why then error(tostring(why)) end
      end)
      if (copied==nil or copied==false) and copy_error then error(tostring(copy_error)) end
      metrics.copy_ms=metrics.copy_ms+math.max(0,now()-tick)
      metrics.strips=metrics.strips+1
      y=y+X.tile_height
      schedule()
    end)
    if not ok then failed(message) end
  end
  if not schedule() then return nil,'Cannot schedule wallpaper build' end
  return picture
end

return X
