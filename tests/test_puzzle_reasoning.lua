-- No fixed answer is passed to the analyzer: it must derive it from clues.
package.path='shared/?.lua;'..package.path
local G=require('procedural_puzzles')
local A=require('puzzle_reasoning')
local seeds={19,101,701,3907,29011,982451653}
for _,kind in ipairs({'hitori','crowns'}) do
 for _,n in ipairs(G.sizes[kind]) do
  local solved,total,forcing=0,0,0
  for _,seed in ipairs(seeds) do
   local p=G.generate(kind,n,seed)
   if p then
    total=total+1
    local a=A.analyze(kind,n,p.clues)
    assert(a.status~='contradiction',kind..' invalid deductions')
    local seen={}
    for _,step in ipairs(a.trace) do
     assert(not seen[step.cell],'duplicate deduction')
     seen[step.cell]=true
     assert(tonumber(p.answer:sub(step.cell,step.cell))==step.value,'unsound deduction')
    end
    if a.solved then assert(a.answer==p.answer);solved=solved+1 end
    if a.counts.forcing then forcing=forcing+1 end
   end
  end
  assert(total>=4)
  print(kind..' '..n..'x'..n..': '..solved..'/'..total..' solved logically, '..forcing..' use forcing')
 end
 local p=assert(G.generate(kind,5,101))
 assert(A.analyze(kind,5,p.clues,1).status=='budget')
end
print('PASS: Hitori and Crown Fields reasoning analyzer, trace correctness and finite work')
