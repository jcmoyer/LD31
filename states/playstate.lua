local gamestate = require('hug.gamestate')
local player = require('game.player')
local flame = require('game.flame')
local map = require('game.map')
local spawner = require('game.spawner')
local timerpool = require('hug.timerpool')
local gameoverstate = require('states.gameoverstate')
local pausestate = require('states.pausestate')

local playstate = setmetatable({}, {__index = gamestate})
local mt = {__index = playstate}

local drill = love.graphics.newImage('assets/drill.png')

local TILESIZE = 32
local SCREENW = love.graphics.getWidth()
local SCREENH = love.graphics.getHeight()
local FIELDW = SCREENW / TILESIZE
local FIELDH = SCREENH / TILESIZE

local pickup = love.audio.newSource('assets/pickup.ogg')
local scorefont = love.graphics.newFont(16)

function playstate.new()
  local instance = {
    player = player.new(),
    flame = flame.new(),
    map = map.new(FIELDW, FIELDH),
    timerpool = timerpool.new(),
    spawners = {},
    nextWave = 5,
    score = 0
  }
  instance = setmetatable(instance, mt)
  instance:reset()
  return instance
end

function playstate:reset()
  self.timerpool:clear()
  self.player = player.new()
  self.map = map.new(FIELDW, FIELDH)
  self.spawners = {}
  self.nextWave = 5
  self.player.x = math.floor(FIELDW / 2) - 1
  self.player.y = math.floor(FIELDH / 1.3)
  self.player.s = 5
  local function increaseSpeed()
    self.player.s = self.player.s + 1
    self.flame:setMagnitude(self.player.s)
    self.timerpool:start(5, increaseSpeed)
  end
  self.timerpool:start(5, increaseSpeed)
  self:startWaveTimer()
end

function playstate:startWaveTimer()
  self.timerpool:start(self.nextWave, function()
    self.nextWave = self.nextWave - 0.20
    if self.nextWave <= 2 then
      self.nextWave = 2 + love.math.random() * 3
    end  
    table.insert(self.spawners, spawner.new(self.map, spawner.newRandomSpawner()))
    self:startWaveTimer()
  end)
end

function playstate:keypressed(key)
  if key == 'up' then
    self.player.qd = 'up'
  elseif key == 'down' then
    self.player.qd = 'down'
  elseif key == 'left' then
    self.player.qd = 'left'
  elseif key == 'right' then
    self.player.qd = 'right'
  end
  
  if key == 'escape' then
    self:sm():push(pausestate.new())
  end
end

function playstate:update(dt)
  self.timerpool:update(dt)
  
  for i = 1, #self.spawners do
    self.spawners[i]:update()
  end
  
  self.map:update()
  
  if self.player.alive then
    self.player:update()
    
    if self.player.y < 0 then
      self.player.y = FIELDH - 1
    elseif self.player.y >= FIELDH then
      self.player.y = 0
    elseif self.player.x < 0 then
      self.player.x = FIELDW - 1
    elseif self.player.x >= FIELDW then
      self.player.x = 0
    end
    
    self.flame:update()
    
    local ore, id = self.map:nextOreAt(self.player.x * TILESIZE, self.player.y * TILESIZE, 32)
    while ore do
      self.score = self.score + ore.score
      self.map:removeOre(id)
      love.audio.play(pickup)
      ore, id = self.map:nextOreAt(self.player.x * TILESIZE + TILESIZE / 2, self.player.y * TILESIZE + TILESIZE / 2, 16)
    end
    
    local t = self.map:tileAt(self.player.x, self.player.y)
    if t:solid() then
      local strength = self.map:destroy(self.player.x, self.player.y)
      self.player.s = self.player.s - strength
      if self.player.s <= 0 then
        self.map:spawnExplosions(6, self.player.x, self.player.y)
        self.player.alive = false
        self:sm():push(gameoverstate.new(self))
      else
        self.flame:setMagnitude(self.player.s)
      end
    end
  end
end

function playstate:draw(a)
  love.graphics.setColor(20, 12, 28)
  love.graphics.rectangle('fill', 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
  
  love.graphics.setColor(255,255,255)
  
  self.map:draw(TILESIZE)
  
  if self.player.alive then
    local px, py = self.player:predict(TILESIZE, a)
    love.graphics.draw(drill, self.player:quad(), px + 16, py + 16, self.player:rotation(), 1, 1, 16, 16)
    
    if py < 0 then
      love.graphics.draw(drill, self.player:quad(), px + 16, 768 + py + 16, self.player:rotation(), 1, 1, 16, 16)
    elseif py > SCREENH - TILESIZE then
      love.graphics.draw(drill, self.player:quad(), px + 16, py + 16 - 768, self.player:rotation(), 1, 1, 16, 16)
    elseif px < 0 then
      love.graphics.draw(drill, self.player:quad(), 1024 + px + 16, py + 16, self.player:rotation(), 1, 1, 16, 16)
    elseif px > SCREENW - TILESIZE then
      love.graphics.draw(drill, self.player:quad(), 1024 + px + 16, py + 16, self.player:rotation(), 1, 1, 16, 16)
    end
    
    local fa = self.player:rotation()
    
    local fxo, fyo
    local fxo2, fyo2
    if self.player.d == 'up' then
      fxo = 7
      fyo = 31
      fxo2 = fxo + 16
      fyo2 = fyo
    elseif self.player.d == 'down' then
      fxo = 7+2
      fyo = 32-31
      fxo2 = fxo + 16
      fyo2 = fyo
    elseif self.player.d == 'right' then
      fxo = 2
      fyo = 7
      fxo2 = fxo
      fyo2 = fyo + 16
    elseif self.player.d == 'left' then
      fxo = 32-2
      fyo = 7+2
      fxo2 = fxo
      fyo2 = fyo + 16
    end
    
    self.flame:draw(px + fxo, py + fyo, fa)
    self.flame:draw(px + fxo2, py + fyo2, fa)
  end
  
  love.graphics.setFont(scorefont)
  local scoretext = 'Score: ' .. self.score
  local sw = scorefont:getWidth(scoretext)

  if (self.player.y < FIELDH / 2) and (self.player.x < FIELDW / 2) then
    love.graphics.print('Score: ' .. self.score, SCREENW - sw, 0)
  else
    love.graphics.print('Score: ' .. self.score)
  end
end

return playstate
