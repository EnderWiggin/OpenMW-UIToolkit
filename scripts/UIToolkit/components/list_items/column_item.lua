---@omw-context player

local ui = require('openmw.ui')
local util = require('openmw.util')
local I = require('openmw.interfaces')

local v2 = util.vector2
local H = require("scripts.UIToolkit.helpers")

local Class = require('scripts.UIToolkit.class')
local Component = require('scripts.UIToolkit.components.component')
local ListItemBase = require('scripts.UIToolkit.components.list_items.base_item')

---@class UIToolkit.ListItem.RowComponent : UIToolkit.Component
---@field data UIToolkit.ListData.Column?
local RowComponent = Class(Component)

---@class UIToolkit.ListItem.Column: UIToolkit.ListItem.Base<UIToolkit.ListData.Column>
local Item = Class(ListItemBase)

---@param columns UIToolkit.ListData.ColumnConfig[]
---@param rowHeight number
function Item:init(columns, rowHeight)
    self.columns = columns
    self.rowHeight = rowHeight
end

---@return number
function Item:getItemHeight()
    return self.rowHeight
end

---@param data UIToolkit.ListData.Column
---@return UIToolkit.Component
function Item:makeComponent(data)
    local active = data.isActive and data.isActive()

    local columns = {}
    for i = 1, #self.columns do
        local cfg = self.columns[i]
        columns[#columns + 1] = cfg.render(data, cfg, self.rowHeight)
    end
    local layout = {
        name = data.id,
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
            autoSize = false,
            relativeSize = v2(1, 1),
        },
        content = ui.content(columns),
        userData = { active = active }
    }
    I.UIToolkit.Interactive.updateState(layout)
    local component = RowComponent:new() --[[@as UIToolkit.ListItem.RowComponent]]
    component.data = data
    component:init(ui.create(layout))
    return component
end

---@param idOrData string|UIToolkit.ListData.Column
---@param ... string|integer
function Item:refreshColumns(idOrData, ...)
    local id, data
    if type(idOrData) == 'string' then
        id = idOrData
    else
        id = idOrData.id
        data = idOrData
    end
    local columns = {}
    local args = { ... }
    for i = 1, select("#", ...) do
        columns[args[i]] = true
    end
    local cached = self:getCachedComponent(id) --[[@as UIToolkit.ListItem.RowComponent]]
    if not cached or cached:isDestroyed() then return end
    data = data or cached.data
    assert(data)
    local content = cached.element.layout.content
    if not content then return end
    for i = 1, #content do
        local part = content[i] --[[@as openmw.ui.Element]]
        if columns[i] or columns[part.layout.name] then
            local cfg = self.columns[i]
            --TODO: add possibility to update instead of re-render?
            I.UIToolkit.queueDestroy(part, true)
            content[i] = cfg.render(data, cfg, self.rowHeight)
            I.UIToolkit.Interactive.updateState(cached.element)
            I.UIToolkit.queueUpdate(cached.element)
        end
    end
end

---@param data UIToolkit.ListData.Column
---@return UTKTooltips.AnyTooltip?
function Item:getTooltip(data)
    local tip = data.tooltip
    if not tip then return nil end
    if type(tip) == "function" then
        ---@cast tip UIToolkit.TooltipProvider
        return tip()
    end
    return tip
end

---@type UIToolkit.ListItem.Column.Renderer
function Item.renderText(data, cfg, height)
    local value = data[cfg.id] or ''
    if type(value) == 'function' then
        value = value()
    end
    if type(value) == 'number' then
        value = H.addSeparators(H.roundToPlaces(value, 2))
    end
    local textSize = cfg.arg and cfg.arg.textSize or nil
    local textAlignH = cfg.arg and cfg.arg.textAlignH or nil
    ---@type openmw.ui.Layout
    local layout = {
        name = cfg.id,
        template = I.UIToolkit.Templates.text(),
        props = {
            textAlignV = ui.ALIGNMENT.Center,
            textAlignH = textAlignH,
            autoSize = false,
            textSize = textSize,
            text = tostring(value),
        },
        userData = { colorable = true },
    }

    Item.applySize(layout, cfg, height)
    return ui.create(layout)
end

---@type UIToolkit.ListItem.Column.Renderer
function Item.renderIcon(data, cfg, height)
    local sz = cfg.arg and cfg.arg.sz or math.min(height, cfg.width or height)
    ---@type openmw.ui.Layout
    local layout = {
        name = cfg.id,
        type = ui.TYPE.Widget,
        props = {},
        content = ui.content { {
            name = 'icon',
            type = ui.TYPE.Image,
            props = {
                resource = I.UIToolkit.texture(data[cfg.id] or 'icons/UIToolkit/unknown-effect.dds'),
                size = v2(sz, sz),
                anchor = v2(0, 0.5),
                relativePosition = v2(0, 0.5),
            },
        } },
    }

    Item.applySize(layout, cfg, height)
    return ui.create(layout)
end

---@param layout openmw.ui.Layout
---@param cfg UIToolkit.ListData.ColumnConfig
---@param height number
function Item.applySize(layout, cfg, height)
    local width = cfg.width or 0
    local auto = (width == 0 and (cfg.auto or 1)) or nil

    local props = layout.props or {}
    props.size = v2(width, height)
    layout.props = props

    local external = layout.external or {}
    external.grow = auto
    layout.external = external
end

return Item
