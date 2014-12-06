local gamestate = require('hug.gamestate')

local menustate = setmetatable({}, {__index = gamestate})

return menustate