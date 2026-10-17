---@omw-context player

local I       = require 'openmw.interfaces'
local ui      = require 'openmw.ui'
local util    = require 'openmw.util'

local data    = require 'scripts.utk_tooltips_complete.data'
local helpers = require 'scripts.UIToolkit.tooltips.utils'


local v2       = util.vector2
local Toolkit  = I.UIToolkit
local Tooltips = I.UTKTooltips
local T        = Toolkit.Templates
local NAME     = 'tooltips-complete'


Tooltips.registerBuilder(NAME, function(item)
    local theme = Toolkit.getTheme()
    return {
        template = T.paragraph(),
        name = NAME,
        props = {
            text = item.text,
            textSize = theme.Sizes.textNormal - 1,
            size = v2(400, 0),
            textColor = theme.Colors.DISABLED,
            textAlignH = ui.ALIGNMENT.Center,
        }
    }
end)

Tooltips.addPreCreateTooltipHandler(function(recipe, tooltip)
    local id = tooltip.object and tooltip.object.recordId or tooltip.key
    if not id then return end
    local text = data[id]
    if not text then return end

    local items = recipe.items
    local found, index = helpers.findByName(items, Tooltips.CONTENT.Footer)
    if not found then index = #items + 1 else index = index - 1 end

    table.insert(items, index, { type = NAME, text = text, name = NAME })
    table.insert(items, index, { type = 'gap', size = 4 })
end)
