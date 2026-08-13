---@omw-context player

local ui = require('openmw.ui')
local util = require('openmw.util')
local auxUi = require('openmw_aux.ui')
local async = require('openmw.async')
local ambient = require('openmw.ambient')
local I = require('openmw.interfaces')

local v2 = util.vector2

local M = {}

local T = {
    Base = require('scripts.UIToolkit.templates.base'),
    Interactive = require('scripts.UIToolkit.templates.interactive'),
}

---@param opts UIToolkit.TextButtonOpts
---@return UIToolkit.TextButton
function M.textButton(opts)
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

    local element = ui.create {
        name = opts.name or 'button',
        template = T.Base.buttonBoxBgr(opts.bgrAlpha),
        props = {},
        content = ui.content { content },
        events = {},
        userData = {},
    }

    T.Interactive.interactive(opts, element)

    ---@type UIToolkit.TextButton
    local component = {
        element = element,
        setText = function(text)
            txt.props.text = text
            I.UIToolkit.queueUpdate(element)
        end
    }

    return component
end

return M
