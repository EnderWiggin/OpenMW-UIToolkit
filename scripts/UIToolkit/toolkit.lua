---@omw-context player

local core = require('openmw.core')
local ui = require('openmw.ui')
local storage = require('openmw.storage')
local util = require('openmw.util')
local auxUi = require('openmw_aux.ui')
local input = require('openmw.input')

local I = require('openmw.interfaces')
local v2 = util.vector2

local H = require('scripts.UIToolkit.helpers')
local Theme = require('scripts.UIToolkit.themes.theme')

local theme = Theme:new()
local sizes = theme.Sizes
local colors = theme.Colors

local ctx = {
    ---@type table<openmw.ui.Element, boolean>
    updateQueue = {},
    ---@type table<openmw.ui.Element, boolean>
    destroyQueue = {},
}

local Buttons = require('scripts.UIToolkit.components.buttons')
local TextEdit = require('scripts.UIToolkit.components.text_edit')
local ScrollBar = require('scripts.UIToolkit.components.scroll_bar')

local Interface = {
    ---@type UIToolkit.Components
    Components = {
        textButton = Buttons.textButton,

        ---@param opts UIToolkit.TextEditOpts
        ---@return UIToolkit.TextEdit
        textEdit = function(opts)
            local edit = TextEdit.new()
            edit:init(opts)
            return edit
        end,

        ---@param opts UIToolkit.ScrollBarOpts
        ---@return UIToolkit.ScrollBar
        scrollBar = function(opts)
            local scroll = ScrollBar.new()
            scroll:init(opts)
            return scroll
        end,
    }
}

function Interface.getCtx() return ctx end

function Interface.getTheme() return theme end

---@param element openmw.ui.Element
---@param deep boolean?
function Interface.queueUpdate(element, deep)
    if ctx.destroyQueue[element] ~= nil then return end
    ctx.updateQueue[element] = deep == true
end

---@param element openmw.ui.Element
---@param deep boolean
function Interface.queueDestroy(element, deep)
    ctx.updateQueue[element] = nil
    ctx.destroyQueue[element] = deep
end

---Applies interactive state to the layout
---@param state UIToolkit.InteractiveState
---@param custom UIToolkit.InteractiveColors?
---@return openmw.util.Color?
function Interface.getInteractiveColor(state, custom, _name)
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
function Interface.applyInteractiveState(layout, state)
    if layout.userData and layout.userData.colorable then
        local color = Interface.getInteractiveColor(state, layout.userData, layout.name)
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
function Interface.updateInteractiveState(layoutOrElement, state)
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
        Interface.applyInteractiveState(l, userData)
    end)
end

local function onFrame()
    if ctx.focusedInteractiveDelayed ~= nil then
        if ctx.focusedInteractiveDelayed == false then
            ctx.focusedInteractive = nil
        else
            ctx.focusedInteractive = ctx.focusedInteractiveDelayed
        end
        ctx.focusedInteractiveDelayed = nil
    end

    for element, deep in pairs(ctx.updateQueue) do
        if deep then
            auxUi.deepUpdate(element)
        else
            element:update()
        end
    end
    ctx.updateQueue = {}

    for element, deep in pairs(ctx.destroyQueue) do
        if deep then
            auxUi.deepDestroy(element)
        else
            element:destroy()
        end
    end
    ctx.destroyQueue = {}
end

return {
    interfaceName = 'UIToolkit',
    interface = Interface,
    engineHandlers = {
        onFrame = onFrame,
    },
}
