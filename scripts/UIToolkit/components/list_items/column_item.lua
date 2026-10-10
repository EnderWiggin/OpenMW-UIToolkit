---@omw-context player|menu

local ui = require('openmw.ui')
local util = require('openmw.util')
local I = require('openmw.interfaces')

local v2 = util.vector2
local H = require("scripts.UIToolkit.helpers")

local Class = require('scripts.UIToolkit.class')
local Component = require('scripts.UIToolkit.components.component')
local ListItemBase = require('scripts.UIToolkit.components.list_items.base_item')

---@class UIToolkit.ListItem.ColumnComponent : UIToolkit.ListItem.RowComponent
---@field dirty? true|table<string, true> set of dirty column ids, or `true` if all columns are dirty

---@class UIToolkit.ListItem.Column: UIToolkit.ListItem.Base<UIToolkit.ListData.Column>
---@field new fun(self:UIToolkit.ListItem.Column):UIToolkit.ListItem.Column
local Item = Class(ListItemBase)

---@param columns UIToolkit.ListData.ColumnConfig[]
---@param rowHeight number
function Item:init(columns, rowHeight)
    self.columns = columns
    self.rowHeight = rowHeight
    self.hidden = {}
end

---@return number
function Item:getItemHeight()
    return self.rowHeight
end

---@param data UIToolkit.ListData.Column
---@return UIToolkit.Component
function Item:makeComponent(data)
    local active = data.isActive and data.isActive()

    local columns = ui.content {}
    for i = 1, #self.columns do
        local cfg = self.columns[i]
        if not self.hidden[cfg.id] then
            columns[#columns + 1] = cfg.render(data, cfg, self.rowHeight)
        end
    end
    local layout = {
        name = data.id,
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
            autoSize = false,
            relativeSize = v2(1, 1),
        },
        content = columns,
        userData = { active = active }
    }
    I.UIToolkit.Interactive.updateState(layout)
    local component = Component:new()
    component:init(ui.create(layout))
    return component
end

---@param data UIToolkit.ListData.Column
---@return UIToolkit.Component
function Item:getComponent(data)
    local component = ListItemBase.getComponent(self, data) --[[@as UIToolkit.ListItem.ColumnComponent]]
    if component.dirty then
        self:refreshDirty(component, data)
    end
    return component
end

---@param cfg UIToolkit.ListData.ColumnConfig
---@return UIToolkit.ListItem.Column.Updater?
local function getUpdater(cfg)
    if cfg.update then return cfg.update end
    if cfg.render == Item.renderText then
        return Item.updateText
    elseif cfg.render == Item.renderIcon then
        return Item.updateIcon
    end
    return nil
end

---@param id string
---@param data UIToolkit.ListData.Column
---@param names string[]
---@private
function Item:refreshColumnsById(id, data, names)
    local cached = self:getCachedComponent(id) --[[@as UIToolkit.ListItem.ColumnComponent]]
    if not cached or cached:isDestroyed() then return end
    data = data or cached.data
    assert(data)
    local content = cached.element.layout.content
    if not content then return end

    -- at least one column was updated or re-rendered
    local changed = false

    local i = 1
    for k = 1, #self.columns do
        local cfg = self.columns[k]
        if not self.hidden[cfg.id] then
            local part = content[i] --[[@as openmw.ui.Element]]
            local layout = H.toLayout(part)
            local isElement = part ~= layout
            if layout and H.findInArray(names, layout.name) then
                local updater = getUpdater(cfg)
                if updater then
                    --update in-place, never re-render; update returns whether the value changed
                    if updater(part, data, cfg, self.rowHeight) then
                        changed = true
                    end
                else
                    --no update method - full re-creation
                    if isElement and part then I.UIToolkit.queueDestroy(part, true) end
                    content[i] = cfg.render(data, cfg, self.rowHeight)
                    changed = true
                end
            end
            i = i + 1
        end
    end

    if changed then
        I.UIToolkit.Interactive.updateState(cached.element)
        I.UIToolkit.queueUpdate(cached.element)
    end
end

