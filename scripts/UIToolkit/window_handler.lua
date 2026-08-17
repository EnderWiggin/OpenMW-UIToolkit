---@omw-context player

local Class = require('scripts.UIToolkit.class')

---@class UIToolkit.WindowHandler
local WindowHandler = Class()

---@param wnd UIToolkit.Window
---@param data any?
---@diagnostic disable-next-line: unused-local
function WindowHandler:onOpened(wnd, data)

end

function WindowHandler:onClosed()

end

---@param innerSize openmw.util.Vector2
---@diagnostic disable-next-line: unused-local
function WindowHandler:onResized(innerSize)

end

return WindowHandler
