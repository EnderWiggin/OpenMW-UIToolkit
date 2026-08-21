---@omw-context all
local context = require('scripts.UIToolkit.scriptContext')
local storage = require('openmw.storage')
local util = require('openmw.util')

local C = require('scripts.UIToolkit.constants')
local H = {}

H.deepPrint = function(tbl, indent)
    if type(tbl) ~= 'table' then return tostring(tbl) end
    indent = indent or 0
    local toprint = string.rep(" ", indent) .. "{\n"
    indent = indent + 2
    for k, v in pairs(tbl) do
        toprint = toprint .. string.rep(" ", indent)
        if (type(k) == "number") then
            toprint = toprint .. "[" .. k .. "] = "
        elseif (type(k) == "string") then
            toprint = toprint .. k .. " = "
        end
        if (type(v) == "number") then
            toprint = toprint .. v .. ",\n"
        elseif (type(v) == "string") then
            toprint = toprint .. "\"" .. v .. "\",\n"
        elseif (type(v) == "table") then
            toprint = toprint .. H.deepPrint(v, indent + 2) .. ",\n"
        else
            toprint = toprint .. "\"" .. tostring(v) .. "\",\n"
        end
    end
    toprint = toprint .. string.rep(" ", indent - 2) .. "}"
    return toprint
end

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

H.roundToPlaces = function(num, places)
    local m = 10 ^ (places or 0)
    return math.floor(num * m + 0.5) / m
end

H.addSeparators = function(number)
    local mode = C.SEPARATOR_OPTS.Space --TODO: add settings
    local separator

    if mode == C.SEPARATOR_OPTS.Comma then
        separator = ','
    elseif mode == C.SEPARATOR_OPTS.Space then
        separator = ' '
    end
    if separator == nil then return tostring(number) end

    local _, _, minus, int, fraction = tostring(number):find('([-]?)(%d+)([.]?%d*)')

    -- reverse the int-string and append a comma to all blocks of 3 digits
    int = int:reverse():gsub("(%d%d%d)", "%1" .. separator)

    -- reverse the int-string back remove an optional comma and put the
    -- optional minus and fractional part back
    return minus .. int:reverse():gsub("^" .. separator, "") .. fraction
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
local I = require('openmw.interfaces')

---@param id string effect id
---@return openmw.core.MagicEffect? record, boolean isCustom
H.getMagicEffectRecord = function(id)
    ---@type openmw.core.MagicEffect?
    local effect = core.magic.effects.records[id]
    if effect then return effect, false end
    effect = I.MagicWindow and I.MagicWindow.Spells.getCustomEffect(id)
    if effect then return effect, true end
    return nil, false
end

---@omw-context-end runtime

return H
