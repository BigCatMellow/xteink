-- Stable generator v1. Small, bounded exact solver; ambiguous patterns are rejected.
local G={}
local function rng(seed)
  local s=seed%2147483646+1
  return function(n) s=s*16807%2147483647;return s%n+1 end
end
local function clue(row)
  local runs={}
  for part in row:gmatch('#+') do runs[#runs+1]=#part end
  return #runs==0 and '0' or table.concat(runs,',')
end
local patterns={}
local function catalog(n)
  if patterns[n] then return patterns[n] end
  local byClue={}
  for mask=0,2^n-1 do
    local cells={}
    for x=1,n do cells[x]=math.floor(mask/2^(x-1))%2==1 and '#' or '.' end
    local row=table.concat(cells)
    local key=clue(row)
    byClue[key]=byClue[key] or {}
    byClue[key][#byClue[key]+1]=row
  end
  patterns[n]=byClue
  return byClue
end
function G.count(rows,budget)
  local n=#rows
  local choices=catalog(n)
  local rc,cc={},{}
  for y=1,n do rc[y]=choices[clue(rows[y])] end
  for x=1,n do
    local col={}
    for y=1,n do col[y]=rows[y]:sub(x,x) end
    cc[x]=choices[clue(table.concat(col))]
  end
  local nodes,found=0,0
  local exhausted=false
  local function search(y,available)
    if found>=2 or exhausted then return end
    nodes=nodes+1
    if nodes>(budget or 6000) then exhausted=true;return end
    if y>n then found=found+1;return end
    for _,row in ipairs(rc[y]) do
      local filtered={}
      local good=true
      for x=1,n do
        filtered[x]={}
        for _,col in ipairs(available[x]) do
          if col:sub(y,y)==row:sub(x,x) then filtered[x][#filtered[x]+1]=col end
        end
        if #filtered[x]==0 then good=false;break end
      end
      if good then search(y+1,filtered) end
      if found>=2 or exhausted then return end
    end
  end
  search(1,cc)
  return exhausted and -1 or found,nodes
end
local function fits(rows)
  local n=#rows
  local black=0
  for _,row in ipairs(rows) do
    local _,count=row:gsub('#','')
    black=black+count
    local _,gaps=clue(row):gsub(',','')
    if gaps>2 then return false end
  end
  for x=1,n do
    local col={}
    for y=1,n do col[y]=rows[y]:sub(x,x) end
    local _,gaps=clue(table.concat(col)):gsub(',','')
    if gaps>2 then return false end
  end
  return black>=n*n*.25 and black<=n*n*.80
end
function G.generate(number)
  assert(number>=1 and number==math.floor(number))
  local rand=rng(number*131+500009)
  local n=({5,7,8})[(number-1)%3+1]
  for attempt=1,40 do
    local rows={}
    for y=1,n do
      local line={}
      for x=1,n do line[x]=rand(100)<=57 and '#' or '.' end
      rows[y]=table.concat(line)
    end
    if fits(rows) and G.count(rows)==1 then return {name='PATTERN '..number,rows=rows} end
  end
  -- Ferrers shape: conjugate row/column sums force a unique matrix.
  -- Reflections preserve uniqueness and keep all run clues short.
  local lengths={}
  local minimum,maximum=math.ceil(n*.30),math.floor(n*.75)
  for y=1,n do lengths[y]=minimum-1+rand(maximum-minimum+1) end
  table.sort(lengths,function(a,b) return a>b end)
  local flipX,flipY=rand(2)==1,rand(2)==1
  local rows={}
  for y=1,n do
    local length=lengths[flipY and n+1-y or y]
    rows[y]=flipX and string.rep('.',n-length)..string.rep('#',length)
      or string.rep('#',length)..string.rep('.',n-length)
  end
  return {name='PATTERN '..number,rows=rows}
end
return G
