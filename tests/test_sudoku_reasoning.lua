-- Verify the Sudoku analyzer against previously independently validated seeds.
package.path='shared/?.lua;games/sudoku/app/?.lua;'..package.path
local G=require('generator')
local A=require('sudoku_reasoning')
local total,solved,ranks=0,0,{}
for d=1,5 do
 local hits=0
 for seed=1,12 do
  local p=G.generate(seed,d,2)
  local a=A.analyze(p.given)
  assert(a.status~='contradiction','valid Sudoku rejected')
  for _,step in ipairs(a.trace) do
   if step.action=='place' then assert(p.solution[step.cell]==step.digit,'incorrect deduction')
   else assert(p.solution[step.cell]~=step.digit,'removed true digit') end
  end
  if a.solved then
   assert(table.concat(a.answer)==table.concat(p.solution))
   solved=solved+1;hits=hits+1;ranks[a.rank]=(ranks[a.rank] or 0)+1
  end
  total=total+1
 end
 print('Sudoku v2 tier '..d..': '..hits..'/12 solved with implemented techniques')
end
local sample=assert(G.generate(101,2,2))
assert(A.analyze(sample.given,1).status=='budget')
local bad={};for i=1,81 do bad[i]=0 end;bad[1]=1;bad[2]=1
assert(A.analyze(bad).status=='contradiction')
assert(solved>=24,'too few solved boards for a useful classifier')
for i=1,5 do print('Technique rank '..i..': '..(ranks[i] or 0)) end
print('PASS: Sudoku deduction trace agrees with '..total..' known unique answers')
