local mathx = require('hug.extensions.math')

local player = {}
local mt = {__index = player}

local TILEDIV = 256

function player.new()
  local instance = {
    -- cell coords
    x = 0,
    y = 0,
    -- progress through tile
    p = 0,
    -- speed
    s = 1,
    -- direction (up, down, left, right)
    d = 'up',
    -- queued direction
    qd = 'up',
    aframes = {
      love.graphics.newQuad(0, 0, 32, 32, 64, 32),
      love.graphics.newQuad(32, 0, 32, 32, 64, 32)
    },
    frame = 1,
    alive = true
  }
  return setmetatable(instance, mt)
end

function player:update()
  self.p = self.p + self.s * 8
  while self.p >= TILEDIV do
    self:advance()
    self.p = self.p - TILEDIV
    self.d = self.qd
  end
  self.frame = (self.frame % #self.aframes) + 1
end

function player:rotation()
  if self.d == 'up' then
    return 3 * math.pi / 2
  elseif self.d == 'down' then
    return math.pi / 2
  elseif self.d == 'left' then
    return math.pi
  elseif self.d == 'right' then
    return 0
  end
end

function player:quad()
  return self.aframes[self.frame]
end

function player:advance()
  if self.d == 'up' then
    self.y = self.y - 1
  elseif self.d == 'down' then
    self.y = self.y + 1
  elseif self.d == 'left' then
    self.x = self.x - 1
  elseif self.d == 'right' then
    self.x = self.x + 1
  end
end

function player:predict(tileSize, a)
  local thisp = self.p
  local nextp = self.p + self.s
  if self.d == 'up' then
    return self.x * tileSize, math.floor(mathx.lerp(
      self.y * tileSize - (thisp / TILEDIV) * tileSize,
      self.y * tileSize - (nextp / TILEDIV) * tileSize,
      a))
  elseif self.d == 'down' then
    return self.x * tileSize, math.floor(mathx.lerp(
      self.y * tileSize + (thisp / TILEDIV) * tileSize,
      self.y * tileSize + (nextp / TILEDIV) * tileSize,
      a))
  elseif self.d == 'left' then
    return math.floor(mathx.lerp(
      self.x * tileSize - (thisp / TILEDIV) * tileSize,
      self.x * tileSize - (nextp / TILEDIV) * tileSize,
      a)), self.y * tileSize
  elseif self.d == 'right' then
    return math.floor(mathx.lerp(
      self.x * tileSize + (thisp / TILEDIV) * tileSize,
      self.x * tileSize + (nextp / TILEDIV) * tileSize,
      a)), self.y * tileSize
  end
end

return player