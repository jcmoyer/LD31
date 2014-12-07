local vector2 = require('hug.vector2')
local mathx = require('hug.extensions.math')
local explosion = require('game.explosion')

local ore = {}
ore.__index = ore

function ore.new(image, score, x, y, vx, vy)
  local instance = {
    image = image,
    p = vector2.new(x, y),
    v = vector2.new(vx, vy),
    score = score
  }
  return setmetatable(instance, ore)
end

function ore:update()
  self.p:add(self.v)
  self.v:mul(0.95)
end

function ore:draw()
  love.graphics.setColor(255, 255, 255)
  local dx, dy = unpack(self.p)
  love.graphics.draw(self.image, math.floor(dx), math.floor(dy))
end

local tile = {}
tile.__index = tile

local spawn = love.audio.newSource('assets/spawn.ogg')
local lightexplosion = love.audio.newSource('assets/lightexplosion.ogg')
local heavyexplosion = love.audio.newSource('assets/heavyexplosion.ogg')
local tntexplode = love.audio.newSource('assets/tntexplode.ogg')

local tiles = {
  {
    block    = love.graphics.newImage('assets/block0.png'),
    ore      = love.graphics.newImage('assets/ore0.png'),
    strength = 1,
    sound    = lightexplosion
  },
  {
    block    = love.graphics.newImage('assets/block1.png'),
    ore      = love.graphics.newImage('assets/ore1.png'),
    strength = 3,
    sound    = heavyexplosion
  },
  {
    block = love.graphics.newImage('assets/fuel.png'),
    strength = -5
  },
  {
    block = love.graphics.newImage('assets/tnt.png'),
    strength = 0,
    sound    = tntexplode,
    handler = function(map, x, y)
      map:spawnExplosions(10, x, y, 10)
      for dx = x - 2, x + 2 do
        for dy = y - 2, y + 2 do
          map:destroy(dx, dy)
        end
      end
    end
  },
  {
    block = love.graphics.newImage('assets/block2.png'),
    ore = love.graphics.newImage('assets/ore2.png'),
    sound = heavyexplosion,
    strength = 5,
    handler = function(map, x, y)
      map:spawnExplosions(2, x, y)
    end
  }
}

function tile.new(n)
  n = mathx.clamp(n, 1, #tiles)
  local instance = {
    data = tiles[1],
    state = 'invisible',
    counter = 0,
    drawSpawner = false,
    spawnTicks = 0
  }
  return setmetatable(instance, tile)
end

function tile:setData(n)
  n = mathx.clamp(n, 1, #tiles)
  self.data = tiles[n]
end

function tile:solid()
  return self.state == 'solid'
end

function tile:update()  
  if self.state == 'spawning' then
    self.counter = self.counter + 1
    while self.counter > 8 do
      self.drawSpawner = not self.drawSpawner
      self.counter = self.counter - 8
      self.spawnTicks = self.spawnTicks + 1
    end
  end
  
  if self.spawnTicks > 20 then
    self.spawnTicks = 0
    love.audio.play(spawn)
    self.state = 'solid'
  end
end

function tile:draw(x, y, tileSize)
  if self.state == 'spawning' then
    if self.drawSpawner then
      love.graphics.setColor(222, 238, 214)
      love.graphics.rectangle('fill', x, y, tileSize, tileSize)
    end
  elseif self.state == 'solid' then
    love.graphics.setColor(255, 255, 255)
    love.graphics.draw(self.data.block, x, y)
  end
end

function tile:destroy()
  if self.data.sound then
    love.audio.play(self.data.sound)
  end
  self.state = 'invisible'
end

local map = {}
local mt = {__index = map}

function map.new(width, height)
  local instance = {
    width = width,
    height = height,
    ores = {},
    explosions = {}
  }
  
  local data = {}
  for y = 0, height do
    for x = 0, width do
      local ix = y * width + x + 1
      data[ix] = tile.new(1)
    end
  end
  
  instance.data = data
  
  return setmetatable(instance, mt)
end

function map:update()
  for i = 1, #self.data do
    self.data[i]:update()
  end
  
  for i = 1, #self.ores do
    self.ores[i]:update()
  end
  
  for i = 1, #self.explosions do
    local explosion = self.explosions[i]
    explosion:update()
  end
end

function map:draw(tileSize)
  for y = 0, self.height do
    for x = 0, self.width do
      local ix = y * self.width + x + 1
      local t  = self.data[ix]
      t:draw(x * tileSize, y * tileSize, tileSize)
    end
  end
  
  for i = 1, #self.ores do
    self.ores[i]:draw()
  end
  
  for i = 1, #self.explosions do
    local explosion = self.explosions[i]
    explosion:draw()
  end
end

function map:spawn(n, x, y)
  if x < 0 or x >= self.width or y < 0 or y >= self.height then return end
  local ix = y * self.width + x + 1
  local t  = self.data[ix]
  if t.state == 'invisible' then
    t:setData(n)
    t.state = 'spawning'
  end
end

function map:tileAt(x, y)
  local ix = y * self.width + x + 1
  local t  = self.data[ix]
  return t
end

function map:destroy(x, y)
  if x < 0 or x >= self.width or y < 0 or y >= self.height then return end
  local ix = y * self.width + x + 1
  local t = self.data[ix]
  if t.state == 'invisible' then return end
  t:destroy()
  
  -- spawn ore
  if t.data.ore then
    for i = 1, 2 + math.floor(love.math.random() * 4) do
      local mag = love.math.random()
      local angle = love.math.random() * math.pi * 2
      local vx = math.cos(angle) * (5 + mag * 10)
      local vy = math.sin(angle) * (5 + mag * 10)
      table.insert(self.ores, ore.new(t.data.ore, t.data.strength * 100, x * 32, y * 32, vx, vy))
    end
  end
  
  if t.data.handler then
    t.data.handler(self, x, y)
  end
  
  return t.data.strength
end

function map:nextOreAt(x, y, r)
  for i = 1, #self.ores do
    local ore = self.ores[i]
    -- only consider ores that have slowed down/stopped
    if (ore.v[1] < 0.2) and (ore.v[2] < 0.2) then
      local vec = ore.p
      local distance = math.sqrt((x - vec[1] + 8)^2 + (y - vec[2] + 8)^2)
      if distance <= r then
        return ore, i
      end
    end
  end
end

function map:removeOre(id)
  table.remove(self.ores, id)
end

function map:spawnExplosions(n, x, y, m)
  for i = 1, n do
    table.insert(self.explosions, explosion.new(x * 32, y * 32, m))
  end
end

return map