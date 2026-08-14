---@omw-context none

---Creates new class, optionally derived from a parent class
---@param parent table? Optional parent class
return function(parent)
    local c = {}
    c.__index = c
    if parent then
        setmetatable(c, { __index = parent })
        c.new = function(self)
            return setmetatable(parent:new(), self or c)
        end
    else
        c.new = function(self)
            return setmetatable({}, self or c)
        end
    end

    return c
end
