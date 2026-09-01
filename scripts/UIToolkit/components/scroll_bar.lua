---@omw-context player

local ui = require('openmw.ui')
local util = require('openmw.util')
local ambient = require('openmw.ambient')
local async = require('openmw.async')
local I = require('openmw.interfaces')

local v2 = util.vector2
local Class = require('scripts.UIToolkit.class')
local Component = require('scripts.UIToolkit.components.component')

local WIDTH = 14

local BTN_UP_TEX = ui.texture { path = 'textures/omw_menu_scroll_up.dds' }
local BTN_DOWN_TEX = ui.texture { path = 'textures/omw_menu_scroll_down.dds' }
local SCROLL_TEX_V = ui.texture { path = 'textures/omw_menu_scroll_center_v.dds' }

local BTN_LEFT_TEX = ui.texture { path = 'textures/omw_menu_scroll_left.dds' }
local BTN_RIGHT_TEX = ui.texture { path = 'textures/omw_menu_scroll_right.dds' }
local SCROLL_TEX_H = ui.texture { path = 'textures/omw_menu_scroll_center_h.dds' }

---@param bar UIToolkit.ScrollBar
---@return openmw.util.Vector2
local function calcScrollBarSize(bar)
    local padding = I.UIToolkit.getTheme().Sizes.padding
    if bar.horizontal then
        return v2(bar.length - ((WIDTH + padding) * 2), WIDTH)
    end
    return v2(WIDTH, bar.length - ((WIDTH + padding) * 2))
end

---@class UIToolkit.ScrollBar : UIToolkit.Component
local ScrollBar = Class(Component)


---@param opts UIToolkit.ScrollBarOpts
function ScrollBar:init(opts)
    local T = I.UIToolkit.Templates
    self.horizontal = opts.horizontal == true
    self.scrollStep = opts.scrollStep
    self.length = opts.length
    self.maxScroll = math.max(0, opts.maxScroll)
    self.handleSize = opts.handleSize
    self.onScroll = opts.onScroll
    self.position = 0
    self.isDragging = false
    ---@type number?
    self.dragOffset = nil

    local function handlePosToScrollPos(p)
        local scrollBarSize = calcScrollBarSize(self)
        local sz = self.horizontal and scrollBarSize.x or scrollBarSize.y
        local handleSize = self:calcHandleSize()

        p = util.clamp(p - (handleSize / 2), 0, sz - handleSize)
        local progress = p / (sz - handleSize)
        return progress * self.maxScroll
    end

    local handleSz = self:calcHandleSize()
    local bsz = 2 * T.getBorderSize('thin')
    local handleProps = {
        resource = self.horizontal and SCROLL_TEX_H or SCROLL_TEX_V,
        size = self.horizontal and v2(handleSz, WIDTH - bsz) or v2(WIDTH - bsz, handleSz),
        tileV = true,
        propagateEvents = true,
    }
    self._handleProps = handleProps

    ---@type openmw.ui.Element
    local barWrapper

    ---@param this UIToolkit.ScrollBar
    ---@param position number
    ---@param silent boolean?
    function self.setPosition(this, position, silent)
        position = util.round(util.clamp(position, 0, self.maxScroll))
        if position == self.position then return end

        self.position = position
        local padding = I.UIToolkit.getTheme().Sizes.padding
        local progress = this:getProgress()
        local hsz = self.horizontal and handleProps.size.x or handleProps.size.y
        local handlePos = (this.length - ((WIDTH + padding) * 2) - hsz - bsz) * progress
        handleProps.position = self.horizontal and v2(handlePos, 0) or v2(0, handlePos)

        I.UIToolkit.queueUpdate(barWrapper)
        if not silent then this.onScroll(this.position, progress) end
    end

    local upButton = {
        template = T.border(),
        props = {
            size = v2(WIDTH, WIDTH),
        },
        content = ui.content {
            {
                type = ui.TYPE.Image,
                props = {
                    resource = self.horizontal and BTN_LEFT_TEX or BTN_UP_TEX,
                    relativeSize = v2(1, 1),
                }
            }
        },
        events = {
            mousePress = async:callback(function(e)
                if e.button ~= 1 then return end
                ambient.playSound('menu click', { scale = false })
                self:scroll(-1)
            end),
        }
    }

    local downButton = {
        template = T.border(),
        props = {
            size = v2(WIDTH, WIDTH),
        },
        content = ui.content {
            {
                type = ui.TYPE.Image,
                props = {
                    resource = self.horizontal and BTN_RIGHT_TEX or BTN_DOWN_TEX,
                    relativeSize = v2(1, 1),
                }
            }
        },
        events = {
            mousePress = async:callback(function(e)
                if e.button ~= 1 then return end
                ambient.playSound('menu click', { scale = false })
                self:scroll(1)
            end),
        }
    }
    self._scrollProps = {
        size = calcScrollBarSize(self),
    }
    local scrollBar = {
        template = T.border(),
        name = 'scrollBar',
        props = self._scrollProps,
        content = ui.content {
            {
                type = ui.TYPE.Image,
                name = 'handle',
                props = handleProps,
                events = {
                    mousePress = async:callback(function(e)
                        if e.button == 1 then
                            ambient.playSound('menu click')
                            self.isDragging = true
                            self.dragOffset = self.horizontal and e.offset.x or e.offset.y
                        end
                        return false
                    end),
                    mouseRelease = async:callback(function(e)
                        if e.button == 1 then
                            self.isDragging = false
                            self.dragOffset = nil
                        end
                        return false
                    end),
                }
            }
        },
        events = {
            mouseMove = async:callback(function(e)
                if e.button == 1 then
                    local halfHand = (self:calcHandleSize() / 2)
                    local offset = self.horizontal and e.offset.x or e.offset.y
                    local adjustedY = offset - (self.dragOffset or halfHand) + halfHand
                    self:setPosition(handlePosToScrollPos(adjustedY))
                end
                return true
            end),
            mousePress = async:callback(function(e)
                if e.button == 1 then
                    ambient.playSound('menu click')
                    self.isDragging = true
                    local offset = self.horizontal and e.offset.x or e.offset.y
                    self:setPosition(handlePosToScrollPos(offset))
                end
            end),
            mouseRelease = async:callback(function(e)
                if e.button == 1 then
                    self.isDragging = false
                end
                return true
            end),
        }
    }
    local gap = I.UIToolkit.getTheme().Sizes.padding
    --TODO: when 0.52 releases replace intervals with `gap` property
    local padding = self.horizontal and T.intervalH or T.intervalV
    barWrapper = ui.create {
        type = ui.TYPE.Flex,
        name = 'scrollBarWrapper',
        props = {
            horizontal = self.horizontal,
        },
        --TODO: since we know sizes, change Flex to Widget and manually position elements
        --but don't forget to reposition them on size change
        content = ui.content {
            upButton,
            padding(gap),
            scrollBar,
            padding(gap),
            downButton,
        }
    }

    Component.init(self, barWrapper)
