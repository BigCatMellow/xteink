-- Sudoku reasoning profile v3 candidate. Pure logic, no RNG or answer lookup.
-- A stalled solver means this technique set was insufficient, not that a
-- puzzle inherently requires guessing. This module does not modify v1/v2.
local A={}
local units,peers,rows,cols,boxes={},{},{},{},{}
for i=1,9 do
 local row,col,box={},{},{}
 for j=1,9 do
  row[j]=(i-1)*9+j;col[j]=(j-1)*9+i
  box[j]=(math.floor((i-1)/3)*3+math.floor((j-1)/3))*9+((i-1)%3)*3+(j-1)%3+1
 end
 units[i]=row;units[9+i]=col;units[18+i]=box
end
for i=1,81 do
 rows[i]=math.floor((i-1)/9)+1;cols[i]=(i-1)%9+1
 boxes[i]=math.floor((rows[i]-1)/3)*3+math.floor((cols[i]-1)/3)+1
 local t={}
 for j=1,81 do
  if i~=j and (cols[i]==(j-1)%9+1 or rows[i]==math.floor((j-1)/9)+1 or boxes[i]==math.floor(math.floor((j-1)/9)/3)*3+math.floor(((j-1)%9)/3)+1) then
   t[#t+1]=j
  end
 end
 peers[i]=t
end
local bit,card,values={},{},{}
for d=1,9 do bit[d]=2^(d-1) end
for m=0,511 do
 local a={}
 for d=1,9 do if math.floor(m/bit[d])%2==1 then a[#a+1]=d end end
 values[m]=a;card[m]=#a
end
local function has(m,d)return math.floor(m/bit[d])%2==1 end
local rank={naked_single=1,hidden_single=2,locked=3,naked_pair=4,hidden_pair=4,xwing=5}
function A.analyze(input,limit)
 assert(type(input)=='table' and #input==81,'Invalid Sudoku dimensions')
 local b,c={},{}
 local counts,trace,work,highest={}, {},0,0
 local cap=limit or 1000000
 local stop={}
 local function tick(n)
  work=work+(n or 1)
  if work>cap then error(stop,0) end
 end
 local function log(tech,cell,d,action)
  counts[tech]=(counts[tech] or 0)+1;highest=math.max(highest,rank[tech])
  trace[#trace+1]={technique=tech,cell=cell,digit=d,action=action}
 end
 for i=1,81 do
  local v=input[i]
  assert(type(v)=='number' and v==math.floor(v) and v>=0 and v<=9,'Invalid Sudoku digit')
  b[i]=v;c[i]=v==0 and 511 or 0
 end
 local function result(status)
  local remaining=0
  for _,v in ipairs(b) do if v==0 then remaining=remaining+1 end end
  return {status=status,solved=status=='solved',answer=b,counts=counts,trace=trace,rank=highest,
   remaining=remaining,work=work}
 end
 for i,v in ipairs(b) do
  if v>0 then
   for _,j in ipairs(peers[i]) do
    if b[j]==v then return result('contradiction') end
    if has(c[j],v) then c[j]=c[j]-bit[v] end
   end
  end
 end
 local function place(i,d,tech)
  if b[i]~=0 or not has(c[i],d) then return false end
  b[i]=d;c[i]=0;log(tech,i,d,'place')
  for _,j in ipairs(peers[i]) do if has(c[j],d) then c[j]=c[j]-bit[d] end end
  return true
 end
 local function remove(i,d,tech)
  if not has(c[i],d) then return false end
  c[i]=c[i]-bit[d];log(tech,i,d,'remove');return true
 end
 local function spots(u,d)
  local a={}
  for _,i in ipairs(u) do if has(c[i],d) then a[#a+1]=i end end
  return a
 end
 local function allsame(a,which)
  local v=which[a[1]]
  for _,i in ipairs(a) do if which[i]~=v then return nil end end
  return v
 end
 local function naked()
  for i=1,81 do
   tick()
   if b[i]==0 and card[c[i]]==1 then return place(i,values[c[i]][1],'naked_single') end
  end
  return false
 end
 local function hidden()
  for _,u in ipairs(units) do
   for d=1,9 do
    tick()
    local a=spots(u,d)
    if #a==1 then return place(a[1],d,'hidden_single') end
   end
  end
  return false
 end
 local function locked()
  for k=1,27 do
   local u=units[k]
   for d=1,9 do
    tick()
    local a=spots(u,d)
    if #a>1 then
     if k>18 then
      local row,col=allsame(a,rows),allsame(a,cols)
      local t=row and units[row] or col and units[9+col]
      if t then
       local changed=false
       for _,i in ipairs(t) do if boxes[i]~=k-18 and remove(i,d,'locked') then changed=true end end
       if changed then return true end
      end
     else
      local box=allsame(a,boxes)
      if box then
       local changed=false
       for _,i in ipairs(units[18+box]) do
        if ((k<=9 and rows[i]~=k) or (k>9 and cols[i]~=k-9)) and remove(i,d,'locked') then changed=true end
       end
       if changed then return true end
      end
     end
    end
   end
  end
  return false
 end
 local function naked_pair()
  for _,u in ipairs(units) do
   for x=1,8 do
    local i=u[x]
    if card[c[i]]==2 then
     local mask=c[i]
     for y=x+1,9 do
      tick()
      local j=u[y]
      if c[j]==mask then
       local count=0
       for _,q in ipairs(u) do if c[q]==mask then count=count+1 end end
       if count==2 then
        local changed=false
        for _,q in ipairs(u) do if q~=i and q~=j then
         for _,d in ipairs(values[mask]) do if remove(q,d,'naked_pair') then changed=true end end
        end end
        if changed then return true end
       end
      end
     end
    end
   end
  end
  return false
 end
 local function hidden_pair()
  for _,u in ipairs(units) do
   for d=1,8 do
    local a=spots(u,d)
    if #a==2 then
     for e=d+1,9 do
      tick()
      local t=spots(u,e)
      if #t==2 and t[1]==a[1] and t[2]==a[2] then
       local changed=false
       for _,i in ipairs(a) do
        local old=c[i]
        for _,v in ipairs(values[old]) do if v~=d and v~=e and remove(i,v,'hidden_pair') then changed=true end end
       end
       if changed then return true end
      end
     end
    end
   end
  end
  return false
 end
 local function xwing()
  for axis=0,1 do
   local cross=axis==0 and cols or rows
   local along=axis==0 and rows or cols
   for d=1,9 do
    for x=1,8 do
     local a=spots(units[axis*9+x],d)
     if #a==2 then
      for y=x+1,9 do
       tick()
       local t=spots(units[axis*9+y],d)
       if #t==2 and cross[t[1]]==cross[a[1]] and cross[t[2]]==cross[a[2]] then
        local changed=false
        for i=1,81 do
         if along[i]~=x and along[i]~=y and (cross[i]==cross[a[1]] or cross[i]==cross[a[2]]) and remove(i,d,'xwing') then changed=true end
        end
        if changed then return true end
       end
      end
     end
    end
   end
  end
  return false
 end
 local function solve()
  while true do
   local unknown=0
   for i=1,81 do if b[i]==0 then
    if c[i]==0 then return 'contradiction' end
    unknown=unknown+1
   end end
   if unknown==0 then return 'solved' end
   for _,u in ipairs(units) do
    local seen={}
    for _,i in ipairs(u) do
     if b[i]>0 then if seen[b[i]] then return 'contradiction' end;seen[b[i]]=true end
    end
    for d=1,9 do
     if not seen[d] and #spots(u,d)==0 then return 'contradiction' end
    end
   end
   if not (naked() or hidden() or locked() or naked_pair() or hidden_pair() or xwing()) then return 'stalled' end
  end
 end
 local ok,status=pcall(solve)
 if not ok then if status==stop then status='budget' else error(status,0) end end
 return result(status)
end
return A
