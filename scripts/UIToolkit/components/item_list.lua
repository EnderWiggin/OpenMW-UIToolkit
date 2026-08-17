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
        ---@type UIToolkit.ListData.Base[]
        items = {},
        ---@type table<string, UIToolkit.ListData.Base>
        itemsById = {},
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
        partialView = true,
        ---@type integer|nil
        hovered = nil,
    }
    self.state = state
    ---@type openmw.ui.Element[]
    self._pool = {}
    ---@type table<integer, {id:string, element:openmw.ui.Element}>
    self._holders = {}

    local function getIndexByYPos(y) return math.floor(y / state.itemHeight) + 1 end

    ---@type openmw.ui.Element
    local scrollable = ui.create {
        name = 'scrollable',
        type = ui.TYPE.Widget,
        props = {
            position = v2(0, 0),
            size = v2(0, 0),
        },
        events = {
            ---@param e openmw.ui.MouseEvent
            mouseMove = async:callback(function(e)
                I.UIToolkit.getCtx().lastMousePos = e.position
                self:setHovered(getIndexByYPos(e.offset.y))
            end),
            focusLoss = async:callback(function() self:setHovered(nil) end),
        },
    }

    local scroll = I.UIToolkit.Components.scrollBar {
        onScroll = function(position)
            scrollable.layout.props.position = v2(0, -position)
            if self.state.partialView then
                self:_updateView()
            else
                I.UIToolkit.queueUpdate(self._scrollable)
            end
        end,
        scrollStep = 2 * state.itemHeight,
        maxScroll = #state.items * state.itemHeight - size.y,
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

---@param n integer
---@param id string
---@param view openmw.ui.Element
---@param changed boolean
---@param sz openmw.util.Vector2
---@return openmw.ui.Element
function ItemList:_getHolder(n, id, view, changed, sz)
    local state = self.state
    local holder = self._holders[n]
    if holder and holder.element and holder.element.layout then
        if holder.id == id and not changed then
            return holder.element
        end
        holder.id = id
        local layout = holder.element.layout
        layout.props.size = sz
        layout.content = ui.content { view }
        I.UIToolkit.queueUpdate(holder.element)
        return holder.element
    end
    local element = ui.create {
        props = {
            size = sz,
            position = v2(0, (n - 1) * state.itemHeight),
        },
        content = ui.content { view },
    }
    self._holders[n] = { id = id, element = element }
    return element
end

---@return integer, integer
function ItemList:_getVisibleItemRange()
    local state = self.state
    local total = #state.items
    if not state.partialView then return 1, total end
    if total == 0 then return 1, 0 end
    local scroll = self._scrollBar:getPosition()
    local from = math.max(math.floor(scroll / state.itemHeight) - 1, 1)
    if from > total then return 1, 0 end
    local to = math.min(math.ceil((scroll + state.currentSize.y) / state.itemHeight) + 1, total)

    return from, to
end

function ItemList:_updateView()
    local state = self.state
    local width = self:getContentWidth()
    local sz = v2(width, state.itemHeight)
    local items = {}
    local layout = self._scrollable.layout
    local from, to = self:_getVisibleItemRange()
    for i = from, to do
        local item = state.items[i]
        local view, changed = state.provider:getView(item, sz)
        items[#items + 1] = self:_getHolder(i, item.id, view, changed, sz)
    end
    layout.props.size = v2(width, #state.items * state.itemHeight)
    layout.content = ui.content(items)
    I.UIToolkit.queueUpdate(self._scrollable)
end

---@param items UIToolkit.ListData.Base[]
function ItemList:setItems(items)
    local state = self.state
    state.items = items
    state.itemsById = {}
    self._scrollBar:setMaxScroll(#state.items * state.itemHeight - state.currentSize.y)
    self:_updateView()
end

---@param provider UIToolkit.ListItem.Base
---@param id string|nil
---@param hovered boolean
local function setItemHoveredStatus(provider, id, hovered)
    if not id then return end
    local view = provider:getCachedView(id)
    if not view then return end
    I.UIToolkit.Interactive.updateState(view, { hovering = hovered })
    I.UIToolkit.queueUpdate(view)
end

---@param idOrIndex string|integer|nil
function ItemList:setHovered(idOrIndex)
    local state = self.state
    ---@type string?
    local id
    ---@type number?
    local index
    local item
    if type(idOrIndex) == "number" then
        item = state.items[idOrIndex]
        id = item and item.id or nil
        index = idOrIndex
    elseif idOrIndex ~= nil then
        id = idOrIndex --[[@as string]]
        item, index = self:getItemById(id)
    end

    if index == state.hovered then return end

    if state.hovered then
        local was = state.items[state.hovered]
        setItemHoveredStatus(state.provider, was and was.id, false)
    end
    setItemHoveredStatus(state.provider, id, true)

    if item then
        local tip = state.provider:getTooltip(item)
        I.UTKTooltips.setTooltip(tip)
    else
        I.UTKTooltips.setTooltip(nil)
    end

    state.hovered = idOrIndex
end

---@param id string
---@return UIToolkit.ListData.Base?, integer?
function ItemList:getItemById(id)
    local state = self.state
    local item = state.itemsById[id]
    if item then return item end
    for i = 1, #state.items do
        item = state.items[i]
        if item and item.id == id then return item, i end
    end
    return nil
end

---@param size openmw.util.Vector2
function ItemList:setSize(size)
    local state = self.state
    size = v2(util.round(size.x), util.round(size.y))
    if size == state.currentSize then return end
    state.currentSize = size
    local width = self:getContentWidth()
    local scroll = self._scrollBar
    scroll.element.layout.props.position = v2(size.x, 0)
    scroll:setLength(size.y)
    scroll:setMaxScroll(#state.items * state.itemHeight - size.y)
    self.element.layout.content[1].props.size = v2(width, size.y)

    I.UIToolkit.queueUpdate(self.element)
    self:_updateView()
end

return ItemList
