---@omw-context none

local Class = require 'scripts.UIToolkit.class'

---@generic T
---@class UIToolkit.CompoundFilterPrivate<T> : UIToolkit.CompoundFilter<T>
---@field filters table<string, fun(item:T):boolean>
---@field disabled table<string, boolean>
local Filter = Class(nil, function(self)
    self.filters = {}
    self.disabled = {}
end)

---@param name string
---@param filter fun(item:T):boolean
function Filter:add(name, filter)
    self.filters[name] = filter
    self._filters = nil
end

---@param name string
function Filter:remove(name)
    self.filters[name] = nil
    self._filters = nil
end

---@param name string
---@param value boolean?
function Filter:disable(name, value)
    if value ~= false then
        self.disabled[name] = true
    else
        self.disabled[name] = nil
    end
    self._filters = nil
end

---@param item T
function Filter:match(item)
    local filters = self:_getFilters()
    for i = 1, #filters do
        if not filters[i](item) then return false end
    end
    return true
end

function Filter:_getFilters()
    if self._filters then return self._filters end
    local filters = {}
    for name, filter in pairs(self.filters) do
        if not self.disabled[name] then
            filters[#filters + 1] = filter
        end
    end
    self._filters = filters
    return self._filters
end

Filter.__call = Filter.match

return Filter --[[@as UIToolkit.CompoundFilter]]
