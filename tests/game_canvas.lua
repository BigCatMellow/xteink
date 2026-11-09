-- Measured host canvas: actual line-height classes, variable glyph widths,
-- text/text collisions, button padding and screen/board boundaries.
local T={}
local function contains(a,b,pad)
  pad=pad or 0
  return b.x>=a.x+pad and b.y>=a.y+pad and b.x+b.w<=a.x+a.w-pad and b.y+b.h<=a.y+a.h-pad
end
local function overlap(a,b)
  return a.x<b.x+b.w and b.x<a.x+a.w and a.y<b.y+b.h and b.y<a.y+a.h
end
function T.fonts(scale)
  local fonts={}
  for name,height in pairs({small=20,medium=24,large=30}) do
    local f={line_height=height}
    function f:measure(s)
      local sum=0
      for ch in s:gmatch('[%z\1-\127\194-\244][\128-\191]*') do
        local unit=ch==' ' and 0.30 or ch:match('[ilI1%.,:!|]') and 0.27
          or ch:match('[MW@]') and 0.85 or 0.55
        sum=sum+unit*height*(scale or 1)
      end
      return math.ceil(sum)
    end
    fonts[name]=f
  end
  return fonts
end
function T.canvas(width,height)
  local text,buttons,regions,overflows={},{},{},{}
  local function audit(kind,box)
    if kind=='text' then text[#text+1]=box
    elseif kind=='button' then buttons[#buttons+1]=box
    elseif kind=='region' then regions[#regions+1]=box
    elseif kind=='overflow' then overflows[#overflows+1]=box.s end
  end
  local function noop() end
  local g={clear=noop,line=noop,rect=noop,circle=noop}
  function g:text(x,y,s,opt)
    local h=opt and opt.font and opt.font.line_height or 24
    assert(h>0)
  end
  function g:reset()
    text,buttons,regions,overflows={},{},{},{}
    _G.__LAYOUT=audit
  end
  function g:verify(label)
    assert(#text>0,label..': no measured text was drawn')
    assert(#overflows==0,label..': paragraph would lose content: '..tostring(overflows[1]))
    local screen={x=0,y=0,w=width or 480,h=height or 800}
    for i,a in ipairs(text) do
      assert(contains(screen,a),label..': off-screen text '..a.s)
      assert(not a.s:find('ERROR',1,true),label..': game entered error screen '..a.s)
      for j=i+1,#text do
        assert(not overlap(a,text[j]),label..': text collision: '..a.s..' / '..text[j].s)
      end
      for _,b in ipairs(buttons) do
        assert(not overlap(a,b) or contains(b,a,6),label..': text crosses button '..b.s..': '..a.s)
      end
      for _,r in ipairs(regions) do
        assert(not overlap(a,r) or contains(r,a),label..': text straddles board: '..a.s)
      end
    end
    for i,a in ipairs(buttons) do
      assert(contains(screen,a),label..': button off screen')
      for j=i+1,#buttons do
        assert(not overlap(a,buttons[j]),label..': overlapping controls '..a.s..' / '..buttons[j].s)
      end
      for _,r in ipairs(regions) do
        assert(not overlap(a,r),label..': control overlaps board '..a.s)
      end
    end
    _G.__LAYOUT=nil
  end
  return g
end
function T.check(ctx,draw,label)
  local original=ctx.fonts
  for _,scale in ipairs({1,1.25}) do
    ctx.fonts=T.fonts(scale)
    local g=T.canvas()
    g:reset();draw(ctx,g);g:verify(label..' font scale '..scale)
  end
  ctx.fonts=original
end
return T
