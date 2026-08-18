---@omw-context player

local ui = require('openmw.ui')
local auxUi = require('openmw_aux.ui')
local util = require('openmw.util')
local I = require('openmw.interfaces')

local v2 = util.vector2
local H = require('scripts.UIToolkit.helpers')

local Theme = require('scripts.UIToolkit.themes.theme')

local th = Theme:new()
local sizes = th.Sizes
local colors = th.Colors

local M = {}

local CACHE = {}

---@generic T : any
---@param key string
---@param calc fun():T
---@return T
local function GetCachedOrCalculate(key, calc)
    if not CACHE[key] then
        local val = calc()
        CACHE[key] = val
        return val
    end
    return CACHE[key]
end

local function text()
    local theme = I.UIToolkit.getTheme()
    return {
        type = ui.TYPE.Text,
        props = {
            textColor = theme.Colors.DEFAULT,
            textSize = theme.Sizes.textNormal,
        },
    }
end

---@return openmw.ui.Template
function M.text()
    return GetCachedOrCalculate('text', text)
end

local function header()
    local theme = I.UIToolkit.getTheme()
    return {
        type = ui.TYPE.Text,
        props = {
            textColor = theme.Colors.HEADER,
            textSize = theme.Sizes.textHeader,
        },
    }
end

---@return openmw.ui.Template
function M.header()
    return GetCachedOrCalculate('header', header)
end

local function paragraph()
    local theme = I.UIToolkit.getTheme()
    return {
        type = ui.TYPE.TextEdit,
        props = {
            textSize = theme.Sizes.textNormal,
            textColor = theme.Colors.DEFAULT,
            autoSize = true,
            readOnly = true,
            multiline = true,
            wordWrap = true,
            size = v2(100, 0),
        },
    }
end

---@return openmw.ui.Template
function M.paragraph()
    return GetCachedOrCalculate('paragraph', paragraph)
end

local function editLine()
    local theme = I.UIToolkit.getTheme()
    return {
        type = ui.TYPE.TextEdit,
        props = {
            size = util.vector2(150, 0),
            autoSize = true,
            textSize = theme.Sizes.textNormal,
            textColor = theme.Colors.DEFAULT,
            multiline = false,
        },
    }
end

---@return openmw.ui.Template
function M.editLine()
    return GetCachedOrCalculate('editLine', editLine)
end

local function editBox()
    local theme = I.UIToolkit.getTheme()
    return {
        type = ui.TYPE.TextEdit,
        props = {
            size = util.vector2(150, 5 * theme.Sizes.textNormal),
            textSize = theme.Sizes.textNormal,
            textColor = theme.Colors.DEFAULT,
            multiline = true,
            wordWrap = true,
        },
    }
end

---@return openmw.ui.Template
function M.editBox()
    return GetCachedOrCalculate('editBox', editBox)
end

M.textNormal = H.deepCopy(I.MWUI.templates.textNormal)
M.textNormal.props.textColor = colors.DEFAULT
M.textNormal.props.textSize = sizes.textNormal

M.textHeader = H.deepCopy(I.MWUI.templates.textHeader)
M.textHeader.props.textColor = colors.DEFAULT_LIGHT
M.textHeader.props.textSize = sizes.textNormal

M.textParagraph = H.deepCopy(I.MWUI.templates.textParagraph)
M.textParagraph.props.textColor = colors.DEFAULT
M.textParagraph.props.textSize = sizes.textNormal

M.textEditLine = H.deepCopy(I.MWUI.templates.textEditLine)
M.textEditLine.props.textColor = colors.DEFAULT
M.textEditLine.props.textSize = sizes.textNormal
M.textEditLine.props.size = v2(0, 0)

M.boxSolid = auxUi.deepLayoutCopy(I.MWUI.templates.boxSolid) --[[@as openmw.ui.Template]]
M.boxSolidThick = auxUi.deepLayoutCopy(I.MWUI.templates.boxSolidThick) --[[@as openmw.ui.Template]]
M.boxSolid.content[1].props.color = colors.BACKGROUND
M.boxSolidThick.content[1].props.color = colors.BACKGROUND

---@param padX number
---@param padY number?
---@return openmw.ui.Template
function M.padding(padX, padY)
    local size = v2(padX, padY or padX)
    return {
        type = ui.TYPE.Container,
        content = ui.content {
            {
                props = {
                    size = size,
                },
            },
            {
                external = { slot = true },
                props = {
                    position = size,
                    relativeSize = v2(1, 1),
                },
            },
            {
                props = {
                    position = size,
                    relativePosition = v2(1, 1),
                    size = size,
                },
            },
        }
    }
