---@omw-context player

local ui = require('openmw.ui')
local util = require('openmw.util')
local auxUi = require('openmw_aux.ui')
local async = require('openmw.async')
local ambient = require('openmw.ambient')

local omwConstants = require('scripts.omw.mwui.constants')
local I = require('openmw.interfaces')
local Class = require('scripts.UIToolkit.class')
local Component = require('scripts.UIToolkit.components.component')
local T = {
    Base = require('scripts.UIToolkit.templates.base'),
}

local v2 = util.vector2

---@class UIToolkit.Window: UIToolkit.Component
local Window = Class(Component)

local MIN_SZ = v2(150, 90)
local HEADER_HEIGHT = 20
local BORDER_THICKNESS = omwConstants.border
local BORDER_THICKNESS_THICK = omwConstants.thickBorder

local borderSideParts = {
    left = v2(0, 0),
    right = v2(1, 0),
    top = v2(0, 0),
    bottom = v2(0, 1),
}

local borderCornerParts = {
    top_left = v2(0, 0),
    top_right = v2(1, 0),
    bottom_left = v2(0, 1),
    bottom_right = v2(1, 1),
}

local borderSidePattern = 'textures/menu_%s_border_%s.dds'
local borderCornerPattern = 'textures/menu_%s_border_%s_corner.dds'

local borderResources = {}
local borderPieces = {}

for _, thickness in ipairs { 'thin', 'thick' } do
    borderResources[thickness] = {}
    for k in pairs(borderSideParts) do
        borderResources[thickness][k] = ui.texture { path = borderSidePattern:format(thickness, k) }
    end
    for k in pairs(borderCornerParts) do
        borderResources[thickness][k] = ui.texture { path = borderCornerPattern:format(thickness, k) }
    end

    borderPieces[thickness] = {}
    for k in pairs(borderSideParts) do
        local horizontal = k == 'top' or k == 'bottom'
        borderPieces[thickness][k] = {
            type = ui.TYPE.Image,
            props = {
                resource = borderResources[thickness][k],
                tileH = horizontal,
                tileV = not horizontal,
            },
        }
    end
    for k in pairs(borderCornerParts) do
        borderPieces[thickness][k] = {
            type = ui.TYPE.Image,
            props = {
                resource = borderResources[thickness][k],
            },
        }
    end
end

local function borderTemplates(thickness)
    local borderSize = (thickness == 'thin') and omwConstants.border or omwConstants.thickBorder
    local borderV = v2(1, 1) * borderSize
    local result = {}

    result.bordersDraggable = {
        content = ui.content {},
    }
    for k, v in pairs(borderSideParts) do
        local horizontal = k == 'top' or k == 'bottom'
        local direction = horizontal and v2(1, 0) or v2(0, 1)
        result.bordersDraggable.content:add {
            template = borderPieces[thickness][k],
            props = {
                position = (direction - v) * borderSize,
                relativePosition = v,
                size = (v2(1, 1) - direction * 3) * borderSize,
                relativeSize = direction,
            },
            userData = {
                dragType = k
            }
        }
    end
    for k, v in pairs(borderCornerParts) do
        result.bordersDraggable.content:add {
            template = borderPieces[thickness][k],
            props = {
                position = -v * borderSize,
                relativePosition = v,
                size = borderV,
            },
            userData = {
                dragType = k
            }
        }
    end
    result.bordersDraggable.content:add {
        external = { slot = true },
        props = {
            position = borderV,
            size = borderV * -2,
            relativeSize = v2(1, 1),
        }
    }

    return result
end

local headerTextures = {
    [1] = ui.texture { path = 'textures/menu_head_block_top_left_corner.dds' },
    [2] = ui.texture { path = 'textures/menu_head_block_top.dds' },
    [3] = ui.texture { path = 'textures/menu_head_block_top_right_corner.dds' },
    [4] = ui.texture { path = 'textures/menu_head_block_left.dds' },
    [5] = ui.texture { path = 'textures/menu_head_block_middle.dds' },
    [6] = ui.texture { path = 'textures/menu_head_block_right.dds' },
    [7] = ui.texture { path = 'textures/menu_head_block_bottom_left_corner.dds' },
    [8] = ui.texture { path = 'textures/menu_head_block_bottom.dds' },
    [9] = ui.texture { path = 'textures/menu_head_block_bottom_right_corner.dds' },
}

local function headerImage(i, tile, size)
    return {
        type = ui.TYPE.Image,
        props = {
            resource = headerTextures[i],
            size = size or util.vector2(0, 0),
            tileH = tile,
            tileV = false,
        },
        external = {
            grow = 1,
            stretch = 1,
        }
    }
