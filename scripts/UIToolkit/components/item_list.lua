---@omw-context player

local ui = require('openmw.ui')
local util = require('openmw.util')
local async = require('openmw.async')
local ambient = require('openmw.ambient')
local I = require('openmw.interfaces')

local v2 = util.vector2
local Class = require('scripts.UIToolkit.class')
local Component = require('scripts.UIToolkit.components.component')
local Scrollable = require('scripts.UIToolkit.components.scrollable')


---@generic T : UIToolkit.ListItem.Base
---@class UIToolkit.ItemList : UIToolkit.Scrollable
local ItemList = Class(Scrollable)

---@param opts UIToolkit.ItemListOpts
function ItemList:init(opts)
    local t = I.UIToolkit.getTheme()
    local size = opts.size
    local onClicked = opts.onItemClicked
    ---@type UIToolkit.ListItem.Base
    local provider = opts.provider
    local state = {
        ---@type UIToolkit.ListData.Base[]
        items = {},
        ---@type table<string, UIToolkit.ListData.Base>
        itemsById = {},
        ---@type UIToolkit.ListItem.Base
        provider = provider,
        itemHeight = provider:getItemHeight(),
        currentSize = size,
        filters = {},
        --parentWindow = opts.parentWindow,
        --hadMouseMoveThisFrame = false,
        ---@type integer|nil
        hovered = nil,
        ---@type openmw.util.Vector2|nil
        lastHoveredPos = nil,
    }
    self.state = state
    ---@type openmw.ui.Element[]
    self._pool = {}
    ---@type table<integer, {id:string, element:openmw.ui.Element}>
    self._holders = {}

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
            mousePress = async:callback(function(e)
                if onClicked then
                    local idx = self:getIndexByYPos(e.offset.y)
                    local item = self.state.items[idx]
                    if item then ambient.playSound('menu click', { scale = false }) end
                    self.state.lastHoveredPos = e.offset.y - self._scrollBar:getPosition()
                end
            end),
            mouseRelease = async:callback(function(e)
                if onClicked then
                    local idx = self:getIndexByYPos(e.offset.y)
                    local item = self.state.items[idx]
                    if item then onClicked(item, idx) end
                    self.state.lastHoveredPos = e.offset.y - self._scrollBar:getPosition()
                end
            end),
            ---@param e openmw.ui.MouseEvent
            mouseMove = async:callback(function(e)
                I.UIToolkit.getCtx().lastMousePos = e.position
                self.state.lastHoveredPos = e.offset.y - self._scrollBar:getPosition()
                self:setHovered(self:getIndexByYPos(e.offset.y))
            end),
            focusLoss = async:callback(function()
                self:setHovered(nil)
                self.state.lastHoveredPos = nil
                return true
            end),
        },
    }

    local scroll = I.UIToolkit.Components.scrollBar {
        onScroll = function(position)
            scrollable.layout.props.position = v2(0, -position)
            self:_updateScrollable()
        end,
        scrollStep = 2 * state.itemHeight,
        maxScroll = #state.items * state.itemHeight - size.y,
        length = size.y
    }
    scroll:updateProps {
        anchor = v2(1, 0),
        relativePosition = v2(1, 0)
    }
    I.UIToolkit.queueUpdate(scroll.element)


    self._scrollable = scrollable
    self._scrollBar = scroll


    local width = self:getContentWidth()

    ---@type openmw.ui.Layout
    local layout = {
        template = I.UIToolkit.Templates.border { padding = t.Sizes.padding },
        props = {
            size = size,
        },
        content = ui.content {
            {
                name = 'content',
                props = { size = v2(width, size.y) },
                content = ui.content { scrollable }
            },
            scroll.element,
        },
        events = {
            focusGain = async:callback(function() I.UIToolkit.getCtx().focusedScrollable = self end),
            focusLoss = async:callback(function() I.UIToolkit.getCtx().focusedScrollable = nil end),
        },
    }
    Component.init(self, ui.create(layout))
end

---@param delta number
function ItemList:onMouseScrolled(delta)
    self._scrollBar:scroll(-delta)
    self:updateHoveredItem()
end

