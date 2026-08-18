---@omw-context player

local omwConstants = require('scripts.omw.mwui.constants')


---@class UIToolkit.Theme.Sizes
local Sizes = {
    ---@type number
    textNormal = omwConstants.textNormalSize,
    ---@type number
    textHeader = omwConstants.textHeaderSize,
    border = 2,
    thickBorder = 4,
    tooltipPadding = 8,
    smallGap = 4,
    standardGap = 8,
    padding = 2,
}

function Sizes:new()
    local o = setmetatable({}, self)
    self.__index = self
    return o
end

return Sizes
