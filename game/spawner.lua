local spawner = {}
local mt = {__index = spawner}

function spawner.new(map, f)
  local instance = {
    map = map,
    nextSpawn = 10,
    f = f
  }
  return setmetatable(instance, mt)
end

local options = {
  function()
    local x1 = love.math.random(0, 31)
    local y1 = love.math.random(0, 23)
    local x2 = love.math.random(0, 31)
    local y2 = love.math.random(0, 23)
    local id = love.math.random(1, 2)
    return spawner.newLineSpawner(id, x1, y1, x2, y2)
  end,
  function()
    local x = love.math.random(0, 31)
    local y = love.math.random(0, 23)
    local r = love.math.random(2, 10)
    local id = love.math.random(1, 2)
    return spawner.newCircleSpawner(id, x, y, r)
  end,
  function()
    local n = love.math.random(1, 10)
    local t = {}
    for i = 1, n do
      local x = love.math.random(0, 31)
      local y = love.math.random(0, 23)
      table.insert(t, {x, y})
    end
    local id = love.math.random(1, 2)
    return spawner.newPointSpawner(id, t)
  end,
  function()
    -- fuel spawner
    local t = {}
    local x = love.math.random(0, 31)
    local y = love.math.random(0, 23)
    table.insert(t, {x, y})
    return spawner.newPointSpawner(3, t)
  end,
  function()
    -- tnt spawner
    local t = {}
    local x = love.math.random(0, 31)
    local y = love.math.random(0, 23)
    table.insert(t, {x, y})
    return spawner.newPointSpawner(4, t)
  end,
  function()
    -- steel spawner
    local n = love.math.random(1, 4)
    local t = {}
    for i = 1, n do
      local x = love.math.random(0, 31)
      local y = love.math.random(0, 23)
      table.insert(t, {x, y})
    end
    return spawner.newPointSpawner(5, t)
  end
}

local rng = love.math.newRandomGenerator()

function spawner.newRandomSpawner()
  return options[rng:random(1, #options)]()
end

function spawner.newSequenceSpawner(...)
  local xs = {...}
  local i = 1
  return function()
    local f = xs[i]
    if not f then
      return
    end
    repeat
      local id, x, y = f()
      if id and x and y then
        return id, x, y
      end
      i = i + 1
    until not (id and x and y)
  end
end

function spawner.newXSpawner(x1, y1, d)
  local n = 0
  return function()
    if n < d then
      n = n + 1
      return x1 + n, y1 + n
    end
  end
end

function spawner.newCircleSpawner(id, x, y, r)
  local a = 0
  return function()
    if a <= 2 * math.pi then
      a = a + math.pi / 16
      return id, math.floor(x + math.cos(a) * r), math.floor(y + math.sin(a) * r)
    end
  end
end

function spawner.newPointSpawner(id, t)
  local points = t
  local i = 1
  return function()
    local p = points[i]
    i = i + 1
    if p then
      return id, p[1], p[2]
    end
  end
end

function spawner.newLineSpawner(id, x0, y0, x1, y1)
  local points = {}
  
  local steep = math.abs(y1 - y0) > math.abs(x1 - x0)
  if steep then
    x0, y0 = y0, x0
    x1, y1 = y1, x1
  end
  
  if x0 > x1 then
    x0, x1 = x1, x0
    y0, y1 = y1, y0
  end
  
  local dx = x1 - x0
  local dy = math.abs(y1 - y0)
  
  local error = dx / 2
  local ystep
  if y0 < y1 then
    ystep = 1
  else
    ystep = -1
  end
  
  local y = y0
  local maxx = x1
  
  for x = x0, maxx - 1 do
    if steep then
      table.insert(points, {y, x})
    else
      table.insert(points, {x, y})
    end
    error = error - dy
    if error < 0 then
      y = y + ystep
      error = error + dx
    end
  end
  
  local i = 1
  return function()
    local p = points[i]
    i = i + 1
    if p then
      return id, p[1], p[2]
    end
  end
end

function spawner:update()
  self.nextSpawn = self.nextSpawn - 1
  
  while self.nextSpawn <= 0 do
    local id, x, y = self.f()
    if id and x and y then
      self.map:spawn(id, x, y)
    end
    self.nextSpawn = self.nextSpawn + 10
  end
end

return spawner