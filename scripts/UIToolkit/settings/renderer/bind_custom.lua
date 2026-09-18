---@omw-context menu

local async = require 'openmw.async'
local core  = require 'openmw.core'
local input = require 'openmw.input'
local ui    = require 'openmw.ui'
local util  = require 'openmw.util'

local I     = require 'openmw.interfaces'
local D     = require 'scripts.UIToolkit.config.defaults'
local U     = require 'scripts.UIToolkit.settings.renderer.utils'


local l10n       = core.l10n 'UIToolkitLib'
local v2         = util.vector2
local Device     = D.Device
local REVERT_TEX = ui.texture { path = 'icons/UIToolkit/revert.dds' }


---@alias UIToolkit.SettingRenderer.CustomBind.Set fun(value:UIToolkit.SettingRenderer.CustomBind[])

---@class UIToolkit.SettingRenderer.CustomBind.Recording
---@field value UIToolkit.SettingRenderer.CustomBind[]
---@field index integer
---@field set UIToolkit.SettingRenderer.CustomBind.Set
---@field state fun(state:boolean)

local M = {}

local function keyName(code)
    if not code then return core.getGMST('sNone') end
    local name = input.getKeyName(code)
    if name == '' then
        name = 'key: ' .. tostring(code)
    end
    return name
end

---@type UIToolkit.SettingRenderer.CustomBind.Recording?
local recording = nil
local function cancel()
    if not recording then return end
    recording.state(false)
    recording = nil
end

---@param value UIToolkit.SettingRenderer.CustomBind[]
---@param index integer
---@param set UIToolkit.SettingRenderer.CustomBind.Set
---@param height number
---@return openmw.ui.Element
local function makeBindingElement(value, index, set, height)
    local toolkit = I.UIToolkit
    local T = toolkit.Templates
    local theme = toolkit.getTheme()
    local textSize = theme.Sizes.textHeader

    local v = value[index]
    local isController = v.device == Device.Controller and v.code ~= nil

    local icon
    local name = keyName(v.code)
    local text = {
        template = T.header(),
        props = {
            text = name,
            autoSize = false,
            textAlignH = ui.ALIGNMENT.Center,
            textAlignV = ui.ALIGNMENT.Center,
            relativeSize = v2(1, 1),
            visible = not isController,
        },
    }
    local content = ui.content { text }

    if isController then
        icon = toolkit.Controller.makeButtonLayout(v.code)
        icon.props.anchor = v2(0.5, 0.5)
        icon.props.relativePosition = v2(0.5, 0.5)
        content:add(icon)
    end

    local btn = {
        name = 'btn-clear',
        type = ui.TYPE.Image,
        props = {
            size = v2(1, 1) * (textSize + 2),
            position = v2(105, height / 2),
            anchor = v2(0, 0.5),
            resource = REVERT_TEX,
            alpha = 0.5,
        },
        userData = { colorable = true, disabled = true },
    }
    local element = ui.create {
        type = ui.TYPE.Container,
        props = {},
        content = ui.content {
            {
                template = T.border(),
                props = {
                    size = v2(100, height),
                },
                content = content,
            },
            toolkit.Interactive.makeInteractive({
                interactiveDisabled = true,
                tooltip = core.getGMST 'sDelete',
                onClick = function()
                    table.remove(value, index)
                    set(value)
                    recording = nil
                end
            }, btn)
        },
    }
    element.layout.events = {
        mouseClick = async:callback(function()
            if recording ~= nil then return end
            text.props.text = '...'
            text.props.visible = true
            if icon then
                icon.props.visible = false
            end
            element:update()
            recording = {
                value = value,
                index = index,
                set = set,
                state = function()
                    text.props.text = name
                    text.props.visible = not isController
                    if icon then
                        icon.props.visible = isController
                    end
                    element:update()
                    recording = nil
                end,
            }
        end),
    }

    return element
end

---@param value UIToolkit.SettingRenderer.CustomBind[]
---@param set UIToolkit.SettingRenderer.CustomBind.Set
---@param args any
---@return openmw.ui.Element
function M.render(value, set, args)
    recording = nil
    local toolkit = I.UIToolkit
    local C = toolkit.Components
    local theme = toolkit.getTheme()
    local textSize = theme.Sizes.textNormal
    local rowHeight = util.round((textSize + 2) * 1.5)

    value = U.parseArgData(value)
    args = U.parseArgData(args)
    value = value or {}

    local y = 0
    ---@type openmw.ui.LayoutOrElement[]
    local items = {}
    for i = 1, #value do
        local bind = makeBindingElement(value, i, set, rowHeight)
        bind.layout.props.position = v2(0, y)
        y = y + rowHeight + 5
        items[#items + 1] = bind
    end

    local add = C.textButton {
        text = l10n 'RendererAddButton',
        padding = v2(4, 2),
        style = 'thin',
        tooltip = l10n 'RendererAddTooltip',
        onClick = function()
            cancel()
            value[#value + 1] = { device = Device.Keyboard }
            set(value)
        end
    }.element
    add.layout.props.position = v2(100, y)
    add.layout.props.anchor = v2(1, 0)
    items[#items + 1] = add

    return ui.create {
        type = ui.TYPE.Container,
        props = {},
        content = ui.content(items),
    }
end

---@param key openmw.input.KeyboardEvent
function M.onKeyPress(key)
    if not recording then return end
    if key.code == input.KEY.Escape then
        cancel()
        return
    end
    local v = recording.value[recording.index]
    v.device = Device.Keyboard
    v.code = key.code
    recording.set(recording.value)
    recording = nil
end

---@param button number
function M.onControllerButtonPress(button)
    if not recording then return end
    if button == input.CONTROLLER_BUTTON.Start then
        cancel()
        return
    end

    local v = recording.value[recording.index]
    v.device = Device.Controller
    v.code = button
    recording.set(recording.value)
    recording = nil
end

return M
