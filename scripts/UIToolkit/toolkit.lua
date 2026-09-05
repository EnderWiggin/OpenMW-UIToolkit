---@omw-context player|menu

local core      = require 'openmw.core'
local input     = require 'openmw.input'
local ui        = require 'openmw.ui'

local context   = require 'scripts.UIToolkit.scriptContext'
local D         = require 'scripts.UIToolkit.config.defaults'
local cfgPlayer = require 'scripts.UIToolkit.config.player'

local Theme     = require 'scripts.UIToolkit.themes.theme'

local theme     = Theme:new()
local isPlayer  = context.get() == context.Types.Player


local ctx = {
    ---@type UIToolkit.Scrollable?
    focusedScrollable = nil,
}

---@class openmw.interfaces.UIToolkit.Menu
local Interface = {
    version       = D.API,
    Templates     = require 'scripts.UIToolkit.templates.base',
    Interactive   = require 'scripts.UIToolkit.templates.interactive',
    Components    = require 'scripts.UIToolkit.components.all_components',
    Layers        = require 'scripts.UIToolkit.layers',
    WindowManager = require 'scripts.UIToolkit.window_manager',
}

local InterfaceP
if isPlayer then
    InterfaceP = Interface --[[@as openmw.interfaces.UIToolkit.Player]]
    InterfaceP.Popups = require 'scripts.UIToolkit.popups'
end

function Interface.getCtx() return ctx end

function Interface.getTheme() return theme end

---@type openmw.ui.Element[]
local updateQueue = {}

---@type openmw.ui.Element[]
local deepUpdateQueue = {}

---@type openmw.ui.Element[]
local destroyQueue = {}

---@type openmw.ui.Element[]
local deepDestroyQueue = {}

--Elements that were destroyed or updated this frame.
--Used to not update or destroy more than once per frame.
--And to not update elements that have just been destroyed.
---@type table<openmw.ui.Element, boolean>
local touched = {}

local function isUiElement(v)
    return v.__type and v.__type.name == 'LuaUi::Element'
end

local function deepElementCallback(layout, callback)
    if not layout or not layout.content then return end
    for i = 1, #layout.content do
        local child = layout.content[i]
        if isUiElement(child) then
            callback(child)
            deepElementCallback(child.layout, callback)
        else
            deepElementCallback(child, callback)
        end
    end
end

---@param element openmw.ui.Element
---@return UIToolkit.Component?
local function tryGetComponent(element)
    if not element.layout then return nil end
    local userData = element.layout.userData
    return userData and userData._component --[[@as UIToolkit.Component?]]
end

---@param element openmw.ui.Element
local function tryDestroy(element)
    if touched[element] then return end
    local component = tryGetComponent(element)
    if component then component:beforeElementDestroy() end
    element:destroy()
    touched[element] = true
end

---@param element openmw.ui.Element
local function tryUpdate(element)
    if touched[element] then return end
    element:update()
    --TODO: add custom 'updated' callback check for components
    touched[element] = true
end

local function processUpdateAndDestroyQueues()
    local _updateQueue = updateQueue
    updateQueue = {}

    local _deepUpdateQueue = deepUpdateQueue
    deepUpdateQueue = {}

    local _destroyQueue = destroyQueue
    destroyQueue = {}

    local _deepDestroyQueue = deepDestroyQueue
    deepDestroyQueue = {}

    for i = 1, #_deepDestroyQueue do
        local element = _deepDestroyQueue[i]
        tryDestroy(element)
        deepElementCallback(element.layout, tryDestroy)
    end

    for i = 1, #_destroyQueue do
        tryDestroy(_destroyQueue[i])
    end

    for i = 1, #_deepUpdateQueue do
        local element = _deepUpdateQueue[i]
        tryUpdate(element)
        deepElementCallback(element.layout, tryUpdate)
    end

    for i = 1, #_updateQueue do
        tryUpdate(_updateQueue[i])
    end

    touched = {}
end

---@param element openmw.ui.Element
---@param deep boolean?
function Interface.update(element, deep)
    if not element then return end
    assert(element.destroy)
    tryUpdate(element)
    if deep == true then
        deepElementCallback(element.layout, tryUpdate)
    end
end

---@param element openmw.ui.Element
---@param deep boolean?
function Interface.destroy(element, deep)
    if not element then return end
    assert(element.destroy)
    tryDestroy(element)
    if deep == true then
        deepElementCallback(element.layout, tryDestroy)
    end
end

