---@omw-context player

local input         = require 'openmw.input'
local types         = require 'openmw.types'
local player        = require 'openmw.self'
local ui            = require 'openmw.ui'
local util          = require 'openmw.util'

local I             = require 'openmw.interfaces'
local H             = require 'scripts.UIToolkit.helpers'

local Class         = require 'scripts.UIToolkit.class'
local WindowHandler = require 'scripts.UIToolkit.window_handler'
local ColumnItem    = require 'scripts.UIToolkit.components.list_items.column_item'

local v2            = util.vector2
local WND_NAME      = 'uitoolkit-demo'


local textSize  = I.UIToolkit.getTheme().Sizes.textNormal
local rowHeight = 1.5 * (textSize + 2)

---@type UIToolkit.SortedList?
local list
---@type UIToolkit.SortedList.Column[]
local columns   = {
    { id = 'icon',   name = nil,    sort = { col = 'id' },     render = ColumnItem.renderIcon, width = rowHeight + 5,   arg = { sz = 1.5 * textSize } },
    { id = 'name',   name = 'Name', sort = {},                 render = ColumnItem.renderText, },
    { id = 'weight', name = 'Wgt.', sort = { numeric = true }, render = ColumnItem.renderText, width = 2 * rowHeight,   arg = { textAlignH = ui.ALIGNMENT.End }, align = ui.ALIGNMENT.End },
    { id = 'value',  name = 'Val.', sort = { numeric = true }, render = ColumnItem.renderText, width = 2.7 * rowHeight, arg = { textAlignH = ui.ALIGNMENT.End }, align = ui.ALIGNMENT.End },
    { id = 'V/W',    name = 'V/W',  sort = { numeric = true }, render = ColumnItem.renderText, width = 2.7 * rowHeight, arg = { textAlignH = ui.ALIGNMENT.End }, align = ui.ALIGNMENT.End },
}

---@class Handler: UIToolkit.WindowHandler
local Handler   = Class(WindowHandler)

---@param wnd UIToolkit.Window
function Handler:onOpened(wnd)
    local theme = I.UIToolkit.getTheme()
    I.UI.setMode(I.UI.MODE.Interface, { windows = {} })
    list = I.UIToolkit.Components.sortedList {
        size = v2(200, 300),
        onItemClicked = function(data)
            if not list then return end
            local cached = list.provider:getCachedComponent(data.id)
            if not cached then return end
            cached:setActive(not cached:isActive())
        end,
        columns = columns,
    }
    list.header:toggleColumn('icon')

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
            name = function()
                return item.count > 1
                    and record.name .. ' (' .. H.addSeparators(item.count) .. ')'
                    or record.name
            end,
            weight = record.weight > 0 and record.weight or '-',
            value = record.value > 0 and record.value or '-',
            ['V/W'] = record.value > 0 and record.weight > 0 and util.round(record.value / record.weight) or '-',
            tooltip = { object = item, observer = player }
        }
    end
    list:setItems(rows)
    wnd:setContent(ui.content {
        list.element,
        {
            template = I.UIToolkit.Templates.border {padding = 5},
            props = {
                size = v2(130, -10),
                position = v2(-5, 5),
                relativeSize = v2(0, 1),
                anchor = v2(1, 0),
                relativePosition = v2(1, 0),
            },
            content = ui.content {
                {
                    type = ui.TYPE.Flex,
                    props = {},
                    content = ui.content {
                        {
                            template = I.UIToolkit.Templates.text(),
                            props = {text = "Examples:"},
                        },
                        I.UIToolkit.Templates.intervalV(15),
                        {
                            type = ui.TYPE.Flex,
                            props = {
                                horizontal = true,
                            },
                            content = ui.content {
                                {
                                    template = I.UIToolkit.Templates.box { padding = v2(10, 5), background = { color = theme.Colors.DAMAGED, opacity = 'transparent' } },
                                    props = {},
                                    content = ui.content {
                                        {
                                            type = ui.TYPE.Image,
                                            props = {
                                                resource = theme.Colors.whiteTexture,
                                                color = theme.Colors.ACTIVE_LIGHT,
                                                size = v2(10, 10),
                                            },
                                        }
                                    },
                                },
                                I.UIToolkit.Templates.intervalH(5),
                                {
                                    template = I.UIToolkit.Templates.box { padding = 5, background = { color = theme.Colors.MAGICK, opacity = 'transparent' } },
                                    props = {},
                                    content = ui.content {
                                        {
                                            type = ui.TYPE.Image,
                                            props = {
                                                resource = theme.Colors.whiteTexture,
                                                color = theme.Colors.DISABLED_LIGHT,
                                                size = v2(10, 10),
                                            },
                                        }
                                    },
                                },
                            },
                        },
                        I.UIToolkit.Templates.intervalV(5),
                        I.UIToolkit.Components.textButton { text = 'Auto Sized' }.element,
                        I.UIToolkit.Templates.intervalV(5),
                        I.UIToolkit.Components.textButton { text = 'Width=110', width = 110 }.element,
                        I.UIToolkit.Templates.intervalV(5),
                        I.UIToolkit.Components.textButton { text = 'Disabled' }:setDisabled(true).element,
                        I.UIToolkit.Templates.intervalV(5),
                        I.UIToolkit.Components.textButton { text = 'Active' }:setActive(true).element,
                        I.UIToolkit.Templates.intervalV(5),
                        I.UIToolkit.Components.textButton { text = 'Thin', style = 'thin' }.element,
                        I.UIToolkit.Templates.intervalV(5),
                        I.UIToolkit.Components.textButton { text = 'Thick', style = 'thick' }.element,
                        I.UIToolkit.Templates.intervalV(5),
                        I.UIToolkit.Components.textButton { text = 'Colored', background = { opacity = 0.5, color = theme.Colors.FATIGUE } }.element,
                    }
                }
            },
        }
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
        list:setSize(inner - v2(140, 0))
    end
end

I.UIToolkit.WindowManager.register(WND_NAME, {
    title = 'UI Toolkit Demo',
    handler = Handler,
    draggable = true,
    resizing = true,
    position = v2(300, 300),
    minSize = v2(500, 350),
})


---@param key openmw.input.KeyboardEvent
local function onKeyRelease(key)
    if key.code ~= input.KEY.ScrollLock then return end

    if I.UIToolkit.WindowManager.isOpen(WND_NAME) then
        I.UIToolkit.WindowManager.close(WND_NAME)
    else
        I.UIToolkit.WindowManager.open(WND_NAME)
    end
end

return {
    engineHandlers = {
        onKeyRelease = onKeyRelease
    },
}
