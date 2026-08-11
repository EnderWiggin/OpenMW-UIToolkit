---@omw-context all
local context = require('scripts.UIToolkit.scriptContext')
local util = require('openmw.util')

local H = {}

local function deepCopy(value, seen)
    if type(value) ~= 'table' then return value end
    local okColor = pcall(function() return value:asHex() end)
    if okColor then return value end
    seen = seen or {}
    if seen[value] then return seen[value] end
    local result = {}
    seen[value] = result
    for key, item in pairs(value) do
        result[deepCopy(key, seen)] = deepCopy(item, seen)
    end
    return result
end

---@generic T : table
---@param table T
---@return T
function H.deepCopy(table)
    return deepCopy(table)
end

function H.shallowCopy(tbl)
    if type(tbl) ~= 'table' then return tbl end
    local copy = {}
    for k, v in pairs(tbl) do
        copy[k] = v
    end
    return copy
end

function H.mergeTables(t1, t2)
    local merged = H.shallowCopy(t1)
    for k, v in pairs(t2) do
        merged[k] = v
    end
    return merged
end

---@param layoutOrElement openmw.ui.Element|openmw.ui.Layout
---@return openmw.ui.Layout
function H.toLayout(layoutOrElement)
    local isElement = type(layoutOrElement) == 'userdata'

    if isElement then
        ---@cast layoutOrElement openmw.ui.Element
        return layoutOrElement.layout
    else
        ---@cast layoutOrElement openmw.ui.Layout
        return layoutOrElement
    end
end

---@param layoutOrElement openmw.ui.Layout|openmw.ui.Element
---@param func fun(layout:openmw.ui.Layout)
function H.forEachInLayout(layoutOrElement, func)
    local layout = H.toLayout(layoutOrElement)
    func(layout)
    if layout.content then
        for _, child in pairs(layout.content) do
            H.forEachInLayout(child, func)
        end
    end
end

if not context.isRuntime() then return H end
---@omw-context-begin runtime

local core = require('openmw.core')


function H.colorFromGMST(gmst)
    local colorString = core.getGMST(gmst)
    local numberTable = {}
    for numberString in colorString:gmatch("([^,]+)") do
        if #numberTable == 3 then break end
        local number = tonumber(numberString:match("^%s*(.-)%s*$"))
        if number then
            table.insert(numberTable, number / 255)
        end
    end

    if #numberTable < 3 then error('Invalid color GMST name: ' .. gmst) end

    return util.color.rgb(table.unpack(numberTable))
end

---@omw-context-end runtime

return H
