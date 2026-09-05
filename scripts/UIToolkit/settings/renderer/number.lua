---@omw-context menu

local ui   = require 'openmw.ui'
local util = require 'openmw.util'
local I    = require 'openmw.interfaces'


local TEXT_WIDTH = 100

--TODO: implement `disabled` option

---@param value number
---@param set fun(value:number)
---@param args UIToolkit.SettingRenderer.Slider
return function(value, set, args)
    local min = args.min
    local max = args.max
    local isInteger = args.integer

    local hasDefault = args.default ~= nil
    local edit = I.UIToolkit.Components.textEdit {
        default = args.default,
        width = TEXT_WIDTH,
        textAlignH = ui.ALIGNMENT.Start,
        showClearButton = hasDefault,
        validate = function(text)
            local number = tonumber(text)
            if not number then
                return false, nil
            else
                if min and number < min then number = min end
                if max and number > max then number = max end
                if isInteger then
                    number = util.round(number)
                end
                return true, number
            end
        end,
        onValueChanged = set,
    }

    edit:setValue(value)

    return edit.element
end
