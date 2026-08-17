---@omw-context player

local core = require('openmw.core')
local ui = require('openmw.ui')
local storage = require('openmw.storage')
local util = require('openmw.util')
local auxUi = require('openmw_aux.ui')
local input = require('openmw.input')

local I = require('openmw.interfaces')
local v2 = util.vector2

local Theme = require('scripts.UIToolkit.themes.theme')

local theme = Theme:new()
local sizes = theme.Sizes
local colors = theme.Colors

local ctx = {
    ---@type table<openmw.ui.Element, boolean>
    updateQueue = {},
    ---@type table<openmw.ui.Element, boolean>
    destroyQueue = {},
    ---@type UIToolkit.Scrollable?
    focusedScrollable = nil,
}

local Buttons = require('scripts.UIToolkit.components.buttons')
local TextEdit = require('scripts.UIToolkit.components.text_edit')
local ScrollBar = require('scripts.UIToolkit.components.scroll_bar')
local ItemList = require('scripts.UIToolkit.components.item_list')

---@class openmw.interfaces.UIToolkit
local Interface = {
    version = 1,
    ---@type UIToolkit.Interactive
    Interactive = require('scripts.UIToolkit.templates.interactive'),
    ---@type UIToolkit.Components
    Components = {
        textButton = Buttons.textButton,

        ---@param opts UIToolkit.TextEditOpts
        ---@return UIToolkit.TextEdit
        textEdit = function(opts)
            local edit = TextEdit:new()
            edit:init(opts)
            return edit
        end,

        ---@param opts UIToolkit.ScrollBarOpts
        ---@return UIToolkit.ScrollBar
        scrollBar = function(opts)
            local scroll = ScrollBar:new()
            scroll:init(opts)
            return scroll
        end,

        ---@param opts UIToolkit.ItemListOpts
        ---@return UIToolkit.ItemList
        itemList = function(opts)
            local list = ItemList:new()
            list:init(opts)
            return list
        end,
    },
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
