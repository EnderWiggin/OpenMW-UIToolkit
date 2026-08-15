---@omw-context player

local ui = require('openmw.ui')
local util = require('openmw.util')
local ambient = require('openmw.ambient')
local async = require('openmw.async')
local omwConstants = require('scripts.omw.mwui.constants')
local I = require('openmw.interfaces')

local v2 = util.vector2
local Class = require('scripts.UIToolkit.class')
local Component = require('scripts.UIToolkit.components.component')

local T = {
    Base = require('scripts.UIToolkit.templates.base'),
    Interactive = require('scripts.UIToolkit.templates.interactive'),
}

local OUTER_WIDTH = 16
local INNER_WIDTH = 14

local BTN_UP_TEX = ui.texture { path = 'textures/omw_menu_scroll_up.dds' }
local BTN_DOWN_TEX = ui.texture { path = 'textures/omw_menu_scroll_down.dds' }
local SCROLL_TEX = ui.texture { path = 'textures/omw_menu_scroll_center_v.dds' }


---@param size number
local function calcScrollBarSize(size)
    return v2(INNER_WIDTH, size - ((INNER_WIDTH + omwConstants.padding) * 2))
end

---@class UIToolkit.ScrollBarV : UIToolkit.Component
local ScrollBarV = Class(Component)


---@param opts UIToolkit.ScrollBarOpts
function ScrollBarV:init(opts)
    self.scrollStep = opts.scrollStep
    self.size = opts.size
    self.maxScroll = opts.maxScroll
    self.handleSize = opts.handleSize
    self.onScroll = opts.onScroll
    self.position = 0
    self.isDragging = false
    ---@type number?
    self.dragOffset = nil

    local function calcHandleSize()
        return self.handleSize
            or math.max((self.size / (self.maxScroll + self.size)) * (self.size - (INNER_WIDTH * 2)),
                INNER_WIDTH)
    end

    local function handlePosToScrollPos(y)
        local scrollBarSize = calcScrollBarSize(self.size)
        local handleSize = calcHandleSize()

        y = util.clamp(y - (handleSize / 2), 0, scrollBarSize.y - handleSize)
        local progress = y / (scrollBarSize.y - handleSize)
        return progress * self.maxScroll
    end

    local handleProps = {
        resource = SCROLL_TEX,
        size = v2(INNER_WIDTH - 4, calcHandleSize()),
        tileV = true,
        propagateEvents = true,
    }
    ---@type openmw.ui.Element
    local barWrapper

    ---@param this UIToolkit.ScrollBarV
    function self._onScrolled(this)
        local progress = this:getProgress()
        local handleProgress = (this.size - ((INNER_WIDTH + omwConstants.padding) * 2) - handleProps.size.y - 4) *
            progress
        handleProps.position = util.vector2(0, handleProgress)

        I.UIToolkit.queueUpdate(barWrapper)
        this.onScroll(this.position, progress)
    end

    local upButton = {
        template = I.MWUI.templates.borders,
        props = {
            size = v2(INNER_WIDTH, INNER_WIDTH),
        },
        content = ui.content {
            {
                type = ui.TYPE.Image,
                props = {
                    resource = BTN_UP_TEX,
                    size = v2(INNER_WIDTH - 4, INNER_WIDTH - 4),
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
        template = I.MWUI.templates.borders,
        props = {
            size = v2(INNER_WIDTH, INNER_WIDTH),
        },
        content = ui.content {
            {
                type = ui.TYPE.Image,
                props = {
                    resource = BTN_DOWN_TEX,
                    size = v2(INNER_WIDTH - 4, INNER_WIDTH - 4),
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
        size = calcScrollBarSize(self.size),
    }
    local scrollBar = {
        template = I.MWUI.templates.borders,
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
                            self.dragOffset = e.offset.y
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
                    local halfHand = (calcHandleSize() / 2)
                    local adjustedY = e.offset.y - (self.dragOffset or halfHand) + halfHand
                    self:setPosition(handlePosToScrollPos(adjustedY))
                end
                return true
            end),
            mousePress = async:callback(function(e)
                if e.button == 1 then
                    ambient.playSound('menu click')
                    self.isDragging = true
                    self:setPosition(handlePosToScrollPos(e.offset.y))
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

    barWrapper = ui.create {
        type = ui.TYPE.Flex,
        name = 'scrollBarWrapper',
        props = {
            position = v2(-OUTER_WIDTH + (OUTER_WIDTH - INNER_WIDTH) / 2, 0),
            relativePosition = v2(1, 0),
        },
        content = ui.content {
            upButton,
            T.Base.intervalV(omwConstants.padding),
            scrollBar,
            T.Base.intervalV(omwConstants.padding),
            downButton,
        }
    }

    Component.init(self, barWrapper)
end

---@return number
function ScrollBarV:getPosition()
    return self.position
end

---@param position number
function ScrollBarV:setPosition(position)
    self.position = util.clamp(position, 0, self.maxScroll)
    self:_onScrolled()
end

---@return number
function ScrollBarV:getProgress()
    return self.maxScroll <= 0 and 0 or self.position / self.maxScroll
end

---@param progress number
function ScrollBarV:setProgress(progress)
    self:setPosition(progress * self.maxScroll)
end

---@param steps number
function ScrollBarV:scroll(steps)
    self.position = util.clamp(self.position + steps * self.scrollStep, 0, self.maxScroll)
    self:_onScrolled()
end

---@param size number
function ScrollBarV:setSize(size)
    self.size = size
    self._scrollProps.size = calcScrollBarSize(size)
    self:setPosition(self.position)
end

---@param maxScroll number
---@param preserveProgress boolean?
function ScrollBarV:setMaxScroll(maxScroll, preserveProgress)
    local progress = self:getProgress()
    self.maxScroll = maxScroll
    if preserveProgress then
        self:setProgress(progress)
    else
        self:setPosition(self.position)
    end
end

return ScrollBarV
