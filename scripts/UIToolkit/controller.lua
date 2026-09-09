---@omw-context player

local input  = require 'openmw.input'
local ui     = require 'openmw.ui'
local util   = require 'openmw.util'

local I      = require 'openmw.interfaces'
local v2     = util.vector2
local BUTTON = input.CONTROLLER_BUTTON
local AXIS   = input.CONTROLLER_AXIS

---@class UIToolkit.Controller.HintData
---@field source string window or popup
---@field id string|number id of the window or popup
---@field ts number time this hint was updated at
---@field hints? (UIToolkit.Controller.Hint|'separator')[]


---@type UIToolkit.Controller.HintData|nil
local currentHint = nil
---@type openmw.ui.Element?
local element = nil


---@class UIToolkit.ControllerPrivate : UIToolkit.Controller
local M = {}


local controllerIsActive = false

--TODO: read from settings
local isPsx              = false
local isXbox             = false
local isSwitch           = false
local alwaysShowHint     = false

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

    if button == BUTTON.DPadDown then return M.getDPadIcon 'down' end
    if button == BUTTON.DPadUp then return M.getDPadIcon 'up' end
    if button == BUTTON.DPadLeft then return M.getDPadIcon 'left' end
    if button == BUTTON.DPadRight then return M.getDPadIcon 'right' end

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
    if axis == AXIS.LeftX or axis == AXIS.LeftY
        or axis == AXIS.MoveLeftRight or axis == AXIS.MoveForwardBackward
    then
        return 'textures/omw_steam_button_lstick.dds'
    end

    if axis == AXIS.RightX or axis == AXIS.RightY
        or axis == AXIS.LookLeftRight or axis == AXIS.LookUpDown
    then
        return 'textures/omw_steam_button_rstick.dds'
    end

    if axis == AXIS.TriggerRight then
        if isXbox then
            return 'textures/omw_xbox_button_rt.dds';
        elseif isSwitch then
            return 'textures/omw_switch_button_zr.dds';
        end
        return 'textures/omw_steam_button_r2.dds';
    end

    if axis == AXIS.TriggerLeft then
        if isXbox then
            return 'textures/omw_xbox_button_lt.dds';
        elseif isSwitch then
            return 'textures/omw_switch_button_zl.dds';
        end
        return 'textures/omw_steam_button_l2.dds';
    end

    return 'icons/UIToolkit/unknown-effect.dds'
end

---@param direction UIToolkit.Controller.DPAdDirection
---@return string
function M.getDPadIcon(direction)
    if direction == 'down' then
        return isPsx and 'icons/UIToolkit/psx_dpad_down.dds' or 'icons/UIToolkit/steam_dpad_down.dds'
    end
    if direction == 'up' then
        return isPsx and 'icons/UIToolkit/psx_dpad_up.dds' or 'icons/UIToolkit/steam_dpad_up.dds'
    end
    if direction == 'left' then
        return isPsx and 'icons/UIToolkit/psx_dpad_left.dds' or 'icons/UIToolkit/steam_dpad_left.dds'
    end
    if direction == 'right' then
        return isPsx and 'icons/UIToolkit/psx_dpad_right.dds' or 'icons/UIToolkit/steam_dpad_right.dds'
    end

    if direction == 'horizontal' then
        return isPsx and 'icons/UIToolkit/psx_dpad_h.dds' or 'icons/UIToolkit/steam_dpad_h.dds'
    end
    if direction == 'vertical' then
        return isPsx and 'icons/UIToolkit/psx_dpad_v.dds' or 'icons/UIToolkit/steam_dpad_v.dds'
    end

    return isPsx and 'textures/omw_psx_button_dpad.dds' or 'textures/omw_steam_button_dpad.dds'
end

---@param icon string
---@param opts UIToolkit.Controller.IconOpts?
---@return openmw.ui.Layout
local function makeIconLayout(icon, opts)
    local toolkit = I.UIToolkit
    local theme = toolkit.getTheme()
    local size = opts and opts.size or 4 * math.ceil((theme.Sizes.textNormal + 4) / 4)
    local color = opts and opts.color or theme.Colors.HEADER
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
---@param opts UIToolkit.Controller.IconOpts?
---@return openmw.ui.Layout
function M.makeButtonLayout(button, opts)
    return makeIconLayout(M.getControllerButtonIcon(button), opts)
