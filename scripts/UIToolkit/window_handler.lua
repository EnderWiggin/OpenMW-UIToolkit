---@omw-context player

local Class = require('scripts.UIToolkit.class')

---@class UIToolkit.WindowHandler
local WindowHandler = Class()

---@param wnd UIToolkit.Window
function WindowHandler:onOpened(wnd)

end

function WindowHandler:onClosed()

end

---@param innerSize openmw.util.Vector2
function WindowHandler:onResized(innerSize)

end

return WindowHandler
