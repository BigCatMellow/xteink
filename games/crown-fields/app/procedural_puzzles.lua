-- Procedural generators, independent of the authored legacy puzzle banks.
-- Version 1: deterministic, 32-bit-safe PRNG, finite work, no fixed fallback.
-- A failed seed is explicit; callers must not overwrite existing progress.
local G={version=1}
local sizes={takuzu={6,8,10},mosaic={6,8,10},hitori={5,6,7,8},akari={5,6,7,8,9,10},crowns={5,6,7,8,9}}
G.sizes=sizes
local function array(n,value)
 local a={} for i=1,n do a[i]=value end return a
end
local function sequence(n)
 local a={} for i=1,n do a[i]=i end return a
end
local function copy(a)
 local b={} for i,v in ipairs(a) do b[i]=v end return b
end
local function contains(a,v)
 for _,x in ipairs(a) do if x==v then return true end end return false
end
local function random(seed)
 local state=seed
 -- Park-Miller / Schrage: no multiplication exceeds signed 32-bit range.
 return function(n)
  local hi=math.floor(state/127773)
  local lo=state-hi*127773
  state=16807*lo-2836*hi
  if state<=0 then state=state+2147483647 end
  return 1+(state-1)%n
 end
end
local function shuffle(a,r)
 for i=#a,2,-1 do local j=r(i);a[i],a[j]=a[j],a[i] end return a
