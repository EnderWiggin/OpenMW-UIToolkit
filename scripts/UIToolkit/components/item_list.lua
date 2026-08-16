---@omw-context player

local ui = require('openmw.ui')
local util = require('openmw.util')
local async = require('openmw.async')
local omwConstants = require('scripts.omw.mwui.constants')
local I = require('openmw.interfaces')

local v2 = util.vector2
local Class = require('scripts.UIToolkit.class')
local Component = require('scripts.UIToolkit.components.component')


local T = require('scripts.UIToolkit.templates.base')

---@class UIToolkit.ItemList : UIToolkit.Component
local ItemList = Class(Component)

---@param opts UIToolkit.ItemListOpts
function ItemList:init(opts)
    local size = opts.size


    local state = {
        sortedRows = {}, -- List of items after sorting
        ---@type UIToolkit.ListItem.Base
        provider = opts.provider,
        itemHeight = opts.itemHeight,
        --columns = columns,
        --columnWidths = {},
        currentSize = size,
        filters = {},
        --parentWindow = opts.parentWindow,
        --hadMouseMoveThisFrame = false,
        --rowCache = {} -- Stores generated row layouts by item ID or index
    }
    self.state = state
    ---@type openmw.ui.Element[]
    self._pool = {}

    ---@type openmw.ui.Element
    local scrollable = ui.create {
        name = 'scrollable',
        type = ui.TYPE.Widget,
        props = {
            position = v2(0, 0),
            size = v2(0, 0),
        },
    }

    local scroll = I.UIToolkit.Components.scrollBar {
        onScroll = function(position)
            scrollable.layout.props.position = v2(0, -position)
            I.UIToolkit.queueUpdate(self._scrollable)
        end,
        scrollStep = 2 * state.itemHeight,
        maxScroll = #state.sortedRows * state.itemHeight - size.y,
        length = size.y
    }
    local props = scroll.element.layout.props
    props.anchor = v2(1, 0)
    props.position = v2(size.x, 0)
    I.UIToolkit.queueUpdate(scroll.element)


    self._scrollable = scrollable
    self._scrollBar = scroll


    local width = self:getContentWidth()

    ---@type openmw.ui.Layout
    local layout = {
        --TODO: use customized template
        template = I.MWUI.templates.boxSolid, --TODO: option to have no border
        props = {},
        content = ui.content {
            {
                name = 'content',
                props = { size = v2(width, size.y) },
                content = ui.content { scrollable }
            },
            scroll.element,
        },
    }
    Component.init(self, ui.create(layout))
end

function ItemList:getContentWidth()
    return math.floor(math.max(0, self.state.currentSize.x - self._scrollBar:getSize().x))
end

---@param old openmw.ui.Element?
---@param pos openmw.util.Vector2
---@param sz openmw.util.Vector2
---@param view openmw.ui.Element
---@return openmw.ui.Element
function ItemList:_getPlaceholder(old, pos, sz, view)
    if not old or not old.layout then
        while #self._pool > 0 do
            old = table.remove(self._pool)
            if old and old.layout then break end
        end
    end
    if old and old.layout then
        old.layout.props.size = sz
        old.layout.props.position = pos
        old.layout.content = ui.content { view }
        I.UIToolkit.queueUpdate(old)
        return old
    end
    return ui.create {
        props = {
            size = sz,
            position = pos,
        },
        content = ui.content { view },
    }
end

---@param old openmw.ui.Element
function ItemList:_returnPlaceholder(old)
    if not old.layout then return end
    old.layout.content = nil
    if #self._pool > 10 then
        I.UIToolkit.queueDestroy(old, false)
        return
    end
    table.insert(self._pool, old)
end

function ItemList:_updateView()
    local state = self.state
    local width = self:getContentWidth()
    local sz = v2(width, state.itemHeight)
    local items = {}
    local layout = self._scrollable.layout
    local old = layout.content or {}
    local p = 0
    for i = 1, #state.sortedRows do
        local item = state.sortedRows[i]
        local view = state.provider:getView(item, sz)
        --TODO: reuse old widgets?
        items[#items + 1] = self:_getPlaceholder(old[i], v2(0, p), sz, view)
        p = p + state.itemHeight
    end
    for i = #items + 1, #old do
        self:_returnPlaceholder(old[i])
    end
    layout.props.size = v2(width, #items * state.itemHeight)
    layout.content = ui.content(items)
    --TODO: destroy unused old widgets?
    I.UIToolkit.queueUpdate(self._scrollable)
end

---@param items UIToolkit.ListData.Base[]
function ItemList:setItems(items)
    local state = self.state
    state.sortedRows = items
    self._scrollBar:setMaxScroll(#state.sortedRows * state.itemHeight - state.currentSize.y)
    self:_updateView()
end

---@param size openmw.util.Vector2
function ItemList:setSize(size)
    local state = self.state
    state.currentSize = size
    local width = self:getContentWidth()
    local scroll = self._scrollBar
    scroll.element.layout.props.position = v2(size.x, 0)
    scroll:setLength(size.y)
    scroll:setMaxScroll(#state.sortedRows * state.itemHeight - size.y)
    self.element.layout.content[1].props.size = v2(width, size.y)

    I.UIToolkit.queueUpdate(self.element)
    self:_updateView()
end

return ItemList
