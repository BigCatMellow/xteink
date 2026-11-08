-- Stable generator v1. Never change an existing seed's grid: saves store its number.
local G={}
local dirs={{1,0},{0,1},{1,1},{0,-1},{-1,0},{1,-1},{-1,1},{-1,-1}}
local themes={
  {'FOREST','PINE','FERN','BARK','ROOT'}, {'SPACE','MOON','STAR','COMET','ORBIT'},
  {'OCEAN','SHARK','SHELL','CORAL','WAVE'}, {'GARDEN','ROSE','SEED','PETAL','VINE'},
  {'KITCHEN','SPOON','FORK','PLATE','CUP'}, {'CASTLE','CROWN','SWORD','GUARD','TOWER'},
  {'WEATHER','CLOUD','RAIN','STORM','WIND'}, {'MUSIC','HARP','DRUM','FLUTE','PIANO'},
  {'TRAIL','PATH','HILL','CAMP','ROCK'}, {'WINTER','SNOW','FROST','ICE','SLED'},
  {'WORKSHOP','NAIL','BOLT','SAW','CLAMP'}, {'MEADOW','HARE','MOTH','GRASS','DEW'},
  {'ART','PAINT','BRUSH','INK','FRAME'}, {'TRAVEL','TRAIN','BOAT','ROAD','MAP'},
  {'FRUIT','PEAR','APPLE','PLUM','LIME'}, {'NIGHT','DREAM','SLEEP','DUSK','DARK'}
}
local function rng(seed)
  local s=seed%2147483646+1
  return function(n) s=s*16807%2147483647;return s%n+1 end
end
local function matches(grid,n,word)
  local result={}
  for y=1,n do for x=1,n do for _,d in ipairs(dirs) do
    local ex,ey=x+(#word-1)*d[1],y+(#word-1)*d[2]
    if ex>=1 and ex<=n and ey>=1 and ey<=n then
      local good=true
      for j=1,#word do
        if grid[y+(j-1)*d[2]][x+(j-1)*d[1]]~=word:sub(j,j) then good=false;break end
      end
      if good then result[#result+1]={x,y,d[1],d[2]} end
    end
  end end end
  return result
end
local function rows(grid,n)
  local result={}
  for y=1,n do result[y]=table.concat(grid[y]) end
  return result
end
function G.generate(mode,number)
  assert((mode==1 or mode==2) and number>=1 and number==math.floor(number))
  local rand=rng(number*97+mode*100003)
  if mode==1 then
    local theme=themes[rand(#themes)]
    local words={theme[2],theme[3],theme[4],theme[5]}
    for attempt=1,64 do
      local grid,paths={},{}
      for y=1,8 do grid[y]={} end
      local placed=true
      for i,word in ipairs(words) do
        local path=nil
        for trial=1,80 do
          local d=dirs[rand(8)]
          local x,y=rand(8),rand(8)
          local ex,ey=x+(#word-1)*d[1],y+(#word-1)*d[2]
          if ex>=1 and ex<=8 and ey>=1 and ey<=8 then
            local good=true
            for j=1,#word do
              local ch=grid[y+(j-1)*d[2]][x+(j-1)*d[1]]
              if ch and ch~=word:sub(j,j) then good=false;break end
            end
            if good then path={x,y,d[1],d[2]};break end
          end
        end
        if not path then placed=false;break end
        paths[i]=path
        for j=1,#word do grid[path[2]+(j-1)*path[4]][path[1]+(j-1)*path[3]]=word:sub(j,j) end
      end
      if placed then
        for y=1,8 do for x=1,8 do
          if not grid[y][x] then grid[y][x]=string.char(64+rand(26)) end
        end end
        local unique=true
        for _,word in ipairs(words) do if #matches(grid,8,word)~=1 then unique=false;break end end
        if unique then return {title=theme[1],n=8,words=words,paths=paths,rows=rows(grid,8)} end
      end
    end
    -- Guaranteed construction: separated rows, filler absent from every target.
    local grid,paths={},{}
    for y=1,8 do grid[y]={};for x=1,8 do grid[y][x]='Z' end end
    for i,word in ipairs(words) do
      local reverse=rand(2)==1
      local x,y=rand(9-#word),i*2-1
      paths[i]={reverse and x+#word-1 or x,y,reverse and -1 or 1,0}
      for j=1,#word do grid[y][paths[i][1]+(j-1)*paths[i][3]]=word:sub(j,j) end
    end
    return {title=theme[1],n=8,words=words,paths=paths,rows=rows(grid,8)}
  end
  -- Keep one chosen FOX fixed, then repair every accidental occurrence.
  local grid,locked={},{}
  local d=dirs[(number-1)%8+1]
  local x,y=2+rand(9),2+rand(9)
  local path={x,y,d[1],d[2]}
  for j=1,3 do locked[(y+(j-1)*d[2]-1)*13+x+(j-1)*d[1]]=true end
  for yy=1,13 do grid[yy]={} end
  for yy=1,13 do for xx=1,13 do local k=rand(3);grid[yy][xx]=('FOX'):sub(k,k) end end
  for j=1,3 do grid[y+(j-1)*d[2]][x+(j-1)*d[1]]=('FOX'):sub(j,j) end
  for repair=1,2048 do
    local extra=nil
    for _,a in ipairs(matches(grid,13,'FOX')) do
      if a[1]~=x or a[2]~=y or a[3]~=d[1] or a[4]~=d[2] then extra=a;break end
    end
    if not extra then return {title='FIND THE FOX',n=13,words={'FOX'},paths={path},rows=rows(grid,13)} end
    local choices={}
    for j=0,2 do
      local xx,yy=extra[1]+j*extra[3],extra[2]+j*extra[4]
      if not locked[(yy-1)*13+xx] then choices[#choices+1]={xx,yy} end
    end
    local a=choices[rand(#choices)]
    local old=grid[a[2]][a[1]]
    local k=rand(2)
    local alternatives=old=='F' and 'OX' or old=='O' and 'FX' or 'FO'
    grid[a[2]][a[1]]=alternatives:sub(k,k)
  end
  -- Bounded fallback: one O, with all other opposite neighbor pairs equal.
  for yy=1,13 do for xx=1,13 do grid[yy][xx]=rand(2)==1 and 'F' or 'X' end end
  local ox,oy=x+d[1],y+d[2]
  for _,v in ipairs({{1,0},{0,1},{1,1},{1,-1}}) do
    local a,b=ox-v[1],oy-v[2]
    local c,e=ox+v[1],oy+v[2]
    grid[b][a]='F';grid[e][c]='F'
  end
  for j=1,3 do grid[y+(j-1)*d[2]][x+(j-1)*d[1]]=('FOX'):sub(j,j) end
  return {title='FIND THE FOX',n=13,words={'FOX'},paths={path},rows=rows(grid,13)}
end
return G
