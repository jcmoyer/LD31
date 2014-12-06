local gamestate = require('hug.gamestate')

local playstate = setmetatable({}, {__index = gamestate})
local mt = {__index = playstate}

function playstate.new()
  return setmetatable({}, mt)
end

function playstate:draw()
end

return playstate
