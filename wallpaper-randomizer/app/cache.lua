-- Five bounded bundles per frame, plus an exact-source commit marker.
-- Nothing outside the app's own storage is touched. Never hash the large XTH
-- in Lua: comparing the 96KB marker with the source is native string equality.
local C={version=1,tile=32,per_group=5,groups=5}
local function prefix(name)
  local key=0
  for i=1,#name do key=(key*131+name:byte(i))%8388593 end
  return 'wpc1-32-'..string.format('%06x',key)
end
local function valid_png(png)
  return #png>=57 and png:sub(1,8)=='\137PNG\r\n\26\n' and
    png:sub(13,16)=='IHDR' and string.unpack('>I4',png,9)==13 and
    string.unpack('>I4',png,17)==480 and string.unpack('>I4',png,21)==32 and
    png:byte(25)==8 and png:byte(26)==0 and png:byte(27)==0 and
    png:byte(28)==0 and png:byte(29)==0 and png:sub(-8)=='IEND\174\66\96\130'
end
local function unpack_group(blob,group)
  if type(blob)~='string' or #blob<34 or #blob>100000 or blob:sub(1,4)~='WPC1' then return nil end
  local w,h,tile,index,count,pos=string.unpack('<I2I2I2I2I2',blob,5)
  if w~=480 or h~=800 or tile~=32 or index~=group or count~=5 then return nil end
  local lengths={}
  for i=1,5 do
    local length
    length,pos=string.unpack('<I4',blob,pos)
    if length<57 or length>20000 then return nil end
    lengths[i]=length
  end
  local entries={}
  for i=1,5 do
    if pos+lengths[i]-1>#blob then return nil end
    local png=blob:sub(pos,pos+lengths[i]-1)
    if not valid_png(png) then return nil end
    entries[i]=png;pos=pos+lengths[i]
  end
  if pos~=#blob+1 then return nil end
  return entries
end
local function pack_group(entries,group)
  local head={'WPC1',string.pack('<I2I2I2I2I2',480,800,32,group,5)}
  for i=1,5 do
    assert(entries[i] and valid_png(entries[i]),'Invalid cached PNG')
    head[#head+1]=string.pack('<I4',#entries[i])
  end
  return table.concat(head)..table.concat(entries)
end

function C.open(ctx,name,raw)
  if not ctx.storage then return nil,'App storage unavailable for caching' end
  local store=ctx.storage
  local base=prefix(name)
  local marker=base..'.idx'
  local function read(file)
    local sized,size=pcall(function() return store:size(file) end)
    if sized and type(size)=='number' and size>100000 then return nil end
    local ok,value=pcall(function() return store:read(file) end)
    return ok and type(value)=='string' and value or nil
  end
  local function write(file,value)
    local ok,result,err=pcall(function() return store:write(file,value) end)
    if not ok or result==false or (result==nil and err) then
      error('Cache write failed: '..tostring(err or result))
    end
    -- Also handles firmware versions whose successful write returns no value.
    if read(file)~=value then error('Cache read-back failed; check storage quota') end
  end
  local matched=read(marker)==raw
  local group,entries,verified=nil,nil,{}
  local invalidated=false
  local session={initial_hit=matched}
  function session:invalidate()
    if invalidated then return end
    local ok,result,err=pcall(function() return store:remove(marker) end)
    -- It may never have existed; only require that it is absent afterwards.
    if read(marker)~=nil then error('Cannot invalidate cached source: '..tostring(err or result or ok)) end
    invalidated=true
  end
  function session:get(y)
    local wanted=math.floor(y/160)
    if wanted~=group then
      group=wanted;entries=nil
      if matched then entries=unpack_group(read(base..'-'..group..'.bin'),group) end
      if entries then verified[group]=true
      else entries={};self:invalidate() end
    end
    return entries[(y%160)//32+1]
  end
  function session:put(y,png)
    local slot=(y%160)//32+1
    assert(group==math.floor(y/160),'Cache access must be sequential')
    entries[slot]=png
    if slot==5 then
      write(base..'-'..group..'.bin',pack_group(entries,group))
      verified[group]=true
    end
  end
  function session:finish()
    for i=0,4 do assert(verified[i],'Incomplete wallpaper cache') end
    if not matched or invalidated then write(marker,raw) end
    -- The source marker is committed last. Interrupted builds never look ready.
    self:release()
  end
  function session:release() entries=nil;raw=nil end
  return session
end

C.prefix=prefix
return C
