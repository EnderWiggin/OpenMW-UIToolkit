---@omw-context player|menu

local ui        = require('openmw.ui')
local util      = require('openmw.util')
local I         = require('openmw.interfaces')

local v2        = util.vector2
local Class     = require('scripts.UIToolkit.class')
local Component = require('scripts.UIToolkit.components.component')

local CHECKMARK = 'icons/UIToolkit/checkmark.dds'

---@class UIToolkit.Checkbox : UIToolkit.Component
local Checkbox  = Class(Component)

---@param opts UIToolkit.CheckboxOpts
function Checkbox:init(opts)
    local T = I.UIToolkit.Templates
    local theme = I.UIToolkit.getTheme()
    local boxSize = opts.boxSize or theme.Sizes.textNormal

    local default = opts.default
    if type(default) == 'function' then
        default = default()
    end
    self._value = default == true
    self._onValueChanged = opts.onValueChanged

    self._checkmarkProps = {
        resource = I.UIToolkit.texture(CHECKMARK),
        relativeSize = v2(1, 1),
        visible = self._value,
    }
    local accented = opts.accentedCheckmark == true
    local content = ui.content {
        {
            name = 'checkbox-box',
            template = T.border { style = 'thin' },
            props = { size = v2(boxSize, boxSize) },
            content = ui.content {
                {
                    name = 'checkbox-checkmark',
                    type = ui.TYPE.Image,
                    props = self._checkmarkProps,
                    userData = {
                        colorable = true,
                        baseColor = accented and theme.Colors.ACTIVE or nil,
                        hoverColor = accented and theme.Colors.ACTIVE_LIGHT or nil,
                        pressColor = accented and theme.Colors.ACTIVE_PRESSED or nil,
                    },
                },
            },
        },
    }

    if opts.text then
        content:add(T.intervalH(theme.Sizes.smallGap))
        content:add {
            name = 'checkbox-label',
            template = T.text(),
            props = {
                text = opts.text,
                textAlignV = ui.ALIGNMENT.Center,
            },
            userData = { colorable = true },
        }
    end

    local element = I.UIToolkit.Interactive.makeInteractive({
        tooltip = opts.tooltip,
        canClick = opts.canClick,
        onMouseMove = opts.onMouseMove,
        interactiveDisabled = opts.interactiveDisabled,
        onClick = function(e)
            self:setValue(not self._value)
            if self._onValueChanged then
                self._onValueChanged(self._value)
            end
            if opts.onClick then
                return opts.onClick(e)
            end
        end,
    }, {
        name = opts.name or 'checkbox',
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
            align = ui.ALIGNMENT.Center,
        },
        content = content,
    })

    Component.init(self, element)
end

---@return boolean
function Checkbox:getValue()
    return self._value
end

---@param value boolean
---@return UIToolkit.Checkbox self
function Checkbox:setValue(value)
    if self:isDestroyed() then return self end

    self._value = value == true
    self._checkmarkProps.visible = self._value
    I.UIToolkit.queueUpdate(self.element)
    return self
end

return Checkbox
