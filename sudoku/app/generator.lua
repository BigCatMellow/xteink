-- Seeded Sudoku adapted from BigCatMellow/meditation's generator design.
-- v1 seeds are stable. Every clue removal must retain exactly one solution.
local G={}
local function copy(a) local b={};for i,v in ipairs(a) do b[i]=v end;return b end
local function rng(seed)
  local s=seed%2147483646+1
  return function(n) s=s*16807%2147483647;return s%n+1 end
end
local peers={}
for i=1,81 do
  peers[i]={}
  local r,c=math.floor((i-1)/9), (i-1)%9
  for j=1,81 do
    local rr,cc=math.floor((j-1)/9),(j-1)%9
    if i~=j and (r==rr or c==cc or (math.floor(r/3)==math.floor(rr/3) and math.floor(c/3)==math.floor(cc/3))) then
      peers[i][#peers[i]+1]=j
    end
  end
end
G.peers=peers
local function options(board,i)
  local used={}
  for _,j in ipairs(peers[i]) do used[board[j]]=true end
  local values={}
  for n=1,9 do if not used[n] then values[#values+1]=n end end
  return values
end
function G.count(input,budget)
  local board=copy(input)
  if #board~=81 then return 0 end
  for i=1,81 do
    if type(board[i])~='number' or board[i]<0 or board[i]>9 or board[i]~=math.floor(board[i]) then return 0 end
    if board[i]>0 then
      for _,j in ipairs(peers[i]) do if board[j]==board[i] then return 0 end end
    end
  end
  local found,nodes,exhausted=0,0,false
  local function solve()
    if found>=2 or exhausted then return end
    nodes=nodes+1
    if nodes>(budget or 12000) then exhausted=true;return end
    local best,values=nil,nil
    for i=1,81 do if board[i]==0 then
      local choices=options(board,i)
      if #choices==0 then return end -- Contradiction is not a completed grid.
      if not values or #choices<#values then best,values=i,choices end
      if #choices==1 then break end
    end end
    if not best then found=found+1;return end
    for _,v in ipairs(values) do board[best]=v;solve();board[best]=0;if found>=2 or exhausted then break end end
  end
  solve()
  return exhausted and -1 or found,nodes
end
local function shuffle(a,rand)
  for i=#a,2,-1 do local j=rand(i);a[i],a[j]=a[j],a[i] end
  return a
end
function G.generate(number,difficulty)
  assert(number>=1 and number==math.floor(number) and difficulty>=1 and difficulty<=3)
  local rand=rng(number*193+difficulty*100019)
  local digits=shuffle({1,2,3,4,5,6,7,8,9},rand)
  local bands=shuffle({0,1,2},rand)
  local stacks=shuffle({0,1,2},rand)
  local rr,cc={},{}
  for _,band in ipairs(bands) do
    for _,row in ipairs(shuffle({0,1,2},rand)) do rr[#rr+1]=band*3+row end
  end
  for _,stack in ipairs(stacks) do
    for _,col in ipairs(shuffle({0,1,2},rand)) do cc[#cc+1]=stack*3+col end
  end
  local solution={}
  local transpose=rand(2)==1
  for y=1,9 do for x=1,9 do
    local r,c=rr[y],cc[x]
    if transpose then r,c=c,r end
    solution[(y-1)*9+x]=digits[(r*3+math.floor(r/3)+c)%9+1]
  end end
  local board=copy(solution)
  local order={}
  for i=1,81 do order[i]=i end
  shuffle(order,rand)
  local remaining=81
  local target=({45,36,30})[difficulty]
  for _,i in ipairs(order) do
    if remaining<=target then break end
    local before=board[i];board[i]=0
    -- A budget exhaustion rejects the removal, preserving uniqueness.
    if G.count(board,1500)==1 then remaining=remaining-1 else board[i]=before end
  end
  return {given=board,solution=solution,clues=remaining}
end
return G
