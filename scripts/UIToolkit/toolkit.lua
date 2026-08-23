---@omw-context player

local core = require('openmw.core')
local input = require('openmw.input')
local ui = require('openmw.ui')

local Theme = require('scripts.UIToolkit.themes.theme')

local theme = Theme:new()

local ctx = {
    ---@type UIToolkit.Scrollable?
    focusedScrollable = nil,
}

---@class openmw.interfaces.UIToolkit
local Interface = {
    version = 1,
    ---@type UIToolkit.Templates
    Templates = require('scripts.UIToolkit.templates.base'),
    ---@type UIToolkit.Interactive
    Interactive = require('scripts.UIToolkit.templates.interactive'),
    ---@type UIToolkit.Components
    Components = require('scripts.UIToolkit.components.all_components'),
    WindowManager = require('scripts.UIToolkit.window_manager'),
}

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
    if not layout.content then return end
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
local function tryDestroy(element)
    if touched[element] then return end
    element:destroy()
    --TODO: add custom 'destroyed' callback check for components
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
function Interface.queueUpdate(element, deep)
    if deep == true then
        deepUpdateQueue[#deepUpdateQueue + 1] = element
    else
        updateQueue[#updateQueue + 1] = element
    end
end

---@param element openmw.ui.Element
---@param deep boolean
function Interface.queueDestroy(element, deep)
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

local function onFrame()
    local dt = core.getRealFrameDuration()
    if ctx.focusedInteractiveDelayed ~= nil then
        if ctx.focusedInteractiveDelayed == false then
            ctx.focusedInteractive = nil
        else
            ctx.focusedInteractive = ctx.focusedInteractiveDelayed
        end
        ctx.focusedInteractiveDelayed = nil
    end

    local scrollable = getFocusedScrollable()
    if scrollable then
        local rightStick = input.getAxisValue(input.CONTROLLER_AXIS.RightY)
        scrollable:onMouseScrolled(-20 * rightStick * dt)
    end

    Interface.WindowManager._onFrame(dt)

    processUpdateAndDestroyQueues()
end

local function onMouseWheel(v)
    local scrollable = getFocusedScrollable()
    if not scrollable then return end
    scrollable:onMouseScrolled(v)
end

---@param id number
local function onControllerButtonPress(id)
    Interface.WindowManager._onControllerButtonPress(id)
end

---@param id number
local function onControllerButtonRelease(id)
    Interface.WindowManager._onControllerButtonRelease(id)
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
}
