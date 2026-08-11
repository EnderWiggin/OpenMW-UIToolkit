---@omw-context player

local omwConstants = require('scripts.omw.mwui.constants')


---@class Sizes
local Sizes = {
    textNormal = omwConstants.textNormalSize,
    textHeader = omwConstants.textHeaderSize,
}

function Sizes:new()
    local o = setmetatable({}, self)
    self.__index = self
    return o
end

return Sizes
