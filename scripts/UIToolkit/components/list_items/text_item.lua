---@omw-context player

local ui = require('openmw.ui')

local Class = require('scripts.UIToolkit.class')
local ListItemBase = require('scripts.UIToolkit.components.list_items.base_item')
local Component = require('scripts.UIToolkit.components.component')

local T = require('scripts.UIToolkit.templates.base')

---@class UIToolkit.ListData.Text : UIToolkit.ListData.Base
---@field text string

---@class UIToolkit.ListItem.Text: UIToolkit.ListItem.Base<UIToolkit.ListData.Text>
local ListItemText = Class(ListItemBase)

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
---@return UTKTooltips.Tooltip?
function ListItemBase:getTooltip(data)
    ---@type UTKTooltips.Tooltip
    return {
        recipe = {
            arrange = ui.ALIGNMENT.Center,
            items = {
                --{ type = 'header', title = data.text, subtitle = 'id: ' .. data.id },
                { text = data.text },
                --{ type = 'default', text = data.text, value = data.id },
            },
        }
    }
end

return ListItemText
