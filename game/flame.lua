local mathx = require('hug.extensions.math')

local flame = {}
local mt = {__index = flame}

local image = love.graphics.newImage('assets/flames.png')

local quads = {
  love.graphics.newQuad(0, 0, 32, 8, image:getWidth(), image:getHeight()),
  love.graphics.newQuad(0, 8, 32, 8, image:getWidth(), image:getHeight()),
  love.graphics.newQuad(0, 16, 32, 8, image:getWidth(), image:getHeight()),
  love.graphics.newQuad(0, 24, 32, 8, image:getWidth(), image:getHeight()),
  love.graphics.newQuad(0, 32, 32, 8, image:getWidth(), image:getHeight()),
  love.graphics.newQuad(0, 40, 32, 8, image:getWidth(), image:getHeight()),
  love.graphics.newQuad(0, 48, 32, 8, image:getWidth(), image:getHeight()),
  love.graphics.newQuad(0, 56, 32, 8, image:getWidth(), image:getHeight())
}

local OX, OY = 28, 3

function flame.new()
  local instance = {
    index = 1,
    mag   = 1,
    low   = true,
    counter = 0
  }
  return setmetatable(instance, mt)
end

function flame:setMagnitude(n)
  self.mag = mathx.clamp(n, 1, 7)
end

function flame:update()
  -- flicker between current and next highest
  if self.low then
    self.index = self.mag
  else
    self.index = self.mag + 1
  end
  
  self.counter = self.counter + 1
  while self.counter >= 10 do
    self.low = not self.low
    self.counter = self.counter - 10
  end
end

function flame:draw(x, y, r)
  love.graphics.draw(image, quads[self.index], x, y, r, 1, 1, OX, OY)
end

return flame