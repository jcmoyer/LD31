local gamestate = require('hug.gamestate')
local timerpool = require('hug.timerpool')
local rectangle = require('hug.rectangle')

local gameoverstate = setmetatable({}, {__index = gamestate})
local mt = {__index = gameoverstate }

local font = love.graphics.newFont(32)
local subfont = love.graphics.newFont(16)

local TEXT = 'game over'
local SUBTEXT = 'press <enter> to play again or <esc> to return to menu'

local fw = font:getWidth(TEXT)
local fh = font:getHeight()
local dx = love.graphics.getWidth() / 2 - fw / 2
local dy = love.graphics.getHeight() / 2 - fh / 2
local TEXTRECT = rectangle.new(dx, dy, fw, fh)
fw = subfont:getWidth(SUBTEXT)
fh = subfont:getHeight()
dx = love.graphics.getWidth() / 2 - fw / 2
dy = dy + font:getHeight() + 10 + subfont:getHeight()
local SUBTEXTRECT = rectangle.new(dx, dy, fw, fh)
local WNDRECT = rectangle.union(TEXTRECT, SUBTEXTRECT)
WNDRECT:inflate(4, 4)

function gameoverstate.new(playstate)
  local instance = {
    timerpool = timerpool.new(),
    drawText = false,
    transparent = true,
    rectangle = rectangle.new(0, 0, 0, 0),
    playstate = playstate
  }
  return setmetatable(instance, mt)
end

function gameoverstate:enter()
  self.timerpool:start(2, function()
    self.drawText = true
  end)
end

function gameoverstate:keypressed(key)
  if key == 'escape' then
    self:sm():pop()
    self:sm():pop()
  end
  
  if key == 'return' then
    self.playstate:reset()
    self:sm():pop()
  end
end

function gameoverstate:update(dt)
  self.timerpool:update(dt)
  return true
end

function gameoverstate:draw()
  if self.drawText then
    love.graphics.setFont(font)
    
    local fw = font:getWidth(TEXT)
    local fh = font:getHeight()
    
    local dx = love.graphics.getWidth() / 2 - fw / 2
    local dy = love.graphics.getHeight() / 2 - fh / 2
    
    love.graphics.setColor(68, 36, 52)
    love.graphics.rectangle('fill', unpack(WNDRECT))
    
    love.graphics.setColor(222, 238, 214)
    love.graphics.print(TEXT, dx, dy)
    
    love.graphics.setFont(subfont)
    
    fw = subfont:getWidth(SUBTEXT)
    dx = love.graphics.getWidth() / 2 - fw / 2
    
    love.graphics.print(SUBTEXT, dx, dy + font:getHeight() + 10 + subfont:getHeight())
  end
end

return gameoverstate