end

---@return openmw.ui.Layout
function M.intervalH(size)
    return { props = { size = v2(size, 0), }, }
end

---@return openmw.ui.Layout
function M.intervalV(size)
    return { props = { size = v2(0, size), }, }
end

function M.effectIconTexture(effectId)
    local effectRecord = H.getMagicEffectRecord(effectId)
    return effectRecord and I.UIToolkit.texture(effectRecord.icon)
end

--- BUTTON TEMPLATES ---

local buttonBorderSize = 4
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

local buttonBorderSidePattern = 'textures/menu_button_frame_%s.dds'
local buttonBorderCornerPattern = 'textures/menu_button_frame_%s_corner.dds'

local buttonBorderResources = {}
local buttonBorderPieces = {}

for k in pairs(borderSideParts) do
    buttonBorderResources[k] = ui.texture { path = buttonBorderSidePattern:format(k) }
    local horizontal = (k == 'top' or k == 'bottom')
    buttonBorderPieces[k] = {
        type = ui.TYPE.Image,
        props = {
            resource = buttonBorderResources[k],
            tileH = horizontal,
            tileV = not horizontal,
        }
    }
end

for k in pairs(borderCornerParts) do
    buttonBorderResources[k] = ui.texture { path = buttonBorderCornerPattern:format(k) }
    buttonBorderPieces[k] = {
        type = ui.TYPE.Image,
        props = {
            resource = buttonBorderResources[k],
        }
    }
end

---@param borderSize number
---@return openmw.ui.Template
function M.buttonBorders(borderSize)
    local btnBorderSz = borderSize or buttonBorderSize
    local template = {
        content = ui.content {},
    }
    for k, v in pairs(borderSideParts) do
        local horizontal = (k == 'top' or k == 'bottom')
        local direction = horizontal and v2(1, 0) or v2(0, 1)
        template.content:add {
            template = buttonBorderPieces[k],
            props = {
                position = (direction - v) * btnBorderSz,
                relativePosition = v,
                size = (v2(1, 1) - direction * 3) * btnBorderSz,
                relativeSize = direction,
            }
        }
    end
    for k, v in pairs(borderCornerParts) do
        template.content:add {
            template = buttonBorderPieces[k],
            props = {
                position = -v * btnBorderSz,
                relativePosition = v,
                size = v2(btnBorderSz, btnBorderSz),
            }
        }
    end
    template.content:add {
        external = { slot = true },
        props = {
            position = v2(btnBorderSz, btnBorderSz),
            size = v2(btnBorderSz * -2, btnBorderSz * -2),
            relativeSize = v2(1, 1),
        }
    }
    return template
end

---@return openmw.ui.Template
function M.buttonBox()
    local template = {
        type = ui.TYPE.Container,
        content = ui.content {},
    }
    local broderSz = buttonBorderSize
    for k, v in pairs(borderSideParts) do
        local horizontal = (k == 'top' or k == 'bottom')
        local direction = horizontal and v2(1, 0) or v2(0, 1)
        template.content:add {
            template = buttonBorderPieces[k],
            props = {
                position = (direction + v) * broderSz,
                relativePosition = v,
                size = (v2(1, 1) - direction) * broderSz,
                relativeSize = direction,
            }
        }
    end
    for k, v in pairs(borderCornerParts) do
        template.content:add {
            template = buttonBorderPieces[k],
            props = {
                position = v * broderSz,
                relativePosition = v,
                size = v2(broderSz, broderSz),
            }
        }
    end
    template.content:add {
        external = { slot = true },
        props = {
            position = v2(broderSz, broderSz),
            relativeSize = v2(1, 1),
        }
    }
    return template
end

---@param bgrAlpha number
---@return openmw.ui.Template
function M.buttonBoxBgr(bgrAlpha)
    local theme = I.UIToolkit.getTheme()
    local template = M.buttonBox()
    template.content:insert(1, {
        name = 'button-background',
        type = ui.TYPE.Image,
        props = {
            resource = theme.Colors.whiteTexture,
            color = theme.Colors.BACKGROUND,
            alpha = bgrAlpha,
            relativeSize = v2(1, 1),
            size = v2(buttonBorderSize * 2, buttonBorderSize * 2),
        }
    })
    return template
end

------------------------

---@cast M UIToolkit.Templates
return M