end

local headerSection = {
    type = ui.TYPE.Flex,
    props = {
        horizontal = true,
    },
    external = {
        grow = 1,
        stretch = 1,
    },
    content = ui.content {
        {
            type = ui.TYPE.Flex,
            props = {
                autoSize = false,
                size = util.vector2(2, HEADER_HEIGHT),
            },
            content = ui.content {
                headerImage(1, false, util.vector2(2, 2)),
                headerImage(4, false, util.vector2(2, 16)),
                headerImage(7, false, util.vector2(2, 2)),
            }
        },
        {
            type = ui.TYPE.Flex,
            props = {
                autoSize = false,
                size = util.vector2(0, HEADER_HEIGHT),
            },
            content = ui.content {
                headerImage(2, true, util.vector2(0, 2)),
                headerImage(5, true, util.vector2(0, 16)),
                headerImage(8, true, util.vector2(0, 2)),
            },
            external = {
                grow = 1,
                stretch = 1,
            }
        },
        {
            type = ui.TYPE.Flex,
            props = {
                autoSize = false,
                size = util.vector2(2, HEADER_HEIGHT),
            },
            content = ui.content {
                headerImage(3, false, util.vector2(2, 2)),
                headerImage(6, false, util.vector2(2, 16)),
                headerImage(9, false, util.vector2(2, 2)),
            }
        }
    }
}

local function makePinButton(pinned, onPinChanged)
    local textures = {
        pinned = function(part, pos, size)
            return {
                type = ui.TYPE.Image,
                props = {
                    position = pos,
                    size = size,
                    resource = I.UIToolkit.texture('textures/menu_rightbuttondown_' .. part .. '.dds')
                }
            }
        end,
        unpinned = function(part, pos, size)
            return {
                type = ui.TYPE.Image,
                props = {
                    position = pos,
                    size = size,
                    resource = I.UIToolkit.texture('textures/menu_rightbuttonup_' .. part .. '.dds')
                }
            }
        end,
    }

    local function updateTextures(element)
        local state = element.layout.userData.pinned and 'pinned' or 'unpinned'
        local content = ui.content {}
        content:add(textures[state]('top_left', v2(0, 0), v2(2, 2)))
        content:add(textures[state]('top', v2(2, 0), v2(15, 2)))
        content:add(textures[state]('top_right', v2(17, 0), v2(2, 2)))
        content:add(textures[state]('left', v2(0, 2), v2(2, 15)))
        content:add(textures[state]('center', v2(2, 2), v2(15, 15)))
        content:add(textures[state]('right', v2(17, 2), v2(2, 15)))
        content:add(textures[state]('bottom_left', v2(0, 17), v2(2, 2)))
        content:add(textures[state]('bottom', v2(2, 17), v2(15, 2)))
        content:add(textures[state]('bottom_right', v2(17, 17), v2(2, 2)))
        element.layout.content = content
        element:update()
    end

    local element = ui.create {
        name = 'pinButton',
        props = {
            size = v2(20, 20),
            propagateEvents = false,
        },
        content = ui.content {},
        userData = {
            pinned = pinned,
        },
        events = {
        },
    }

    element.layout.events.mousePress = async:callback(function(e, layout)
        if e.button ~= 1 then return end
        ambient.playSound('menu click')
        layout.userData.pinned = not layout.userData.pinned
        if onPinChanged then
            onPinChanged(layout.userData.pinned)
        end
        updateTextures(element)
    end)

    updateTextures(element)

    return element
end

local bordersDraggable = borderTemplates('thin').bordersDraggable
local bordersDraggableThick = borderTemplates('thick').bordersDraggable

---@enum DragType
local DragType = {
    ResizeTL = 'top_left',
    ResizeBR = 'bottom_right',
    ResizeTR = 'top_right',
    ResizeBL = 'bottom_left',
    ResizeL = 'left',
    ResizeR = 'right',
    ResizeT = 'top',
    ResizeB = 'bottom',
    Move = 'move',
}

local dragTypePointers = {
    [DragType.ResizeL] = 'hresize',
    [DragType.ResizeR] = 'hresize',
    [DragType.ResizeT] = 'vresize',
    [DragType.ResizeB] = 'vresize',
    [DragType.ResizeTL] = 'dresize',
    [DragType.ResizeTR] = 'dresize2',
    [DragType.ResizeBL] = 'dresize2',
    [DragType.ResizeBR] = 'dresize',
    [DragType.Move] = 'arrow',
}

