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


---@class UIToolkit.ScrollBarV : UIToolkit.Component
local ScrollBarV = Class(Component)


---@param opts UIToolkit.ScrollBarOpts
function ScrollBarV:init(opts)
    self.scrollStep = opts.scrollStep
    self.size = opts.size
    self.maxScroll = opts.maxScroll
    self.onScroll = opts.onScroll
    self.position = 0
    self.isDragging = false
    ---@type number?
    self.dragOffset = nil

    --TODO: add ability to resize the bar
    --TODO: add ability to change max scroll
    --TODO: add ability to set scroll from outside

    local function calcScrollBarSize()
        return v2(INNER_WIDTH, self.size - ((INNER_WIDTH + omwConstants.padding) * 2))
    end
    local function calcHandleSize()
        return math.max(
            (self.size / (self.maxScroll + self.size)) * (self.size - (INNER_WIDTH * 2)),
            INNER_WIDTH)
    end

    local function handlePosToScrollPos(y)
        local scrollBarSize = calcScrollBarSize()
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
    local function onScroller()
        local scrollProgress = self.maxScroll == 0 and 0 or self.position / self.maxScroll
        local handleProgress = (self.size - ((INNER_WIDTH + omwConstants.padding) * 2) - handleProps.size.y - 4) *
            scrollProgress
        handleProps.position = util.vector2(0, handleProgress)

        I.UIToolkit.queueUpdate(barWrapper)
        self.onScroll()
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
                self.position = util.clamp(self.position - self.scrollStep, 0, self.maxScroll)
                onScroller()
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
                self.position = util.clamp(self.position + self.scrollStep, 0, self.maxScroll)
                onScroller()
            end),
        }
    }

    local scrollBar = {
        template = I.MWUI.templates.borders,
        name = 'scrollBar',
        props = {
            size = calcScrollBarSize(),
        },
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
                    self.position = util.clamp(handlePosToScrollPos(adjustedY), 0, self.maxScroll)
                    onScroller()
                end
                return true
            end),
            mousePress = async:callback(function(e)
                if e.button == 1 then
                    ambient.playSound('menu click')
                    self.isDragging = true
                    self.position = util.clamp(handlePosToScrollPos(e.offset.y), 0, self.maxScroll)
                    onScroller()
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

return ScrollBarV
