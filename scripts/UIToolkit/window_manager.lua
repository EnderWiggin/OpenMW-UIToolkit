---@omw-context player

local ui = require('openmw.ui')
local util = require('openmw.util')
local I = require('openmw.interfaces')
local section = require('openmw.storage').playerSection('UIToolkit:WindowData')
local H = require('scripts.UIToolkit.helpers')

local cfgPlayer = require('scripts.UIToolkit.config.player')
local Window = require('scripts.UIToolkit.components.window')


---@class UIToolkit.WindowManager
local M = {}

---@type table<string, {opts:UIToolkit.WindowOpts, wnd:UIToolkit.Window?, handler: UIToolkit.WindowHandler?}>
local windows = {}

local buttonPressDuration = {}

---@type string[]
local windowFocusQueue = {}

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
    wnd:init(opts, id, saved and {
        pinned = saved.pinned == true,
        position = toAbsolute(saved.position),
        size = toAbsolute(saved.size),
    } or nil)
    windows[id].wnd = wnd
    if handler then
        --TODO: load custom window state
        handler:onOpened(wnd, data)
    end
    M._queueFocusedWindow(id)
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

    local handler = data.handler
    if handler then handler:onClosed() end

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
    data.handler = nil
    H.removeFromArray(windowFocusQueue, id)
end

---@return UIToolkit.WindowHandler? handler, string? id
function M.getFocusedWindowHandler()
    for i = 1, #windowFocusQueue do
        local id = windowFocusQueue[i]
        local data = windows[id]
        if data and data.handler then return data.handler, id end
    end
    return nil, nil
end

---@param id string
function M._queueFocusedWindow(id)
    if windowFocusQueue[1] == id then return end
    H.removeFromArray(windowFocusQueue, id)
    table.insert(windowFocusQueue, 1, id)
end

function M._onFrame(dt)
    --process repeated controller buttons
    for button, held in pairs(buttonPressDuration) do
        held = held + dt
        if held > cfgPlayer.controller.n_RepeatingButtonsThreshold then
            held = held - cfgPlayer.controller.n_RepeatingButtonsStep
            M._onControllerButtonRepeat(button)
        end
        buttonPressDuration[button] = held
    end

    --call onFrame for open windows
    for i = 1, #windowFocusQueue do
        local data = windows[windowFocusQueue[i]]
        local handler = data and data.handler
        if handler then handler:onFrame(dt) end
    end
end

---@param button number
function M._onControllerButtonPress(button)
    buttonPressDuration[button] = 0


    local focused = M.getFocusedWindowHandler()
    if not focused then return end
    focused:onControllerButtonPress(button)
end

---@param button number
function M._onControllerButtonRelease(button)
    buttonPressDuration[button] = nil
end

---@param button number
function M._onControllerButtonRepeat(button)
    local focused = M.getFocusedWindowHandler()
    if not focused then return end
    focused:onControllerButtonRepeat(button)
end

---@param id string
---@return boolean
function M.isOpen(id)
    if not windows[id] then return false end
    return windows[id].wnd ~= nil
end

return M
