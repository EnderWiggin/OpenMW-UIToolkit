---@omw-context player

local input      = require 'openmw.input'
local types      = require 'openmw.types'
local player     = require 'openmw.self'
local ui         = require 'openmw.ui'
local util       = require 'openmw.util'

local I          = require 'openmw.interfaces'
local H          = require 'scripts.UIToolkit.helpers'

local ColumnItem = require 'scripts.UIToolkit.components.list_items.column_item'

local v2         = util.vector2
local WND_NAME   = 'uitoolkit-demo'
local isOpen     = false

---@class Handler: UIToolkit.WindowHandler
local Handler    = {}

local textSize   = I.MWUI.templates.textNormal.props.textSize
local rowHeight  = 1.5 * (textSize + 2)
---@type UIToolkit.ItemList?
local list
local provider   = ColumnItem:new()
provider:init({
    { id = 'icon',   render = ColumnItem.renderIcon, arg = { sz = 1.5 * textSize },           width = rowHeight + 5 },
    { id = 'name',   render = ColumnItem.renderText, },
    { id = 'weight', render = ColumnItem.renderText, arg = { textAlignH = ui.ALIGNMENT.End }, width = 1.5 * rowHeight },
    { id = 'value',  render = ColumnItem.renderText, arg = { textAlignH = ui.ALIGNMENT.End }, width = 2 * rowHeight },
    { id = 'V/W',    render = ColumnItem.renderText, arg = { textAlignH = ui.ALIGNMENT.End }, width = 2 * rowHeight },
}, rowHeight)


---@param wnd UIToolkit.Window
function Handler:onOpened(wnd)
    I.UI.setMode(I.UI.MODE.Interface, { windows = {} })
    list = I.UIToolkit.Components.itemList {
        provider = provider,
        size = v2(200, 300),
        onItemClicked = function(data, idx)

        end
    }
    ---@type UIToolkit.ListData.Column[]
    local rows = {}
    local items = types.Actor.inventory(player):getAll()
    for i = 1, #items do
        ---@type openmw.Object
        local item = items[i]
        local record = item.type.records[item.recordId]
        rows[#rows + 1] = {
            id = item.id,
            icon = record.icon,
            name = record.name .. (item.count > 1 and ' (' .. H.addSeparators(item.count) .. ")" or ''),
            weight = record.weight,
            value = record.value,
            ['V/W'] = function() return record.weight > 0 and record.value / record.weight or '--' end,
            tooltip = { object = item, observer = player }
        }
    end
    list:setItems(rows)
    wnd:setContent(ui.content {
        list.element
    })

    Handler:onResized(wnd:getInnerSize())
end

function Handler:onClosed()
    I.UI.setMode()
    list = nil
end

---@param inner openmw.util.Vector2
function Handler:onResized(inner)
    if list then
        list:setSize(inner)
    end
end

I.UIToolkit.WindowManager.register(WND_NAME, {
    title = 'UI Toolkit Demo',
    handler = Handler,
    draggable = true,
    resizing = true,
    position = v2(300, 300),
    minSize = v2(300, 300),
})


---@param key openmw.input.KeyboardEvent
local function onKeyRelease(key)
    if key.code ~= input.KEY.Backspace then return end

    isOpen = not isOpen
    if isOpen then
        I.UIToolkit.WindowManager.open(WND_NAME)
    else
        I.UIToolkit.WindowManager.close(WND_NAME)
    end
end

return {
    engineHandlers = {
        onKeyRelease = onKeyRelease
    },
}
