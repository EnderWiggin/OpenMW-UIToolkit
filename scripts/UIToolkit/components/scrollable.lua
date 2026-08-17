---@omw-context player

local I = require('openmw.interfaces')
local Class = require('scripts.UIToolkit.class')
local Component = require('scripts.UIToolkit.components.component')

---@class UIToolkit.Scrollable : UIToolkit.Component
local Scrollable = Class(Component)


---@param delta number
---@diagnostic disable-next-line: unused-local
function Scrollable:onMouseScrolled(delta) end

return Scrollable