---@param borderTemplate openmw.ui.Layout
---@param onDragTypeChanged fun(dragType: string?)?
---@param noResize boolean?
---@return openmw.ui.Template
local function makeDraggable(borderTemplate, onDragTypeChanged, noResize)
    local template = auxUi.deepLayoutCopy(borderTemplate) --[[@as openmw.ui.Template]]
    ---@type openmw.ui.Content
    local content = template.content

    local function setDragType(index)
        local borderPiece = content[index]
        if borderPiece.userData and borderPiece.userData.dragType then
            local dragType = noResize and DragType.Move or borderPiece.userData.dragType
            borderPiece.props.pointer = dragTypePointers[dragType] or 'arrow'
            borderPiece.events = {
                focusGain = async:callback(function()
                    if onDragTypeChanged then
                        onDragTypeChanged(dragType)
                    end
                end),
                focusLoss = async:callback(function()
                    if onDragTypeChanged then
                        onDragTypeChanged(nil)
                    end
                end),
            }
        end
    end

    for i = 1, 8 do
        setDragType(i)
    end

    return template
end

---@param opts UIToolkit.WindowOpts
---@param saved? UIToolkit.WindowSaveData
function Window:init(opts, saved)
    local theme = I.UIToolkit.getTheme()

    local noResize = not opts.resizing
    local draggable = opts.draggable or not noResize
    local handler = opts.handler
    local pinned = false
    if saved then
        pinned = saved.pinned
    elseif opts.pinned ~= nil then
        pinned = opts.pinned
    end
    local minSize = opts.minSize or MIN_SZ
    local position = saved and saved.position or opts.position or v2(0, 0)
    local size = saved and saved.size or opts.size or minSize

    ---@type openmw.ui.Template
    local baseTemplate = I.MWUI.templates.bordersThick
    local data = {
        minSize = minSize,
        pinned = pinned,
        pinnable = opts.pinnable == true or opts.pinned == true,

        ---@type DragType?
        dragType = nil,
    }

    local function setDragType(dragType)
        data.dragType = dragType
    end

    if draggable then
        baseTemplate = makeDraggable(bordersDraggableThick, setDragType, noResize)
    end
    local title = {
        name = 'title',
        template = T.Base.text(),
        props = {
            text = opts.title,
            textSize = theme.Sizes.textHeader,
        }
    }
    local header = ui.create {
        name = 'header',
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
        },
        external = {
            stretch = 1,
        },
        content = ui.content {
            headerSection,
            T.Base.intervalH(8),
            title,
            T.Base.intervalH(8),
            headerSection,
        },
        events = {
            focusGain = async:callback(function()
                if draggable then
                    setDragType(DragType.Move)
                end
            end),
            focusLoss = async:callback(function()
                if draggable then
                    setDragType(nil)
                end
            end),
        }
    }

    local body = ui.create {
        name = 'body',
        template = baseTemplate,
        props = {},
        external = {
            grow = 1,
            stretch = 1,
        },
    }

    local pinButton = makePinButton(data.pinned, function(newPinned) data.pinned = newPinned end)
    pinButton.layout.props.anchor = v2(1, 0)
    pinButton.layout.props.relativePosition = v2(1, 0)
    pinButton.layout.props.visible = data.pinnable == true

    local windowLayout = {
        layer = 'Windows',
        template = baseTemplate,
        props = {
            position = position,
            size = size,
        },
        content = ui.content {
            {
                name = 'background',
                type = ui.TYPE.Image,
                props = {
                    resource = I.UIToolkit.texture('transparent'),
                    color = theme.Colors.BACKGROUND,
                    relativeSize = util.vector2(1, 1),
                }
            },
            {
                name = 'foreground',
                type = ui.TYPE.Flex,
                props = {
                    relativeSize = util.vector2(1, 1),
                },
                content = ui.content {
                    header,
                    body,
                }
            },
            pinButton
        },
        events = {},
        userData = {},
    }

    local window = ui.create(windowLayout)

    if draggable then
        data.dragging = false
        data.dragStartAbs = nil
        data.dragStartSize = nil
        data.dragStartPos = nil

        window.layout.events = {
            mousePress = async:callback(function(e, layout)
                if e.button ~= 1 then return end
                if data.dragType == nil then return end
                data.dragging = true
                data.dragStartAbs = e.position
                data.dragStartSize = layout.props.size
                data.dragStartPos = layout.props.position
                if data.dragType == DragType.Move then
                    ambient.playSound('menu click')
                end
            end),
            mouseMove = async:callback(function(e, layout)
                local minWidth = data.minSize.x
                local minHeight = data.minSize.y
                --userData.hadMouseMoveThisFrame = true
                I.UIToolkit.getCtx().lastMousePos = e.position
                if data.dragging and data.dragStartAbs and data.dragStartSize and data.dragStartPos then
                    local delta = e.position - data.dragStartAbs
                    local layerSize = ui.layers[ui.layers.indexOf('Windows')].size
                    local newSize = data.dragStartSize
                    local newPos = data.dragStartPos
                    local dX, dY, w, h
                    local resized = false

                    -- Horizontal resizing
                    if data.dragType == DragType.ResizeL or data.dragType == DragType.ResizeTL or data.dragType == DragType.ResizeBL then
                        local maxDeltaX = data.dragStartSize.x - minWidth
                        dX = util.clamp(delta.x, -data.dragStartPos.x, maxDeltaX)
                        newSize = util.vector2(data.dragStartSize.x - dX, newSize.y)
                        newPos = util.vector2(data.dragStartPos.x + dX, newPos.y)
                        resized = true
                    elseif data.dragType == DragType.ResizeR or data.dragType == DragType.ResizeTR or data.dragType == DragType.ResizeBR then
                        local maxWidth = layerSize.x - data.dragStartPos.x
                        w = util.clamp(data.dragStartSize.x + delta.x, minWidth, maxWidth)
                        newSize = util.vector2(w, newSize.y)
                        resized = true
                    end

                    -- Vertical resizing
                    if data.dragType == DragType.ResizeT or data.dragType == DragType.ResizeTL or data.dragType == DragType.ResizeTR then
                        local maxDeltaY = data.dragStartSize.y - minHeight
                        dY = util.clamp(delta.y, -data.dragStartPos.y, maxDeltaY)
                        newSize = util.vector2(newSize.x, data.dragStartSize.y - dY)
                        newPos = util.vector2(newPos.x, data.dragStartPos.y + dY)
                        resized = true
                    elseif data.dragType == DragType.ResizeB or data.dragType == DragType.ResizeBL or data.dragType == DragType.ResizeBR then
                        local maxHeight = layerSize.y - data.dragStartPos.y
                        h = util.clamp(data.dragStartSize.y + delta.y, minHeight, maxHeight)
                        newSize = util.vector2(newSize.x, h)
                        resized = true
                    end

                    -- Moving
                    if data.dragType == DragType.Move then
                        newPos = data.dragStartPos + delta
                        newPos = util.vector2(
                            util.clamp(newPos.x, 0, layerSize.x - newSize.x),
                            util.clamp(newPos.y, 0, layerSize.y - newSize.y)
                        )
                    end

                    layout.props.size = newSize
                    layout.props.position = newPos

                    window:update()

                    if resized then
                        header:update()
                        body:update()
                        if handler then handler:onResized(self:getInnerSize()) end
                    end
                end
            end),
            focusGain = async:callback(function()
                window.layout.userData.focusDelayed = true
            end),
            focusLoss = async:callback(function()
                window.layout.userData.focusDelayed = false
            end),
            mouseRelease = async:callback(function(e)
                if e.button ~= 1 then return end
                data.dragging = false
            end),
        }
    else
        window.layout.events = {
            mouseMove = async:callback(function(e)
                I.UIToolkit.getCtx().lastMousePos = e.position
            end),
        }
    end

    ---@param content openmw.ui.Content
    self.setContent = function(_, content)
        body.layout.content = content
        I.UIToolkit.queueUpdate(body)
    end

    self.getPosition = function(_)
        return window.layout.props.position
    end

    self.getSize = function(_)
        return window.layout.props.size
    end

    self.getInnerSize = function(_)
        local sz = window.layout.props.size
        local borders = 4 * BORDER_THICKNESS_THICK
        return util.vector2(sz.x - borders, sz.y - borders - HEADER_HEIGHT)
    end

    self.setTitle = function(_, newTitle)
        title.props.text = newTitle
        header:update()
    end

    self.isPinned = function()
        return data.pinned == true
    end

    self.setPinnable = function(_, pinnable)
        data.pinnable = pinnable
        if pinnable then
            pinButton.layout.props.visible = true
            pinButton:update()
        else
            pinButton.layout.props.visible = false
            pinButton:update()
        end
    end

    self.setMinSize = function(_, minSz)
        if data.minSize == minSz then return end
        data.minSize = minSz or MIN_SZ
        --TODO: update size if smaller?
    end

    Component.init(self, window)
end

return Window
