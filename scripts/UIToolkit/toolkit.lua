---@omw-context player

local ui = require('openmw.ui')
local auxUi = require('openmw_aux.ui')

local Theme = require('scripts.UIToolkit.themes.theme')

local theme = Theme:new()

local ctx = {
    ---@type table<openmw.ui.Element, boolean>
    updateQueue = {},
    ---@type table<openmw.ui.Element, boolean>
    destroyQueue = {},
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

local function onMouseWheel(v)
    local scrollable = ctx.focusedScrollable
    if not scrollable then return end
    if scrollable:isDestroyed() then return end
    scrollable:onMouseScrolled(v)
end

return {
    interfaceName = 'UIToolkit',
    interface = Interface,
    engineHandlers = {
        onFrame = onFrame,
        onMouseWheel = onMouseWheel,
    },
}
