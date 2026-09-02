---@omw-context none

---Creates new class, optionally derived from a parent class
---@param parent table? Optional parent class
---@param init fun(self:table)? Optional parent class
return function(parent, init)
    local c = {}
    c.__index = c
    if parent then
        setmetatable(c, { __index = parent })
        c.new = function(self)
            local o = setmetatable(parent:new(), self or c)
            if init then init(o) end
            return o
        end
    else
        c.new = function(self)
            local o = setmetatable({}, self or c)
            if init then init(o) end
            return o
        end
    end

    return c
end
