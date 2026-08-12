---@omw-context player
local ui = require('openmw.ui')
local util = require('openmw.util')
local auxUi = require('openmw_aux.ui')
local auxUtil = require('openmw_aux.util')
local I = require('openmw.interfaces')
local types = require('openmw.types')
local core = require('openmw.core')
local self = require('openmw.self')
local Tooltips = require('scripts.UIToolkit.tooltips.tooltips')
local T = {
    Base = require('scripts.UIToolkit.templates.base'),
}

---@type UTKTooltips.PreCreateHandler[]
local preCreateTooltipHandlers = {}
---@type UTKTooltips.PostCreateHandler[]
local postCreateTooltipHandlers = {}

local boxTemplateNormal = I.MWUI.templates.boxSolid
local boxTemplateOwned = auxUi.deepLayoutCopy(I.MWUI.templates.boxSolid)
boxTemplateOwned.content[1].props.color = util.color.rgb(0.15, 0, 0)
boxTemplateOwned.content[1].props.alpha = 1.0


local showOwnedObjects = true --TODO: read from settings

local function isOwned(obj)
    if not obj then
        return false
    end

    local owner = obj.owner
    if owner.recordId and owner.recordId ~= self.object.recordId then
        return true
    end

    local faction = owner.factionId
    if faction then
        local rank = types.NPC.getFactionRank(self.object, owner.factionId)
        if rank == 0 then
            -- Not in faction.
            return true
        else
            return rank < (owner.factionRank or 0)
        end
    end

    return false
end

local function isKnockedOut(obj)
    local isParalyzed = types.Actor.activeEffects(obj):getEffect(core.magic.EFFECT_TYPE.Paralyze) ~= 0
    local isDead = types.Actor.isDead(obj)
    local canMove = types.Actor.canMove(obj)
    -- If the actor can't move, but is neither paralyzed nor dead, then the actor must be knocked out
    return not canMove and not isDead and not isParalyzed
end

local function isAllowedToUse(obj, actor)
    if not obj or not actor then
        return true
    end

    if types.Door.objectIsInstance(obj) and not types.Lockable.isLocked(obj) then
        return true
    end

    local record = obj.type.record(obj)

    -- This is the current engine implementation for detecting a bed, the following comment is copied from the engine:
    -- TODO: implement a better check to check if target is owned bed
    if types.Activator.objectIsInstance(obj) and string.sub(tostring(record.mwscript), 1, 3) ~= 'bed' then
        return true
    end

    if types.NPC.objectIsInstance(obj) then
        if types.Actor.isDead(obj) then
            return true
        end

        return not (isKnockedOut(obj) or self.controls.sneak)
    end

    if isOwned(obj) then
        return false
    end

    return obj.recordid ~= 'stolen_goods'
end

local objectType = {
    [types.Activator] = Tooltips.TYPE.Activator,
    [types.Apparatus] = Tooltips.TYPE.Apparatus,
    [types.Armor] = Tooltips.TYPE.Armor,
    [types.Book] = Tooltips.TYPE.Book,
    [types.Clothing] = Tooltips.TYPE.Clothing,
    [types.Container] = Tooltips.TYPE.Container,
    [types.Creature] = Tooltips.TYPE.Creature,
    [types.Door] = Tooltips.TYPE.Door,
    [types.Ingredient] = Tooltips.TYPE.Ingredient,
    [types.Light] = Tooltips.TYPE.Light,
    [types.Lockpick] = Tooltips.TYPE.Lockpick,
    [types.Miscellaneous] = Tooltips.TYPE.Miscellaneous,
    [types.NPC] = Tooltips.TYPE.NPC,
    [types.Player] = Tooltips.TYPE.Player,
    [types.Potion] = Tooltips.TYPE.Potion,
    [types.Probe] = Tooltips.TYPE.Probe,
    [types.Repair] = Tooltips.TYPE.Repair,
    [types.Static] = Tooltips.TYPE.Static,
    [types.Weapon] = Tooltips.TYPE.Weapon,
}

local function autoType(tooltip)
    if not tooltip then return end
    if tooltip.object then
        local t = objectType[tooltip.object.type]
        if t then
            tooltip.type = t
            return true
        end
    end
    if tooltip.key then
        for k, v in pairs(objectType) do
            if k.records[tooltip.key] then
                tooltip.type = v
                return true
            end
        end
    end
    return false
end

