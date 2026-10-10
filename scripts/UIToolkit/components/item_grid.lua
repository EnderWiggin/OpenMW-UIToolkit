---@omw-context player|menu

local ui = require('openmw.ui')
local util = require('openmw.util')
local async = require('openmw.async')
local ambient = require('openmw.ambient')
local async = require('openmw.async')
local I = require('openmw.interfaces')

local v2 = util.vector2
local H = require('scripts.UIToolkit.helpers')
local Class = require('scripts.UIToolkit.class')
local Component = require('scripts.UIToolkit.components.component')
local Scrollable = require('scripts.UIToolkit.components.scrollable')


---@generic T : UIToolkit.GridItem.Base
---@class UIToolkit.ItemGrid : UIToolkit.Scrollable
local ItemGrid = Class(Scrollable)

---@param opts UIToolkit.ItemGridOpts
function ItemGrid:init(opts)
    local t = I.UIToolkit.getTheme()
    local size = opts.size
    local onClicked = opts.onItemClicked
    local onRClicked = opts.onItemRClicked
    local onAnyClicked = opts.onItemClickedAny
    local onListClicked = opts.onListClicked
    ---@type UIToolkit.GridItem.Base
    local provider = opts.provider
    local state = {
        horizontal = opts.horizontal == true,
        ---@type UIToolkit.ListData.Base[]
        items = {},
        ---@type UIToolkit.GridItem.Base
        provider = provider,
        itemSize = provider:getItemSize(),
        currentSize = size,
        filters = {},
        ---@type integer|nil
        hovered = nil,
        ---@type openmw.util.Vector2|nil
        lastHoveredPos = nil,
        highlightElement = provider:getHighlightView(),
        needHighlight = false,
    }
    self.itemDeepUpdate = opts.itemDeepUpdate == true
    self.state = state
    self.noBorder = opts.noBorder
    ---@type openmw.ui.Element[]
    self._pool = {}
    ---@type table<integer, {id:string, element:openmw.ui.Element}>
    self._holders = {}


    local mousePressed = {}
    local function getCallback(btn)
        if btn == 1 then return onClicked end
        if btn == 3 then return onRClicked end
        return nil
    end

    ---@param btn number
    ---@param offset openmw.util.Vector2
    local function processItemClick(btn, offset)
        local wasPressed = mousePressed[btn]
        mousePressed[btn] = nil
        if not wasPressed then return end

        local _size = self._scrollable.layout.props.size
        if offset.x < 0 or offset.y < 0 or offset.x >= _size.x or offset.y >= _size.y then return end

        local callback = getCallback(btn)
        if not callback and not onAnyClicked then return end

        local idx = self:getIndexByPos(offset)
        if idx ~= wasPressed then return end --released over another item
        local item = self.state.items[idx]
        if not item then return end

        if callback then callback(item, idx) end
        if onAnyClicked then onAnyClicked(item, idx, btn) end
    end

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
                local offset = e.offset
                self:_updateLastHoveredPos(offset)

                if not getCallback(e.button) and not onAnyClicked then return end

                local idx = self:getIndexByPos(offset)
                local item = self.state.items[idx]
                mousePressed[e.button] = item ~= nil and idx or nil
                if not item then return end
                ambient.playSound('menu click', { scale = false })
            end),
            mouseRelease = async:callback(function(e)
                local offset = e.offset
                self:_updateLastHoveredPos(offset)
                local btn = e.button

                processItemClick(btn, offset)
                if onListClicked then onListClicked(btn) end
            end),
            ---@param e openmw.ui.MouseEvent
            mouseMove = async:callback(function(e)
                I.UIToolkit.setCursorPos(e.position)
                local offset = e.offset
                self:_updateLastHoveredPos(offset)
                self:setHovered(self:getIndexByPos(offset))
                return true
            end),
            focusLoss = async:callback(function()
                self:setHovered(nil)
                state.lastHoveredPos = nil
                return true
            end),
        },
    }

    local scroll = I.UIToolkit.Components.scrollBar {
        onScroll = function(position)
            if state.horizontal then
                scrollable.layout.props.position = v2(-position, 0)
            else
                scrollable.layout.props.position = v2(0, -position)
            end
            self:_updateScrollable()
        end,
        horizontal = state.horizontal,
        width = opts.scrollWidth,
        slim = opts.slimScroll,
        scrollStep = 2 * (state.horizontal and state.itemSize.x or state.itemSize.y),
        maxScroll = 0,
        length = self:_getScrollLength()
    }
    if state.horizontal then
        scroll:updateProps {
            anchor = v2(0, 1),
            relativePosition = v2(0, 1)
        }
    else
        scroll:updateProps {
            anchor = v2(1, 0),
            relativePosition = v2(1, 0)
        }
    end
    I.UIToolkit.queueUpdate(scroll.element)


    self._scrollable = scrollable
    self._scrollBar = scroll
    scroll:setMaxScroll(self:_getMaxScroll())


    ---@type openmw.ui.Layout
    local layout = {
        template = not self.noBorder and I.UIToolkit.Templates.border { padding = t.Sizes.padding } or nil,
        props = {
            size = size,
        },
        content = ui.content {
            {
                name = 'content',
                props = { size = self:getContentSize() },
                content = ui.content { scrollable }
            },
            scroll.element,
        },
        events = {
            focusGain = async:callback(function() I.UIToolkit.getCtx().focusedScrollable = self end),
            focusLoss = async:callback(function() I.UIToolkit.getCtx().focusedScrollable = nil end),
            mouseRelease = async:callback(function(e) if onListClicked then onListClicked(e.button) end end),
            mouseMove = async:callback(function(e) I.UIToolkit.setCursorPos(e.position) end),
        },
    }
    Component.init(self, ui.create(layout))
