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

-- v2 deduction engine: line-pattern intersections, constrained by known marks.
-- It reasons only from clues and marks, never from the hidden picture. A
-- completed fixed point is a constructive proof of a unique solution.
local function key(list)
  local parts={}
  for i,v in ipairs(list) do parts[i]=tostring(v) end
  return table.concat(parts,',')
end
local function clues(rows)
  local n=#rows
  local rc,cc={},{}
  for y=1,n do rc[y]=clue(rows[y]) end
  for x=1,n do
    local col={}
    for y=1,n do col[y]=rows[y]:sub(x,x) end
    cc[x]=clue(table.concat(col))
  end
  return rc,cc
end
local function safe_mark(n)
  local a={}
  for i=1,n*n do a[i]=0 end
  return a
end
function G.propagate(n,rowClues,colClues,marks)
  if n<1 or n>10 or #rowClues~=n or #colClues~=n then
    return {contradiction=true,reason='invalid dimensions'}
  end
  local catalogued=catalog(n)
  local possibilities={{},{}}
  for axis=1,2 do
    local arr=axis==1 and rowClues or colClues
    for line=1,n do
      local literal=type(arr[line])=='table' and key(arr[line]) or arr[line]
      local valid=catalogued[literal]
      if not valid or #valid==0 then
        return {contradiction=true,reason='impossible line clue'}
      end
      possibilities[axis][line]=valid
    end
  end
  local board={}
  for i=1,n*n do
    local mark=marks and marks[i] or 0
    if mark~=0 and mark~=1 and mark~=2 then
      return {contradiction=true,reason='bad mark'}
    end
    board[i]=mark
  end
  local steps,rounds={},0
  for sweep=1,n*n+1 do
    local progressed=false
    for axis=1,2 do
      for line=1,n do
        local positions=possibilities[axis][line]
        local matching={}
        for _,pattern in ipairs(positions) do
          local valid=true
          for k=1,n do
            local i=axis==1 and (line-1)*n+k or (k-1)*n+line
            local actual=pattern:sub(k,k)=='#' and 1 or 2
            if board[i]~=0 and board[i]~=actual then valid=false;break end
          end
          if valid then matching[#matching+1]=pattern end
        end
        if #matching==0 then
          return {contradiction=true,reason='no patterns fit the marks',
            steps=steps,rounds=rounds,board=board}
        end
        possibilities[axis][line]=matching
        -- A cell forced in *every* fitting pattern is a sound deduction.
        for k=1,n do
          local same=true
          local char=matching[1]:sub(k,k)
          for j=2,#matching do
            if matching[j]:sub(k,k)~=char then same=false;break end
          end
          if same then
            local i=axis==1 and (line-1)*n+k or (k-1)*n+line
            local v=char=='#' and 1 or 2
            if board[i]==0 then
              board[i]=v;progressed=true
              steps[#steps+1]={x=(i-1)%n+1,y=math.floor((i-1)/n)+1,
                value=v,axis=axis,round=sweep,options=#matching}
            elseif board[i]~=v then
              return {contradiction=true,reason='forced marks disagree',
                steps=steps,rounds=rounds,board=board}
            end
          end
        end
      end
    end
    if not progressed then break end
    rounds=sweep
  end
  local unresolved=0
  for i=1,n*n do if board[i]==0 then unresolved=unresolved+1 end end
  return {solved=unresolved==0,unresolved=unresolved,rounds=rounds,
    steps=steps,board=board,contradiction=false}
end
function G.deduce(rowClues,colClues,marks)
  local n=#rowClues
  local outcome=G.propagate(n,rowClues,colClues,marks)
  if outcome.contradiction then return nil,outcome.reason end
  return outcome.steps[1],outcome
end
local function acceptable(rows)
  local n=#rows
  local filled=0
  local rc,cc=clues(rows)
  for _,row in ipairs(rows) do for i=1,#row do
    if row:sub(i,i)=='#' then filled=filled+1 end
  end end
  if filled<n*n*.3 or filled>n*n*.7 then return false end
  local maxRuns=n<=8 and 4 or 5
  for _,cl in ipairs(rc) do
    if select(2,cl:gsub(',',''))+1>maxRuns then return false end
  end
  for _,cl in ipairs(cc) do
    if select(2,cl:gsub(',',''))+1>maxRuns then return false end
  end
  return true,rc,cc
end
function G.generate_v2(number,strict,attempts)
  assert(number>=13 and number==math.floor(number))
  -- More intricate generated continuation while 5x5 pictures remain authored.
  -- Geometry stays large enough for touch and the clue stack on 480x800.
  local n=({8,10,7,10})[(number-13)%4+1]
  local desired=n==7 and 3 or n==8 and 4 or 5
  local density=n==7 and 48 or n==8 and 47 or 49
  local rand=rng(number*131+791009)
  local best,bestRounds=nil,-1
  for attempt=1,(attempts or 36) do
    local rows={}
    for y=1,n do
      local items={}
      for x=1,n do items[x]=rand(100)<=density and '#' or '.' end
      rows[y]=table.concat(items)
    end
    local acceptableShape,rc,cc=acceptable(rows)
    if acceptableShape then
      local analysis=G.propagate(n,rc,cc)
      if analysis.solved and not analysis.contradiction then
        if analysis.rounds>bestRounds then
          best={name='LOGIC '..number,rows=rows,rounds=analysis.rounds,
            generation=2}
          bestRounds=analysis.rounds
        end
        if analysis.rounds>=desired then break end
      end
    end
  end
  if best then return best end
  if strict then return nil,'No verified random pattern' end
  -- Legacy-only deterministic, no-guess safety net. The row lengths and corresponding
  -- column patterns force the complete board even on unlucky seeds.
  local rows={}
  for y=1,n do
    local length=n-y+1
    rows[y]=string.rep('#',length)..string.rep('.',n-length)
  end
  local rc,cc=clues(rows)
  assert(G.propagate(n,rc,cc).solved,'logic fallback must be deductively solved')
  return {name='LOGIC '..number,rows=rows,rounds=1,generation=2}
end

return G
