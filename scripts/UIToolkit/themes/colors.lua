---@omw-context player

local H = require('scripts.UIToolkit.helpers')

---@class Colors
local Colors = {
    DEFAULT = H.colorFromGMST('fontcolor_color_normal'),
    DEFAULT_LIGHT = H.colorFromGMST('fontcolor_color_normal_over'),
    DEFAULT_PRESSED = H.colorFromGMST('fontcolor_color_normal_pressed'),
    ACTIVE = H.colorFromGMST('fontcolor_color_active'),
    ACTIVE_LIGHT = H.colorFromGMST('fontcolor_color_active_over'),
    ACTIVE_PRESSED = H.colorFromGMST('fontcolor_color_active_pressed'),
    DISABLED = H.colorFromGMST('fontcolor_color_disabled'),
    DISABLED_LIGHT = H.colorFromGMST('fontcolor_color_disabled_over'),
    DISABLED_PRESSED = H.colorFromGMST('fontcolor_color_disabled_pressed'),
    POSITIVE = H.colorFromGMST('fontcolor_color_positive'),
    DAMAGED = H.colorFromGMST('fontcolor_color_negative'),
    HEADER = H.colorFromGMST('fontcolor_color_header'),
    BACKGROUND = H.colorFromGMST('fontcolor_color_background'),
}

function Colors:new()
    local o = setmetatable({}, self)
    self.__index = self
    return o
end

return Colors
