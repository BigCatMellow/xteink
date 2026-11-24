-- Explainable Hitori and Crown Fields difficulty analysis.
-- This is a deduction proof, not a human rating or an exhaustive solver.
-- Candidate contradiction checks are one level deep: no recursive guessing.
local A={}
local function array(n,value)local t={} for i=1,n do t[i]=value end return t end
local function clone(a)local t={} for i,v in ipairs(a) do t[i]=v end return t end
local function neighbors(n,i)
 local t={};local x,y=(i-1)%n+1,math.floor((i-1)/n)+1
 if x>1 then t[#t+1]=i-1 end
 if x<n then t[#t+1]=i+1 end
 if y>1 then t[#t+1]=i-n end
 if y<n then t[#t+1]=i+n end
 return t
end
local function hitori_rules(n,clues)
 local rules={}
 for i=1,n*n do
  for j=i+1,n*n do
   if clues:sub(i,i)==clues:sub(j,j) and ((i-1)%n==(j-1)%n or math.floor((i-1)/n)==math.floor((j-1)/n)) then
    rules[#rules+1]={{i,j},1,2,'duplicate'}
   end
  end
  for _,j in ipairs(neighbors(n,i)) do if j>i then rules[#rules+1]={{i,j},0,1,'adjacent'} end end
 end
 return rules
end
local function crown_rules(n,clues)
 local rules={}
 for i=1,n do
  local row,col,reg={},{},{}
  for j=1,n do row[j]=(i-1)*n+j;col[j]=(j-1)*n+i end
  for j=1,n*n do if clues:byte(j)==64+i then reg[#reg+1]=j end end
  rules[#rules+1]={row,1,1,'row'}
  rules[#rules+1]={col,1,1,'column'}
  rules[#rules+1]={reg,1,1,'region'}
 end
 for y=1,n-1 do for x=1,n do
  local i=(y-1)*n+x
  for _,dx in ipairs({-1,1}) do
   if x+dx>=1 and x+dx<=n then rules[#rules+1]={{i,y*n+x+dx},0,1,'touch'} end
  end
 end end
 return rules
end
-- Required white cells must connect via cells that can still be white.
-- Unknown-only components are not assumed white.
local function possible_white(n,a,blocked)
 local start,total=nil,0
 for i,v in ipairs(a) do if v==0 then start=start or i;total=total+1 end end
 if not start then return true end
 if blocked==start then return false end
 local q,seen={start},{[start]=true};local h,count=1,0
 while h<=#q do
  local i=q[h];h=h+1
  if a[i]==0 then count=count+1 end
  for _,j in ipairs(neighbors(n,i)) do
   if j~=blocked and a[j]~=1 and not seen[j] then seen[j]=true;q[#q+1]=j end
  end
 end
 return count==total
end
function A.analyze(kind,n,clues,budget)
 assert(kind=='hitori' or kind=='crowns','Unsupported reasoning kind')
 assert(type(clues)=='string' and #clues==n*n,'Invalid clues')
 local rules=kind=='hitori' and hitori_rules(n,clues) or crown_rules(n,clues)
 local a=array(n*n,-1)
 local trace,counts,work,rounds={}, {},0,0
 local limit=budget or 1000000
 local stop={}
 local function tick()
  work=work+1
  if work>limit then error(stop,0) end
 end
 local function put(state,i,v,rule,log)
  if state[i]==v then return true end
  if state[i]>=0 then return false end
  state[i]=v
  if log then
   counts[rule]=(counts[rule] or 0)+1
   trace[#trace+1]={cell=i,value=v,technique=rule}
  end
  return true
 end
 local function propagate(state,log)
  while true do
   local changed=false
   local exact={}
   for _,r in ipairs(rules) do
    tick()
    local unknown,ones={},0
    for _,i in ipairs(r[1]) do
     if state[i]<0 then unknown[#unknown+1]=i elseif state[i]==1 then ones=ones+1 end
    end
    local lo,hi=math.max(0,r[2]-ones),math.min(#unknown,r[3]-ones)
    if lo>hi then return false end
    if #unknown>0 and (hi==0 or lo==#unknown) then
     local v=hi==0 and 0 or 1
     for _,i in ipairs(unknown) do
      if not put(state,i,v,r[4],log) then return false end
      changed=true
     end
    elseif kind=='crowns' and lo==hi and #unknown>0 then
     local set={} for _,i in ipairs(unknown) do set[i]=true end
     exact[#exact+1]={unknown,lo,set}
    end
   end
   if kind=='hitori' then
    if not possible_white(n,state) then return false end
    if not changed then
     for i,v in ipairs(state) do
      tick()
      if v<0 and not possible_white(n,state,i) then
       if not put(state,i,0,'connectivity',log) then return false end
       changed=true;break
      end
     end
    end
   elseif not changed then
    -- Locked candidates: when a smaller exact unit is contained in a
    -- larger residual exact unit, subtract its known count.
    for _,x in ipairs(exact) do
     for _,y in ipairs(exact) do
      tick()
      if #x[1]<#y[1] then
       local subset=true
       for _,i in ipairs(x[1]) do if not y[3][i] then subset=false;break end end
       if subset then
        local remaining=y[2]-x[2];local len=#y[1]-#x[1]
        if remaining<0 or remaining>len then return false end
        if remaining==0 or remaining==len then
         for _,i in ipairs(y[1]) do if not x[3][i] then
          if not put(state,i,remaining==0 and 0 or 1,'locked',log) then return false end
          changed=true
         end end
        end
       end
      end
      if changed then break end
     end
     if changed then break end
    end
   end
   if not changed then return true end
   if log then rounds=rounds+1 end
  end
 end
 local function solve()
  while true do
   if not propagate(a,true) then return 'contradiction' end
   local unknown=0
   for _,v in ipairs(a) do if v<0 then unknown=unknown+1 end end
   if unknown==0 then return 'solved' end
   local forced=false
   for i,v in ipairs(a) do
    if v<0 then
     local zero,one=clone(a),clone(a)
     zero[i]=0;one[i]=1
     local valid0=propagate(zero,false)
     local valid1=propagate(one,false)
     if not valid0 and not valid1 then return 'contradiction' end
     if valid0~=valid1 then
      assert(put(a,i,valid0 and 0 or 1,'forcing',true))
      forced=true;break
     end
    end
   end
   if not forced then return 'stalled' end
  end
 end
 local ok,status=pcall(solve)
 if not ok then if status==stop then status='budget' else error(status,0) end end
 local digits,remaining={},0
 for i,v in ipairs(a) do digits[i]=v<0 and '.' or tostring(v);if v<0 then remaining=remaining+1 end end
 local technique=counts.forcing and 'forcing' or (counts.connectivity or counts.locked) and 'intermediate' or 'direct'
 return {status=status,solved=status=='solved',answer=table.concat(digits),remaining=remaining,
  counts=counts,technique=technique,rounds=rounds,work=work,trace=trace}
end
return A
