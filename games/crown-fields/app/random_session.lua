-- Shared generated-session storage for new puzzle families.
-- Sixteen shards per game leave room in the Hub's shared 512-file sandbox.
local Store=require('puzzle_store')
local G=require('procedural_puzzles')
local R={sizes=G.sizes,write=Store.write}
local function storage16(storage)
 local function key(name)
  local prefix,num=name:match('^(.-)%-(%d+)%.txt$')
  if prefix then return prefix..'-'..(tonumber(num)%16)..'.txt' end
  return name
 end
 return {read=function(_,name)return storage:read(key(name))end,
  write=function(_,name,value)return storage:write(key(name),value)end}
end
function R.get(storage,prefix,number)return Store.get(storage16(storage),prefix,number)end
function R.put(storage,prefix,number,value)return Store.put(storage16(storage),prefix,number,value)end
local INDEX='random-index.txt'
local MAX=999999999
local nonce=0
local function int(v,a,b)
 local n=tonumber(v);return n and n==math.floor(n) and n>=a and n<=b and n
end
function R.pointer(storage,legacy)
 local raw,err=storage:read(INDEX)
 if raw==nil then
  if err and err~='not_found' then error(err) end
  return nil
 end
 local level,max,size=raw:match('^v1\n(%d+)\n(%d+)\n(%d+)$')
 level=int(level,legacy+1,MAX);max=int(max,legacy+1,MAX);size=int(size,5,10)
 assert(level and max and size and level<=max,'Invalid generated session index')
 return {level=level,max=max,size=size}
end
function R.supported(kind,n)
 for _,size in ipairs(G.sizes[kind]) do if size==n then return true end end
 return false
end
function R.read(storage,kind,number)
 local raw=assert(R.get(storage,'random',number),'Missing generated puzzle')
 local n,seed,ver,clues,answer,marks,mode,extra,won,hist=
  raw:match('^v1\n(%d+)\n(%d+)\n(%d+)\n([%.#%w]+)\n([01]+)\n([012]+)\n([12])\n([01])\n([01])\n(.*)$')
 n=int(n,5,10);seed=int(seed,1,2147483646);ver=int(ver,1,1)
 assert(n and seed and ver and R.supported(kind,n) and #clues==n*n and #answer==n*n and #marks==n*n,'Invalid generated record')
 if kind=='akari' then assert(not clues:find('[^%.#01234]'),'Invalid Akari clue')
 elseif kind=='crowns' then
  for i=1,#clues do assert(clues:byte(i)>=65 and clues:byte(i)<=64+n,'Invalid crown region') end
 end
 local history={}
 for v in hist:gmatch('[^;]+') do
  assert(#v==n*n and not v:find('[^012]') and #history<(kind=='akari' and 24 or 12),'Invalid undo record')
  history[#history+1]=v
 end
 return {number=number,n=n,seed=seed,version=ver,clues=clues,answer=answer,
  marks=marks,mode=tonumber(mode),extra=extra=='1',won=won=='1',history=history}
end
function R.save(storage,p,max,size)
 assert(p.number<=max)
 R.put(storage,'random',p.number,table.concat({'v1',p.n,p.seed,p.version,p.clues,p.answer,
  p.marks,p.mode,p.extra and '1' or '0',p.won and '1' or '0',table.concat(p.history,';')},'\n'))
 Store.write(storage,INDEX,table.concat({'v1',p.number,max,size},'\n'))
end
function R.select(storage,number,max,size)
 Store.write(storage,INDEX,table.concat({'v1',number,max,size},'\n'))
end
function R.generate(ctx,kind,n,number,exclude,forced,limit)
 if not R.supported(kind,n) or number>MAX then return nil end
 for _=1,(forced and 1 or 3) do
  nonce=nonce+1
  local ms=0
  if ctx.clock and type(ctx.clock.millis)=='function' then
   local ok,v=pcall(function()return ctx.clock:millis()end)
   if ok and type(v)=='number' then ms=math.floor(v)%1000000 end
  end
  local seed=forced or ((number%1000000)*193+ms*127+(nonce%1000000)*389)%2147483646+1
  local p=G.generate(kind,n,seed,limit)
  if p and p.clues~=exclude then
   p.number=number;p.marks=string.rep('0',n*n);p.history={};p.mode=1;p.extra=false;p.won=false
   return p
  end
 end
 return nil
end
return R
