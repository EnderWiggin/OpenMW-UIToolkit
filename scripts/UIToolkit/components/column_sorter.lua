---@omw-context player

local ui = require('openmw.ui')
local util = require('openmw.util')

local v2 = util.vector2

local I = require('openmw.interfaces')

local Class = require('scripts.UIToolkit.class')
local Component = require('scripts.UIToolkit.components.component')

local SORT_ASC = ui.texture { path = 'icons/UIToolkit/sort_asc.dds' }
local SORT_DESC = ui.texture { path = 'icons/UIToolkit/sort_desc.dds' }
local SORT_DEFAULT = ui.texture { path = 'icons/UIToolkit/sort_default.dds' }
local ICON_SZ = 16

local M = {}

---@class UIToolkit.ColumnSorter : UIToolkit.Component
---@field new fun(self:UIToolkit.ColumnSorter):UIToolkit.ColumnSorter
---@field activeColumn string|nil
---@field ascending boolean
local ColumnSorter = Class(Component)

---@param opts UIToolkit.ColumnSorterOpts
function ColumnSorter:init(opts)
    self.onChanged = opts.onChanged
    self.columns = opts.columns --[[@as  UIToolkit.ColumnSorter.Column[] ]]
    self.activeColumn = opts.default
    self.ascending = true

    local items = {}
    for i = 1, #self.columns do
        local cfg = self.columns[i]
        items[#items + 1] = M.renderItem(self, cfg)
    end
    local layout = {
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
            autoSize = false,
        },
        content = ui.content(items),
    }
    Component.init(self, ui.create(layout))
end

---@param id string
---@param asc boolean?
function ColumnSorter:toggleColumn(id, asc)
    if self:isDestroyed() then return end

    local cfg = self:getColumnConfig(id)
    if cfg == nil then return end

    if asc == nil then
        if self.activeColumn == id then
            asc = not self.ascending
        else
            asc = true
        end
    end

    local previous = self:getColumnConfig(self.activeColumn)
    if previous then
        local col = M.findColumn(self.element, previous.id)
        local props = col.layout.content['icon'].props
        if not previous.name and not previous.inactive then
            props.resource = SORT_DEFAULT
        else
            props.visible = false
            props.size = v2(0, 0)
        end
        I.UIToolkit.queueUpdate(col)
    end

    if id then
        local col = M.findColumn(self.element, id)
        local props = col.layout.content['icon'].props
        props.resource = asc and SORT_ASC or SORT_DESC
        props.visible = true
        props.size = v2(ICON_SZ, ICON_SZ)
    end

    self.activeColumn = id
    self.ascending = asc

    if self.onChanged then
        self.onChanged(id, asc)
    end
end

---@param id string?
---@return UIToolkit.ColumnSorter.Column?
function ColumnSorter:getColumnConfig(id)
    if not id then return nil end
    ---@type UIToolkit.ColumnSorter.Column
    local cfg
    for i = 1, #self.columns do
        cfg = self.columns[i]
        if cfg.id == id then return cfg end
    end
    return nil
end

function ColumnSorter:getActiveColumn()
    return self.activeColumn, self.ascending == true
end

---@param self UIToolkit.ColumnSorter
---@param cfg UIToolkit.ColumnSorter.Column
---@return openmw.ui.Layout|openmw.ui.Element
function M.renderItem(self, cfg)
    local width = cfg.width or 0
    local auto = (width == 0 and (cfg.auto or 1)) or nil
    local name = cfg.name
    local t = I.UIToolkit.getTheme()

    local content = ui.content {}

    if name then
        content:add {
            name = 'text',
            template = I.UIToolkit.Templates.text(),
            props = {
                text = name,
                autoSize = true,
                textAlignV = ui.ALIGNMENT.Center,
            },
            userData = {
                colorable = true,
                baseColor = t.Colors.HEADER,
                hoverColor = t.Colors.ACTIVE_LIGHT,
                pressColor = t.Colors.ACTIVE_PRESSED,
            },
        }
    end

    if name or not cfg.inactive then
        content:add {
            name = 'icon',
            type = ui.TYPE.Image,
            props = {
                resource = SORT_DEFAULT,
                color = t.Colors.DEFAULT,
                visible = name == nil,
                size = v2(name == nil and ICON_SZ or 0, ICON_SZ),
            },
            userData = { colorable = true },
        }
    end

    local layout = {
        name = cfg.id,
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
            autoSize = false,
            size = v2(width, 0),
            relativeSize = v2(0, 1),
            arrange = ui.ALIGNMENT.Center,
            align = cfg.align,
        },
        external = { grow = auto },
        content = content,
    }
    if cfg.inactive then return layout end

    return I.UIToolkit.Interactive.makeInteractive({
        onClick = function() self:toggleColumn(cfg.id) end,
    }, layout)
end

---@param element openmw.ui.Element
---@param id string
---@return openmw.ui.Element
function M.findColumn(element, id)
    ---@type openmw.ui.Content
    local content = element.layout.content
    for i = 1, #content do
        ---@type openmw.ui.Element
        local child = content[i]
        if child.layout and child.layout.name == id then return child end
    end
    error("Couldn't find column " .. id)
end

return ColumnSorter
