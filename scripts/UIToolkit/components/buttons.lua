---@omw-context player

local ui = require('openmw.ui')
local util = require('openmw.util')
local auxUi = require('openmw_aux.ui')
local async = require('openmw.async')
local ambient = require('openmw.ambient')
local I = require('openmw.interfaces')

local v2 = util.vector2

local Class = require('scripts.UIToolkit.class')
local Component = require('scripts.UIToolkit.components.component')
local M = {}

local T = {
    Base = require('scripts.UIToolkit.templates.base'),
}

---@class UIToolkit.TextButton : UIToolkit.Component
local TextButton = Class(Component)

---@param opts UIToolkit.TextButtonOpts
function TextButton:init(opts)
    local txt = {
        template = T.Base.text(),
        props = { text = opts.text, },
        userData = { colorable = true },
    }

    local content
    if opts.width then
        txt.props.anchor = v2(0.5, 0.5)
        txt.props.relativePosition = v2(0.5, 0.5)
        content = {
            props = {
                size = v2(opts.width, txt.template.props.textSize),
            },
            content = ui.content { txt, }
        }
    else
        content = {
            template = T.Base.padding(8, 0),
            content = ui.content { txt, }
        }
    end

    local element = I.UIToolkit.Interactive.makeInteractive(opts, {
        name = opts.name or 'button',
        template = T.Base.buttonBoxBgr(opts.bgrAlpha),
        props = {},
        content = ui.content { content },
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
    local btn = TextButton.new()
    btn:init(opts)
    return btn
end

return M
