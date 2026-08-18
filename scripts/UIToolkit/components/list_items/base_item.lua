---@omw-context player

local I = require('openmw.interfaces')

local Class = require('scripts.UIToolkit.class')

---@generic T: UIToolkit.ListData.Base
---@class UIToolkit.ListItem.Base<T>
---@field cache table<string, {size:openmw.util.Vector2, component:UIToolkit.Component}>
local ListItemBase = Class(nil, function(self)
    self.cache = {}
end)

---@generic T: UIToolkit.ListData.Base
---@param data T
---@param size openmw.util.Vector2
---@return UIToolkit.Component
---@diagnostic disable-next-line: unused-local
function ListItemBase:makeComponent(data, size)
    error('Need to implement `makeComponent()`!')
end

---@generic T: UIToolkit.ListData.Base
---@param data T
---@return UTKTooltips.Tooltip?
---@diagnostic disable-next-line: unused-local
function ListItemBase:getTooltip(data)
    return nil
end

---@param data UIToolkit.ListData.Base
---@param size openmw.util.Vector2
---@return openmw.ui.Element, boolean
function ListItemBase:getView(data, size)
    local component, changed = self:getComponent(data, size)
    return component.element, changed
end

---@param data UIToolkit.ListData.Base
---@param size openmw.util.Vector2
---@return UIToolkit.Component, boolean
function ListItemBase:getComponent(data, size)
    local cached = self.cache[data.id]
    local changed = false
    if not cached or cached.size ~= size or cached.component:isDestroyed() then
        changed = true
        cached = {
            size = size,
            component = self:makeComponent(data, size),
        }
        self.cache[data.id] = cached
    end

    return cached.component, changed
end

---@param id string
---@return openmw.ui.Element|nil
function ListItemBase:getCachedView(id)
    local component = self:getCachedComponent(id)
    return component and component.element
end

---@param id string
---@return UIToolkit.Component|nil
function ListItemBase:getCachedComponent(id)
    local cached = self.cache[id]
    if not cached or not cached.component or cached.component:isDestroyed() then
        return nil
    end

    return cached.component
end

---@param id string
---@param size openmw.util.Vector2
---@return boolean
function ListItemBase:isDirty(id, size)
    local cached = self.cache[id]
    return not cached or cached.size ~= size or cached.component:isDestroyed()
end

---@param id string
function ListItemBase:remove(id)
    local cached = self.cache[id]
    if cached and not cached.component:isDestroyed() then
        I.UIToolkit.queueDestroy(cached.component.element, true)
    end
    self.cache[id] = nil
end

function ListItemBase:clear()
    for _, cached in pairs(self.cache) do
        if cached and not cached.component:isDestroyed() then
            I.UIToolkit.queueDestroy(cached.component.element, true)
        end
    end

    self.cache = {}
end

return ListItemBase
