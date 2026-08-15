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

---@param opts UIToolkit.InteractiveOpts
---@param layoutOrElement openmw.ui.Element|openmw.ui.Layout
---@return openmw.ui.Element
function M.interactive(opts, layoutOrElement)
    local toolkit = I.UIToolkit
    local ctx = toolkit.getCtx()
    ---@type openmw.ui.Element
    local element
    local isElement = type(layoutOrElement) == 'userdata'

    if isElement then
        ---@cast layoutOrElement openmw.ui.Element
        element = layoutOrElement
    else
        ---@cast layoutOrElement openmw.ui.Layout
        element = ui.create(layoutOrElement)
    end

    element.layout.userData = element.layout.userData or {}
    element.layout.userData.interactive = true

    element.layout.events = element.layout.events or {}
    element.layout.events.mousePress = async:callback(function(e)
        if e.button ~= 1 then
            return false
        end
        if opts.onClick then
            if opts.canClick and not opts.canClick() then
                return false
            end
            ambient.playSound('menu click', { scale = false })
            toolkit.updateInteractiveState(element.layout, { pressed = true })
            toolkit.queueUpdate(element)
            return true
        end
        return false
    end)
    element.layout.events.mouseRelease = async:callback(function(e)
        if e.button ~= 1 then
            return false
        end
        if opts.onClick then
            if not element.layout.userData.pressed then
                return false
            end
            toolkit.updateInteractiveState(element.layout, { pressed = false })
            toolkit.queueUpdate(element)
            return opts.onClick()
        end
        return false
    end)
    local isAlive = function() return element.layout ~= nil end
    element.layout.events.focusLoss = async:callback(function()
        I.UTKTooltips.setTooltip(nil)
        toolkit.updateInteractiveState(element, { hovering = false })
        toolkit.queueUpdate(element)
        ctx.lastMousePos = nil
        return true
    end)
    element.layout.events.focusGain = async:callback(function()
        --ctx.focusedInteractiveDelayed = element
        toolkit.updateInteractiveState(element, { hovering = true })
        toolkit.queueUpdate(element)

        local tooltip = opts.tooltip
        if type(tooltip) == "function" then
            tooltip = tooltip()
        end
        if tooltip then
            I.UTKTooltips.setTooltip(tooltip, isAlive)
        end
        return true
    end)
    element.layout.events.mouseMove = async:callback(function(e, tgt)
        ctx.lastMousePos = e.position --TODO: this is temporary, until 0.52, where `ui.mousePosition` would hopefully exist
        if opts.onMouseMove then
            opts.onMouseMove(e, tgt, element)
        end
    end)
    return element
end

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