end

---@param axis number
---@param opts UIToolkit.Controller.IconOpts?
---@return openmw.ui.Layout
function M.makeAxisLayout(axis, opts)
    return makeIconLayout(M.getControllerAxisIcon(axis), opts)
end

---@param hints (UIToolkit.Controller.Hint|'separator')[]
---@return openmw.ui.Layout[]
local function makeLayouts(hints)
    local toolkit = I.UIToolkit
    local T = toolkit.Templates
    local theme = toolkit.getTheme()
    local textSize = theme.Sizes.textNormal
    local rowHeight = util.round((textSize + 2) * 1.5)

    ---@type openmw.ui.Layout
    local separator = {
        props = {
            size = v2(rowHeight, rowHeight),
        },
        content = ui.content { {
            template = I.MWUI.templates.verticalLine,
            props = {
                anchor = v2(0.5, 0),
                relativePosition = v2(0.5, 0),
            },
        } }
    }
    local gap = T.intervalH(util.round((textSize + 2) / 2))

    local layouts = {}

    local isSeparator = false
    local wasSeparator = false
    for i = 1, #hints do
        local hint = hints[i]
        isSeparator = hint == 'separator'

        if i > 1 and not isSeparator and not wasSeparator then
            layouts[#layouts + 1] = gap
        end

        if isSeparator then
            layouts[#layouts + 1] = separator
        else
            local _input = hint.input
            if #_input == 0 then
                layouts[#layouts + 1] = _input.axis
                    and M.makeAxisLayout(_input.id)
                    or M.makeButtonLayout(_input.id)
            else
                for j = 1, #_input do
                    if hint.combo and j > 1 then
                        layouts[#layouts + 1] = {
                            template = T.header(),
                            props = { text = '+', textSize = textSize + 2 },
                        }
                    end
                    local tmp = _input[j]
                    layouts[#layouts + 1] = tmp.axis
                        and M.makeAxisLayout(tmp.id)
                        or M.makeButtonLayout(tmp.id)
                end
            end
            layouts[#layouts + 1] = {
                template = T.text(),
                props = { text = hint.text },
            }
        end

        wasSeparator = isSeparator
    end

    return layouts
end

---@param hints? (UIToolkit.Controller.Hint|'separator')[]
local function showControllerHint(hints)
    if element then
        I.UIToolkit.destroy(element)
        element = nil
    end

    if not hints then return end

    local toolkit = I.UIToolkit
    local theme = toolkit.getTheme()
    local textSize = theme.Sizes.textNormal

    element = ui.create {
        layer = 'ControllerButtons',
        type = ui.TYPE.Image,
        props = {
            resource = theme.Colors.whiteTexture,
            color = theme.Colors.BACKGROUND,
            alpha = 0.8,
            size = v2(0, 30 + textSize),
            relativeSize = v2(1, 0),
            anchor = v2(0.5, 1),
            relativePosition = v2(0.5, 1),
            visible = controllerIsActive or alwaysShowHint,
        },
        content = ui.content { {
            type = ui.TYPE.Flex,
            props = {
                horizontal = true,
                align = ui.ALIGNMENT.Center,
                arrange = ui.ALIGNMENT.Center,
                autoSize = false,
                relativeSize = v2(1, 1),
            },
            content = ui.content(makeLayouts(hints)),
        } },

    }
end

function M._onFrame(dt)
    local hintData
    --TODO: check popups first
    hintData = I.UIToolkit.WindowManager.getFocusedWindowHintData()

    if not hintData then
        showControllerHint(nil)
        currentHint = nil
        return
    end

    if currentHint then
        if currentHint.source == hintData.source
            and currentHint.id == hintData.id
            and currentHint.ts >= hintData.ts
        then
            return
        end
    end
    currentHint = hintData
    showControllerHint(hintData.hints)
end

function M._setControllerActiveState(state)
    if state == controllerIsActive then return end
    controllerIsActive = state
    if element then
        element.layout.props.visible = controllerIsActive or alwaysShowHint
        I.UIToolkit.update(element)
    end
end

function M.getControllerActiveState()
    return controllerIsActive
end

return M
