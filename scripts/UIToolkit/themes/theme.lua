---@omw-context player|menu

local async     = require 'openmw.async'
local storage   = require 'openmw.storage'
local vfs       = require 'openmw.vfs'

local D         = require 'scripts.UIToolkit.config.defaults'
local Sizes     = require 'scripts.UIToolkit.themes.sizes'
local Colors    = require 'scripts.UIToolkit.themes.colors'
local cfgPlayer = require 'scripts.UIToolkit.config.player'

local section   = storage.playerSection(D.Section.Interface)
local hasRe     = vfs.fileExists('textures/menu_thin_border_top2.dds')


---@class UIToolkit.Theme
local Theme = {
    Sizes = Sizes:new(),
    Colors = Colors:new(),
    --Interface Reimagined support
    IntRe = false,
}

---@param theme UIToolkit.Theme
local function updateIntRe(theme)
    local mode = cfgPlayer.interface.s_IntRe
    if mode == D.InterfaceReimagined.On then
        theme.IntRe = true
    elseif mode == D.InterfaceReimagined.Auto then
        theme.IntRe = hasRe
    else
        theme.IntRe = false
    end
end

function Theme:new()
    local o = setmetatable({}, self)
    self.__index = self
    section:subscribe(async:callback(function() updateIntRe(o) end))
    updateIntRe(o)
    return o
end

return Theme
