---@omw-context player

local core = require('openmw.core')
local ui = require('openmw.ui')
local util = require('openmw.util')
local I = require('openmw.interfaces')

local H = require('scripts.UIToolkit.helpers')
local C = require('scripts.UIToolkit.constants')

local v2 = util.vector2
local hasGapAPI = C.API.GAP

local Component = require('scripts.UIToolkit.components.component')

local M = {}
local POPUP_LAYER = 'UIToolkit:Popups'

if not ui.layers.indexOf(POPUP_LAYER) then
    ui.layers.insertAfter('Windows', POPUP_LAYER, { interactive = true })
end

---@type openmw.ui.Element[]
local popups = {}

local placeholder = {
    name = 'popup-holder',
    props = {
        relativeSize = v2(1, 1),
    },
}

local modals = Component:new()

modals:init(ui.create {
    name = POPUP_LAYER,
    layer = POPUP_LAYER,
    props = {
        relativeSize = v2(1, 1),
        visible = false,
    },
    content = ui.content {
        {
            name = 'modal-background',
            type = ui.TYPE.Image,
            props = {
                relativeSize = v2(1, 1),
                resource = ui.texture { path = 'white' },
                color = util.color.rgb(0, 0, 0),
                alpha = 0.35,
            },
        },
        placeholder,
    }
})

local function resetContext()
    I.UIToolkit.getCtx().focusedScrollable = nil
    I.UTKTooltips.setTooltip(nil)
end

local MODE = 'Interface'
local wasOn = false;

local function checkUIMode(on, changed)
    if on then
        if changed then wasOn = I.UI.getMode() ~= nil end
        if I.UI.getMode() == nil then
            I.UI.addMode(MODE, { windows = {} })
        end
    else
        if not wasOn then
            I.UI.removeMode(MODE)
        end
    end
end

local function closePopup(element)
    resetContext()
    I.UIToolkit.queueDestroy(element, true)
    H.removeFromArray(popups, element)
    if #popups == 0 then
        placeholder.content = nil
        modals:setVisible(false)
        checkUIMode(false)
    else
        placeholder.content = ui.content { popups[#popups] }
        modals:setVisible(true)
        checkUIMode(true, false)
    end
end

---@param opts UIToolkit.PopupOpts
---@return fun() close function that closes this popup
function M.show(opts)
    local hadPopups = M.hasActivePopup()
    resetContext()
    local T = I.UIToolkit.Templates
    local GAP = 10

    local element

    local buttons = {}
    if opts.buttons then
        for i = 1, #opts.buttons do
            local button = opts.buttons[i]
            if not hasGapAPI and i > 1 then
                buttons[#buttons + 1] = T.intervalH(GAP)
            end
            buttons[#buttons + 1] = I.UIToolkit.Components.textButton {
                name = 'button-' .. i,
                text = button.text,
                style = button.style or 'button',
                tooltip = button.tooltip,
                onClick = function()
                    if button.onClicked then button.onClicked() end
                    if not button.noClose then closePopup(element) end
                end }.element
        end
    end

    local content = {}

    if opts.title then
        content[#content + 1] = {
            name = 'popup-title',
            template = T.header(),
            props = {
                text = opts.title,
                textAlignH = ui.ALIGNMENT.Center,
            },
        }
    end

    local body = opts.body
    if body then
        if not hasGapAPI and #content > 0 then
            content[#content + 1] = T.intervalV(GAP)
        end
        if type(body) == 'string' then
            content[#content + 1] = {
                name = 'popup-body',
                template = T.paragraph(),
                props = {
                    text = opts.body,
                    relativeSize = v2(1, 0),
                    size = v2(300, 0),
                    textAlignH = ui.ALIGNMENT.Center,
                    textAlignV = ui.ALIGNMENT.Center,
                },
                external = { stretch = 1 }
            }
        elseif body.element then --this is Component
            content[#content + 1] = body.element
        else                     --this is Element or Layout
            content[#content + 1] = body
        end
    end

    if #buttons > 0 then
        if not hasGapAPI and #content > 0 then
            content[#content + 1] = T.intervalV(GAP)
        end
        content[#content + 1] = {
            name = 'buttons-flex',
            type = ui.TYPE.Flex,
            props = {
                gap = hasGapAPI and GAP or nil,
                horizontal = true,
                arrange = ui.ALIGNMENT.Center,
            },
            content = ui.content(buttons),
        }
    end

    if #content == 0 then
        return function() end
    end

    element = ui.create {
        name = 'popup-box',
        template = I.UIToolkit.Templates.box { padding = 5, background = 'transparent', style = opts.borderStyle or 'thick' },
        props = {
            anchor = v2(0.5, 0.5),
            relativePosition = v2(0.5, 0.5),
        },
        content = ui.content { {
            name = 'content-flex',
            type = ui.TYPE.Flex,
            props = {
                gap = hasGapAPI and GAP or nil,
                align = ui.ALIGNMENT.Center,
                arrange = ui.ALIGNMENT.Center,
            },
            external = { stretch = 1 },
            content = ui.content(content),
        } },
    }
    popups[#popups + 1] = element
    placeholder.content = ui.content { element }
    modals:setVisible(true)

    checkUIMode(true, not hadPopups)
    return function() closePopup(element) end
end

function M.hasActivePopup()
    return #popups > 0
end

return M
