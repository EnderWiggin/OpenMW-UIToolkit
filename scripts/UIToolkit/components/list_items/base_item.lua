---@omw-context player

local I = require('openmw.interfaces')

local Class = require('scripts.UIToolkit.class')

---@class UIToolkit.ListData.Base
---@field id string

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

---@param data UIToolkit.ListData.Base
---@param size openmw.util.Vector2
---@return openmw.ui.Element
function ListItemBase:getView(data, size)
    local cached = self.cache[data.id]
    if not cached or cached.size ~= size or cached.component:isDestroyed() then
        cached = {
            size = size,
            component = self:makeComponent(data, size),
        }
        self.cache[data.id] = cached
    end

    return cached.component.element
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