function ItemList:getContentWidth()
    local s = I.UIToolkit.getTheme().Sizes
    return math.floor(math.max(0, self.state.currentSize.x - self._scrollBar:getSize().x - 3 * s.padding - 2 * s.border))
end

---@param n integer
---@param id string
---@param view openmw.ui.Element
---@return openmw.ui.Element
function ItemList:_getHolder(n, id, view)
    local state = self.state
    local holder = self._holders[n]
    local element = holder and holder.element
    local layout = element and element.layout
    if layout then
        holder.id = id
        if layout.content[1] ~= view then
            layout.content = ui.content { view }
            I.UIToolkit.queueUpdate(holder.element)
        end
        return holder.element
    end
    element = ui.create {
        props = {
            position = v2(0, (n - 1) * state.itemHeight),
            size = v2(0, state.itemHeight),
            relativeSize = v2(1, 0),
        },
        content = ui.content { view },
    }
    self._holders[n] = { id = id, element = element }
    return element
end

---@return integer, integer
function ItemList:getVisibleItemRange()
    local state = self.state
    local total = #state.items
    if total == 0 then return 1, 0 end
    local scroll = self._scrollBar:getPosition()
    local from = math.max(math.floor(scroll / state.itemHeight) - 1, 1)
    if from > total then return 1, 0 end
    local to = math.min(math.ceil((scroll + state.currentSize.y) / state.itemHeight) + 1, total)

    return from, to
end

function ItemList:_updateScrollable()
    local state = self.state
    local width = self:getContentWidth()
    local sz = v2(width, state.itemHeight)
    local items = {}
    local layout = self._scrollable.layout
    local from, to = self:getVisibleItemRange()
    for i = from, to do
        local item = state.items[i]
        local view = state.provider:getView(item, sz)
        items[#items + 1] = self:_getHolder(i, item.id, view)
    end
    layout.props.size = v2(width, #state.items * state.itemHeight)
    layout.content = ui.content(items)
    I.UIToolkit.queueUpdate(self._scrollable)
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

---@return UIToolkit.ListData.Base[]
function ItemList:getItems()
    return self.state.items
end

---@param items UIToolkit.ListData.Base[]
function ItemList:setItems(items)
    local state = self.state
    if state.hovered then --cleanup previously hovered item - it might be gone in new list
        local was = state.items[state.hovered]
        setItemHoveredStatus(state.provider, was and was.id, false)
        state.hovered = nil
    end
    state.items = items
    state.itemsById = {}
    self._scrollBar:setMaxScroll(#state.items * state.itemHeight - state.currentSize.y)
    I.UIToolkit.queueUpdate(self._scrollBar.element)
    self:_updateScrollable()
    self:updateHoveredItem()
end

---@param y number
function ItemList:getIndexByYPos(y) return math.floor(y / self.state.itemHeight) + 1 end

function ItemList:updateHoveredItem()
    local p = self.state.lastHoveredPos
    if not p then return end
    self:setHovered(self:getIndexByYPos(p + self._scrollBar:getPosition()))
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
        I.UTKTooltips.setTooltip(tip, function() return not self:isDestroyed() end)
    else
        I.UTKTooltips.setTooltip(nil)
    end

    state.hovered = idOrIndex
end

---@return number
function ItemList:getPosition()
    return self._scrollBar:getPosition()
end

---@param position number
function ItemList:setPosition(position)
    self._scrollBar:setPosition(position)
end

---@return number
function ItemList:getProgress()
    return self._scrollBar:getProgress()
end

---@param progress number
function ItemList:setProgress(progress)
    self._scrollBar:setProgress(progress)
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
    local s = I.UIToolkit.getTheme().Sizes
    local state = self.state
    size = v2(util.round(size.x), util.round(size.y))
    if size == state.currentSize then return end
    state.currentSize = size
    local width = self:getContentWidth()
    local scroll = self._scrollBar
    scroll:setLength(size.y - 2 * (s.border + s.padding))
    scroll:setMaxScroll(#state.items * state.itemHeight - size.y)
    I.UIToolkit.queueUpdate(scroll.element)

    self:updateProps { size = size }
    self.element.layout.content[1].props.size = v2(width, size.y)

    I.UIToolkit.queueUpdate(self.element)
    self:_updateScrollable()
end

return ItemList
