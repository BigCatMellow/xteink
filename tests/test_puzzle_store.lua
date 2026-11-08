package.path='shared/?.lua;'..package.path
local Store=require('puzzle_store')
local files={}
local storage={read=function(_,name) return files[name] end,write=function(_,name,data) files[name]=data end}
-- More than the firmware's 512-file limit, preserving distinct numbered records.
for n=1,2048 do Store.put(storage,'puzzle',n,'board='..n..'\nnotes=1,2\t100%\r\n') end
local count=0
for _ in pairs(files) do count=count+1 end
assert(count==64,'archive file count must be bounded')
for n=1,2048 do assert(Store.get(storage,'puzzle',n)=='board='..n..'\nnotes=1,2\t100%\r\n') end
Store.put(storage,'puzzle',65,'updated')
assert(Store.get(storage,'puzzle',65)=='updated')
assert(Store.get(storage,'puzzle',1)=='board=1\nnotes=1,2\t100%\r\n')
assert(Store.get(storage,'puzzle',2049)==nil)
local failing={read=function() return nil,'io_error' end,write=storage.write}
assert(not pcall(Store.put,failing,'puzzle',1,'x'),'failed reads must not overwrite a shard')
failing={read=function() return nil,'not_found' end,write=function() return nil,'quota' end}
assert(not pcall(Store.put,failing,'puzzle',1,'x'),'failed writes must not be reported as successful')
print('Puzzle store: 2048 records in 64 files, escaping, replacement and I/O failures PASS')
