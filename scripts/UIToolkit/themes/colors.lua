---@omw-context player

local core = require('openmw.core')
local util = require('openmw.util')
local ui = require('openmw.ui')

local function colorFromGMST(gmst)
    return util.color.commaString(core.getGMST(gmst))
end

---@class Colors
local Colors = {
    DEFAULT = colorFromGMST('fontcolor_color_normal'),
    DEFAULT_LIGHT = colorFromGMST('fontcolor_color_normal_over'),
    DEFAULT_PRESSED = colorFromGMST('fontcolor_color_normal_pressed'),
    ACTIVE = colorFromGMST('fontcolor_color_active'),
    ACTIVE_LIGHT = colorFromGMST('fontcolor_color_active_over'),
    ACTIVE_PRESSED = colorFromGMST('fontcolor_color_active_pressed'),
    DISABLED = colorFromGMST('fontcolor_color_disabled'),
    DISABLED_LIGHT = colorFromGMST('fontcolor_color_disabled_over'),
    DISABLED_PRESSED = colorFromGMST('fontcolor_color_disabled_pressed'),
    POSITIVE = colorFromGMST('fontcolor_color_positive'),
    DAMAGED = colorFromGMST('fontcolor_color_negative'),
    HEADER = colorFromGMST('fontcolor_color_header'),
    BACKGROUND = colorFromGMST('fontcolor_color_background'),
    HEALTH = util.color.commaString(core.getGMST("FontColor_color_health")),
    MAGICK = util.color.commaString(core.getGMST("FontColor_color_magic")),
    FATIGUE = util.color.commaString(core.getGMST("FontColor_color_fatigue")),

    --TODO: find better place for textures?
    whiteTexture = ui.texture { path = 'white' },
    menuBarGray = ui.texture { path = 'textures/menu_bar_gray.dds' },
}

function Colors:new()
    local o = setmetatable({}, self)
    self.__index = self
    return o
end

return Colors
