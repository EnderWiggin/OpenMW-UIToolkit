---@omw-context player

local ui = require('openmw.ui')
local util = require('openmw.util')

local v2 = util.vector2

local I = require('openmw.interfaces')

local Class = require('scripts.UIToolkit.class')
local Component = require('scripts.UIToolkit.components.component')
local ColumnItemProvider = require('scripts.UIToolkit.components.list_items.column_item')

---@class UIToolkit.SortedList : UIToolkit.Component
---@field new fun(self:UIToolkit.SortedList):UIToolkit.SortedList
local SortedList = Class(Component)

---@param opts UIToolkit.SortedListOpts
function SortedList:init(opts)
    self.size = opts.size
    self.defaultSort = opts.defaultSort
    ---@type UIToolkit.ColumnComparator[]
    self.comparators = {}

    local theme = I.UIToolkit.getTheme()
    local rowHeight = opts.rowHeight or util.round(1.5 * (theme.Sizes.textNormal + 2))

    self.provider = ColumnItemProvider:new()

    ---@type UIToolkit.ListData.ColumnConfig[]
    local providerColumns = {}
    ---@type UIToolkit.ColumnSorter.Column[]
    local headerColumns = {}

    for i = 1, #opts.columns do
        local cfg = opts.columns[i]

        providerColumns[#providerColumns + 1] = {
            id = cfg.id,
            width = cfg.width,
            auto = cfg.auto,
            render = cfg.render,
            arg = cfg.arg,
        }

        headerColumns[#headerColumns + 1] = {
            id = cfg.id,
            name = cfg.name,
            width = cfg.width,
            auto = cfg.auto,
            align = cfg.align,
            inactive = not cfg.sort,
        }

        self.comparators[cfg.id] = cfg.sort
    end

    self.provider:init(providerColumns, rowHeight)

    self.list = I.UIToolkit.Components.itemList {
        size = self:getListSize(),
        provider = self.provider,
        onItemClicked = opts.onItemClicked,
    }

    self.header = I.UIToolkit.Components.columnSorter {
        columns = headerColumns,
        onChanged = function() self:sortItems() end,
    }

    self.header:updateProps {
        position = v2(theme.Sizes.border + theme.Sizes.padding, 0),
    }

    self.list:updateProps { position = v2(0, rowHeight) }

    Component.init(self, ui.create {
        props = {
            size = opts.size,
        },
        content = ui.content {
            self.header.element,
            self.list.element,
        }
    })

    self:setSize(opts.size)
end

---@param items? UIToolkit.ListData.Column[]
function SortedList:sortItems(items)
    items = items or self.list:getItems() --[[@as UIToolkit.ListData.Column[] ]]
    local col, asc = self.header:getActiveColumn()
    local comparator = col and self.comparators[col]
    table.sort(items, function(a, b)
        local result = 0

        if comparator then result = comparator(a, b) end

        if result == 0 and self.defaultSort then result = self.defaultSort(a, b) end

        if result ~= 0 then
            if not asc then result = -result end
            return result < 0
        end
        return a.id < b.id
    end)
    self.list:setItems(items)
end

---@param items UIToolkit.ListData.Column[]
function SortedList:setItems(items)
    self:sortItems(items)
end

---@param size openmw.util.Vector2
function SortedList:setSize(size)
    self.size = size

    self.list:setSize(self:getListSize())

    self.header:updateProps { size = self:getHeaderSize() }
    I.UIToolkit.queueUpdate(self.header.element)

    self:updateProps { size = size }
    I.UIToolkit.queueUpdate(self.element)
end

---@return openmw.util.Vector2
function SortedList:getListSize()
    return self.size - v2(0, self.provider.rowHeight)
end

---@return openmw.util.Vector2
function SortedList:getHeaderSize()
    return v2(self.list:getContentWidth(), self.provider.rowHeight)
end

return SortedList
