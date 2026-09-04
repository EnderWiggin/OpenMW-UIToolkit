---@omw-context all

local Class = require('scripts.UIToolkit.class')

---@class UIToolkit.WindowHandler
local WindowHandler = Class()

---@param wnd UIToolkit.Window
---@param data any?
---@param saved table? Table that was returned from `onClosed`
---@diagnostic disable-next-line: unused-local
function WindowHandler:onOpened(wnd, data, saved)

end

---@return table? saved data to store. Will be passed to `onOpened`
function WindowHandler:onClosed()

end

---@param innerSize openmw.util.Vector2
---@diagnostic disable-next-line: unused-local
function WindowHandler:onResized(innerSize)

end

---@param dt number
---@diagnostic disable-next-line: unused-local
function WindowHandler:onFrame(dt)

end

---@param button number
---@diagnostic disable-next-line: unused-local
function WindowHandler:onControllerButtonPress(button)

end

---@param button number
---@diagnostic disable-next-line: unused-local
function WindowHandler:onControllerButtonRepeat(button)

end

---@return UIToolkit.Scrollable?
function WindowHandler:getFocusedScrollable()
    return nil
end

return WindowHandler
