---@omw-context player|menu

local I = require('openmw.interfaces')

local Class = require('scripts.UIToolkit.class')

---@generic T: UIToolkit.ListData.Base
---@class UIToolkit.ListItem.Base<T>
---@field cache table<string, UIToolkit.Component>
local ListItemBase = Class(nil, function(self)
    self.cache = {}
end)

---@generic T: UIToolkit.ListData.Base
---@param data T
---@return UIToolkit.Component
---@diagnostic disable-next-line: unused-local
function ListItemBase:makeComponent(data)
    error('Need to implement `makeComponent()`!')
end

---@return number
function ListItemBase:getItemHeight()
    error('Need to implement `getItemHeight()`!')
end

---@generic T: UIToolkit.ListData.Base
---@param data T
---@return UTKTooltips.AnyTooltip?
---@diagnostic disable-next-line: unused-local
function ListItemBase:getTooltip(data)
    return nil
end

---@param data UIToolkit.ListData.Base
---@return openmw.ui.Element
function ListItemBase:getView(data)
    local component = self:getComponent(data)
    return component.element
end

---@param data UIToolkit.ListData.Base
---@return UIToolkit.Component
function ListItemBase:getComponent(data)
    local cached = self.cache[data.id]
    if cached and not cached:isDestroyed() then return cached end

    local component = self:makeComponent(data)
    self.cache[data.id] = component
    return component
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
    if not cached or cached:isDestroyed() then
        return nil
    end

    return cached
end

---@param id string
function ListItemBase:remove(id)
    local cached = self.cache[id]
    if cached and not cached:isDestroyed() then
        I.UIToolkit.queueDestroy(cached.element, true)
    end
    self.cache[id] = nil
end

function ListItemBase:clear()
    for _, cached in pairs(self.cache) do
        if cached and not cached:isDestroyed() then
            I.UIToolkit.queueDestroy(cached.element, true)
        end
    end

    self.cache = {}
end

return ListItemBase
