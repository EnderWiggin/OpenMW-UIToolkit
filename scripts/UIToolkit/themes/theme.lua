---@omw-context player

local Sizes = require('scripts.UIToolkit.themes.sizes')
local Colors = require('scripts.UIToolkit.themes.colors')


---@class Theme
local Theme = {
    Sizes = Sizes:new(),
    Colors = Colors:new(),
}

function Theme:new()
    local o = setmetatable({}, self)
    self.__index = self
    return o
end

return Theme
