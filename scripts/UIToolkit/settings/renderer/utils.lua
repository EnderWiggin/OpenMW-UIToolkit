---@omw-context none

local M = {}

function M.parseArgData(data)
    if type(data) ~= 'userdata' then return data end
    local t = {}
    for k, v in pairs(data) do
        t[M.parseArgData(k)] = M.parseArgData(v)
    end
    return t
end

return M
