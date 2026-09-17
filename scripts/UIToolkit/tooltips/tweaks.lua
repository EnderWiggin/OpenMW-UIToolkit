---@omw-context player

local types     = require 'openmw.types'
local ui        = require 'openmw.ui'
local I         = require 'openmw.interfaces'

local helpers   = require 'scripts.UIToolkit.tooltips.utils'
local H         = require 'scripts.UIToolkit.helpers'
local cfgPlayer = require 'scripts.UIToolkit.config.player'

local Interface = I.UTKTooltips


Interface.addPreCreateTooltipHandler(function(recipe, tooltip)
    if not cfgPlayer.interface.b_CompactWeightValue then return end

    local items = {}

    -- Move value to bottom row
    local valueItem, valueIndex = helpers.findByName(recipe.items, Interface.CONTENT.Value)
    if valueItem then
        table.remove(recipe.items, valueIndex)
        items[#items + 1] = {
            type = 'value',
            image = 'icons/gold.dds',
            value = valueItem.value
        }
    end

    -- Move weight to bottom row; for armor, show weight class as text in place
    local weightItem, weightIndex = helpers.findByName(recipe.items, Interface.CONTENT.Weight)
    if weightItem then
        table.remove(recipe.items, weightIndex)
        local weight = weightItem.value
        if tooltip.type == Interface.TYPE.Armor and tooltip.object then
            --TODO: do not require object on newer API where weight class can be calculated from record
            local record = types.Armor.records[tooltip.key or tooltip.object.recordId]
            assert(record)
            local _, index = helpers.findByName(recipe.items, Interface.CONTENT.ArmorRating)
            local weightClass = helpers.armorWeightClass(record, tooltip.object)
            weight = H.addSeparators(helpers.formatOneDecimal(record.weight))
            table.insert(recipe.items, index or weightIndex, {
                text = 'Type',
                value = weightClass,
                name = Interface.CONTENT.Weight
            })
        end

        items[#items + 1] = {
            type = 'value',
            image = 'icons/weight.dds',
            value = weight
        }
    end

    -- Horizontal flex row at bottom with gap spacers
    if #items > 0 then
        local gap = { type = 'gap', grow = 1, size = 4 }
        for i = 1, #items - 1 do
            table.insert(items, i * 2, gap)
        end

        recipe.items[#recipe.items + 1] = { type = 'gap', size = 4 }
        recipe.items[#recipe.items + 1] = {
            type = 'root',
            name = Interface.CONTENT.Footer,
            horizontal = true,
            align = ui.ALIGNMENT.End,
            items = items,
        }
    end
end)