---@param element openmw.ui.Element
---@param deep boolean?
function Interface.queueUpdate(element, deep)
    if not element then return end
    assert(element.update)
    if deep == true then
        deepUpdateQueue[#deepUpdateQueue + 1] = element
    else
        updateQueue[#updateQueue + 1] = element
    end
end

---@param element openmw.ui.Element
---@param deep boolean?
function Interface.queueDestroy(element, deep)
    if not element then return end
    assert(element.destroy)
    if deep == true then
        deepDestroyQueue[#deepDestroyQueue + 1] = element
    else
        destroyQueue[#destroyQueue + 1] = element
    end
end

local TEX_CACHE = {}

---@param path string
---@param size openmw.util.Vector2?
---@param offset openmw.util.Vector2?
---@return string
local function textureKey(path, size, offset)
    return '[' .. path .. ']:' .. tostring(size) .. ':' .. tostring(offset)
end

---@param path string
---@param size openmw.util.Vector2?
---@param offset openmw.util.Vector2?
---@return openmw.ui.TextureResource
function Interface.texture(path, size, offset)
    local key = textureKey(path, size, offset)
    if TEX_CACHE[key] then return TEX_CACHE[key] end
    local tex = ui.texture { path = path, size = size, offset = offset }
    TEX_CACHE[key] = tex
    return tex
end

---@return UIToolkit.Scrollable?
local function getFocusedScrollable()
    local scrollable = ctx.focusedScrollable
    if not scrollable then return nil end
    if scrollable:isDestroyed() or not scrollable:isVisible() then
        ctx.focusedScrollable = nil
        return nil
    end
    return scrollable
end
local buttonPressDuration = {}

---@param button number
local function onControllerButtonRepeat(button)
    if isPlayer then
        local popup = InterfaceP.Popups.getActivePopup()
        if popup then
            local callback = popup.handler.onControllerButtonRepeat
            if callback then callback(button) end
            return
        end
    end

    local focused = InterfaceP.WindowManager.getFocusedWindowHandler()
    if not focused then return end
    focused:onControllerButtonRepeat(button)
end

local function onFrame()
    local dt = core.getRealFrameDuration()

    local scrollable = getFocusedScrollable()
    if not scrollable and isPlayer then
        local popup = InterfaceP.Popups.getActivePopup()
        if popup then
            local method = popup.handler.getFocusedScrollable
            if method then scrollable = method() end
        end
    end

    if not scrollable then
        local window = Interface.WindowManager.getFocusedWindowHandler()
        scrollable = window and window:getFocusedScrollable()
    end

    if scrollable then
        local rightStick = input.getAxisValue(input.CONTROLLER_AXIS.RightY)
        if math.abs(rightStick) > 0.1 then
            scrollable:onMouseScrolled(-20 * rightStick * dt)
        end
    end

    --process repeated controller buttons
    if cfgPlayer.controller.b_RepeatingButtons then
        for button, held in pairs(buttonPressDuration) do
            held = held + dt
            if held > cfgPlayer.controller.n_RepeatingButtonsThreshold then
                held = held - cfgPlayer.controller.n_RepeatingButtonsStep
                onControllerButtonRepeat(button)
            end
            buttonPressDuration[button] = held
        end
    end
    Interface.WindowManager._onFrame(dt)

    processUpdateAndDestroyQueues()
end

local function onMouseWheel(v)
    local scrollable = getFocusedScrollable()
    if not scrollable then return end
    scrollable:onMouseScrolled(v)
end

---@param button number
local function onControllerButtonPress(button)
    buttonPressDuration[button] = 0

    if isPlayer then
        local popup = InterfaceP.Popups.getActivePopup()
        if popup then
            local callback = popup.handler.onControllerButtonPress
            if callback then callback(button) end
            return
        end
    end

    local focused = Interface.WindowManager.getFocusedWindowHandler()
    if not focused then return end
    focused:onControllerButtonPress(button)
end

---@param button number
local function onControllerButtonRelease(button)
    buttonPressDuration[button] = nil
end

local function onUIModeChanged()
    Interface.Layers.closeDropbox()
end

return {
    interfaceName = 'UIToolkit',
    interface = Interface,
    engineHandlers = {
        onFrame = onFrame,
        onMouseWheel = onMouseWheel,
        onControllerButtonPress = onControllerButtonPress,
        onControllerButtonRelease = onControllerButtonRelease
    },
    eventHandlers = {
        UiModeChanged = onUIModeChanged,
    },
}
