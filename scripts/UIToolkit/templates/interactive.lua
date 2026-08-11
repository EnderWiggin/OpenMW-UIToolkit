---@omw-context player

local ui = require('openmw.ui')
local util = require('openmw.util')
local auxUi = require('openmw_aux.ui')
local async = require('openmw.async')
local ambient = require('openmw.ambient')
local I = require('openmw.interfaces')

local v2 = util.vector2

local M = {}

local T = {
    Base = require('scripts.UIToolkit.templates.base'),
}

---@param text string
---@param onClick function
---@param name string? name for the element, defaults to 'button'
---@param bgrAlpha number?
---@return openmw.ui.Element
function M.button(text, onClick, name, bgrAlpha)
    local txt = ui.create {
        template = T.Base.text(),
        props = { text = text, },
        userData = { colorable = true },
    }

    local element = ui.create {
        name = name or 'button',
        template = bgrAlpha and T.Base.buttonBoxBgr(bgrAlpha) or T.Base.buttonBox(),
        props = {},
        content = ui.content {
            {
                template = T.Base.padding(8, 0),
                content = ui.content { txt, }
            }
        },
        events = {},
        userData = {},
    }

    if not onClick then return element end

    local toolkit = I.UIToolkit
    ---@type UIToolkit.InteractiveState
    local data = element.layout.userData

    element.layout.events.focusGain = async:callback(function()
        data.hovering = true
        toolkit.applyInteractiveState(txt.layout, data)
        toolkit.queueUpdate(txt)
    end)
    element.layout.events.focusLoss = async:callback(function()
        data.hovering = false
        toolkit.applyInteractiveState(txt.layout, data)
        toolkit.queueUpdate(txt)
    end)
    element.layout.events.mousePress = async:callback(function()
        ambient.playSound('menu click', { scale = false })
        data.pressed = true
        toolkit.applyInteractiveState(txt.layout, data)
        toolkit.queueUpdate(txt)
    end)
    element.layout.events.mouseRelease = async:callback(function()
        if onClick then onClick() end
        data.pressed = false
        toolkit.applyInteractiveState(txt.layout, data)
        toolkit.queueUpdate(txt)
    end)
    return element
end

return M
