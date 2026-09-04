---@omw-context player

local ui = require('openmw.ui')
local util = require('openmw.util')
local I = require('openmw.interfaces')

local v2 = util.vector2
local Class = require('scripts.UIToolkit.class')
local ListItemBase = require('scripts.UIToolkit.components.list_items.base_item')
local Component = require('scripts.UIToolkit.components.component')

---@class UIToolkit.ListItem.Text: UIToolkit.ListItem.Base<UIToolkit.ListData.Text>
---@field new fun(self:UIToolkit.ListItem.Text):UIToolkit.ListItem.Text
local ListItemText = Class(ListItemBase)

---@return number
function ListItemBase:getItemHeight()
    return util.round(1.1 * I.UIToolkit.getTheme().Sizes.textNormal)
end

---@param data UIToolkit.ListData.Text
---@return UIToolkit.Component
function ListItemText:makeComponent(data)
    local T = I.UIToolkit.Templates

    local component = Component:new()
    component:init(ui.create {
        template = T.text(),
        props = {
            text = data.text,
            autoSize = false,
            size = v2(0, self:getItemHeight()),
            relativeSize = v2(1, 0),
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
