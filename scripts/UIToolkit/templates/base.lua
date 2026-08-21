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

--TODO: extract cache to separate file
local CACHE = {}

---@param arg any?
---@return string
local function getArgKey(arg)
    if type(arg) ~= 'table' then return tostring(arg) end
    local entries = {}
    for k, v in pairs(arg) do
        table.insert(entries, tostring(k) .. "=" .. tostring(v))
    end
    table.sort(entries)
    return '{' .. table.concat(entries, ",") .. '}'
end

---@return string
local function constructKey(key, ...)
    local n = select("#", ...)
    if n <= 0 then return key end
    local opts = { ... }
    local parts = { key }
    for i = 1, n do
        parts[#parts + 1] = getArgKey(opts[i])
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

--TODO: replace usage of these with new methods
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

local borderResources = {}
local borderPieces = {}
for _, thickness in ipairs { 'thin', 'thick' } do
    borderResources[thickness] = {}
    for k in pairs(sideParts) do
        borderResources[thickness][k] = ui.texture { path = borderSidePattern:format(thickness, k) }
    end
    for k in pairs(cornerParts) do
        borderResources[thickness][k] = ui.texture { path = borderCornerPattern:format(thickness, k) }
    end

    borderPieces[thickness] = {}
    for k in pairs(sideParts) do
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
    for k in pairs(cornerParts) do
        borderPieces[thickness][k] = {
            type = ui.TYPE.Image,
            props = {
                resource = borderResources[thickness][k],
            },
        }
    end
end

---@class UIToolkit.Templates._BoxOpts
---@field thickness 'thin' | 'thick'
---@field padding number
---@field background? number no background if omitted.

---@param opts UIToolkit.Templates.BoxOpts?
---@return UIToolkit.Templates._BoxOpts?
local function _processBoxOpts(opts)
    local thickness = opts and opts.thickness or 'thin'
    local padding = opts and opts.padding or 0
    local bg = opts and opts.background
    if bg and type(bg) ~= 'number' then
        if bg 'solid' then
            bg = 1
        elseif bg 'transparent' then
            ---@diagnostic disable-next-line: undefined-field
            bg = ui._getMenuTransparency and ui._getMenuTransparency() or 0.5
        else
            bg = nil
        end
    end
    ---@type UIToolkit.Templates._BoxOpts
    return {
        thickness = thickness,
        padding = padding,
        background = bg --[[@as number?]]
    }
end

--#region Borders

---@param opts UIToolkit.Templates._BoxOpts
---@return openmw.ui.Template
local function border(opts)
    local theme = I.UIToolkit.getTheme()
    local thickness = opts.thickness
    local background = opts.background

    local borderSize = thickness == 'thick' and theme.Sizes.thickBorder or theme.Sizes.border
    local borderV = v2(1, 1) * borderSize
    local padV = v2(1, 1) * opts.padding

    local result = {
        content = ui.content {},
    }

    if background then
        result.content:add {
            type = ui.TYPE.Image,
            props = {
                resource = theme.Colors.whiteTexture,
                color = theme.Colors.BACKGROUND,
                alpha = background,
                relativeSize = v2(1, 1),
            },
        }
    end

    for k, v in pairs(sideParts) do
        local horizontal = k == 'top' or k == 'bottom'
        local direction = horizontal and v2(1, 0) or v2(0, 1)
        result.content:add {
            template = borderPieces[thickness][k],
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
            template = borderPieces[thickness][k],
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
            position = borderV + padV,
            size = (borderV + padV) * -2,
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
    local padding = opts.padding
    local borderSize = thickness == 'thick' and theme.Sizes.thickBorder or theme.Sizes.border
    local borderV = v2(1, 1) * borderSize
    local padV = v2(1, 1) * padding

    local result = {
        type = ui.TYPE.Container,
        content = ui.content {},
    }

    if background then
        result.content:add {
            type = ui.TYPE.Image,
            props = {
                resource = theme.Colors.whiteTexture,
                color = theme.Colors.BACKGROUND,
                alpha = background,
                relativeSize = v2(1, 1),
            },
        }
    end

    for k, v in pairs(sideParts) do
        local horizontal = k == 'top' or k == 'bottom'
        local direction = horizontal and v2(1, 0) or v2(0, 1)
        local edge = k == 'bottom' or k == 'right'
        result.content:add {
            template = borderPieces[thickness][k],
            props = {
                position = (direction + v) * borderSize + v * (edge and 2 * padding or -padding),
                relativePosition = v,
                size = (v2(1, 1) - direction) * borderSize + direction * padding * 2,
                relativeSize = direction,
            }
        }
    end
    for k, v in pairs(cornerParts) do
        result.content:add {
            template = borderPieces[thickness][k],
            props = {
                position = v * (borderSize + 2 * padding),
                relativePosition = v,
                size = borderV,
            },
        }
    end
    result.content:add {
        external = { slot = true },
        props = {
            position = borderV + padV,
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

--- BUTTON TEMPLATES ---
--TODO: try making use of code for borders and boxes

local buttonBorderSize = 4

local buttonBorderSidePattern = 'textures/menu_button_frame_%s.dds'
local buttonBorderCornerPattern = 'textures/menu_button_frame_%s_corner.dds'

local buttonBorderResources = {}
local buttonBorderPieces = {}

for k in pairs(sideParts) do
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

for k in pairs(cornerParts) do
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
    for k, v in pairs(sideParts) do
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
    for k, v in pairs(cornerParts) do
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
    for k, v in pairs(sideParts) do
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
    for k, v in pairs(cornerParts) do
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