end

function ItemGrid:beforeElementDestroy()
    self.state.provider:clear()
    local n = table.maxn(self._holders)
    for i = 1, n do
        local holder = self._holders[i]
        I.UIToolkit.queueDestroy(holder and holder.element, false)
    end
    self._holders = {}
end

---@param delta number
function ItemGrid:onMouseScrolled(delta)
    self._scrollBar:scroll(-delta)
    self:updateHoveredItem()
end

---@return openmw.util.Vector2
function ItemGrid:getContentSize()
    local s = I.UIToolkit.getTheme().Sizes
    local state = self.state
    if state.horizontal then
        local height = state.currentSize.y - self._scrollBar:getSize().y - s.standardGap
        if not self.noBorder then
            height = height - 2 * (s.padding + s.border)
        end
        return v2(state.currentSize.x, math.floor(math.max(0, height)))
    else
        local width = state.currentSize.x - self._scrollBar:getSize().x - s.standardGap
        if not self.noBorder then
            width = width - 2 * (s.padding + s.border)
        end
        return v2(math.floor(math.max(0, width)), state.currentSize.y)
    end
end

---@param n integer
---@param id string
---@param view openmw.ui.Element
---@return openmw.ui.Element, boolean
function ItemGrid:_getHolder(n, id, view, visible)
    local state = self.state
    local holder = self._holders[n]
    local element = holder and holder.element
    local layout = element and element.layout
    local viewUserData = H.userData(view)
    if layout then
        local props = layout.props
        holder.id = id
        local old = layout.content and layout.content[1]
        local pos = self:getPosByIndex(n)
        local needUpdate = pos ~= props.position or props.visible ~= visible
        if needUpdate then
            props.position = pos
            props.visible = visible
        end

        -- In some cases view might have been re-parented to another holder
        -- check its stored index to see if that's the case
        local viewIdx = viewUserData._index
        if visible and viewIdx ~= n or old ~= view then
            if viewIdx and viewIdx ~= n then
                --index is present and does not match current = remove this view from previous parent
                local parent = self._holders[viewIdx]
                parent = parent and parent.element
                local tmp_layout = parent and parent.layout
                if tmp_layout and tmp_layout.content then
                    tmp_layout.content = nil
                    I.UIToolkit.queueUpdate(parent, true)
                end
            end
            if old then H.userData(old)._index = nil end
            viewUserData._index = n
            layout.content = ui.content { view }
            I.UIToolkit.queueUpdate(element, true)
        elseif needUpdate then
            I.UIToolkit.queueUpdate(element)
        end
        return holder.element, false
    end
    viewUserData._index = n
    element = ui.create {
        props = {
            position = self:getPosByIndex(n),
            size = state.itemSize,
            visible = visible,
        },
        content = ui.content { view },
    }
    self._holders[n] = { id = id, element = element }
    return element, true
