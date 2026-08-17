---@omw-context player

local ui = require('openmw.ui')
local util = require('openmw.util')
local I = require('openmw.interfaces')
local section = require('openmw.storage').playerSection('UIToolkit:WindowData')
local H = require('scripts.UIToolkit.helpers')

local Window = require('scripts.UIToolkit.components.window')


---@class UIToolkit.WindowManager
local M = {}

---@type table<string, {opts:UIToolkit.WindowOpts, wnd:UIToolkit.Window?, handler: UIToolkit.WindowHandler?}>
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
---@param data any?
---@return UIToolkit.Window
function M.open(id, data)
    local cfg = assert(windows[id])
    if cfg.wnd ~= nil then return cfg.wnd end
    local opts = H.shallowCopy(assert(cfg.opts))
    local handler = opts.handler
    if type(handler) == 'function' then handler = handler() end
    windows[id].handler = handler
    opts.handler = handler

    ---@type UIToolkit.WindowSaveData
    local saved = section:get(id)
    local wnd = Window:new()
    wnd:init(opts, saved and {
        pinned = saved.pinned == true,
        position = toAbsolute(saved.position),
        size = toAbsolute(saved.size),
    } or nil)
    windows[id].wnd = wnd
    if handler then
        --TODO: load custom window state
        handler:onOpened(wnd, data)
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
    local handler = data.handler
    if handler then handler:onClosed() end
    data.handler = nil
end

---@param id string
---@return boolean
function M.isOpen(id)
    if not windows[id] then return false end
    return windows[id].wnd ~= nil
end

return M
