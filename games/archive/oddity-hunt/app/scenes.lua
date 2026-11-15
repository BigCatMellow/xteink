-- Authored scene sets + deterministic scatter. No runtime randomness or animation.
local M={}
M.KINDS={
 'KEY','FISH','LEAF','BOAT','STAR','MOON','CUP','CROWN','BELL','HOUSE',
 'FLOWER','ANCHOR','BOOK','KITE','HEART','BIRD','CLOCK','UMBRELLA','APPLE','LANTERN'
}
M.LEVELS={
 {name='THE ATTIC',targets={1,2,3,4,5},slots={4,13,22,31,40},seed=1103},
 {name='CURIO SHOP',targets={6,7,8,9,10},slots={1,17,23,32,42},seed=2047},
 {name='BOTANIC TABLE',targets={11,12,13,14,15},slots={7,10,24,34,38},seed=3517},
 {name='CLOCKROOM',targets={16,17,18,19,20},slots={2,16,21,33,41},seed=4801},
 {name='NIGHT DESK',targets={1,8,11,16,19},slots={5,14,27,29,39},seed=5297},
 {name='HARBOR BOX',targets={2,6,12,15,18},slots={3,12,19,35,42},seed=6481},
 {name='LOST AND FOUND',targets={3,7,13,17,20},slots={6,15,22,30,37},seed=7159},
 {name='OLD LIBRARY',targets={4,9,14,16,18},slots={1,9,26,34,40},seed=8317},
 {name='STARGAZER',targets={5,10,11,15,19},slots={4,16,28,36,42},seed=9697},
 {name='COTTAGE SHELF',targets={1,6,12,17,20},slots={7,13,23,31,39},seed=10193},
 {name='MUSEUM CABINET',targets={2,8,13,14,19},slots={2,14,24,33,38},seed=11071},
 {name='FINAL SHELF',targets={3,9,11,16,18},slots={5,12,21,35,41},seed=12109}
}
local function step(x) return (x*48271)%2147483647 end
local function rand(state,n)
  state=step(state)
  return state,(state%n)+1
end
function M.build(level)
  local p=M.LEVELS[level]
  if not p then error('invalid scene') end
  local targetAt={}
  local reserved={}
  for i,kind in ipairs(p.targets) do
    if reserved[kind] then error('duplicate target') end
    reserved[kind]=true
    if targetAt[p.slots[i]] then error('duplicate target slot') end
    targetAt[p.slots[i]]=i
  end
  local fillers={}
  for k=1,#M.KINDS do
    if not reserved[k] then fillers[#fillers+1]=k end
  end
  local state=p.seed
  -- Use each distractor at least twice, then shuffle the 37-piece pool.
  local pool={}
  for i=1,37 do pool[i]=fillers[(i-1)%#fillers+1] end
  for i=#pool,2,-1 do
    local j
    state,j=rand(state,i)
    pool[i],pool[j]=pool[j],pool[i]
  end
  local objects={}
  local distractor=1
  for slot=1,42 do
    local col=(slot-1)%7
    local row=math.floor((slot-1)/7)
    local jx,jy
    state,jx=rand(state,15)
    state,jy=rand(state,15)
    local ti=targetAt[slot]
    local kind=ti and p.targets[ti] or pool[distractor]
    if not ti then distractor=distractor+1 end
    objects[slot]={
      x=50+col*62+jx-8,
      y=169+row*70+jy-8,
      kind=kind,target=ti or 0,slot=slot
    }
  end
  return {name=p.name,objects=objects,targets=p.targets}
end
return M
