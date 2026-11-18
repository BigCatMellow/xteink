-- Procedural, deterministic, no-guess Minesweeper generator.
-- Uses the same direct-number and subset-difference inference as Hint.
-- A candidate is accepted only after the solver opens every safe square.
-- No prearranged mine coordinates, unverified "best" fallback or RNG state leaks.
local G={}
local SETTINGS={
  {n=8,mines=10,minOpening=12,maxOpening=55,minPasses=2,minSubset=0},
  {n=10,mines=18,minOpening=7,maxOpening=48,minPasses=3,minSubset=1},
  {n=12,mines=27,minOpening=4,maxOpening=48,minPasses=4,minSubset=2}
}
G.settings=SETTINGS
local MAXSEED=2147483646
local function rng(seed)
  local s=math.floor(seed)%MAXSEED+1
  return function(limit)
    s=s*16807%2147483647
    return s%limit+1
  end
end
local neighborhoods={}
local function neighbors(n)
  if neighborhoods[n] then return neighborhoods[n] end
  local all={}
  for i=1,n*n do
    local x,y=(i-1)%n+1,math.floor((i-1)/n)+1
    local list={}
    for dy=-1,1 do for dx=-1,1 do
      local xx,yy=x+dx,y+dy
      if (dx~=0 or dy~=0) and xx>=1 and yy>=1 and xx<=n and yy<=n then
        list[#list+1]=(yy-1)*n+xx
      end
    end end
    all[i]=list
  end
  neighborhoods[n]=all
  return all
end
local function build(n,indices)
  local mine={}
  for _,i in ipairs(indices) do mine[i]=true end
  local adj=neighbors(n)
  local clues={}
  for i=1,n*n do
    local count=0
    for _,j in ipairs(adj[i]) do if mine[j] then count=count+1 end end
    clues[i]=count
  end
  return mine,adj,clues
end
local function reveal(i,mine,adj,clues,opened,flagged)
  local q,head={i},1
  local changed=0
  while head<=#q do
    local p=q[head];head=head+1
    if not opened[p] and not flagged[p] and not mine[p] then
      opened[p]=true;changed=changed+1
      if clues[p]==0 then
        for _,j in ipairs(adj[p]) do
          if not opened[j] and not flagged[j] then q[#q+1]=j end
        end
      end
    end
  end
  return changed
end
local function candidates(n,mine,adj,clues,opened,flagged)
  local constraints={}
  for i=1,n*n do
    if opened[i] and clues[i]>0 then
      local hidden,need,lookup={},clues[i],{}
      for _,j in ipairs(adj[i]) do
        if flagged[j] then need=need-1
        elseif not opened[j] then hidden[#hidden+1]=j;lookup[j]=true end
      end
      if need<0 or need>#hidden then return nil end
      if #hidden>0 then
        constraints[#constraints+1]={hidden=hidden,need=need,lookup=lookup}
      end
    end
  end
  return constraints
end
local function inferred(constraints)
  local safe,flag={},{}
  local count=0
  local function add(dest,i)
    if not dest[i] then dest[i]=true;count=count+1 end
  end
  for _,c in ipairs(constraints) do
    if c.need==0 then for _,i in ipairs(c.hidden) do add(safe,i) end
    elseif c.need==#c.hidden then for _,i in ipairs(c.hidden) do add(flag,i) end end
  end
  if count>0 then return safe,flag,false end
  local subset=false
  for _,a in ipairs(constraints) do
    for _,b in ipairs(constraints) do
      if #a.hidden<#b.hidden then
        local contained=true
        for _,i in ipairs(a.hidden) do
          if not b.lookup[i] then contained=false;break end
        end
        if contained then
          local remaining=b.need-a.need
          local extra={}
          for _,i in ipairs(b.hidden) do
            if not a.lookup[i] then extra[#extra+1]=i end
          end
          if remaining==0 then
            for _,i in ipairs(extra) do add(safe,i) end
            subset=true
          elseif remaining==#extra then
            for _,i in ipairs(extra) do add(flag,i) end
            subset=true
          end
        end
      end
    end
  end
  return safe,flag,subset
end
function G.analyze(n,positions)
  if type(n)~='number' or n<4 or n>12 or type(positions)~='table' then
    return {solved=false,reason='invalid dimensions'}
  end
  local mine,adj,clues=build(n,positions)
  if mine[1] or clues[1]~=0 then return {solved=false,reason='unsafe start'} end
  local opened,flagged={},{}
  local opening=reveal(1,mine,adj,clues,opened,flagged)
  local passes,subsetMoves,subsetPasses=0,0,0
  for _=1,n*n*2 do
    local constraints=candidates(n,mine,adj,clues,opened,flagged)
    if not constraints then break end
    local safe,flag,subset=inferred(constraints)
    local progressed,moveCount=0,0
    for i=1,n*n do
      if flag[i] and not flagged[i] then
        if not mine[i] then return {solved=false,reason='bad mine deduction'} end
        flagged[i]=true;progressed=progressed+1;moveCount=moveCount+1
      end
    end
    for i=1,n*n do
      if safe[i] and not opened[i] and not flagged[i] then
        if mine[i] then return {solved=false,reason='bad safe deduction'} end
        progressed=progressed+reveal(i,mine,adj,clues,opened,flagged)
        moveCount=moveCount+1
      end
    end
    if progressed==0 then break end
    passes=passes+1
    if subset then
      subsetMoves=subsetMoves+moveCount
      subsetPasses=subsetPasses+1
    end
  end
  local openedCount=0
  for i=1,n*n do if opened[i] then openedCount=openedCount+1 end end
  return {solved=openedCount==n*n-#positions,
    opening=opening,passes=passes,subsetMoves=subsetMoves,
    subsetPasses=subsetPasses,opened=openedCount}
end
function G.generate(seed,difficulty)
  local cfg=SETTINGS[difficulty]
  assert(cfg and type(seed)=='number' and seed>=1 and seed==math.floor(seed))
  local n=cfg.n
  local random=rng(seed*131+difficulty*791009)
  local pool={}
  for i=1,n*n do
    local x,y=(i-1)%n+1,math.floor((i-1)/n)+1
    if x>2 or y>2 then pool[#pool+1]=i end
  end
  for attempt=1,128 do
    -- Partial Fisher-Yates: no duplicate mine positions.
    for i=#pool,2,-1 do
      local j=random(i)
      pool[i],pool[j]=pool[j],pool[i]
    end
    local indices={}
    for i=1,cfg.mines do indices[i]=pool[i] end
    local metrics=G.analyze(n,indices)
    if metrics.solved and
       metrics.opening>=cfg.minOpening and
       metrics.opening<=cfg.maxOpening and
       metrics.passes>=cfg.minPasses and
       metrics.subsetMoves>=cfg.minSubset then
      table.sort(indices)
      return {n=n,mines=indices,difficulty=difficulty,seed=seed,
        attempts=attempt,metrics=metrics}
    end
  end
  return nil,'No verified no-guess field for this seed'
end
return G
