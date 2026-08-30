---@omw-context player

local ui = require('openmw.ui')
local util = require('openmw.util')
local I = require('openmw.interfaces')

local v2 = util.vector2
local H = require('scripts.UIToolkit.helpers')

local M = {}

--TODO: extract cache to separate file
local CACHE = {}

---@return string
local function constructKey(key, ...)
    local n = select("#", ...)
    if n <= 0 then return key end
    local opts = { ... }
    local parts = { key }
    for i = 1, n do
        parts[#parts + 1] = H.toStringDeep(opts[i])
    end
    return table.concat(parts, '|')
end

---@generic T : any
---@param key string
---@param calc fun(...):T
---@return T
local function GetCachedOrCalculate(key, calc, ...)
    key = constructKey(key, ...)
    if not CACHE[key] then
        local val = calc(...)
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

---@param effectId string
---@param sz number
---@return openmw.ui.Layout
function M.effectIcon(effectId, sz)
    local layout = {
        type = ui.TYPE.Image,
        props = {
            size = v2(1, 1) * sz,
            resource = M.effectIconTexture(effectId),
        },
    }
    return layout
end

local sideParts = {
    left = v2(0, 0),
    right = v2(1, 0),
    top = v2(0, 0),
    bottom = v2(0, 1),
}
local cornerParts = {
    top_left = v2(0, 0),
    top_right = v2(1, 0),
    bottom_left = v2(0, 1),
    bottom_right = v2(1, 1),
}

local borderSidePattern = 'textures/menu_%s_border_%s.dds'
local borderCornerPattern = 'textures/menu_%s_border_%s_corner.dds'
local buttonBorderSidePattern = 'textures/menu_button_frame_%s.dds'
local buttonBorderCornerPattern = 'textures/menu_button_frame_%s_corner.dds'

local borderResources = {}

for _, thickness in ipairs { 'thin', 'thick' } do
    borderResources[thickness] = {}
    for k in pairs(sideParts) do
        borderResources[thickness][k] = ui.texture { path = borderSidePattern:format(thickness, k) }
    end
    for k in pairs(cornerParts) do
        borderResources[thickness][k] = ui.texture { path = borderCornerPattern:format(thickness, k) }
    end
end

local buttonBorderResources = {}
borderResources['button'] = buttonBorderResources
for k in pairs(sideParts) do
    buttonBorderResources[k] = ui.texture { path = buttonBorderSidePattern:format(k) }
end

for k in pairs(cornerParts) do
    buttonBorderResources[k] = ui.texture { path = buttonBorderCornerPattern:format(k) }
end

---@param thickness UIToolkit.Thickness
---@return table<string,openmw.ui.Layout>
local function _borderPieces(thickness)
    local pieces = {}
    for k in pairs(sideParts) do
        local horizontal = k == 'top' or k == 'bottom'
        pieces[k] = {
            type = ui.TYPE.Image,
            props = {
                resource = borderResources[thickness][k],
                tileH = horizontal,
                tileV = not horizontal,
            },
        }
    end
    for k in pairs(cornerParts) do
        pieces[k] = {
            type = ui.TYPE.Image,
            props = {
                resource = borderResources[thickness][k],
            },
        }
    end
    return pieces
end

---@param thickness UIToolkit.Thickness
---@return table<string,openmw.ui.Layout>
local function borderPieces(thickness)
    return GetCachedOrCalculate('borderPieces', _borderPieces, thickness)
end

---@param thickness UIToolkit.Thickness
---@return number
function M.getBorderSize(thickness)
    local sizes = I.UIToolkit.getTheme().Sizes
    return (not thickness or thickness == 'thin') and sizes.border or sizes.thickBorder
end

---@class UIToolkit.Templates._BoxOpts
---@field thickness UIToolkit.Thickness
---@field borderSize number
---@field padding openmw.util.Vector2
---@field background? {alpha: number, color:openmw.util.Color}

---@param opts UIToolkit.Templates.BoxOpts?
---@return UIToolkit.Templates._BoxOpts?
local function _processBoxOpts(opts)
    local theme = I.UIToolkit.getTheme()
    local thickness = opts and opts.thickness or 'thin'
    local padding = opts and opts.padding or 0
    local bg = opts and opts.background

    local alpha, color

    if type(bg) == 'table' then
        alpha = bg and bg.opacity
        color = bg and bg.color
    else
        alpha = bg
    end

    if alpha and type(alpha) ~= 'number' then
        if alpha == 'solid' then
            alpha = 1
        elseif alpha == 'transparent' then
            ---@diagnostic disable-next-line: undefined-field
            alpha = ui._getMenuTransparency and ui._getMenuTransparency() or 0.5
        else
            alpha = nil
        end
    end
    ---@cast alpha number|nil

    local background
    if alpha and alpha > 0 then
        background = {
            alpha = alpha,
            color = color or theme.Colors.BACKGROUND,
        }
    end

    if type(padding) == "number" then
        padding = v2(1, 1) * padding
    end
    ---@type UIToolkit.Templates._BoxOpts
    return {
        thickness = thickness,
        borderSize = thickness == 'thin' and theme.Sizes.border or theme.Sizes.thickBorder,
        padding = padding --[[@as openmw.util.Vector2]],
        background = background,
    }
end

--#region Borders

---@param opts UIToolkit.Templates._BoxOpts
---@return openmw.ui.Template
local function border(opts)
    local theme = I.UIToolkit.getTheme()
    local thickness = opts.thickness
    local background = opts.background

    local borderSize = opts.borderSize
    local borderV = v2(1, 1) * borderSize
    local padding = opts.padding

    local result = {
        content = ui.content {},
    }

    if background then
        result.content:add {
            type = ui.TYPE.Image,
            props = {
                resource = theme.Colors.whiteTexture,
                color = background.color,
                alpha = background.alpha,
                relativeSize = v2(1, 1),
            },
        }
    end

    local pieces = borderPieces(thickness)
    for k, v in pairs(sideParts) do
        local horizontal = k == 'top' or k == 'bottom'
        local direction = horizontal and v2(1, 0) or v2(0, 1)
        result.content:add {
            template = pieces[k],
            props = {
                position = (direction - v) * borderSize,
                relativePosition = v,
                size = (v2(1, 1) - direction * 3) * borderSize,
                relativeSize = direction,
            }
        }
    end
    for k, v in pairs(cornerParts) do
        result.content:add {
            template = pieces[k],
            props = {
                position = -v * borderSize,
                relativePosition = v,
                size = borderV,
            },
        }
    end
    result.content:add {
        external = { slot = true },
        props = {
            position = borderV + padding,
            size = (borderV + padding) * -2,
            relativeSize = v2(1, 1),
        }
    }

    return result
end

---@param opts UIToolkit.Templates.BoxOpts
---@return openmw.ui.Template
function M.border(opts)
    return GetCachedOrCalculate('border', border, _processBoxOpts(opts))
end

--#endregion Borders

--#region Boxes

---@param opts UIToolkit.Templates._BoxOpts
---@return openmw.ui.Template
local function box(opts)
    local theme = I.UIToolkit.getTheme()
    local thickness = opts.thickness
    local background = opts.background
    local borderSize = opts.borderSize
    local borderV = v2(1, 1) * borderSize
    local padding = opts.padding

    local result = {
        type = ui.TYPE.Container,
        content = ui.content {},
    }

    if background then
        result.content:add {
            type = ui.TYPE.Image,
            props = {
                resource = theme.Colors.whiteTexture,
                color = background.color,
                alpha = background.alpha,
                size = (padding + borderV) * 2,
                relativeSize = v2(1, 1),
            },
        }
    end

    local pieces = borderPieces(thickness)
    for k, v in pairs(sideParts) do
        local horizontal = k == 'top' or k == 'bottom'
        local direction = horizontal and v2(1, 0) or v2(0, 1)
        local edge = k == 'bottom' or k == 'right'
        result.content:add {
            template = pieces[k],
            props = {
                position = (direction + v) * borderSize + v:emul(padding * (edge and 2 or -1)),
                relativePosition = v,
                size = (v2(1, 1) - direction) * borderSize + direction:emul(padding) * 2,
                relativeSize = direction,
            }
        }
    end
    for k, v in pairs(cornerParts) do
        result.content:add {
            template = pieces[k],
            props = {
                position = v * borderSize + v:emul(padding) * 2,
                relativePosition = v,
                size = borderV,
            },
        }
    end
    result.content:add {
        external = { slot = true },
        props = {
            position = borderV + padding,
            relativeSize = v2(1, 1),
        }
    }

    return result
end

---@param opts UIToolkit.Templates.BoxOpts
---@return openmw.ui.Template
function M.box(opts)
    return GetCachedOrCalculate('box', box, _processBoxOpts(opts))
end

--#endregion Boxes

---@cast M UIToolkit.Templates
return M