end

---@return number
function ScrollBar:getPosition()
    return self.position
end

---@return number
function ScrollBar:getProgress()
    return self.maxScroll <= 0 and 0 or self.position / self.maxScroll
end

---@param progress number
---@param silent boolean?
function ScrollBar:setProgress(progress, silent)
    self:setPosition(progress * self.maxScroll, silent)
end

---@param steps number
function ScrollBar:scroll(steps)
    self:setPosition(self.position + steps * self.scrollStep)
end

function ScrollBar:calcHandleSize()
    return self.handleSize
        or math.max((self.length / (self.maxScroll + self.length)) * (self.length - (WIDTH * 2)),
            WIDTH)
end

---@return openmw.util.Vector2
function ScrollBar:getSize()
    return self._scrollProps.size
end

---@param size number
function ScrollBar:setLength(size)
    if self.length == size then return end
    self.length = size
    self._scrollProps.size = calcScrollBarSize(self)
    I.UIToolkit.queueUpdate(self.element)
    self:setPosition(self.position)
end

---@param maxScroll number
---@param preserveProgress boolean?
function ScrollBar:setMaxScroll(maxScroll, preserveProgress)
    local progress = self:getProgress()
    self.maxScroll = math.max(0, maxScroll)
    if not self.handleSize then
        local bsz = 2 * I.UIToolkit.Templates.getBorderSize('thin')
        local handleSz = self:calcHandleSize()
        self._handleProps.size = self.horizontal and v2(handleSz, WIDTH - bsz) or v2(WIDTH - bsz, handleSz)
    end

    if preserveProgress then
        self:setProgress(progress)
    else
        self:setPosition(self.position)
    end
end

return ScrollBar
