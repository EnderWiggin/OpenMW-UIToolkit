---@omw-context player|menu

local I = require('openmw.interfaces')
local H = require('scripts.UIToolkit.helpers')
local Class = require('scripts.UIToolkit.class')

---@class UIToolkit.Component
local Component = Class()

---@param element openmw.ui.Element
function Component:init(element)
    self.element = element
    H.userData(element)._component = self
end

function Component:isDestroyed()
    return self.element == nil or self.element.layout == nil
end

function Component:beforeElementDestroy() end

---@return boolean|nil -- whether component is visible, `nil` if destroyed.
function Component:isVisible()
    if self:isDestroyed() then return nil end
    local props = self.element.layout.props
    return (props and props.visible or nil) ~= false
end

--- Sets component's visibility and queues update
---@param value boolean?
---@return UIToolkit.Component self
function Component:setVisible(value)
    if self:isDestroyed() then return self end

    self:updateProps { visible = value }
    I.UIToolkit.queueUpdate(self.element)
    return self
end

---@return boolean|nil --Returns active flag. If component is destroyed - returns nil.
function Component:isActive()
    if self:isDestroyed() then return nil end

    ---@type UIToolkit.InteractiveState
    local userData = self.element.layout.userData
    return userData ~= nil and userData.active == true
end

--- Sets active state of the component and queues update.
---@param value boolean?
---@param deep boolean?
---@return UIToolkit.Component self
function Component:setActive(value, deep)
    if self:isDestroyed() then return self end

    I.UIToolkit.Interactive.updateState(self.element, { active = value })
    I.UIToolkit.queueUpdate(self.element, deep == true)

    return self
end

---@return boolean|nil --Returns disabled flag. If component is destroyed - returns nil.
function Component:isDisabled()
    if self:isDestroyed() then return nil end

    ---@type UIToolkit.InteractiveState
    local userData = self.element.layout.userData
    return userData ~= nil and userData.disabled == true
end

--- Sets disabled state of the component and queues update.
---@param value boolean?
---@param deep boolean?
---@return UIToolkit.Component self
function Component:setDisabled(value, deep)
    if self:isDestroyed() then return self end

    I.UIToolkit.Interactive.updateState(self.element, { disabled = value })
    I.UIToolkit.queueUpdate(self.element, deep == true)

    return self
end

---@param props table
---@return UIToolkit.Component self
function Component:updateProps(props)
    if self:isDestroyed() then return self end

    self.element.layout.props = H.mergeTables(self.element.layout.props or {}, props)
    return self
end

return Component
