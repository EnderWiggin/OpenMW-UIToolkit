---@omw-context player|menu

local async        = require 'openmw.async'
local storage      = require 'openmw.storage'
local omwConstants = require 'scripts.omw.mwui.constants'
local cfgPlayer    = require 'scripts.UIToolkit.config.player'
local D            = require 'scripts.UIToolkit.config.defaults'


local textSize = omwConstants.textNormalSize


---@class UIToolkit.Theme.Sizes
local Sizes = {
    ---@type number
    textNormal = textSize,
    ---@type number
    textHeader = omwConstants.textHeaderSize,
    border = 2,
    thickBorder = 4,
    tooltipPadding = 8,
    smallGap = 4,
    standardGap = 8,
    padding = 2,
    lineHeight = 2 + textSize,
    listRowScale = cfgPlayer.interface.f_ListRowScale,
}

function Sizes:new()
    local o = setmetatable({}, self)
    self.__index = self
    return o
end

storage.playerSection(D.Section.Interface):subscribe(async:callback(function()
    Sizes.listRowScale = cfgPlayer.interface.f_ListRowScale
end))

return Sizes
