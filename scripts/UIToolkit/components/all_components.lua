---@omw-context player

local Buttons = require('scripts.UIToolkit.components.buttons')
local TextEdit = require('scripts.UIToolkit.components.text_edit')
local ScrollBar = require('scripts.UIToolkit.components.scroll_bar')
local ItemList = require('scripts.UIToolkit.components.item_list')
local ColumnSorter = require('scripts.UIToolkit.components.column_sorter')
local SortedList = require('scripts.UIToolkit.components.list_with_sorter_columns')
local Dropbox = require('scripts.UIToolkit.components.dropbox')
local Checkbox = require('scripts.UIToolkit.components.checkbox')

local M = {}

M.textButton = Buttons.textButton

---@param opts UIToolkit.CheckboxOpts
---@return UIToolkit.Checkbox
function M.checkbox(opts)
    local checkbox = Checkbox:new()
    checkbox:init(opts)
    return checkbox
end

---@param opts UIToolkit.TextEditOpts
---@return UIToolkit.TextEdit
M.textEdit = function(opts)
    local edit = TextEdit:new()
    edit:init(opts)
    return edit
end

---@param opts UIToolkit.DropboxOpts
---@return UIToolkit.Dropbox
function M.dropbox(opts)
    local dropbox = Dropbox:new()
    dropbox:init(opts)
    return dropbox
end

---@param opts UIToolkit.ScrollBarOpts
---@return UIToolkit.ScrollBar
M.scrollBar = function(opts)
    local scroll = ScrollBar:new()
    scroll:init(opts)
    return scroll
end

---@param opts UIToolkit.ItemListOpts
---@return UIToolkit.ItemList
M.itemList = function(opts)
    local list = ItemList:new()
    list:init(opts)
    return list
end

---@param opts UIToolkit.ColumnSorterOpts
---@return UIToolkit.ColumnSorter
function M.columnSorter(opts)
    local sorter = ColumnSorter:new()
    sorter:init(opts)
    return sorter
end

---@param opts UIToolkit.SortedListOpts
---@return UIToolkit.SortedList
function M.sortedList(opts)
    local sorted = SortedList:new()
    sorted:init(opts)
    return sorted
end

---@cast M UIToolkit.Components
return M