end
local function neighbors(n,i,wide)
 local x,y=(i-1)%n+1,math.floor((i-1)/n)+1
 local out={}
 for dy=-1,1 do for dx=-1,1 do
  if (wide or math.abs(dx)+math.abs(dy)==1) and x+dx>=1 and x+dx<=n and y+dy>=1 and y+dy<=n then
   out[#out+1]=(y+dy-1)*n+x+dx
  end
 end end
 return out
end
local function str(a)
 local s={} for i,v in ipairs(a) do s[i]=v<0 and '.' or tostring(v) end
 return table.concat(s)
end
local function connected(n,a)
 local start,total=nil,0
 for i,v in ipairs(a) do if v~=1 then start=start or i;total=total+1 end end
 if not start then return false end
 local q,seen={start},{[start]=true};local h=1
 while h<=#q do
  for _,j in ipairs(neighbors(n,q[h],false)) do
   if a[j]~=1 and not seen[j] then seen[j]=true;q[#q+1]=j end
  end
  h=h+1
 end
 return #q==total
end

-- Complete lines for Takuzu. Enumerate without bitwise operators or large
-- integers, then use line domains for sound no-guess clue removal.
local function patterns(n)
 local out,p={},{}
 local function walk(k,ones)
  if k>n then if ones==n/2 then out[#out+1]=copy(p) end return end
  for v=0,1 do
   if ones+v<=n/2 and k-ones-v<=n/2 and not(k>=3 and p[k-1]==v and p[k-2]==v) then
    p[k]=v;walk(k+1,ones+v)
   end
  end
 end
 walk(1,0);return out
end
local function tak_full(n,pat,r,tick)
 local rows,used={},{}
 local function walk(y)
  if y>n then
   local seen={}
   for x=1,n do
    local c={} for j=1,n do c[j]=rows[j][x] end
    local key=table.concat(c);if seen[key] then return false end;seen[key]=true
   end
   return true
  end
  for _,p in ipairs(shuffle(sequence(#pat),r)) do
   tick(1)
   if not used[p] then
    local row,ok=pat[p],true
    for x=1,n do
     local ones=row[x]
     for j=1,y-1 do ones=ones+rows[j][x] end
     if ones>n/2 or y-ones>n/2 or (y>=3 and rows[y-1][x]==row[x] and rows[y-2][x]==row[x]) then ok=false;break end
    end
    if ok then
     rows[y]=row;used[p]=true
     if walk(y+1) then return true end
     used[p]=nil;rows[y]=nil
    end
   end
  end
  return false
 end
 if not walk(1) then return nil end
 local a={} for _,row in ipairs(rows) do for _,v in ipairs(row) do a[#a+1]=v end end
 return a
end
local function tak_prove(n,pat,clue,tick)
 local a=copy(clue);local rounds=0
 while true do
  local changed=false
  for axis=1,2 do
   local domains,cells,fixed={},{},{}
   for line=1,n do
    local ids={} for j=1,n do ids[j]=axis==1 and (line-1)*n+j or (j-1)*n+line end
    cells[line]=ids
    local d={}
    for k,p in ipairs(pat) do
     tick(1)
     local ok=true
     for j,i in ipairs(ids) do if a[i]>=0 and a[i]~=p[j] then ok=false;break end end
     if ok then d[#d+1]=k end
    end
    if #d==0 then return nil end
    domains[line]=d
    if #d==1 then if fixed[d[1]] then return nil end;fixed[d[1]]=true end
   end
   for line,d in ipairs(domains) do
    if #d>1 then
     local keep={} for _,k in ipairs(d) do if not fixed[k] then keep[#keep+1]=k end end
     d=keep
    end
    if #d==0 then return nil end
    for j,i in ipairs(cells[line]) do
     if a[i]<0 then
      local v,all=pat[d[1]][j],true
      for _,k in ipairs(d) do if pat[k][j]~=v then all=false;break end end
      if all then a[i]=v;changed=true end
     end
    end
   end
  end
  if not changed then
   for _,v in ipairs(a) do if v<0 then return nil end end
   return a,rounds
  end
  rounds=rounds+1
 end
end
local function takuzu(n,r,tick)
 local pat=patterns(n)
 local a=tak_full(n,pat,r,tick)
 if not a then return nil end
 local c=copy(a);local left=#c;local rounds=0
 local target=math.ceil(n*n*.32)
 for _,i in ipairs(shuffle(sequence(#c),r)) do
  local old=c[i];c[i]=-1
  local result,depth=tak_prove(n,pat,c,tick)
  if result and str(result)==str(a) then
   left=left-1;rounds=depth
   if left<=target and rounds>=2 then break end
  else c[i]=old end
 end
 if left>math.ceil(n*n*.58) or rounds<2 then return nil end
 return {clues=str(c),answer=str(a),proof='deduction',rounds=rounds}
end

-- Binary cardinality constraints, with sound subset deductions for equalities.
-- Each rule is {member indices, lower bound, upper bound}.
local function propagate(rules,a,tick,subsets)
 local rounds=0
 while true do
  local changed=false;local pending={}
  for _,rule in ipairs(rules) do
   tick(1)
   local unknown,ones={},0
   for _,i in ipairs(rule[1]) do
    if a[i]<0 then unknown[#unknown+1]=i elseif a[i]==1 then ones=ones+1 end
   end
   local lo=math.max(0,rule[2]-ones)
   local hi=math.min(#unknown,rule[3]-ones)
   if lo>hi then return nil end
   if #unknown>0 and (hi==0 or lo==#unknown) then
    local v=hi==0 and 0 or 1
    for _,i in ipairs(unknown) do a[i]=v;changed=true end
   elseif subsets and #unknown>0 and lo==hi then
    local set={} for _,i in ipairs(unknown) do set[i]=true end
    pending[#pending+1]={unknown,lo,set}
   end
  end
  if subsets and not changed then
   -- Make one sound subset deduction at a time, then rebuild residual rules.
   for _,A in ipairs(pending) do
    for _,B in ipairs(pending) do
     tick(1)
     if #A[1]<#B[1] then
      local subset=true
      for _,i in ipairs(A[1]) do if not B[3][i] then subset=false;break end end
      if subset then
       local count=B[2]-A[2];local len=#B[1]-#A[1]
       if count<0 or count>len then return nil end
       if count==0 or count==len then
        for _,i in ipairs(B[1]) do if not A[3][i] then a[i]=count==0 and 0 or 1 end end
        changed=true;break
       end
      end
     end
    end
    if changed then break end
   end
  end
  if not changed then return a,rounds end
  rounds=rounds+1
 end
end
local function all_assigned(a)
 for _,v in ipairs(a) do if v<0 then return false end end return true
end
local function mosaic_prove(n,c,tick)
 local rules={}
 for i,v in ipairs(c) do if v>=0 then rules[#rules+1]={neighbors(n,i,true),v,v} end end
 local a,rounds=propagate(rules,array(n*n,-1),tick,true)
 if a and all_assigned(a) then return a,rounds end
end
local function mosaic(n,r,tick)
 for _=1,24 do
  local a,c={},{}
  for i=1,n*n do a[i]=r(100)<=45 and 1 or 0 end
  for i=1,#a do local count=0 for _,j in ipairs(neighbors(n,i,true)) do count=count+a[j] end c[i]=count end
  local solved=mosaic_prove(n,c,tick)
  if solved then
   local left=#c;local rounds=0;local target=math.ceil(n*n*.58)
   for _,i in ipairs(shuffle(sequence(#c),r)) do
    local old=c[i];c[i]=-1
    local v,depth=mosaic_prove(n,c,tick)
    if v and str(v)==str(a) then
     left=left-1;rounds=depth
     if left<=target and rounds>=3 then break end
    else c[i]=old end
   end
   if left<=math.ceil(n*n*.75) and rounds>=3 then return {clues=str(c),answer=str(a),proof='deduction',rounds=rounds} end
  end
 end
end

-- Akari: random wall topology, a non-conflicting maximal lamp set, then
-- numbered-wall constraints. Remove clues only if forced deductions still
-- reconstruct the entire lamp assignment.
local function akari_rules(n,grid)
 local cells,ids,visible,rules={},{},{},{}
 for i,ch in ipairs(grid) do if ch=='.' then cells[#cells+1]=i;ids[i]=#cells end end
 for k,i in ipairs(cells) do
  local x,y=(i-1)%n+1,math.floor((i-1)/n)+1
  local h,v={k},{k}
  for _,d in ipairs({{-1,0},{1,0},{0,-1},{0,1}}) do
   local a,b=x+d[1],y+d[2]
   while a>=1 and a<=n and b>=1 and b<=n do
    local j=ids[(b-1)*n+a];if not j then break end
    local t=d[1]~=0 and h or v;t[#t+1]=j
    a=a+d[1];b=b+d[2]
   end
  end
  local lit=copy(h)
  for j=2,#v do lit[#lit+1]=v[j] end
  visible[k]=lit
  rules[#rules+1]={h,0,1};rules[#rules+1]={v,0,1};rules[#rules+1]={lit,1,#lit}
 end
 for i,ch in ipairs(grid) do
  local v=tonumber(ch)
  if v then
   local t={} for _,j in ipairs(neighbors(n,i,false)) do if ids[j] then t[#t+1]=ids[j] end end
   rules[#rules+1]={t,v,v}
  end
 end
 return cells,visible,rules
end
local function akari_prove(n,grid,tick)
 local cells,_,rules=akari_rules(n,grid)
 local a,rounds=propagate(rules,array(#cells,-1),tick,false)
 if not a or not all_assigned(a) then return nil end
 local full=array(n*n,0)
 for i,j in ipairs(cells) do full[j]=a[i] end
 return full,rounds
end
local function akari(n,r,tick)
 for _=1,64 do
  tick(1)
  local grid={}
  for i=1,n*n do grid[i]=r(100)<=25 and '#' or '.' end
  local cells,visible=akari_rules(n,grid)
  if #cells>=math.ceil(n*n*.55) and #cells<=math.floor(n*n*.9) then
   local lit,full={},array(n*n,0)
   local lamps=0
   for _,i in ipairs(shuffle(sequence(#cells),r)) do
    if not lit[i] then
     full[cells[i]]=1;lamps=lamps+1
     for _,j in ipairs(visible[i]) do lit[j]=true end
    end
   end
   if lamps>=n then
    local walls={}
    for i,ch in ipairs(grid) do
     if ch=='#' then
      local v=0 for _,j in ipairs(neighbors(n,i,false)) do v=v+full[j] end
      grid[i]=tostring(v);walls[#walls+1]=i
     end
    end
    local solved,rounds=akari_prove(n,grid,tick)
    if solved and str(solved)==str(full) then
     local left=#walls
     for _,i in ipairs(shuffle(walls,r)) do
      if left<=2 then break end
      local old=grid[i];grid[i]='#'
      local a,d=akari_prove(n,grid,tick)
      if a and str(a)==str(full) then left=left-1;rounds=d else grid[i]=old end
     end
     if rounds>=2 then return {clues=table.concat(grid),answer=str(full),proof='deduction',rounds=rounds} end
    end
   end
  end
 end
end

-- Hitori: randomized Latin square, connected unshaded cells, non-adjacent
-- shaded cells, duplicated values in both axes. Independent exact counting
-- rejects any second answer. The count is not a human difficulty rating.
local function hitori_count(n,c,tick)
 local rules,degree={},array(n*n,0)
 local function add(i,j,lo,hi)
  rules[#rules+1]={{i,j},lo,hi};degree[i]=degree[i]+1;degree[j]=degree[j]+1
 end
 for i=1,#c do
  for j=i+1,#c do
   if c[i]==c[j] and ((i-1)%n==(j-1)%n or math.floor((i-1)/n)==math.floor((j-1)/n)) then add(i,j,1,2) end
  end
  for _,j in ipairs(neighbors(n,i,false)) do if j>i then add(i,j,0,1) end end
 end
 local count,first,nodes=0,nil,0
 local function search(a)
  if count>=2 then return end
  tick(1);nodes=nodes+1
  local v=propagate(rules,a,tick,false)
  if not v or not connected(n,v) then return end
  local i=nil
  for j,x in ipairs(v) do if x<0 and (not i or degree[j]>degree[i]) then i=j end end
  if not i then count=count+1;first=first or v;return end
  for bit=0,1 do local b=copy(v);b[i]=bit;search(b) end
 end
 search(array(n*n,-1))
 return count,first,nodes
end
local function hitori(n,r,tick)
 for _=1,160 do
  tick(1)
  local xs,ys,digits=shuffle(sequence(n),r),shuffle(sequence(n),r),shuffle(sequence(n),r)
  local c,a={},array(n*n,0)
  for y=1,n do for x=1,n do c[(y-1)*n+x]=digits[(xs[x]+ys[y]-2)%n+1] end end
  local target=math.floor(n*n*.25);local shaded=0
  for _,i in ipairs(shuffle(sequence(n*n),r)) do
   local ok=true for _,j in ipairs(neighbors(n,i,false)) do if a[j]==1 then ok=false;break end end
   if ok then a[i]=1;if connected(n,a) then shaded=shaded+1 else a[i]=0 end end
   if shaded>=target then break end
  end
  if shaded==target then
   local ok=true
   for i,v in ipairs(a) do
    if v==1 then
     local x,y=(i-1)%n+1,math.floor((i-1)/n)+1
     local row,col,choices={},{},{}
     for j=1,n do
      local p,q=(y-1)*n+j,(j-1)*n+x
      if a[p]==0 then row[c[p]]=true end
      if a[q]==0 then col[c[q]]=true end
     end
     for j=1,n do if row[j] and col[j] and j~=c[i] then choices[#choices+1]=j end end
     if #choices==0 then ok=false;break end
     c[i]=choices[r(#choices)]
    end
   end
   if ok then
    local count,answer,nodes=hitori_count(n,c,tick)
    if count==1 and str(answer)==str(a) and nodes>=3 then return {clues=str(c),answer=str(a),proof='unique',nodes=nodes} end
   end
  end
 end
end

-- Crown Fields: start with a random valid crown permutation. Grow contiguous
-- regions one cell at a time, rejecting any growth that introduces a second
-- solution. No disconnected/single-cell regions or fixed-board symmetries.
local function crown_count(n,b,tick)
 local count,rows,cols,regions=0,{},{},{}
 local function walk(y,prior)
  if count>=2 then return end
  tick(1)
  if y>n then count=count+1;return end
  for x=1,n do
   local v=b[(y-1)*n+x]
   if v>0 and not cols[x] and not regions[v] and math.abs(x-prior)>1 then
    cols[x]=true;regions[v]=true;rows[y]=x
    walk(y+1,x)
    cols[x]=nil;regions[v]=nil
    if count>=2 then return end
   end
  end
 end
 walk(1,-2);return count
end
local function crowns(n,r,tick)
 for _=1,96 do
  local p=nil
  for _=1,100 do
   tick(1)
   local a=shuffle(sequence(n),r);local ok=true
   for y=2,n do if math.abs(a[y]-a[y-1])<=1 then ok=false;break end end
   if ok then p=a;break end
  end
  if p then
   local b,sizes,answer=array(n*n,0),array(n,1),array(n*n,0)
   for y=1,n do local i=(y-1)*n+p[y];b[i]=y;answer[i]=1 end
   local good=true
   for _=1,n*n-n do
    local options,small={},{}
    for i=1,#b do if b[i]==0 then
     local seen={}
     for _,j in ipairs(neighbors(n,i,false)) do
      local v=b[j]
      if v>0 and not seen[v] then
       seen[v]=true;local opt={i,v};options[#options+1]=opt
       if sizes[v]<2 then small[#small+1]=opt end
      end
     end
    end end
    local added=false
    for _,group in ipairs({shuffle(small,r),shuffle(options,r)}) do
     for _,opt in ipairs(group) do
      tick(1)
      local i,v=opt[1],opt[2]
      b[i]=v
      if crown_count(n,b,tick)==1 then sizes[v]=sizes[v]+1;added=true;break end
      b[i]=0
     end
     if added then break end
    end
    if not added then good=false;break end
   end
   for _,v in ipairs(sizes) do if v<2 then good=false end end
   if good then
    local s={} for i,v in ipairs(b) do s[i]=string.char(64+v) end
    return {clues=table.concat(s),answer=str(answer),proof='unique'}
   end
  end
 end
end
local makers={takuzu=takuzu,mosaic=mosaic,hitori=hitori,akari=akari,crowns=crowns}
function G.generate(kind,n,seed,max_work)
 assert(makers[kind] and contains(sizes[kind],n),'Invalid puzzle kind or size')
 assert(type(seed)=='number' and seed==math.floor(seed) and seed>=1 and seed<=2147483646,'Invalid seed')
 local work,limit=0,max_work or 12000000
 assert(type(limit)=='number' and limit>=1 and limit<=12000000,'Invalid work budget')
 local stop={}
 local function tick(n0)
  work=work+n0
  if work>limit then error(stop,0) end
 end
 local ok,p=pcall(makers[kind],n,random(seed),tick)
 if not ok then
  if p==stop then return nil,'budget exhausted',work end
  error(p,0)
 end
 if not p then return nil,'no acceptable puzzle',work end
 p.kind=kind;p.n=n;p.seed=seed;p.version=G.version;p.work=work
 return p
end
return G
