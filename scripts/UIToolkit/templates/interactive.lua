---@omw-context player

local ui = require('openmw.ui')
local util = require('openmw.util')
local async = require('openmw.async')
local ambient = require('openmw.ambient')
local I = require('openmw.interfaces')

local H = require('scripts.UIToolkit.helpers')

local M = {}

---@param opts UIToolkit.InteractiveOpts
---@param layoutOrElement openmw.ui.Element|openmw.ui.Layout
---@return openmw.ui.Element
function M.makeInteractive(opts, layoutOrElement)
    local toolkit = I.UIToolkit
    local ctx = toolkit.getCtx()
    local nonInteractiveDisabled = not opts.interactiveDisabled
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
        --TODO: this is temporary, until 0.52, where `ui.mousePosition` would hopefully exist
        ctx.lastMousePos = e.position
        if e.button ~= 1 then return end
        if nonInteractiveDisabled and element.layout.userData.disabled then return end
        if opts.onClick then
            if opts.canClick and not opts.canClick() then
                return false
            end
            ambient.playSound('menu click', { scale = false })
            M.updateState(element.layout, { pressed = true })
            toolkit.queueUpdate(element)
        end
    end)
    element.layout.events.mouseRelease = async:callback(function(e)
        --TODO: this is temporary, until 0.52, where `ui.mousePosition` would hopefully exist
        ctx.lastMousePos = e.position
        if e.button ~= 1 then return end
        if nonInteractiveDisabled and element.layout.userData.disabled then return end
        if opts.onClick then
            if not element.layout.userData.pressed then
                return false
            end
            M.updateState(element.layout, { pressed = false })
            toolkit.queueUpdate(element)
            return opts.onClick(e)
        end
        return false
    end)
    local isAlive = function() return element.layout ~= nil end
    element.layout.events.focusLoss = async:callback(function()
        if I.UTKTooltips then I.UTKTooltips.setTooltip(nil) end
        if nonInteractiveDisabled and element.layout.userData.disabled then return end
        M.updateState(element, { hovering = false })
        toolkit.queueUpdate(element)
        ctx.lastMousePos = nil
        return true
    end)
    element.layout.events.focusGain = async:callback(function()
        if nonInteractiveDisabled and element.layout.userData.disabled then return end
        M.updateState(element, { hovering = true })
        toolkit.queueUpdate(element)

        if I.UTKTooltips then
            local tooltip = opts.tooltip
            if type(tooltip) == "function" then
                tooltip = tooltip()
            end
            if tooltip then
                I.UTKTooltips.setTooltip(tooltip, { isAlive = isAlive })
            end
        end
    end)
    element.layout.events.mouseMove = async:callback(function(e, tgt)
        --TODO: this is temporary, until 0.52, where `ui.mousePosition` would hopefully exist
        ctx.lastMousePos = e.position
        if opts.onMouseMove then
            opts.onMouseMove(e, tgt, element)
        end
    end)
    M.updateState(element.layout)
    return element
end

---Applies interactive state to the layout
---@param state UIToolkit.InteractiveState
---@param custom UIToolkit.InteractiveColors?
---@return openmw.util.Color?
function M.getColor(state, custom)
    local colors = I.UIToolkit.getTheme().Colors
    ---@type openmw.util.Color?
    local color
    if state.active then
        if state.pressed then
            color = colors.ACTIVE_PRESSED
        elseif state.hovering then
            color = colors.ACTIVE_LIGHT
        else
            color = colors.ACTIVE
        end
    elseif state.disabled then
        if state.pressed then
            color = colors.DISABLED_PRESSED
        elseif state.hovering then
            color = colors.DISABLED_LIGHT
        else
            color = colors.DISABLED
        end
    else
        custom = custom or {}
        if state.pressed then
            color = custom.pressColor or colors.DEFAULT_PRESSED
        elseif state.hovering then
            color = custom.hoverColor or colors.DEFAULT_LIGHT
        else
            color = custom.baseColor or colors.DEFAULT
        end
    end
    return color
end

---Applies interactive state to the layout
---@param layout openmw.ui.Layout
---@param state UIToolkit.InteractiveState
function M.applyState(layout, state)
    if layout.userData and layout.userData.colorable then
        local color = M.getColor(state, layout.userData)
        layout.props = layout.props or {}
        if layout.type == ui.TYPE.Text or layout.type == ui.TYPE.TextEdit or (layout.template and (layout.template.type == ui.TYPE.Text or layout.template.type == ui.TYPE.TextEdit)) then
            layout.props.textColor = color
        elseif layout.type == ui.TYPE.Image or (layout.template and layout.template.type == ui.TYPE.Image) then
            layout.props.color = color
        end
    end

    if layout.userData and layout.userData.opacityStates then
        local states = layout.userData.opacityStates
        local alpha
        if state.active then
            if state.pressed then
                alpha = states.activePressed or states.activeHover or states.active or states.default
            elseif state.hovering then
                alpha = states.activeHover or states.active or states.hover or states.default
            else
                alpha = states.active or states.default
            end
        elseif state.disabled then
            if state.pressed then
                alpha = states.disabledPressed or states.disabledHover or states.disabled or states.default
            elseif state.hovering then
                alpha = states.disabledHover or states.disabled or states.hover or states.default
            else
                alpha = states.disabled or states.default
            end
        else
            if state.pressed then
                alpha = states.pressed or states.hover or states.default
            elseif state.hovering then
                alpha = states.hover or states.default
            else
                alpha = states.default
            end
        end

        layout.props = layout.props or {}
        layout.props.alpha = alpha
    end
end

---Recursively updates interactive state of the element and its children
---@param layoutOrElement openmw.ui.Layout|openmw.ui.Element
---@param state UIToolkit.InteractiveState?
function M.updateState(layoutOrElement, state)
    --TODO: add option to queue updates for each changed element?
    local layout = H.toLayout(layoutOrElement)
    local userData = layout.userData or {}
    if state then
        if state.active ~= nil then userData.active = state.active end
        if state.pressed ~= nil then userData.pressed = state.pressed end
        if state.hovering ~= nil then userData.hovering = state.hovering end
        if state.disabled ~= nil then userData.disabled = state.disabled end
        layout.userData = userData
    end
    H.forEachInLayout(layout, function(l)
        M.applyState(l, userData)
    end)
end

return M
