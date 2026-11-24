-- Emit original generated boards for a separate Python verifier.
package.path='shared/?.lua;'..package.path
local G=require('procedural_puzzles')
local seeds={19,101,701,3907,29011,982451653}
for _,kind in ipairs({'takuzu','mosaic','hitori','akari','crowns'}) do
 for _,n in ipairs(G.sizes[kind]) do
  local seen,success={},0
  for _,seed in ipairs(seeds) do
   local p,err,work=G.generate(kind,n,seed)
   if p then
    local again=assert(G.generate(kind,n,seed))
    assert(p.clues==again.clues and p.answer==again.answer and p.work==again.work,'seed replay mismatch')
    assert(#p.clues==n*n and #p.answer==n*n)
    assert(not seen[p.clues],'duplicate board in seed sample')
    seen[p.clues]=true;success=success+1
    print(table.concat({kind,n,seed,p.clues,p.answer,p.proof,p.work},'\t'))
   else
    io.stderr:write(kind..' '..n..' seed '..seed..': '..err..' ('..work..')\n')
   end
  end
  assert(success>=4,kind..' '..n..' insufficient success: '..success)
 end
 local p,why=G.generate(kind,G.sizes[kind][1],19,1)
 assert(p==nil and why=='budget exhausted','bounded failure must not return a fixed puzzle')
end
