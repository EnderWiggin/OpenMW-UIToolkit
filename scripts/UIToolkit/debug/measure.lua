---@omw-context runtime

local core = require 'openmw.core'


local START = {}

---@class UIToolkit.Debug.Measure
local M = {}

---@param name string
function M.start(name)
    START[name] = core.getRealTime()
end

---@param name string
---@return integer elapsed milliseconds since `start` with same name
function M.finish(name)
    local start = START[name]
    if not start then return 0 end
    return M.toMillis(core.getRealTime() - start)
end

---@param delta number seconds
---@return integer milliseconds
function M.toMillis(delta)
    return math.floor(0.5 + 1000 * delta)
end

return M --[[@as UIToolkit.Debug.Measure]]
