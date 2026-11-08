-- Optional private first-launch save seed. Never replace existing hub progress.
local Importer={}
local function read(storage,name)
  local value,err=storage:read(name)
  if value==nil and err and err~='not_found' then error('Cannot read save: '..tostring(err)) end
  return value
end
local function write(storage,name,value)
  local result,err=storage:write(name,value)
  if result==false or (result==nil and err) then error('Cannot import save: '..tostring(err)) end
end
function Importer.run(context,expected,allowed)
  if not expected then return {ready=true,count=0} end
  local receipt=read(context.storage,'hub-import.txt')
  if receipt==expected.id then return {ready=true,count=expected.count,already=true} end
  local data=nil
  for _,source in ipairs({context.package or false,context.data or false}) do
    if source then
      for _,method in ipairs({'read','read_text'}) do
        if type(source[method])=='function' then
          local ok,value=pcall(source[method],source,'import-saves.txt')
          if ok and type(value)=='string' then data=value;break end
        end
      end
    end
    if data then break end
  end
  assert(data,'Saved progress package could not be read')
  local header,rest=data:match('^(HUBSAVES1)\n(.*)$')
  assert(header,'Invalid save import format')
  local records,seen={},{}
  for line in rest:gmatch('[^\n]+') do
    local key,length,hex=line:match('^([%w._-]+)\t(%d+)\t([%da-f]*)$')
    assert(key and not key:find('..',1,true) and #key<=64 and not seen[key],'Invalid save import entry')
    local id=key:match('^([a-z]+)%-%-')
    assert(id and allowed[id],'Unknown game save')
    assert(#hex%2==0 and tonumber(length)==#hex/2,'Truncated save import')
    seen[key]=true
    records[#records+1]={key,hex:gsub('..',function(pair) return string.char(tonumber(pair,16)) end)}
  end
  assert(#records==expected.count,'Incomplete save import')
  local count=0
  for _,record in ipairs(records) do
    if read(context.storage,record[1])==nil then
      write(context.storage,record[1],record[2])
      assert(read(context.storage,record[1])==record[2],'Imported save readback failed')
      count=count+1
    end
  end
  write(context.storage,'hub-import.txt',expected.id)
  assert(read(context.storage,'hub-import.txt')==expected.id,'Import receipt readback failed')
  return {ready=true,count=count}
end
return Importer
