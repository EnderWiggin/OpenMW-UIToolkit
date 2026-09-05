---@omw-context menu

local ui   = require 'openmw.ui'
local util = require 'openmw.util'
local I    = require 'openmw.interfaces'


local LENGTH     = 250
local BAR_WIDTH  = 20
local TEXT_WIDTH = 90

--TODO: implement `disabled` option

---@param value number
---@param set fun(value:number)
---@param args UIToolkit.SettingRenderer.Slider
return function(value, set, args)
    local min = args.min
    local max = args.max
    local isInteger = args.integer

    local range = max - min
    local step = args.step or (isInteger and 1 or 0.1)
    local maxScroll = util.round(10000 * range)
    step = maxScroll * step / range

    ---@param p number
    ---@return number
    local function progressToValue(p)
        local v = min + p * range
        if args.integer then
            return util.round(v)
        end
        return v
    end

    ---@param v number
    ---@return number
    local function valueToProgress(v)
        return (v - min) / range
    end

    local slider
    local edit

    local function sliderValueChanged(_, progress)
        local v = progressToValue(progress)
        edit:setValue(v)
        if slider.isDragging then return end
        set(v)
    end

    slider = I.UIToolkit.Components.scrollBar {
        length = LENGTH,
        maxScroll = maxScroll,
        width = BAR_WIDTH,
        scrollStep = step,
        horizontal = true,
        onScroll = sliderValueChanged,
        onDragStopped = sliderValueChanged,
    }

    local hasDefault = args.default ~= nil
    edit = I.UIToolkit.Components.textEdit {
        default = args.default,
        width = TEXT_WIDTH,
        textAlignH = ui.ALIGNMENT.Start,
        showClearButton = hasDefault,
        validate = function(text)
            local number = tonumber(text)
            if not number then
                return false, nil
            else
                local v = util.clamp(number, min, max)
                if isInteger then
                    v = util.round(v)
                end
                return true, v
            end
        end,
        onValueChanged = function(v)
            set(v)
            slider:setProgress(valueToProgress(v), true)
        end
    }

    slider:setProgress(valueToProgress(value), true)
    edit:setValue(value)

    return {
        type = ui.TYPE.Flex,
        props = {
            arrange = ui.ALIGNMENT.End,
        },
        content = ui.content {
            slider.element,
            I.UIToolkit.Templates.intervalV(5),
            edit.element,
        },
    }
end
