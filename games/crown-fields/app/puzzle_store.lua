-- Keep numbered puzzle records in 64 shards instead of one file per puzzle.
-- Licorice limits each app to 512 files. Records are never evicted on navigation.
local Store={}
local function filename(prefix,number)
  assert(type(prefix)=='string' and prefix:match('^[a-z%d-]+$'))
  assert(number>=1 and number==math.floor(number))
  return prefix..'-'..((number-1)%64)..'.txt'
end
local function read(storage,name)
  local value,err=storage:read(name)
  if value==nil then
    if err and err~='not_found' then error('Cannot read puzzle save: '..tostring(err)) end
    return ''
  end
  assert(type(value)=='string','Invalid puzzle save')
  return value
end
local function escape(data)
  return (data:gsub('%%','%%25'):gsub('\n','%%0A'):gsub('\r','%%0D'):gsub('\t','%%09'))
end
local function unescape(data)
  return (data:gsub('%%(%x%x)',function(h) return string.char(tonumber(h,16)) end))
end
function Store.get(storage,prefix,number)
  local data=read(storage,filename(prefix,number))
  local wanted=tostring(number)
  for key,value in data:gmatch('(%d+)\t([^\n]*)\n') do
    if key==wanted then return unescape(value) end
  end
  return nil
end
function Store.write(storage,name,value)
  local ok,err=storage:write(name,value)
  if ok==false or (ok==nil and err) then error('Cannot save puzzle: '..tostring(err)) end
end
function Store.put(storage,prefix,number,value)
  local name=filename(prefix,number)
  local data=read(storage,name)
  local result={}
  local wanted=tostring(number)
  for key,record in data:gmatch('(%d+)\t([^\n]*)\n') do
    if key~=wanted then result[#result+1]=key..'\t'..record..'\n' end
  end
  result[#result+1]=wanted..'\t'..escape(value)..'\n'
  Store.write(storage,name,table.concat(result))
end
return Store
