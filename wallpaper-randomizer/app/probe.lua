-- Single-operation device probes. Never render a whole wallpaper here.
local XTH=require('xth')
local P={}
local tiny_hex='89504e470d0a1a0a0000000d4948445200000020000000200800000000561125280000001b49444154789c63648082501c3413030130aa6054c1a882e1aa0000934d013f3d72cfda0000000049454e44ae426082'
local tiny=tiny_hex:gsub('..',function(h) return string.char(tonumber(h,16)) end)

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
  for _,name in ipairs({'total_ms','layer_ms','cache_ms','encode_ms','decode_ms','copy_ms','queue_ms',
    'cache_hits','encoded_strips','strips'}) do
    lines[#lines+1]=name..'='..tostring(metrics[name] or 0)
  end
  if c.storage then pcall(function() c.storage:write('preview-timing.txt',table.concat(lines,'\n')..'\n') end) end
end

function P.run(c,kind,name,read)
  P.note(c,'start',kind)
  local ok,picture,message=pcall(function()
    local png,w,h
    if kind=='png' then
      png,w,h=tiny,32,32
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
    P.note(c,'decode-start',kind..' '..w..'x'..h)
    local image,err=c.image:decode(png)
    if not image then error('Decoder rejected image: '..tostring(err)) end
    P.note(c,'decode-ok',kind)
    local result={}
    function result:draw(g)
      P.note(c,'draw-start',kind)
      local good,why=pcall(function() g:image(image,math.floor((480-w)/2),math.floor((800-h)/2)) end)
      if not good then P.note(c,'draw-error',why);return nil,tostring(why) end
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
