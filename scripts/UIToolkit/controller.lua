---@omw-context player

local input  = require 'openmw.input'
local ui     = require 'openmw.ui'
local util   = require 'openmw.util'

local I      = require 'openmw.interfaces'
local v2     = util.vector2
local BUTTON = input.CONTROLLER_BUTTON
local AXIS   = input.CONTROLLER_AXIS


local M = {}

--TODO: read from settings
local isPsx = false
local isXbox = false
local isSwitch = false

---@param button number
---@return string
function M.getControllerButtonIcon(button)
    if button == BUTTON.A then
        return isPsx and 'textures/omw_psx_button_x.dds' or 'textures/omw_steam_button_a.dds';
    end
    if button == BUTTON.B then
        return isPsx and 'textures/omw_psx_button_circle.dds' or 'textures/omw_steam_button_b.dds';
    end

    if button == BUTTON.X then
        return isPsx and 'textures/omw_psx_button_square.dds' or 'textures/omw_steam_button_x.dds';
    end
    if button == BUTTON.Y then
        return isPsx and 'textures/omw_psx_button_triangle.dds' or 'textures/omw_steam_button_y.dds';
    end
    if button == BUTTON.DPadDown
        or button == BUTTON.DPadRight
        or button == BUTTON.DPadLeft
        or button == BUTTON.DPadUp
    then
        --TODO: split into different icons for each direction?
        return isPsx and 'textures/omw_psx_button_dpad.dds' or 'textures/omw_steam_button_dpad.dds'
    end

    if button == BUTTON.Back then return 'textures/omw_steam_button_view.dds' end
    if button == BUTTON.Start then return 'textures/omw_steam_button_menu.dds' end

    if button == BUTTON.LeftStick then return 'textures/omw_steam_button_l3.dds' end
    if button == BUTTON.RightStick then return 'textures/omw_steam_button_r3.dds' end

    if button == BUTTON.LeftShoulder then
        if isXbox then return 'textures/omw_xbox_button_lb.dds' end
        if isSwitch then return 'textures/omw_switch_button_l.dds' end
        return 'textures/omw_steam_button_l1.dds'
    end
    if button == BUTTON.RightShoulder then
        if isXbox then return 'textures/omw_xbox_button_rb.dds' end
        if isSwitch then return 'textures/omw_switch_button_r.dds' end
        return 'textures/omw_steam_button_r3.dds'
    end
    return 'icons/UIToolkit/unknown-effect.dds'
end

---@param axis number
---@return string
function M.getControllerAxisIcon(axis)
    if axis == AXIS.LeftX
        or axis == AXIS.LeftY
    then
        return 'textures/omw_steam_button_lstick.dds'
    end

    if axis == AXIS.RightX
        or axis == AXIS.RightY
    then
        return 'textures/omw_steam_button_rstick.dds'
    end

    if axis == AXIS.TriggerLeft then
        if isXbox then
            return 'textures/omw_xbox_button_rt.dds';
        elseif isSwitch then
            return 'textures/omw_switch_button_zr.dds';
        end
        return 'textures/omw_steam_button_r2.dds';
    end

    if axis == AXIS.TriggerRight then
        if isXbox then
            return 'textures/omw_xbox_button_lt.dds';
        elseif isSwitch then
            return 'textures/omw_switch_button_zl.dds';
        end
        return 'textures/omw_steam_button_l2.dds';
    end

    return 'icons/UIToolkit/unknown-effect.dds'
end

local function makeIconLayout(icon, opts)
    local toolkit = I.UIToolkit
    local theme = toolkit.getTheme()
    local size = opts and opts.size or 4 * math.ceil((theme.Sizes.textNormal + 4) / 4)
    local color = theme.Colors.DISABLED --TODO: customize color?
    return {
        type = ui.TYPE.Image,
        props = {
            resource = toolkit.texture(icon),
            size = v2(size, size),
            color = color,
        },
    }
end

---@param button number
---@param opts? {size: number?}
---@return openmw.ui.Layout
function M.makeButtonLayout(button, opts)
    return makeIconLayout(M.getControllerButtonIcon(button), opts)
end

---@param axis number
---@param opts? {size: number?}
---@return openmw.ui.Layout
function M.makeAxisLayout(axis, opts)
    return makeIconLayout(M.getControllerAxisIcon(axis), opts)
end

return M
