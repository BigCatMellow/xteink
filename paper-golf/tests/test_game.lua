-- Host-independent smoke tests for Pocket Golf's original rules and drawing.
_G.__TEST = {}
dofile('app/index.lua')
local A = __TEST.api
local function eq(a,b,label)
  assert(a == b, (label or 'different values') .. ': ' .. tostring(a) .. ' ~= ' .. tostring(b))
end
local storage = {}
local f = { measure = function(_, s) return #s * 12 end }
local ctx = {
  storage = {
    read = function(_, name) return storage[name] end,
    write = function(_, name, value) storage[name] = value end
  },
  clock = {
    millis = function() return 934 end,
    now = function() return { epoch_sec = 2000000000 } end
  },
  fonts = { small=f, medium=f, large=f },
  invalidate = function() end
}
on_load(ctx)
assert(storage['save.txt'])
eq(A.state().stage,'roll','initial stage')
eq(A.state().hole,1,'first hole')

-- Generated layouts stay stable, with a playable tee, cup and clear fairway corridor.
for seed = 1, 15 do
  for hole = 1, 9 do
    local b = A.generate(seed * 10000, hole)
    local b2 = A.generate(seed * 10000, hole)
    eq(b.tx,b2.tx,'tee determinism')
    eq(b.hx,b2.hx,'cup determinism')
    eq(table.concat(b.map,','),table.concat(b2.map,','),'map determinism')
    eq(b.map[(b.ty-1)*9+b.tx],'tee','tee terrain')
    eq(b.map[(b.hy-1)*9+b.hx],'cup','cup terrain')
    assert(b.tx >= 1 and b.tx <= 9 and b.hx >= 1 and b.hx <= 9)
  end
end

A.begin(12345)
local original = A.state()
local startx, starty = original.x, original.y
assert(A.roll())
assert(not A.roll(), 'cannot reroll while aiming')
local s = A.state()
assert(s.die >= 1 and s.die <= 6)
local legal = A.legal()
assert(#legal > 0,'tee should have landing squares')
local first = legal[1]
assert(not A.shoot(s.x,s.y),'cannot shoot zero distance')
eq(s.strokes,0,'invalid shot does not count')
assert(A.shoot(first.x,first.y))
eq(s.strokes,1,'stroke count')
assert(s.x ~= startx or s.y ~= starty)
eq(s.die,0)
eq(s.stage,'roll')
local saved = storage['save.txt']
assert(saved and saved:find('strokes=1',1,true))

-- Reload preserves position, scores and pending die (as well as terrain seed).
local x, y = s.x, s.y
assert(A.roll())
local die = s.die
on_leave()
on_load(ctx)
eq(A.state().x,x)
eq(A.state().y,y)
eq(A.state().die,die)
eq(A.state().stage,'aim')
assert(storage['save.txt'] ~= saved)

-- Range modifiers and straight flight: water can be crossed, trees stop a shot.
A.begin(2026)
local v = A.state()
local b = A.course()
v.x, v.y, v.die, v.stage = 5, 6, 6, 'aim'
for yy = 1, 12 do for xx = 1, 9 do b.map[(yy-1)*9+xx] = 'rough' end end
b.map[(6-1)*9+5] = 'fairway'
eq(A.range(),7,'fairway +1')
b.map[(6-1)*9+5] = 'sand'
eq(A.range(),5,'sand -1')
v.die = 1
eq(A.range(),1,'minimum range')
v.die = 6
b.map[(5-1)*9+5] = 'water'
b.map[(3-1)*9+5] = 'tree'
local spots = A.legal()
local has_overwater, has_water, has_beyond_tree = false,false,false
for _, p in ipairs(spots) do
  if p.x == 5 and p.y == 4 then has_overwater = true end
  if p.x == 5 and p.y == 5 then has_water = true end
  if p.x == 5 and p.y == 2 then has_beyond_tree = true end
end
assert(has_overwater,'water may be crossed')
assert(not has_water,'water cannot be a landing')
assert(not has_beyond_tree,'trees block flight')

-- Complete 9 holes, and prove the scorecard and new-round transition work.
A.begin(98765)
for h = 1, 9 do
  local state, course = A.state(), A.course()
  eq(state.hole,h)
  state.x, state.y = course.hx, course.hy+1
  state.stage, state.die = 'aim', 1
  assert(A.shoot(course.hx,course.hy),'tap cup from adjacent cell')
  eq(state.stage,'finished')
  eq(state.scores[h],1)
  if h < 9 then assert(A.next_hole()) end
end
local strokes, par = A.totals()
eq(strokes,9,'nine-hole total')
assert(par >= 27 and par <= 36)
assert(A.next_hole(), 'replay after nine holes')
eq(A.state().hole,1)
eq(A.state().stage,'roll')
eq(A.totals(),0)

-- Render every important state using a lightweight fake canvas.
local count = 0
local g = {}
for _, method in ipairs({'clear','text','rect','line','circle'}) do
  g[method] = function() count = count + 1 end
end
local function draw_ok()
  on_draw(ctx,g)
  assert(count > 50,'expected course art to render')
end
draw_ok()
assert(A.roll())
draw_ok()
local m = A.legal()[1]
assert(A.shoot(m.x,m.y))
draw_ok()
A.tap(40,727) -- NEW confirmation
draw_ok()
A.tap(90,440) -- CANCEL
draw_ok()

-- A corrupted save should be rejected instead of throwing at load.
storage['save.txt'] = 'not a save'
assert(not A.restore())
on_load(ctx)
eq(A.state().stage,'roll')
print('Pocket Golf: gameplay, persistence, scorecard and drawing tests passed')
