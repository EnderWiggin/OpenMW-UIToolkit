---@omw-context player|menu

local ui   = require 'openmw.ui'
local util = require 'openmw.util'
local I    = require 'openmw.interfaces'


local v2        = util.vector2
local H         = require('scripts.UIToolkit.helpers')
local Class     = require('scripts.UIToolkit.class')
local Component = require('scripts.UIToolkit.components.component')


---@class UIToolkit.ProgressBarPrivate : UIToolkit.ProgressBar
---@field new fun(self:UIToolkit.ProgressBar):UIToolkit.ProgressBarPrivate
local ProgressBar = Class(Component)


local function getProgress(value, max)
    if max <= 0 then return 1 end
    if value <= 0 then return 0 end
    return value / max
end

---@param opts UIToolkit.ProgressBarOpts
function ProgressBar:init(opts)
    local theme = I.UIToolkit.getTheme()
    local T = I.UIToolkit.Templates
    local border = T.getBorderSize('thin')

    local textSize = opts.textSize or theme.Sizes.textNormal
    local color = opts.color or theme.Colors.HEALTH

    self.textStyle = opts.textStyle or 'full'
    self.max = opts.max or 100
    self.value = opts.value or 0

    self._barProps = {
        relativeSize = v2(getProgress(self.value, self.max), 1),
        resource = theme.Colors.menuBarGray,
        color = color,
    }

    self._textProps = {
        text = self:getText(),
        textShadow = true,
        textAlignH = ui.ALIGNMENT.Center,
        textAlignV = ui.ALIGNMENT.Center,
        -- relativePosition + anchor would have been simpler, but text coming out of
        -- text widgets are slightly misaligned and need to be manually raised 2 pixels
        autoSize = false,
        relativeSize = v2(1, 1),
        position = v2(0, -1),
        visible = self.textStyle ~= 'none',
    }

    Component:init(I.UIToolkit.Interactive.makeInteractive(opts, {
        template = T.border { style = 'thin' },
        props = {
            size = v2(100 + 2 * border, textSize + 2 * (border + theme.Sizes.padding))
        },
        content = ui.content { {
            type = ui.TYPE.Widget,
            props = {
                relativeSize = v2(1, 1),
            },
            content = ui.content {
                {
                    template = T.text(),
                    props = self._textProps,
                    userData = { colorable = true },
                },
                {
                    type = ui.TYPE.Image,
                    props = self._barProps,
                },
            },
        } }
    }))
end

function ProgressBar:getMax()
    return self.max
end

function ProgressBar:getValue()
    return self.value
end

function ProgressBar:setMax(max)
    self.max = math.max(0, max)
    self.value = util.clamp(self.value, 0, self.max)
    self:update()
end

function ProgressBar:setValue(value)
    self.value = util.clamp(value, 0, self.max)
    self:update()
end

function ProgressBar:getText()
    if self.textStyle == 'none' then return '' end
    if self.textStyle == 'value' then return H.addSeparators(self.value) end
    return string.format('%s/%s', H.addSeparators(self.value), H.addSeparators(self.max))
end

function ProgressBar:update()
    self._barProps.relativeSize = v2(getProgress(self.value, self.max), 1)
    self._textProps.text = self:getText()
    I.UIToolkit.queueUpdate(self.element)
end

return ProgressBar