---@param idOrData string|UIToolkit.ListData.Column
---@param ... string
function Item:refreshColumns(idOrData, ...)
    local id, data
    if type(idOrData) == 'string' then
        id = idOrData
    else
        id = idOrData.id
        data = idOrData
    end
    self:refreshColumnsById(id, data, { ... })
end

---@param idOrData string|UIToolkit.ListData.Column
function Item:markAllDirty(idOrData)
    local id = type(idOrData) == 'string' and idOrData or idOrData.id
    local cached = self:getCachedComponent(id) --[[@as UIToolkit.ListItem.ColumnComponent]]
    if not cached then return end
    cached.dirty = true
end

---Marks all currently cached items as having all columns dirty
function Item:markCacheDirty()
    for id, cached in pairs(self.cache) do
        if cached:isDestroyed() then
            self.cache[id] = nil
        else
            cached.dirty = true
        end
    end
end

---@param idOrData string|UIToolkit.ListData.Column
---@param columnId string
function Item:markColumnDirty(idOrData, columnId)
    local id = type(idOrData) == 'string' and idOrData or idOrData.id
    local cached = self:getCachedComponent(id) --[[@as UIToolkit.ListItem.ColumnComponent]]
    if not cached then return end
    local dirty = cached.dirty
    if dirty == true then return end
    if not dirty then
        dirty = {}
        cached.dirty = dirty
    end
    dirty[columnId] = true
end

---@param component UIToolkit.ListItem.ColumnComponent
---@param data UIToolkit.ListData.Column
---@private
function Item:refreshDirty(component, data)
    local dirty = component.dirty
    if not dirty then return end
    component.dirty = nil
    local id = (data and data.id) or (component.data and component.data.id)
    if not id then return end
    if dirty == true then
        local names = {}
        for i = 1, #self.columns do
            names[#names + 1] = self.columns[i].id
        end
        self:refreshColumnsById(id, data, names)
    else
        local names = {}
        for name in pairs(dirty) do
            names[#names + 1] = name
        end
        self:refreshColumnsById(id, data, names)
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

---@param hidden? table<string, boolean>
function Item:setHiddenColumns(hidden)
    self.hidden = hidden or {}
    self:clear()
end

---@param data UIToolkit.ListData.Column
---@param cfg UIToolkit.ListData.ColumnConfig
---@return string|number
local function formatColumnValue(data, cfg)
    local value = data[cfg.id] or ''
    if type(value) == 'function' then
        value = value()
    end
    if type(value) == 'number' then
        value = H.addSeparators(H.roundToPlaces(value, 2))
    end
    return value
end

---@type UIToolkit.ListItem.Column.Renderer
function Item.renderText(data, cfg, height)
    local value = formatColumnValue(data, cfg)
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
    return layout
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
    return layout
end

---@param part openmw.ui.Layout
---@param data UIToolkit.ListData.Column
---@param cfg UIToolkit.ListData.ColumnConfig
---@return boolean changed
function Item.updateText(part, data, cfg)
    local new = tostring(formatColumnValue(data, cfg))
    local props = H.props(part)
    if props.text == new then return false end
    props.text = new
    return true
end

---@param part openmw.ui.Layout
---@param data UIToolkit.ListData.Column
---@param cfg UIToolkit.ListData.ColumnConfig
---@return boolean changed
function Item.updateIcon(part, data, cfg)
    local icon = H.findLayoutByPath(part, { 'icon' })
    local new = I.UIToolkit.texture(data[cfg.id] or 'icons/UIToolkit/unknown-effect.dds')
    local props = H.props(icon)
    if props.resource == new then return false end
    props.resource = new
    return true
end

---@type UIToolkit.ListItem.Column.Renderer
function Item.renderHidden(_, cfg, height)
    return ui.create {
        name = cfg.id,
        type = ui.TYPE.Widget,
        props = { size = v2(0, height) },
    }
end

---@param layout openmw.ui.Layout
---@param cfg UIToolkit.ListData.ColumnConfig
---@param height number
function Item.applySize(layout, cfg, height)
    local width = cfg.width or 0
    local auto = (width == 0 and (cfg.auto or 1)) or nil

    local props = H.props(layout)
    props.size = v2(width, height)

    local external = layout.external or {}
    external.grow = auto
    layout.external = external
end

return Item
