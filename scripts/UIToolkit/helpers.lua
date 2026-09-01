---@omw-context all
local context = require('scripts.UIToolkit.scriptContext')
local storage = require('openmw.storage')
local util = require('openmw.util')

local C = require('scripts.UIToolkit.constants')

---@class UIToolkit.Helpers
local H = {}

H.toStringDeep = function(tbl, indent)
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
            toprint = toprint .. H.toStringDeep(v, indent + 2) .. ",\n"
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

---
---@param array any[]
---@param what any
---@return integer? index of the item, or nil if not fount
function H.findInArray(array, what)
    for i = 1, #array do
        if array[i] == what then return i end
    end
    return nil
end

---Removes all instances of `what` from `array`
---@param array any[]
---@param what any
function H.removeFromArray(array, what)
    local idx = H.findInArray(array, what)
    while idx do
        table.remove(array, idx)
        idx = H.findInArray(array, what)
    end
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

---Returns list of `str` parts split by `separator`
---@param str string string to split
---@param separator string? defaults to `%s` (space)
---@return string[]
function H.splitString(str, separator)
    separator = separator or "%s" -- Default to whitespace separator
    local result = {}
    for part in string.gmatch(str, "([^" .. separator .. "]+)") do
        table.insert(result, part)
    end
    return result
end

---Returns `str` with spaces in front and end trimmed
---@param str string
---@return string
function H.trim(str)
    return str:match("^%s*(.-)%s*$")
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

---@param content openmw.ui.Content
---@param name string|integer
---@return openmw.ui.Layout?
local function getContentLayoutByName(content, name)
    local ok, tmp = pcall(function() return content[name] end)
    if ok and tmp then
        return H.toLayout(tmp)
    end

    --In some cases there may be content with names child, but wrong name-to-index table
    --try finding proper layout by iterating
    for i = 1, #content do
        local w = content[i]
        local layout = w and H.toLayout(w)
        if layout and layout.name == name then
            return layout
        end
    end
    return nil
end

---@param layoutOrElement openmw.ui.Element|openmw.ui.Layout
---@param path (string|integer)[]
---@return openmw.ui.Layout layout the requested layout, otherwise throws error
function H.findLayoutByPath(layoutOrElement, path)
    assert(layoutOrElement, 'empty layoutOrElement')
    ---@type openmw.ui.Layout?
    local layout = H.toLayout(layoutOrElement)
    ---@cast layout openmw.ui.Layout
    for i = 1, #path do
        local msg = ' for path: "' .. table.concat(path, '/') .. '", part: ' .. i
        assert(layout, 'empty layout' .. msg)
        local content = layout.content
        assert(content, 'empty content' .. msg)
        layout = getContentLayoutByName(content, path[i])
    end
    return layout or error('empty layout for path: "' .. table.concat(path, '/') .. '"')
end

---@param layoutOrElement openmw.ui.Element|openmw.ui.Layout
---@param path (string|integer)[]
---@return openmw.ui.Layout? layout the requested layout, otherwise nil
function H.findLayoutByPathSafe(layoutOrElement, path)
    local ok, layout = pcall(H.findLayoutByPath, layoutOrElement, path)
    return ok and layout or nil
end

---@param layoutOrElement openmw.ui.Layout|openmw.ui.Element
---@return table
function H.props(layoutOrElement)
    local layout = H.toLayout(layoutOrElement)
    if not layout then return {} end
    layout.props = layout.props or {}
    return layout.props
end

---@param layoutOrElement openmw.ui.Layout|openmw.ui.Element
---@return table
function H.userData(layoutOrElement)
    local layout = H.toLayout(layoutOrElement)
    if not layout then return {} end
    layout.userData = layout.userData or {}
    return layout.userData
end

if not context.isRuntime() then return H end
---@omw-context-begin runtime

local core = require('openmw.core')
local I = require('openmw.interfaces')

---@param gmst string
---@return string
local function hexFromGMST(gmst)
    local color = util.color.commaString(core.getGMST(gmst))
    local str = string.format("#%02X%02X%02X",
        util.round(255 * color.r),
        util.round(255 * color.g),
        util.round(255 * color.b)
    ):lower()
    return str
end

---To be used in l10n files for text coloring
H.TextColorParams = {
    color_normal = hexFromGMST('fontcolor_color_normal'),
    color_header = hexFromGMST('fontcolor_color_header'),
    color_positive = hexFromGMST('fontcolor_color_positive'),
    color_negative = hexFromGMST('fontcolor_color_negative'),
}

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
