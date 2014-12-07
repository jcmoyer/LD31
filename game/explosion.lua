local mathx = require('hug.extensions.math')
local vector2 = require('hug.vector2')

local explosion = {}
local mt = {__index = explosion}

local image = love.graphics.newImage('assets/explosion.png')

local quads = {}
for i = 0, 7 do
  local quad = love.graphics.newQuad(0, i * 64, 64, 64, image:getWidth(), image:getHeight())
  table.insert(quads, quad)
end

local OX, OY = 32, 32

function explosion.new(x, y, mag)
  local r = love.math.random() * math.pi * 2
  local m
  if mag then
    m = mag - (love.math.random() * mag / 2)
  else
    m = 2 + love.math.random() * 3
  end
  local instance = {
    index = 1,
    counter = 0,
    alive = true,
    p = vector2.new(x, y),
    v = vector2.new(math.cos(r) * m, math.sin(r) * m),
    r = love.math.random() * math.pi * 2
  }
  return setmetatable(instance, mt)
end

function explosion:update() 
  self.counter = self.counter + 1
  while self.counter >= 5 do
    self.low = not self.low
    self.counter = self.counter - 5
    self.index = self.index + 1
  end
  if self.index > #quads then
    self.alive = false
  end
  self.p:add(self.v)
  self.v:mul(0.80)
end

function explosion:draw()
  if self.alive then
    local dx, dy = unpack(self.p)
    love.graphics.draw(image, quads[self.index], math.floor(dx), math.floor(dy), 0, 1, 1, OX, OY)
  end
end

return explosion