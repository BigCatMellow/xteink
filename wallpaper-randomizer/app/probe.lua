-- Single-operation device probes. Never render a whole wallpaper here.
local XTH=require('xth')
local P={}
local tiny_hex='89504e470d0a1a0a0000000d4948445200000020000000200800000000561125280000001b49444154789c63648082501c3413030130aa6054c1a882e1aa0000934d013f3d72cfda0000000049454e44ae426082'
local tiny=tiny_hex:gsub('..',function(h) return string.char(tonumber(h,16)) end)

function P.jpeg_prefix(name)
  local key=0
  for i=1,#name do key=(key*131+name:byte(i))%8388593 end
  return 'wpj1-'..string.format('%06x',key)
end

function P.note(c,stage,detail)
  local device=c.device or {}
  local text='stage='..stage..'\ndetail='..tostring(detail or '')..
    '\nfirmware='..tostring(device.firmware)..'\nmodel='..tostring(device.model)..
    '\nmaxinteger='..tostring(math.maxinteger)..'\n'
  -- Checkpoint before each native operation; hard crashes can bypass pcall.
  if c.storage then pcall(function() c.storage:write('preview-diagnostics.txt',text) end) end
end

function P.composer_log(c)
  return function(stage,detail)
    -- Five recovery checkpoints per frame, instead of three synchronous SD
    -- writes per strip. Always preserve startup, errors and completion.
    if stage:match('^strip%-') then
      if stage~='strip-encode-start' or detail%160~=0 then return end
    end
    P.note(c,stage,detail)
  end
end

function P.timing(c,metrics)
  local lines={}
  for _,name in ipairs({'cache_kind','total_ms','layer_ms','cache_ms','encode_ms','decode_ms','copy_ms','queue_ms',
    'cache_hits','encoded_strips','strips'}) do
    lines[#lines+1]=name..'='..tostring(metrics[name] or 0)
  end
  if c.storage then pcall(function() c.storage:write('preview-timing.txt',table.concat(lines,'\n')..'\n') end) end
end

function P.run(c,kind,name,read)
  local function now()
    local ok,value=pcall(function() return c.clock:millis() end)
    return ok and tonumber(value) or 0
  end
  local started=now()
  P.note(c,'start',kind)
  local ok,picture,message=pcall(function()
    local png,w,h
    if kind=='png' then
      png,w,h=tiny,32,32
    elseif kind=='jpeg' then
      local raw=read(name)
      local valid,err=XTH.validate(raw)
      if not valid then error(err) end
      local base=P.jpeg_prefix(name)
      if read(base..'.idx')~=raw then error('Prepare the quick preview for this image') end
      png=read(base..'.jpg')
      if type(png)~='string' or #png<4 or png:sub(1,2)~='\255\216' or png:sub(-2)~='\255\217' then
        error('Quick JPEG cache is missing or damaged')
      end
      w,h=480,800
    else
      P.note(c,'file-read-start',name)
      local raw=read(name)
      if not raw then error('Cannot read '..tostring(name)) end
      P.note(c,'file-read-ok',#raw..' bytes')
      local valid,err=XTH.validate(raw)
      if not valid then error(err) end
      P.note(c,'file-validated',name)
      if kind=='file' then return nil,'XTH header and size are valid' end
      if c.budget then pcall(function() c.budget:extend() end) end
      P.note(c,'tile-encode-start','row 128, height 16')
      png=XTH.strip(raw,128,16)
      w,h=480,16
      P.note(c,'tile-encode-ok',#png..' bytes')
    end
    if not c.image then error('Image decoder unavailable') end
    if c.budget then pcall(function() c.budget:extend() end) end
    -- The exact-source marker is no longer needed. Let the host reclaim it
    -- before decoding a full image; no compositor layer is allocated here.
    if kind=='jpeg' and c.gc then pcall(function() c.gc:collect() end) end
    P.note(c,'decode-start',kind..' '..w..'x'..h)
    local decode_started=now()
    local image,err=c.image:decode(png)
    local decoded=now()
    if not image then error('Decoder rejected image: '..tostring(err)) end
    if kind=='jpeg' and ((image.width and image.width~=w) or (image.height and image.height~=h)) then
      image:release();error('Quick JPEG has incorrect dimensions')
    end
    P.note(c,'decode-ok',kind)
    local result={}
    if kind=='jpeg' then
      result.metrics={cache_kind='jpeg100',total_ms=math.max(0,decoded-started),
        cache_ms=math.max(0,decode_started-started),decode_ms=math.max(0,decoded-decode_started),
        cache_hits=1,encoded_strips=0,strips=1}
    end
    function result:draw(g)
      P.note(c,'draw-start',kind)
      local good,value,why=pcall(function() return g:image(image,math.floor((480-w)/2),math.floor((800-h)/2)) end)
      if not good or ((value==nil or value==false) and why) then
        local message=not good and value or why
        P.note(c,'draw-error',message);return nil,tostring(message)
      end
      P.note(c,'draw-ok',kind)
      return true
    end
    function result:release()
      if image then pcall(function() image:release() end);image=nil end
    end
    return result,'Single-image test passed'
  end)
  if not ok then P.note(c,'lua-error',picture);return nil,tostring(picture) end
  return picture,message
end

return P
