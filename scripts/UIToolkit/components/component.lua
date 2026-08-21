---@omw-context player

local I = require('openmw.interfaces')
local H = require('scripts.UIToolkit.helpers')
local Class = require('scripts.UIToolkit.class')

---@class UIToolkit.Component
local Component = Class()

---@param element openmw.ui.Element
function Component:init(element)
    self.element = element
end

function Component:isDestroyed()
    return self.element == nil or self.element.layout == nil
end

--- If value is set - will update active state of the control
---@param value boolean?
---@return boolean|nil --Returns active flag. If control is destroyed - returns nil.
function Component:visible(value)
    if self:isDestroyed() then return nil end
    local props = self.element.layout.props
    if value ~= nil then
        props = props or {}
        props.visible = value
        self.element.layout.props = props
        I.UIToolkit.queueUpdate(self.element)
    end

    return props == nil or props.visible ~= false
end

--- If value is set - will update active state of the control
---@param value boolean?
---@return boolean|nil --Returns active flag. If control is destroyed - returns nil.
function Component:active(value)
    if self:isDestroyed() then return nil end

    if value ~= nil then
        I.UIToolkit.Interactive.updateState(self.element, { active = value })
        I.UIToolkit.queueUpdate(self.element)
    end

    ---@type UIToolkit.InteractiveState
    local userData = self.element.layout.userData
    return userData ~= nil and userData.active == true
end

--- If value is set - will update disabled state of the control
---@param value boolean?
---@return boolean|nil --Returns disabled flag. If control is destroyed - returns nil.
function Component:disabled(value)
    if self:isDestroyed() then return nil end

    if value ~= nil then
        I.UIToolkit.Interactive.updateState(self.element, { disabled = value })
        I.UIToolkit.queueUpdate(self.element)
    end

    ---@type UIToolkit.InteractiveState
    local userData = self.element.layout.userData
    return userData ~= nil and userData.disabled == true
end

---@param props table
---@return UIToolkit.Component
function Component:updateProps(props)
    if self:isDestroyed() then return self end

    self.element.layout.props = H.mergeTables(self.element.layout.props or {}, props)
    return self
end

return Component