end

---@param strict boolean? if true, range will be strict - only fully visible items are included
---@return integer, integer
function ItemGrid:getVisibleItemRange(strict)
    local state = self.state
    local total = #state.items
    if total == 0 then return 1, 0 end
    local scroll = self._scrollBar:getPosition()
    local contentSize = self:getContentSize()
    local itemSize = state.itemSize

    local roundFrom = strict and math.ceil or math.floor
    local roundTo = strict and math.floor or math.ceil
    if state.horizontal then
        local height = math.floor(contentSize.y / itemSize.y)

        local from = math.max(height * roundFrom(scroll / itemSize.x), 1)
        if from > total then return 1, 0 end
        local to = math.min(height * roundTo((scroll + contentSize.x) / itemSize.x), total)

        return from, to
    else
        local width = math.floor(contentSize.x / itemSize.x)

        local from = math.max(width * roundFrom(scroll / itemSize.y), 1)
        if from > total then return 1, 0 end
        local to = math.min(width * roundTo((scroll + contentSize.y) / itemSize.y), total)

        return from, to
    end
end

---@return integer
function ItemGrid:getVisibleItemCount()
    local state = self.state
    local contentSize = self:getContentSize()
    local itemSize = state.itemSize
    if state.horizontal then
        local height = math.floor(contentSize.y / itemSize.y)
        return height * math.ceil(contentSize.x / itemSize.x)
    else
        local width = math.floor(contentSize.x / itemSize.x)
        return width * math.ceil(contentSize.y / itemSize.y)
    end
end

