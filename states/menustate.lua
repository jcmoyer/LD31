local gamestate = require('hug.gamestate')
local playstate = require('states.playstate')

local menustate = setmetatable({}, {__index = gamestate})
local mt = {__index = menustate}

local namefont = love.graphics.newFont(48)
local linefont = love.graphics.newFont(24)

local lines = {
  'use the arrow keys to move',
  'survive as long as possible! hitting blocks slows you down!',
  'if your speed reaches zero, game over!',
  'running into a block at high speed will break it into ore',
  'collect ore to increase your score'
}

function menustate.new()
  local instance = {
  }
  return setmetatable(instance, mt)
end

function menustate:keypressed(key)
  if key == 'return' then
    self:sm():push(playstate.new())
  end
  
  if key == 'escape' then
    love.event.quit()
  end
end

function menustate:draw()
  love.graphics.setColor(20/255, 12/255, 28/255)
  love.graphics.rectangle('fill', 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
  
  local title = love.window.getTitle()
  love.graphics.setFont(namefont)
  love.graphics.setColor(222/255, 238/255, 214/255)
  local tw = namefont:getWidth(title)
  love.graphics.print(title, love.graphics.getWidth() / 2 - tw / 2, love.graphics.getHeight() / 6)
  
  local basey = 240
  local basex = 32
  local spacing = 15
  local lineheight = linefont:getHeight()
  love.graphics.setFont(linefont)
  love.graphics.setColor(222/255, 238/255, 214/255)
  for i = 1, #lines do
    love.graphics.print(lines[i], basex, basey + (i - 1) * (spacing + lineheight))
  end
  
  local instr = 'press <enter> when you\'re ready to play'
  local lw = linefont:getWidth(instr)
  
  love.graphics.print(instr, love.graphics.getWidth() / 2 - lw / 2, love.graphics.getHeight() / 1.5)
end

return menustate
