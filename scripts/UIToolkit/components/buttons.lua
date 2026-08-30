---@omw-context player

local ui = require('openmw.ui')
local util = require('openmw.util')
local I = require('openmw.interfaces')

local v2 = util.vector2

local Class = require('scripts.UIToolkit.class')
local Component = require('scripts.UIToolkit.components.component')
local M = {}

---@class UIToolkit.TextButton : UIToolkit.Component
local TextButton = Class(Component)

---@param opts UIToolkit.TextButtonOpts
function TextButton:init(opts)
    local T = I.UIToolkit.Templates
    local txt = {
        template = T.text(),
        props = { text = opts.text, },
        userData = { colorable = true },
    }
    local thickness = opts.thickness or 'button'
    local padding
    if opts.width then
        txt.props.size = v2(opts.width - 2 * T.getBorderSize(thickness), txt.template.props.textSize)
        txt.props.autoSize = false
        txt.props.textAlignH = ui.ALIGNMENT.Center
    else
        padding = v2(8, 0)
    end

    local box = T.box {
        thickness = thickness,
        background = opts.background or 'solid',
        padding = padding,
    }

    local element = I.UIToolkit.Interactive.makeInteractive(opts, {
        name = opts.name or 'button',
        template = box,
        props = {},
        content = ui.content { txt },
        events = {},
        userData = {},
    })

    self._txt = txt
    Component.init(self, element)
end

function TextButton:setText(text)
    self._txt.props.text = text
    I.UIToolkit.queueUpdate(self.element)
end

---@param opts UIToolkit.TextButtonOpts
---@return UIToolkit.TextButton
function M.textButton(opts)
    local btn = TextButton:new()
    btn:init(opts)
    return btn
end

return M