---@param tooltip UTKTooltips.Tooltip
local function createTooltipLayout(tooltip)
    local layout = nil
    local recipe = tooltip.recipe
    if not tooltip.recipe then
        if not tooltip.type and not autoType(tooltip) then
            error('Cannot use new tooltip: Unable to determine type')
        end

        local func = Tooltips.recipes[tooltip.type]
        if func then
            recipe = func(tooltip)
        end
    end
    recipe = recipe or {}
    recipe.items = recipe.items or {}
    auxUtil.callEventHandlers(preCreateTooltipHandlers, recipe, tooltip)

    if recipe.items and #recipe.items > 0 then
        layout = Tooltips.buildTooltip(recipe, tooltip)
    end
    if layout then
        local template = boxTemplateNormal
        if showOwnedObjects and not isAllowedToUse(tooltip.object, tooltip.observer) then
            template = boxTemplateOwned
        end

        layout = {
            template = template,
            content = ui.content { {
                template = T.Base.padding(8),
                content = ui.content { layout }
            } },
            props = {},
            layer = 'Popup',
        }
    end

    auxUtil.callEventHandlers(postCreateTooltipHandlers, layout, tooltip)

    return layout
end




---
-- Allows to extend or override built-in tooltips
-- @module Tooltips
-- @context player
-- @usage require('openmw.interfaces').Tooltips
--
--@usage
---- An example handler that adds faction info to NPCs
--I.Tooltips.addPreCreateTooltipHandler(function(recipe, tooltip)
--    -- Add faction info to NPC tooltips
--    if tooltip.object and types.NPC.objectIsInstance(tooltip.object) then
--        local factions = types.NPC.getFactions(tooltip.object)
--        for _, factionId in pairs(factions) do
--            local faction = core.factions.record(factionId)
--            local rank = faction.ranks[types.NPC.getFactionRank(tooltip.object, factionId)]
--            recipe.items[#recipe.items+1] = {text = rank.name..', '..faction.name}
--        end
--    end
--end)
--
--@usage
--local function findByName(items, name)
--    for index, item in ipairs(items or {}) do
--        if item.name == name then
--            return item, index
--        end
--    end
--end
---- An example handler that finds and modified an existing tooltip item
--I.Tooltips.addPreCreateTooltipHandler(function(recipe, tooltip)
--    -- Always include icon for objects with icons
--    if tooltip.object then
--        local record = tooltip.object.type.records[tooltip.object.recordId]
--        if record.icon then
--            local header = findByName(recipe.items, I.Tooltips.CONTENT.Header)
--            if header and not header.icon then
--                header.image = record.icon
--            end
--        end
--    end
--end)
--
--@usage
--local function unknownEffects(effects, max)
--    -- This function populates the 'unknown' table used to hide some effects
--    -- This function
--    local maxIndex = 0
--    -- Note that we need to do pairs instead of ipairs on effect, because there can be gaps.
--    for _, effect in pairs(effects) do
--        -- effect.index is the c++ index, so we had to add 1
--        maxIndex = math.max(maxIndex, effect.index + 1)
--    end
--    if max < maxIndex then
--        local unknown = {}
--        for i = max + 1, maxIndex do
--            unknown[i] = true
--        end
--        return unknown
--    end
--end
---- An example handler that adds magic effect info to traps
--I.Tooltips.addPreCreateTooltipHandler(function(recipe, tooltip)
--    -- Reveal trap effects if security+intelligence is high enough
--    local object = tooltip.object
--    -- observer is used to determine observer's skill/attributes etc.
--    local observer = tooltip.observer
--    if observer and object and types.Lockable.objectIsInstance(object) then
--        local trap = types.Lockable.getTrapSpell(object)
--        if trap then
--            -- Determine intelligence/security of the observer and compute how many effects should be revealed
--            local intelligence = types.Actor.stats.attributes.intelligence(observer).modified
--            local luck = types.Actor.stats.attributes.luck(observer).modified
--            local security = types.NPC.stats.skills.security(observer).modified
--            local x = math.ceil((intelligence * 2 / 3) + (security * 4 / 3) + (luck / 5))
--            recipe.items[#recipe.items+1] = {
--                type = 'magicEffects',
--                effects = trap.effects,
--                unknown = unknownEffects(trap.effects, math.floor(x / 100)),
--                skipTarget = true,
--                name = I.Tooltips.CONTENT.MagicEffects
--            }
--        end
--    end
--end)
--
--@usage
--local function removeByName(items, name)
--    local toRemove = {}
--    for index, item in ipairs(items or {}) do
--        if item.name == name then
--            toRemove[#toRemove+1] = index
--        end
--    end
--    for _, index in ipairs(toRemove) do
--        table.remove(items, index)
--    end
--end
---- An example handler that removes a tooltip item
--I.Tooltips.addPreCreateTooltipHandler(function(recipe, tooltip)
--    -- Hide that a container is trapped if observer's security+intelligence is too low
--    local object = tooltip.object
--    local observer = tooltip.observer
--    if observer and object and types.Lockable.objectIsInstance(object) then
--        local intelligence = types.Actor.stats.attributes.intelligence(observer).modified
--        local luck = types.Actor.stats.attributes.luck(observer).modified
--        local security = types.NPC.stats.skills.security(observer).modified
--        local x = math.ceil((intelligence * 2 / 3) + (security * 4 / 3) + (luck / 5))
--        if x < 60 then
--            removeByName(recipe.items, I.Tooltips.CONTENT.Trap)
--            -- The previous example handler reveals magic effects, so we have to remove those as well
--            -- or the trap would still be revealed
--            removeByName(recipe.items, I.Tooltips.CONTENT.MagicEffects)
--        end
--    end
--end)
--
--@usage
---- An example of registering a new builder of type "value", that renders its value as an icon + item.value
--local coin =
--I.Tooltips.registerBuilder('value', function(item)
--    return {
--         type = ui.TYPE.Flex,
--         props = {horizontal = true},
--         content = ui.content{{
--                type = ui.TYPE.Image,
--                props = {
--                    resource = ui.texture{path = item.image},
--                    size = util.vector2(16, 16)
--                }
--            },
--            {
--                template = I.MWUI.templates.textHeader,
--                props = {
--                    text = tostring(item.value),
--                },
--            }
--        }
--    }
--end)
---- Now register a handler that transform monetary value lines from default into the new 'value' item type, and move them last and align them right
--I.Tooltips.addPreCreateTooltipHandler(function(recipe, tooltip)
--    -- 'findByName' is described in a previous example
--    local item, index = findByName(recipe.items, I.Tooltips.CONTENT.Value)
--    if item then
--        item.type = 'value'
--        item.image = 'icons/m/tx_gold_001.dds'
--        item.align = ui.ALIGNMENT.End
--        if index ~= #recipe.items then
--            table.remove(recipe.items, index)
--            recipe.items[#recipe.items+1] = item
--        end
--    end
--end)
--
--@usage
---- Handler that uses the 'root' builder to create a recursive tooltip
---- In this example we take value, condition, and weight and replace them with
---- 'value' items from the previous example, and then arrange them horizontally at the bottom
---- using the 'root' builder.
--I.Tooltips.addPreCreateTooltipHandler(function(recipe, tooltip)
--    -- List of items to put in the new recipe
--    local items = {}
--    local item, index = findByName(recipe.items, I.Tooltips.CONTENT.Value)
--    if item then
--        -- Remove the old item and add to the new items list instead
--        table.remove(recipe.items, index)
--        items[#items+1] = { type = 'value', image = 'icons/m/tx_gold_001.dds', value = item.value }
--    end
--    item, index = findByName(recipe.items, I.Tooltips.CONTENT.Condition)
--    if item then
--        if tooltip.object then
--            local rec = tooltip.object.type.records[tooltip.object.recordId]
--            if rec.health then
--                local current = types.Item.itemData(tooltip.object).condition
--                local pct = math.ceil((current / rec.health) * 100)
--                -- Remove the old item and add to the new items list instead
--                table.remove(recipe.items, index)
--                items[#items+1] = { type = 'value', value = tostring(pct)..'%', image = 'icons/m/tx_repair_j_01.dds' }
--            end
--        end
--    end
--    item, index = findByName(recipe.items, I.Tooltips.CONTENT.Weight)
--    if item then
--        -- Remove the old item and add to the new items list instead
--        if tooltip.type == I.Tooltips.TYPE.Armor then
--            -- Armor needs to keep its weight classification visible, so keep a text item for that
--            local skill = I.Combat.getArmorSkill(tooltip.object or tooltip.key)
--            recipe.items[index] = {text = 'Type', value = core.stats.Skill.records[skill].name}
--            item.value = item.value:match("(%d+%.?%d*)")
--        else
--            table.remove(recipe.items, index)
--        end
--        -- Use a basket to represent weight
--        items[#items+1] = { type = 'value', image = 'icons/m/misc_de_basket_01.dds', value = item.value }
--    end
--
--    -- Use gap items to properly fill out the width of the widget
--    if #items > 1 then
--        local gap = {type = 'gap', grow = 1, size = 12}
--        for i = 1, #items - 1 do
--            table.insert(items, i * 2, gap)
--        end
--    end
--
--    -- Insert these items as a root item, which will be built as a horizontal flex
--    if #items > 0 then
--        recipe.items[#recipe.items+1] = {type = 'gap', size = 6}
--        recipe.items[#recipe.items+1] = {
--            type = 'root',
--            horizontal = true,
--            items = items,
--            stretch = 1,
--        }
--    end
--end)
--
--@usage
---- An example of creating a layout that displays a tooltip when moused over
--local tooltipEvents = {
--    focusGain = async:callback(function(_, layout)
--        I.Tooltips.setTooltip{
--            type = I.Tooltips.TYPE.Spell,
--            key = layout.userData.spellId,
--        }
--    end),
--    focusLoss = async:callback(function(layout)
--        I.Tooltips.setTooltip(nil)
--    end),
--}
--
--local function spellNameWithTooltip(spellId)
--    local spell = core.magic.spells.record(spellId)
--    return {
--        template = I.MWUI.templates.textNormal,
--        props = {text = spell.name},
--        events = tooltipEvents,
--        userData = {spellId = spellId},
--    }
--end
--
--local element = ui.create{
--    template = I.MWUI.templates.boxSolid,
--    props = {visible = true},
--    layer = 'MainMenu',
--    content = ui.content{{
--        type = ui.TYPE.Flex,
--        content = ui.content{
--            spellNameWithTooltip('fireball'),
--            spellNameWithTooltip('feather'),
--            spellNameWithTooltip('levitate'),
--        },
--    }}
--}


return {
    interfaceName = 'UTKTooltips',
    interface = {
        version = 1,
        --- Instantiates the tooltip by filling in the layout member. This invokes create tooltip handlers.
        -- @function [parent=#Tooltips] createTooltipLayout
        -- @param #Tooltip tooltip The tooltip.
        createTooltipLayout = createTooltipLayout,

        --- Adds a handler for creating tooltip recipes. Receives a @{#Recipe} and a @{#Tooltip} as its parameters
        -- Note that this handler is called whenever createTooltipLayout() is invoked. You can check if the call corresponds
        -- to the current tooltip by checking if it is equal to @{#Tooltips.currentTooltip}
        -- @function [parent=#Tooltips] addPreCreateTooltipHandler
        -- @param #function handler The handler.
        addPreCreateTooltipHandler = function(handler)
            preCreateTooltipHandlers[#preCreateTooltipHandlers + 1] = handler
        end,

        --- Adds a handler for creating tooltips layouts. Receives a @{openmw.ui#Layout} and a @{#Tooltip} as its parameters
        -- Note that this handler is called after the preCreateTooltip handlers, if the result was a recipe with at least 1 item.
        -- You can check if the call corresponds to the current tooltip by checking if it is equal to @{#Tooltips.currentTooltip}
        -- @function [parent=#Tooltips] addPostCreateTooltipHandler
        -- @param #function handler The handler.
        addPostCreateTooltipHandler = function(handler)
            postCreateTooltipHandlers[#postCreateTooltipHandlers + 1] = handler
        end,

        --- Add a builder for a @{#RecipeItemType}. Overrides the existing builder if present
        -- @function [parent=#Tooltips] registerBuilder
        -- @param #RecipeItemType type
        -- @param #function builder The builder
        registerBuilder = function(type, func)
            Tooltips.builders[type] = func
        end,

        --- A list of all built-in tooltip contents. use view(I.Tooltips.CONTENT) in luap in the in-game console to see the full list.
        -- These are the names of layouts within the tooltips, to be used to index into content by name
        -- @field [parent=#Tooltips] #table CONTENT
        CONTENT = Tooltips.CONTENT,

        --- A list of all built-in tooltip types.
        -- @field [parent=#Tooltips] #list<#TooltipType> TYPE
        TYPE = Tooltips.TYPE,

        --- A map of @{#RecipeItemType} to builder functions
        -- @field [parent=#Tooltips] #list<#function> builders
        builders = Tooltips.builders,
    },

    eventHandlers = {
        OMWMusicCombatTargetsChanged = function(data)
            actorCombatTargets[data.actor.id] = data.targets
        end
    }
}
