---@omw-context player

local ui = require('openmw.ui')
local util = require('openmw.util')
local I = require('openmw.interfaces')

local Class = require('scripts.UIToolkit.class')
local ListItemBase = require('scripts.UIToolkit.components.list_items.base_item')
local Component = require('scripts.UIToolkit.components.component')

local T = require('scripts.UIToolkit.templates.base')

---@class UIToolkit.ListItem.Text: UIToolkit.ListItem.Base<UIToolkit.ListData.Text>
---@field new fun(self:UIToolkit.ListItem.Text):UIToolkit.ListItem.Text
local ListItemText = Class(ListItemBase)

---@return number
function ListItemBase:getItemHeight()
    return util.round(1.1 * I.UIToolkit.getTheme().Sizes.textNormal)
end

---@param data UIToolkit.ListData.Text
---@param size openmw.util.Vector2
---@return UIToolkit.Component
function ListItemText:makeComponent(data, size)
    local component = Component:new()
    component:init(ui.create {
        template = T.text(),
        props = {
            size = size,
            text = data.text,
            textAlignV = ui.ALIGNMENT.Center,
        },
        userData = { colorable = true },
    })
    return component
end

---@param data UIToolkit.ListData.Text
---@return UTKTooltips.AnyTooltip?
function ListItemText:getTooltip(data)
    return data.tooltip
end

return ListItemText
