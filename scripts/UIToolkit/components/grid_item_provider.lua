---@omw-context player|menu

local I     = require 'openmw.interfaces'

local Class = require 'scripts.UIToolkit.class'



---@class UIToolkit.GridItem.Component : UIToolkit.Component
---@field data UIToolkit.ListData.Base?

---@param data UIToolkit.ListData.Base
---@param component UIToolkit.GridItem.Component<UIToolkit.ListData.Base>
local function updateState(data, component)
    local isActive = (data.isActive and data.isActive()) == true
    local isDisabled = (data.isDisabled and data.isDisabled()) == true

    if (component:isActive() == true) ~= isActive or (component:isDisabled() == true) ~= isDisabled then
        I.UIToolkit.Interactive.updateState(component.element, {
            active = data.isActive and data.isActive(),
            disabled = data.isDisabled and data.isDisabled(),
        })
        return true
    end
    return false
end


---@generic T: UIToolkit.ListData.Base
---@class UIToolkit.GridItem.Base<T>
---@field cache table<string, UIToolkit.Component>
local GridItemBase = Class(nil, function(self)
    self.cache = {}
end)

---@param data UIToolkit.ListData.Base
---@return UIToolkit.Component
---@diagnostic disable-next-line: unused-local
function GridItemBase:makeComponent(data)
    error('Need to implement `makeComponent()`!')
end

---@return openmw.util.Vector2
function GridItemBase:getItemSize()
    error('Need to implement `getItemSize()`!')
end

---@generic T: UIToolkit.ListData.Base
---@param data T
---@return UTKTooltips.AnyTooltip?
---@diagnostic disable-next-line: unused-local
function GridItemBase:getTooltip(data)
    return nil
end

---@return openmw.ui.Element?
function GridItemBase:getHighlightView()
    return nil
end

---@param data UIToolkit.ListData.Base
---@return openmw.ui.Element
function GridItemBase:getView(data)
    local component = self:getComponent(data)
    return component.element
end

---@param data UIToolkit.ListData.Base
---@return UIToolkit.Component
function GridItemBase:getComponent(data)
    local cached = self.cache[data.id]
    if cached and not cached:isDestroyed() then return cached end

    local component = self:makeComponent(data) --[[@as UIToolkit.GridItem.Component<UIToolkit.ListData.Base>]]
    component.data = data
    updateState(data, component)
    self.cache[data.id] = component
    return component
end

---@param id string
---@return openmw.ui.Element|nil
function GridItemBase:getCachedView(id)
    local component = self:getCachedComponent(id)
    return component and component.element
end

---@param id string
---@return UIToolkit.Component|nil
function GridItemBase:getCachedComponent(id)
    local cached = self.cache[id]
    if not cached or cached:isDestroyed() then
        return nil
    end

    return cached
end

---@param idOrData string|UIToolkit.ListData.Base
function GridItemBase:refreshState(idOrData)
    local id, data
    if type(idOrData) == 'string' then
        id = idOrData
    else
        id = idOrData.id
        data = idOrData
    end

    local cached = self:getCachedView(id) --[[@as UIToolkit.GridItem.Component<UIToolkit.ListData.Base>?]]
    if not cached then return end
    data = data or cached.data
    assert(data)

    if updateState(data, cached) then
        I.UIToolkit.queueUpdate(cached.element, true)
    end
end

---@param id string
function GridItemBase:remove(id)
    local cached = self.cache[id]
    if cached and not cached:isDestroyed() then
        I.UIToolkit.queueDestroy(cached.element, true)
    end
    self.cache[id] = nil
end

function GridItemBase:clear()
    for _, cached in pairs(self.cache) do
        if cached and not cached:isDestroyed() then
            I.UIToolkit.queueDestroy(cached.element, true)
        end
    end

    self.cache = {}
end

return GridItemBase
