---@omw-context player

local ui = require('openmw.ui')
local util = require('openmw.util')
local I = require('openmw.interfaces')
local section = require('openmw.storage').playerSection('UIToolkit:WindowData')

local Window = require('scripts.UIToolkit.components.window')


---@class UIToolkit.WindowManager
local M = {}

---@type table<string, {opts:UIToolkit.WindowOpts, wnd:UIToolkit.Window?}>
local windows = {}

---@param id string
---@param opts UIToolkit.WindowOpts
function M.register(id, opts)
    if windows[id] then M.close(id) end
    windows[id] = { opts = opts }
end

---@param c openmw.util.Vector2
---@return openmw.util.Vector2
local function toAbsolute(c)
    if not c then return util.vector2(0, 0) end
    local layerSize = ui.layers[ui.layers.indexOf('Windows')].size
    return util.vector2(
        util.round(c.x * layerSize.x),
        util.round(c.y * layerSize.y)
    )
end

---@param id string
---@return UIToolkit.Window
function M.open(id)
    local data = assert(windows[id])
    if data.wnd ~= nil then return data.wnd end
    local opts = assert(data.opts)

    ---@type UIToolkit.WindowSaveData
    local saved = section:get(id)
    local wnd = Window:new()
    wnd:init(opts, saved and {
        pinned = saved.pinned == true,
        position = toAbsolute(saved.position),
        size = toAbsolute(saved.size),
    } or nil)
    windows[id].wnd = wnd
    if opts.onOpen then
        --TODO: load custom window state
        opts.onOpen(wnd)
    end
    return wnd
end

---@param c openmw.util.Vector2
---@return openmw.util.Vector2
local function toRelative(c)
    local layerSize = ui.layers[ui.layers.indexOf('Windows')].size
    return util.vector2(
        c.x / layerSize.x,
        c.y / layerSize.y
    )
end

---@param id string
function M.close(id)
    local data = assert(windows[id])
    local wnd = data.wnd
    if not wnd then return end

    ---@type UIToolkit.WindowSaveData
    local saved = {
        pinned = wnd:isPinned(),
        position = toRelative(wnd:getPosition()),
        size = toRelative(wnd:getSize()),
    }
    --TODO: save custom window state
    section:set(id, saved)
    data.wnd = nil
    I.UIToolkit.queueDestroy(wnd.element, true)
    if data.opts.onClosed then data.opts.onClosed() end
end

---@param id string
---@return boolean
function M.isOpen(id)
    if not windows[id] then return false end
    return windows[id].wnd ~= nil
end

return M
