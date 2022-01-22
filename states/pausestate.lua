local gamestate = require('hug.gamestate')

local pausestate = setmetatable({}, {__index = gamestate})
pausestate.__index = pausestate

local font = love.graphics.newFont(32)

function pausestate.new()
  local instance = { transparent = true }
  return setmetatable(instance, pausestate)
end

function pausestate:keypressed(key)
  if key == 'escape' then
    self:sm():pop()
  end
end

function pausestate:draw()
  local text = 'paused'
  
  love.graphics.setFont(font)
  
  local tw = font:getWidth(text)
  local th = font:getHeight()
  
  local sw = love.graphics.getWidth()
  local sh = love.graphics.getHeight()
  
  local dx = sw / 2 - tw / 2
  local dy = sh / 2 - th / 2
  
  love.graphics.setColor(68/255, 36/255, 52/255)
  love.graphics.rectangle('fill', dx - 4, dy - 4, tw + 8, th + 8)
  
  love.graphics.setColor(222/255, 238/255, 214/255)
  love.graphics.print('paused', dx, dy)
  
  return true
end

return pausestate