--TODO: for 0.52 try implementing it using Flex with wrapping
function ItemGrid:_updateScrollable()
    local state = self.state
    local itemSize = state.itemSize
    local scrollerSize = self:getContentSize()
    local itemCount = #state.items
    if state.horizontal then
        local height = math.floor(scrollerSize.y / itemSize.y)
        scrollerSize = v2(itemSize.x * math.ceil(itemCount / height), itemSize.y * height)
    else
        local width = math.floor(scrollerSize.x / itemSize.x)
        scrollerSize = v2(itemSize.x * width, itemSize.y * math.ceil(itemCount / width))
    end
    local items = {}
    ---@type openmw.ui.Layout
    local layout = self._scrollable.layout
    local from, to = self:getVisibleItemRange()
    local updateContent = false
    local created
    for i = 1, itemCount do
        local item = state.items[i]
        local view = state.provider:getView(item)
        items[#items + 1], created = self:_getHolder(i, item.id, view, i >= from and i <= to)
        updateContent = updateContent or created
    end
    layout.props.size = scrollerSize
    if updateContent then
        if state.highlightElement then table.insert(items, 1, state.highlightElement) end
        --if state.highlightElement then table.insert(items, state.highlightElement) end
        layout.content = ui.content(items)
    end
    I.UIToolkit.queueUpdate(self._scrollable)
    self:_updateItemHighlight()
end

---@private
---@param provider UIToolkit.GridItem.Base
---@param id string|nil
---@param hovered boolean
function ItemGrid:setItemHoveredStatus(provider, id, hovered)
    if not id then return end
    local view = provider:getCachedView(id)
    if not view then return end
    I.UIToolkit.Interactive.updateState(view, { hovering = hovered })
    I.UIToolkit.queueUpdate(view, self.itemDeepUpdate)
end

---@return UIToolkit.ListData.Base[]
function ItemGrid:getItems()
    return self.state.items
end

---@param items UIToolkit.ListData.Base[]
function ItemGrid:setItems(items)
    local state = self.state
    local wasHovered
    if state.hovered then --cleanup previously hovered item - it might be gone in new list
        local was = state.items[state.hovered]
        wasHovered = was and was.id
        local new = items[state.hovered]
        if not new or wasHovered ~= new.id then
            self:setItemHoveredStatus(state.provider, wasHovered, false)
            state.hovered = nil
        end
    end
    state.items = items
    state.itemsById = {}
    self._scrollBar:setMaxScroll(self:_getMaxScroll())
    I.UIToolkit.queueUpdate(self._scrollBar.element)
    self:_updateScrollable()
    self:updateHoveredItem()
end

function ItemGrid:_getMaxScroll()
    local t = I.UIToolkit.getTheme()
    local state = self.state
    local contentSize = self:getContentSize()
    local itemSize = state.itemSize
    local maxScroll = 0
    if state.horizontal then
        local height = math.floor(contentSize.y / itemSize.y)
        maxScroll = math.ceil(#state.items / height) * itemSize.x - state.currentSize.x
    else
        local width = math.floor(contentSize.x / itemSize.x)
        maxScroll = math.ceil(#state.items / width) * itemSize.y - state.currentSize.y
    end
    if not self.noBorder then
        maxScroll = maxScroll + 2 * t.Sizes.padding
    end
    return maxScroll
end

function ItemGrid:_getScrollLength()
    local s = I.UIToolkit.getTheme().Sizes
    local state = self.state
    local length
    if state.horizontal then
        length = state.currentSize.x
    else
        length = state.currentSize.y
    end

    if self.noBorder then return length end
    return length - 2 * (s.border + s.padding)
end

---@param p openmw.util.Vector2
---@return integer
function ItemGrid:getIndexByPos(p)
    local state = self.state
    local contentSize = self:getContentSize()
    local itemSize = state.itemSize
    local x = math.floor(p.x / itemSize.x)
    local y = math.floor(p.y / itemSize.y)
    if state.horizontal then
        local height = math.floor(contentSize.y / itemSize.y)
        return 1 + x * height + y
    else
        local width = math.floor(contentSize.x / itemSize.x)
        return 1 + x + y * width
    end
end

---@param idx integer
---@return openmw.util.Vector2
function ItemGrid:getPosByIndex(idx)
    local state = self.state
    local itemSize = state.itemSize
    local contentSize = self:getContentSize()
    if state.horizontal then
        local height = math.floor(contentSize.y / itemSize.y)
        local x = math.floor((idx - 1) / height)
        local y = idx - 1 - x * height
        return v2(itemSize.x * x, itemSize.y * y)
    else
        local width = math.floor(contentSize.x / itemSize.x)
        local y = math.floor((idx - 1) / width)
        local x = idx - 1 - y * width
        return v2(itemSize.x * x, itemSize.y * y)
    end
end

---@param offset openmw.util.Vector2
function ItemGrid:_updateLastHoveredPos(offset)
    local state = self.state
    local p = self._scrollBar:getPosition()
    if state.horizontal then
        state.lastHoveredPos = v2(offset.x - p, offset.y)
    else
        state.lastHoveredPos = v2(offset.x, offset.y - p)
    end
end

---@param visible boolean?
function ItemGrid:_updateItemHighlight(visible)
    local state = self.state
    if not state.highlightElement then return end
    local props = H.props(state.highlightElement)
    if state.hovered then
        props.position = self:getPosByIndex(state.hovered)
    else
        visible = false
    end
    if visible ~= nil then
        props.visible = visible
    end
    I.UIToolkit.update(state.highlightElement)
end

function ItemGrid:updateHoveredItem()
    local state = self.state
    local lastPos = self.state.lastHoveredPos
    if not lastPos then return end
    local scrollPos = self._scrollBar:getPosition()
    local p = lastPos + (self.state.horizontal and v2(scrollPos, 0) or v2(0, scrollPos))

    self:setHovered(self:getIndexByPos(p), state.needHighlight)
end

---@param idOrIndex string|integer|nil
---@param highlight boolean?
function ItemGrid:setHovered(idOrIndex, highlight)
    if self:isDestroyed() then return end
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
        self:setItemHoveredStatus(state.provider, was and was.id, false)
    end
    self:setItemHoveredStatus(state.provider, id, true)

    if item then
        local tip = state.provider:getTooltip(item)
        I.UTKTooltips.setTooltip(tip, { isAlive = function() return not self:isDestroyed() end, })
    else
        I.UTKTooltips.setTooltip(nil)
        highlight = false
    end

    state.hovered = idOrIndex
    state.needHighlight = highlight
    self:_updateItemHighlight(highlight)
end

---@return UIToolkit.ListData.Base? item, integer? index
function ItemGrid:getHovered()
    local state = self.state
    if not state.hovered then return nil, nil end
    return state.items[state.hovered], state.hovered
end

---@return number
function ItemGrid:getPosition()
    return self._scrollBar:getPosition()
end

---@param position number
function ItemGrid:setPosition(position)
    self._scrollBar:setPosition(position)
end

---@return number
function ItemGrid:getProgress()
    return self._scrollBar:getProgress()
end

---@param progress number
function ItemGrid:setProgress(progress)
    self._scrollBar:setProgress(progress)
end

---@param shift openmw.util.Vector2
function ItemGrid:shiftHoveredItem(shift)
    local state = self.state
    local itemSize = state.itemSize
    local contentSize = self:getContentSize()
    local itemLength, delta
    if state.horizontal then
        local height = math.floor(contentSize.y / itemSize.y)
        itemLength = itemSize.x
        delta = shift.x * height + shift.y
    else
        local width = math.floor(contentSize.x / itemSize.x)
        itemLength = itemSize.y
        delta = shift.x + shift.y * width
    end

    if not delta or delta == 0 then return end
    local down = delta > 0
    local rows = state.items
    local from, to = self:getVisibleItemRange(true)
    local rIdx = state.hovered
    local tIdx = down and from or to
    if rIdx then
        util.clamp(rIdx, from, to)
        tIdx = rIdx + delta
        if down then
            if rIdx == #rows then
                down = false
                tIdx = 1
            end
            to = to - 1
        else
            if rIdx == 1 then
                down = true
                tIdx = #rows
            end
            from = from + 1
        end
    end
    tIdx = util.clamp(tIdx, 1, #rows)

    if tIdx < from or tIdx > to then
        local tPos = tIdx + (down and 0 or from - to)
        tPos = (tPos - 1) * itemLength
        local pos = self:getPosition()

        self:setPosition(down
            and math.max(pos, tPos)
            or math.min(pos, tPos)
        )
    end
    state.lastHoveredPos = nil
    self:setHovered(tIdx, true)
end

---@param id string
---@return UIToolkit.ListData.Base?, integer?
function ItemGrid:getItemById(id)
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
function ItemGrid:setSize(size)
    local state = self.state
    size = v2(util.round(size.x), util.round(size.y))
    if size == state.currentSize then return end
    state.currentSize = size
    local contentSz = self:getContentSize()
    local scroll = self._scrollBar
    scroll:setLength(self:_getScrollLength())
    scroll:setMaxScroll(self:_getMaxScroll())
    local toolkit = I.UIToolkit
    toolkit.queueUpdate(scroll.element)

    self:updateProps { size = size }
    self.element.layout.content[1].props.size = contentSz

    toolkit.queueUpdate(self.element)
    self:_updateScrollable()
end

return ItemGrid
