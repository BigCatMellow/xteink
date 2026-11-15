-- Original miniature black-on-white line art for Oddity Hunt.
-- Geometry fits a 48x48 touch neighborhood; no images, text, or animation.
local M={}
function M.draw(g,kind,cx,cy,variant)
  local s=(variant%4==0) and 0.9 or 1
  local mirror=(variant%5==0) and -1 or 1
  local function X(x) return math.floor(cx+x*s*mirror+0.5) end
  local function Y(y) return math.floor(cy+y*s+0.5) end
  local function line(a,b,c,d)
    g:line(X(a),Y(b),X(c),Y(d),{line_width=2})
  end
  local function circle(x,y,r,filled)
    g:circle(X(x),Y(y),math.floor(r*s+0.5),filled and {fill=true} or {line_width=2})
  end
  local function rect(x,y,w,h)
    local x1,x2=X(x),X(x+w)
    g:rect(math.min(x1,x2),Y(y),math.abs(x2-x1),math.floor(h*s+0.5),{line_width=2})
  end
  if kind==1 then -- KEY
    circle(-11,-8,7);circle(-11,-8,2)
    line(-5,-4,15,12);line(15,12,18,8);line(11,9,8,14)
    line(8,14,4,10)
  elseif kind==2 then -- FISH
    line(-16,0,-6,-10);line(-6,-10,10,-8)
    line(10,-8,16,0);line(16,0,10,8)
    line(10,8,-6,10);line(-6,10,-16,0)
    line(-16,0,-22,-9);line(-22,-9,-22,9);line(-22,9,-16,0)
    circle(9,-2,2,true);line(-5,-8,0,-15);line(0,-15,5,-9)
  elseif kind==3 then -- LEAF
    line(-17,16,-10,-1);line(-10,-1,1,-14);line(1,-14,14,-18)
    line(14,-18,18,-3);line(18,-3,8,10);line(8,10,-17,16)
    line(-18,18,13,-11)
    line(0,3,0,-8);line(7,-4,13,-4);line(-5,8,-12,7)
  elseif kind==4 then -- BOAT
    line(-19,7,19,7);line(19,7,12,17);line(12,17,-12,17)
    line(-12,17,-19,7);line(0,7,0,-19)
    line(0,-18,15,4);line(15,4,0,4)
    line(-2,-14,-12,4);line(-12,4,-2,4)
  elseif kind==5 then -- STAR
    local pts={{0,-20},{5,-7},{19,-6},{8,3},{13,18},{0,9},{-13,18},{-8,3},{-19,-6},{-5,-7}}
    for i,p in ipairs(pts) do
      local q=pts[i%#pts+1]
      line(p[1],p[2],q[1],q[2])
    end
    circle(0,1,2,true)
  elseif kind==6 then -- MOON
    line(5,-19,-5,-16);line(-5,-16,-13,-8);line(-13,-8,-16,1)
    line(-16,1,-12,11);line(-12,11,-3,17);line(-3,17,7,19)
    line(7,19,1,12);line(1,12,-3,4);line(-3,4,-3,-4)
    line(-3,-4,0,-12);line(0,-12,5,-19)
    circle(13,-12,2,true);circle(16,10,1,true)
  elseif kind==7 then -- CUP
    line(-15,-12,13,-12);line(13,-12,10,12);line(10,12,-12,12)
    line(-12,12,-15,-12);circle(17,-2,7)
    line(-19,16,18,16);line(-7,-17,4,-17)
  elseif kind==8 then -- CROWN
    line(-17,-10,-10,3);line(-10,3,-5,-18)
    line(-5,-18,0,1);line(0,1,7,-16)
    line(7,-16,12,3);line(12,3,19,-10)
    line(19,-10,13,12);line(13,12,-14,12);line(-14,12,-17,-10)
    rect(-14,13,27,5)
  elseif kind==9 then -- BELL
    line(-14,9,-8,4);line(-8,4,-8,-8)
    line(-8,-8,-4,-14);line(-4,-14,4,-14)
    line(4,-14,9,-8);line(9,-8,9,4);line(9,4,15,9)
    line(15,9,-14,9);circle(0,-17,3)
    line(-16,12,16,12);circle(0,15,3,true)
  elseif kind==10 then -- HOUSE
    line(-20,-3,0,-19);line(0,-19,20,-3);line(-16,-6,-16,17)
    line(-16,17,16,17);line(16,17,16,-6)
    rect(-6,3,12,14);rect(8,-3,5,7)
    circle(3,11,1,true)
  elseif kind==11 then -- FLOWER
    circle(0,-9,5,true)
    circle(0,-19,6);circle(10,-12,6)
    circle(7,-2,6);circle(-7,-2,6);circle(-10,-12,6)
    line(0,-3,0,19);line(0,9,-12,4);line(-12,4,-8,15)
    line(0,11,12,7);line(12,7,8,17)
  elseif kind==12 then -- ANCHOR
    circle(0,-17,5);line(0,-12,0,16)
    line(-10,-6,10,-6);line(-14,6,-14,13);line(-14,13,-6,18)
    line(-6,18,0,16);line(0,16,6,18);line(6,18,14,13)
    line(14,13,14,6);line(-19,6,-14,6);line(14,6,19,6)
  elseif kind==13 then -- BOOK
    line(0,-13,-16,-18);line(-16,-18,-19,12);line(-19,12,0,16)
    line(0,16,19,12);line(19,12,16,-18);line(16,-18,0,-13)
    line(0,-13,0,16);line(-14,-9,-4,-5);line(4,-5,14,-9)
    line(-14,0,-4,4);line(4,4,14,0)
  elseif kind==14 then -- KITE
    line(0,-20,17,-1);line(17,-1,0,18);line(0,18,-17,-1)
    line(-17,-1,0,-20);line(0,-20,0,18);line(-17,-1,17,-1)
    line(0,18,6,23);line(6,23,11,18)
  elseif kind==15 then -- HEART
    local pts={{0,-12},{-8,-19},{-17,-15},{-20,-6},{-17,2},
      {0,19},{17,2},{20,-6},{17,-15},{8,-19}}
    for i,p in ipairs(pts) do
      local q=pts[i%#pts+1]
      line(p[1],p[2],q[1],q[2])
    end
  elseif kind==16 then -- BIRD
    circle(-4,4,13);circle(8,-10,8)
    line(15,-10,21,-7);line(21,-7,15,-4)
    line(-12,4,-20,-4);line(-20,-4,-19,9);line(-19,9,-12,9)
    line(-14,2,-1,12);line(-1,12,7,1)
    circle(10,-12,2,true)
    line(-6,16,-6,21);line(-6,21,-12,21)
    line(3,16,3,21);line(3,21,8,21)
  elseif kind==17 then -- CLOCK
    circle(0,0,18);circle(0,0,2,true)
    line(0,0,0,-12);line(0,0,9,5)
    line(0,-16,0,-14);line(16,0,14,0)
    line(0,16,0,14);line(-16,0,-14,0)
    line(-8,-20,8,-20)
  elseif kind==18 then -- UMBRELLA
    line(-20,-3,-12,-13);line(-12,-13,0,-18);line(0,-18,12,-13)
    line(12,-13,20,-3);line(-20,-3,-10,-2);line(-10,-2,0,-5)
    line(0,-5,10,-2);line(10,-2,20,-3)
    line(0,-18,0,13);line(0,13,5,18);line(5,18,11,15)
  elseif kind==19 then -- APPLE
    circle(-7,3,12);circle(7,3,12)
    line(-14,13,-7,18);line(-7,18,0,16)
    line(0,16,7,18);line(7,18,14,13)
    line(0,-7,1,-20);line(1,-20,12,-17);line(12,-17,6,-12)
  elseif kind==20 then -- LANTERN
    line(-10,-15,10,-15);line(-10,-15,-15,-9);line(10,-15,15,-9)
    rect(-15,-9,30,27);rect(-9,-4,18,17)
    line(-10,18,10,18);line(-5,-15,-5,-20);line(-5,-20,5,-20)
    line(5,-20,5,-15);line(-15,4,-20,4);line(15,4,20,4)
    circle(0,5,3,true)
  end
end
return M
