---@omw-context player
local core = require('openmw.core')
local util = require('openmw.util')
local types = require('openmw.types')
local ui = require('openmw.ui')
local I = require('openmw.interfaces')
local helpers = require('scripts.UIToolkit.tooltips.utils')

-- Short-hands
local Player = types.Player
local Actor = types.Actor
local Door = types.Door
local Weapon = types.Weapon
local Lockable = types.Lockable
local NPC = types.NPC
local Item = types.Item
local V2 = util.vector2

local Tooltips = {}

Tooltips.builders = require('scripts.UIToolkit.tooltips.builders')

local rebalanceSoulGems = false --TODO: read setting

---@type UTKTooltips.ContentNames
local CONTENT =
{
    ActiveEffects = 'ActiveEffects',
    ArmorRating = 'ArmorRating',
    LevelAttributeIncreases = 'LevelAttributeIncreases',
    Banner = 'Banner',
    Caption = 'Caption',
    CastCost = 'CastCost',
    ChargeMeter = 'ChargeMeter',
    ChopDamage = 'ChopDamage',
    Condition = 'Condition',
    Damage = 'Damage',
    EmptyLine = 'EmptyLine',
    EnchantmentType = 'EnchantmentType',
    EXPELLED = 'EXPELLED',
    FactionFavoriteSkills = 'FactionFavoriteSkills',
    FactionFavoriteSkillsList = 'FactionFavoriteSkillsList',
    FactionNextRank = 'FactionNextRank',
    FactionNextRankAttributes = 'FactionNextRankAttributes',
    FactionNextRankSkills = 'FactionNextRankSkills',
    FactionRank = 'FactionRank',
    Header = 'Header',
    Icon = 'Icon',
    List = 'List',
    Lock = 'Lock',
    MagicEffects = 'MagicEffects',
    MainFlex = 'MainFlex',
    MapNote = 'MapNote',
    Paragraph = 'Paragraph',
    ProgressBar = 'ProgressBar',
    Quality = 'Quality',
    Root = 'Root',
    School = 'School',
    Specialization = 'Specialization',
    SkillList = 'SkillList',
    SkillMaxed = 'SkillMaxed',
    SpellList = 'SpellList',
    SlashDamage = 'SlashDamage',
    Teleport = 'Teleport',
    Text = 'Text',
    ThrustDamage = 'ThrustDamage',
    Trap = 'Trap',
    Value = 'Value',
    WeaponType = 'WeaponType',
    Weight = 'Weight',
}

Tooltips.CONTENT = CONTENT
Tooltips.TYPE =
{
    Activator = 'Activator',
    ActiveSpellEffect = 'ActiveSpellEffect',
    Apparatus = 'Apparatus',
    Armor = 'Armor',
    Attribute = 'Attribute',
    BirthSign = 'BirthSign',
    Book = 'Book',
    Caption = 'Caption',
    CaptionOneLine = 'CaptionOneLine',
    Class = 'Class',
    Clothing = 'Clothing',
    Container = 'Container',
    Creature = 'Creature',
    Door = 'Door',
    Faction = 'Faction',
    HandToHand = 'HandToHand',
    Ingredient = 'Ingredient',
    Level = 'Level',
    Light = 'Light',
    Lockpick = 'Lockpick',
    MagicEffect = 'MagicEffect',
    MapMarker = 'MapMarker',
    Miscellaneous = 'Miscellaneous',
    None = 'None',
    NPC = 'NPC',
    Player = 'Player',
    Potion = 'Potion',
    Probe = 'Probe',
    Race = 'Race',
    Repair = 'Repair',
    Skill = 'Skill',
    Specialization = 'Specialization',
    Spell = 'Spell',
    Stat = 'Stat',
    Static = 'Static',
    Weapon = 'Weapon',
}
local recordDispatch = {
    [Tooltips.TYPE.ActiveSpellEffect] = core.magic.effects,
    [Tooltips.TYPE.Attribute] = core.stats.Attribute,
    [Tooltips.TYPE.BirthSign] = types.Player.birthSigns,
    [Tooltips.TYPE.Class] = types.NPC.classes,
    [Tooltips.TYPE.Faction] = core.factions,
    [Tooltips.TYPE.MagicEffect] = core.magic.effects,
    [Tooltips.TYPE.Race] = types.NPC.races,
    [Tooltips.TYPE.Skill] = core.stats.Skill,
    [Tooltips.TYPE.Spell] = core.magic.spells,
}
for k, v in pairs(types) do
    local key = Tooltips.TYPE[k]
    if key then
        recordDispatch[key] = v
    end
end
function Tooltips.findRecord(tooltip)
    local r = recordDispatch[tooltip.type]
    if r then
        if tooltip.key then return r.records[tooltip.key] end
        if tooltip.object then return r.records[tooltip.object.recordId] end
    end
end

local icons =
{
    handToHandNormal = 'icons/k/stealth_handtohand.dds',
    handToHandWerewolf = 'icons/k/tx_werewolf_hand.dds',
    health = 'icons/k/health.dds',
    magicka = 'icons/k/magicka.dds',
    fatigue = 'icons/k/fatigue.dds',
    door = 'textures/door_icon.dds'
}

local gmsts =
{
    'fCombatDistance',
    'fWortChanceValue',
}
local l10n = core.l10n('OMWEngine')

local enchantmentTypeStrings = {
    [core.magic.ENCHANTMENT_TYPE.CastOnStrike] = l10n('ItemCastWhenStrikes'),
    [core.magic.ENCHANTMENT_TYPE.CastOnUse] = l10n('ItemCastWhenUsed'),
    [core.magic.ENCHANTMENT_TYPE.CastOnce] = l10n('ItemCastOnce'),
    [core.magic.ENCHANTMENT_TYPE.ConstantEffect] = l10n('ItemCastConstant'),
}

local weaponTypeToSkill = {
    [Weapon.TYPE.Arrow] = 'marksman',
    [Weapon.TYPE.AxeOneHand] = 'axe',
    [Weapon.TYPE.AxeTwoHand] = 'axe',
    [Weapon.TYPE.BluntOneHand] = 'bluntweapon',
    [Weapon.TYPE.BluntTwoClose] = 'bluntweapon',
    [Weapon.TYPE.BluntTwoWide] = 'bluntweapon',
    [Weapon.TYPE.Bolt] = 'marksman',
    [Weapon.TYPE.LongBladeOneHand] = 'longblade',
    [Weapon.TYPE.LongBladeTwoHand] = 'longblade',
    [Weapon.TYPE.MarksmanBow] = 'marksman',
    [Weapon.TYPE.MarksmanCrossbow] = 'marksman',
    [Weapon.TYPE.MarksmanThrown] = 'marksman',
    [Weapon.TYPE.ShortBladeOneHand] = 'shortblade',
    [Weapon.TYPE.SpearTwoWide] = 'spear',
}
local skillToName = {}
for _, record in pairs(core.stats.Skill.records) do
    skillToName[record.id] = record.name
end

local twoHanded = {
    [Weapon.TYPE.AxeTwoHand] = true,
    [Weapon.TYPE.BluntTwoClose] = true,
    [Weapon.TYPE.BluntTwoWide] = true,
    [Weapon.TYPE.LongBladeTwoHand] = true,
    [Weapon.TYPE.SpearTwoWide] = true,
}

local oneHanded = {
    [Weapon.TYPE.AxeOneHand] = true,
    [Weapon.TYPE.BluntOneHand] = true,
    [Weapon.TYPE.LongBladeOneHand] = true,
    [Weapon.TYPE.ShortBladeOneHand] = true,
}

local isMelee = {
    [Weapon.TYPE.AxeOneHand] = true,
    [Weapon.TYPE.AxeTwoHand] = true,
    [Weapon.TYPE.BluntOneHand] = true,
    [Weapon.TYPE.BluntTwoClose] = true,
    [Weapon.TYPE.BluntTwoWide] = true,
    [Weapon.TYPE.LongBladeTwoHand] = true,
    [Weapon.TYPE.LongBladeOneHand] = true,
    [Weapon.TYPE.ShortBladeOneHand] = true,
    [Weapon.TYPE.SpearTwoWide] = true,
}

local isMarksman = {
    [Weapon.TYPE.MarksmanBow] = true,
    [Weapon.TYPE.MarksmanCrossbow] = true,
    [Weapon.TYPE.MarksmanThrown] = true,
}

local isAmmo = {
    [Weapon.TYPE.Arrow] = true,
    [Weapon.TYPE.Bolt] = true,
}

local noHealth = {
    [Weapon.TYPE.Arrow] = true,
    [Weapon.TYPE.Bolt] = true,
    [Weapon.TYPE.MarksmanThrown] = true,
}

local weaponTypeToName = {}
for _, type in pairs(Weapon.TYPE) do
    local skill = weaponTypeToSkill[type]
    local s = skillToName[skill]
    if twoHanded[type] then
        s = s .. ', ' .. l10n('TwoHanded')
    end
    if oneHanded[type] then
        s = s .. ', ' .. l10n('OneHanded')
    end
    weaponTypeToName[type] = s
end

for _, gmst in ipairs(gmsts) do
    gmsts[gmst] = core.getGMST(gmst)
end

local function getCondition(object)
    if object then
        return Item.itemData(object).condition
    end
end

local function armorWeightClass(record)
    local armorSkill = I.Combat.getArmorSkill(record)
    if armorSkill == 'lightarmor' then
        return l10n('Light')
    elseif armorSkill == 'mediumarmor' then
        return l10n('Medium')
    elseif armorSkill == 'heavyarmor' then
        return l10n('Heavy')
    end
    -- In case mods allow non-standard armor weight classes
    return core.stats.Skill.record(armorSkill).name
end

local function lockLevelString(object)
    if object
        and Lockable.objectIsInstance(object)
        and Lockable.getLockLevel(object) ~= 0 then
        local text = l10n('Unlocked')
        if Lockable.isLocked(object) then
            text = l10n('LockLevel') .. ': ' .. tostring(Lockable.getLockLevel(object))
        end
        return text
    end
end

local function enchantment(items, record, object, noCharge)
    if record.enchant then
        local enchant = core.magic.enchantments.records[record.enchant]
        items[#items + 1] = { text = enchantmentTypeStrings[enchant.type], name = CONTENT.EnchantmentType }

        local noTarget = false
        local noDuration = false

        if enchant.type == core.magic.ENCHANTMENT_TYPE.ConstantEffect then
            noTarget = true
            noDuration = true
        end

        items[#items + 1] = {
            type = 'magicEffects',
            effects = enchant.effects,
            skipTarget = noTarget,
            skipDuration =
                noDuration,
            name = CONTENT.MagicEffects
        }

        local chargeCurrent = enchant.charge
        local chargeMax = enchant.charge
        if chargeMax > 0 and not noCharge then
            if object then
                local itemData = Item.itemData(object)
                chargeCurrent = itemData.enchantmentCharge
            end
            items[#items + 1] = { text = l10n('Charge'), name = CONTENT.Text }
            items[#items + 1] = {
                type = 'progressBar',
                current = chargeCurrent,
                max = chargeMax,
                name = CONTENT
                    .ChargeMeter
            }
        end
    end
end

local function header(record, object)
    if record.name and #record.name > 0 then
        local item = { type = 'header', title = record.name, name = CONTENT.Header }
        if object and Item.objectIsInstance(object) then
            if object.count > 1 then
                item.title = item.title .. ' (' .. tostring(object.count) .. ')'
            end
            local soul = helpers.getSoul(object)
            if soul then
                item.title = item.title .. ' (' .. soul.name .. ')'
            end
            if record.icon and not object.parentContainer then
                -- Item tooltips do not render the icon when the item is in an inventory.
                item.image = record.icon
            end
        end
        return item
    end
end

Tooltips.activatorRecipe = function(tooltip)
    local record = types.Activator.records[tooltip.key or tooltip.object.recordId]
    if not record then return end
    if record.name == '' then return end
    local items = {}
    items[#items + 1] = header(record, tooltip.object)
    return {
        name = 'Activator',
        arrange = ui.ALIGNMENT.Center,
        items = items,
    }
end

Tooltips.apparatusRecipe = function(tooltip)
    local record = types.Apparatus.records[tooltip.key or tooltip.object.recordId]
    if not record then return end
    local items = {}
    items[#items + 1] = header(record, tooltip.object)
    items[#items + 1] = {
        text = l10n('Quality'),
        value = Tooltips.formatOneDecimal(record.quality),
        name = CONTENT
            .Quality
    }
    items[#items + 1] = { text = l10n('Weight'), value = Tooltips.formatOneDecimal(record.weight), name = CONTENT.Weight }
    items[#items + 1] = { text = l10n('Value'), value = math.floor(record.value), name = CONTENT.Value }
    return {
        name = 'Apparatus',
        arrange = ui.ALIGNMENT.Center,
        items = items,
    }
end

Tooltips.armorRecipe = function(tooltip)
    local record = types.Armor.records[tooltip.key or tooltip.object.recordId]
    if not record then return end
    local weightClass = armorWeightClass(record)
    local rating = record.baseArmor
    if tooltip.object and tooltip.observer then
        rating = I.Combat.getEffectiveArmorRating(tooltip.object, tooltip.observer)
    end
    local condition = getCondition(tooltip.object) or record.health
    local items = {}
    items[#items + 1] = header(record, tooltip.object)
    items[#items + 1] = { text = l10n('ArmorRating'), value = math.floor(rating), name = CONTENT.ArmorRating }
    items[#items + 1] = {
        text = l10n('Condition'),
        value = tostring(condition) .. '/' .. tostring(record.health),
        name =
            CONTENT.Condition
    }
    items[#items + 1] = {
        text = l10n('Weight'),
        value = Tooltips.formatOneDecimal(record.weight) ..
            ' (' .. weightClass .. ')',
        name = CONTENT.Weight
    }
    items[#items + 1] = { text = l10n('Value'), value = math.floor(record.value), name = CONTENT.Value }
    enchantment(items, record, tooltip.object)
    return {
        name = 'Armor',
        arrange = ui.ALIGNMENT.Center,
        items = items,
    }
end

Tooltips.bookRecipe = function(tooltip)
    local record = types.Book.records[tooltip.key or tooltip.object.recordId]
    if not record then return end
    local items = {}
    items[#items + 1] = header(record, tooltip.object)
    items[#items + 1] = { text = l10n('Weight'), value = Tooltips.formatOneDecimal(record.weight), name = CONTENT.Weight }
    items[#items + 1] = { text = l10n('Value'), value = math.floor(record.value), name = CONTENT.Value }
    enchantment(items, record, tooltip.object, true)
    return {
        name = 'Book',
        arrange = ui.ALIGNMENT.Center,
        items = items,
    }
end

Tooltips.clothingRecipe = function(tooltip)
    local record = types.Clothing.records[tooltip.key or tooltip.object.recordId]
    if not record then return end
    local items = {}
    items[#items + 1] = header(record, tooltip.object)
    items[#items + 1] = { text = l10n('Weight'), value = Tooltips.formatOneDecimal(record.weight), name = CONTENT.Weight }
    items[#items + 1] = { text = l10n('Value'), value = math.floor(record.value), name = CONTENT.Value }
    enchantment(items, record, tooltip.object)
    return {
        name = 'Clothing',
        arrange = ui.ALIGNMENT.Center,
        items = items,
    }
end

Tooltips.containerRecipe = function(tooltip)
    local record = types.Container.records[tooltip.key or tooltip.object.recordId]
    if not record then return end
    local lockLevel = lockLevelString(tooltip.object)
    local items = {}
    items[#items + 1] = header(record, tooltip.object)
    if lockLevel then
        items[#items + 1] = { text = lockLevel, name = CONTENT.Lock }
    end
    if helpers.isTrapped(tooltip.object) then
        items[#items + 1] = { text = l10n('Trapped'), name = CONTENT.Trap }
    end
    return {
        name = 'Container',
        arrange = ui.ALIGNMENT.Center,
        items = items,
    }
end

Tooltips.creatureRecipe = function(tooltip)
    local record = types.Creature.records[tooltip.key or tooltip.object.recordId]
    if not record then return end
    local items = {}
    items[#items + 1] = header(record, tooltip.object)
    return {
        name = 'Creature',
        arrange = ui.ALIGNMENT.Center,
        items = items,
    }
end

Tooltips.doorRecipe = function(tooltip)
    local record = types.Door.records[tooltip.key or tooltip.object.recordId]
    if not record then return end
    local lockLevel = lockLevelString(tooltip.object)
    local items = {}
    items[#items + 1] = header(record, tooltip.object)
    if tooltip.object and Door.isTeleport(tooltip.object) then
        local destCell = Door.destCell(tooltip.object)
        if destCell then
            items[#items + 1] = { text = l10n('To'), name = CONTENT.Teleport }
            items[#items + 1] = { text = destCell.displayName, name = CONTENT.Teleport }
        end
    end
    if lockLevel then
        items[#items + 1] = { text = lockLevel, name = CONTENT.Lock }
    end
    if helpers.isTrapped(tooltip.object) then
        items[#items + 1] = { text = l10n('Trapped'), name = CONTENT.Trap }
    end
    return {
        name = 'Door',
        arrange = ui.ALIGNMENT.Center,
        items = items,
    }
end

Tooltips.ingredientRecipe = function(tooltip)
    local record = types.Ingredient.records[tooltip.key or tooltip.object.recordId]
    if not record then return end
    local items = {}
    local unknown = nil
    if tooltip.observer then
        local skill = helpers.getSkill(tooltip.observer, 'alchemy') or 100
        unknown = helpers.unknownEffects(record.effects, math.floor(skill / gmsts.fWortChanceValue))
    end
    items[#items + 1] = header(record, tooltip.object)
    items[#items + 1] = { text = l10n('Weight'), value = Tooltips.formatOneDecimal(record.weight), name = CONTENT.Weight }
    items[#items + 1] = { text = l10n('Value'), value = math.floor(record.value), name = CONTENT.Value }
    items[#items + 1] = {
        type = 'magicEffects',
        unknown = unknown,
        effects = record.effects,
        skipTarget = true,
        skipMagnitude = true,
        skipDuration = true,
        name = CONTENT.MagicEffects
    }
    return {
        name = 'Ingredient',
        arrange = ui.ALIGNMENT.Center,
        items = items,
    }
end

Tooltips.miscellaneousRecipe = function(tooltip)
    local record = types.Miscellaneous.records[tooltip.key or tooltip.object.recordId]
    if not record then return end
    local value = record.value
    local soul = helpers.getSoul(tooltip.object)
    if soul then
        value = helpers.soulGemValue(soul.soulValue, value, rebalanceSoulGems)
    end
    local items = {}
    items[#items + 1] = header(record, tooltip.object)
    items[#items + 1] = { text = l10n('Weight'), value = Tooltips.formatOneDecimal(record.weight), name = CONTENT.Weight }
    items[#items + 1] = { text = l10n('Value'), value = math.floor(value), name = CONTENT.Value }
    return {
        name = 'Miscellaneous',
        arrange = ui.ALIGNMENT.Center,
        items = items,
    }
end

Tooltips.npcRecipe = function(tooltip)
    local record = types.NPC.records[tooltip.key or tooltip.object.recordId]
    if not record then return end
    local items = {}
    items[#items + 1] = header(record, tooltip.object)
    return {
        name = 'NPC',
        arrange = ui.ALIGNMENT.Center,
        items = items,
    }
end

Tooltips.lightRecipe = function(tooltip)
    local record = types.Light.records[tooltip.key or tooltip.object.recordId]
    if not record then return end
    if record.name == '' then return end
    local items = {}
    items[#items + 1] = header(record, tooltip.object)
    items[#items + 1] = { text = l10n('Weight'), value = Tooltips.formatOneDecimal(record.weight), name = CONTENT.Weight }
    items[#items + 1] = { text = l10n('Value'), value = math.floor(record.value), name = CONTENT.Value }
    return {
        name = 'Light',
        arrange = ui.ALIGNMENT.Center,
        items = items,
    }
end

Tooltips.lockpickRecipe = function(tooltip)
    local record = types.Lockpick.records[tooltip.key or tooltip.object.recordId]
    if not record then return end
    local uses = getCondition(tooltip.object) or record.maxCondition
    local items = {}
    items[#items + 1] = header(record, tooltip.object)
    items[#items + 1] = { text = l10n('Uses'), value = tostring(uses), name = CONTENT.Condition }
    items[#items + 1] = { text = l10n('Weight'), value = Tooltips.formatOneDecimal(record.weight), name = CONTENT.Weight }
    items[#items + 1] = { text = l10n('Value'), value = math.floor(record.value), name = CONTENT.Value }
    return {
        name = 'Lockpick',
        arrange = ui.ALIGNMENT.Center,
        items = items,
    }
end

Tooltips.playerRecipe = function(_)
    -- Default empty
end

Tooltips.potionRecipe = function(tooltip)
    local record = types.Potion.records[tooltip.key or tooltip.object.recordId]
    ---@cast record openmw.types.PotionRecord
    local items = {}
    local unknown = nil
    if tooltip.observer then
        local skill = helpers.getSkill(tooltip.observer, 'alchemy') or 100
        local multiplier = math.floor(skill / gmsts.fWortChanceValue)
        unknown = helpers.unknownEffects(record.effects, 2 * multiplier)
    end
    items[#items + 1] = header(record, tooltip.object)
    items[#items + 1] = { text = l10n('Weight'), value = Tooltips.formatOneDecimal(record.weight), name = CONTENT.Weight }
    items[#items + 1] = { text = l10n('Value'), value = math.floor(record.value), name = CONTENT.Value }
    items[#items + 1] = {
        type = 'magicEffects',
        unknown = unknown,
        effects = record.effects,
        skipTarget = true,
        skipMagnitude = true,
        skipDuration = true,
        name =
            CONTENT.MagicEffects
    }
    return {
        name = 'Potion',
        arrange = ui.ALIGNMENT.Center,
        items = items,
    }
end

Tooltips.probeRecipe = function(tooltip)
    local record = types.Probe.records[tooltip.key or tooltip.object.recordId]
    if not record then return end
    local uses = getCondition(tooltip.object) or record.maxCondition
    local items = {}
    items[#items + 1] = header(record, tooltip.object)
    items[#items + 1] = { text = l10n('Uses'), value = tostring(uses), name = CONTENT.Condition }
    items[#items + 1] = { text = l10n('Weight'), value = Tooltips.formatOneDecimal(record.weight), name = CONTENT.Weight }
    items[#items + 1] = { text = l10n('Value'), value = math.floor(record.value), name = CONTENT.Value }
    return {
        name = 'Probe',
        arrange = ui.ALIGNMENT.Center,
        items = items,
    }
end

Tooltips.repairRecipe = function(tooltip)
    local record = types.Repair.records[tooltip.key or tooltip.object.recordId]
    if not record then return end
    local uses = getCondition(tooltip.object) or record.maxCondition
    local items = {}
    items[#items + 1] = header(record, tooltip.object)
    items[#items + 1] = { text = l10n('Uses'), value = tostring(uses), name = CONTENT.Condition }
    items[#items + 1] = { text = l10n('Weight'), value = Tooltips.formatOneDecimal(record.weight), name = CONTENT.Weight }
    items[#items + 1] = { text = l10n('Value'), value = math.floor(record.value), name = CONTENT.Value }
    return {
        name = 'Repair',
        arrange = ui.ALIGNMENT.Center,
        items = items,
    }
end

Tooltips.staticRecipe = function(_)
    -- Default empty
end

Tooltips.weaponRecipe = function(tooltip)
    local record = types.Weapon.records[tooltip.key or tooltip.object.recordId]
    ---@cast record openmw.types.WeaponRecord
    local items = {}
    local condition = getCondition(tooltip.object) or record.health
    items[#items + 1] = header(record, tooltip.object)

    if not isAmmo[record.type] then
        items[#items + 1] = { text = l10n('Type') .. ' ' .. weaponTypeToName[record.type], name = CONTENT.WeaponType }
    end
    if isMelee[record.type] then
        items[#items + 1] = {
            text = l10n('Chop'),
            min = record.chopMinDamage,
            max = record.chopMaxDamage,
            name = CONTENT.Damage
        }
        items[#items + 1] = {
            text = l10n('Slash'),
            min = record.slashMinDamage,
            max = record.slashMaxDamage,
            name = CONTENT.Damage
        }
        items[#items + 1] = {
            text = l10n('Thrust'),
            min = record.thrustMinDamage,
            max = record.thrustMaxDamage,
            name = CONTENT.Damage
        }
    elseif isMarksman[record.type] then
        items[#items + 1] = {
            text = l10n('Attack'),
            min = record.chopMinDamage,
            max = record.chopMaxDamage,
            name = CONTENT.Damage
        }
    end

    if condition and not noHealth[record.type] then
        items[#items + 1] = {
            text = l10n('Condition'),
            value = tostring(condition) .. '/' .. tostring(record.health),
            name = CONTENT.Condition
        }
    end
    items[#items + 1] = { text = l10n('Weight'), value = Tooltips.formatOneDecimal(record.weight), name = CONTENT.Weight }
    items[#items + 1] = { text = l10n('Value'), value = math.floor(record.value), name = CONTENT.Value }
    enchantment(items, record, tooltip.object)
    return {
        name = 'Weapon',
        arrange = ui.ALIGNMENT.Center,
        items = items,
    }
end

local attributeMultiplier = function(attribute, player)
    local increases = types.Actor.stats.level(player).skillIncreasesForAttribute
    if types.Actor.stats.attributes[attribute](player).base < 100 then
        local increase = increases[attribute]
        if increase >= 10 then
            return 5
        elseif increase >= 7 then
            return 4
        elseif increase >= 5 then
            return 3
        elseif increase >= 1 then
            return 2
        end
        return 1
    end
    return 0
end

Tooltips.formatOneDecimal = function(n)
    -- Format with 1 decimal and then remove trailing .0
    return string.format("%.1f", n):gsub("%.0$", "")
end

Tooltips.buildTooltip = function(recipe, tooltip)
    return Tooltips.builders.root(recipe, tooltip)
end

Tooltips.activeEffectRecipe = function(tooltip)
    if not tooltip.observer or not Actor.objectIsInstance(tooltip.observer) then
        -- Only actors can have active effects
        return
    end
    local mgef = core.magic.effects.records[tooltip.key]

    -- This header is centered despite the rest of the tooltip being aligned left.
    local items = {
        { type = 'header', title = mgef.name, image = mgef.icon, iconSize = V2(16, 16), align = ui.ALIGNMENT.Center },
    }

    for _, activeSpell in pairs(Actor.activeSpells(tooltip.observer)) do
        for _, activeEffect in pairs(activeSpell.effects) do
            if activeEffect.id == mgef.id then
                local magnitude = math.floor(activeEffect.magnitudeThisFrame)
                items[#items + 1] = {
                    text = helpers.formatActiveEffectName(activeSpell.name, mgef, activeEffect),
                    value = magnitude .. helpers.getMagicEffectUnits(mgef, magnitude > 1)
                }
            end
        end
    end

    -- TODO: Duration setting

    return {
        type = Tooltips.TYPE.ActiveSpellEffect,
        items = items
    }
end

Tooltips.attributeRecipe = function(tooltip)
    if not tooltip.key then return end
    local attribute = core.stats.Attribute.records[tooltip.key]
    if not attribute then return end

    return {
        type = Tooltips.TYPE.Attribute,
        gap = 4,
        items = {
            { type = 'header',    title = attribute.name,      image = attribute.icon },
            { type = 'paragraph', text = attribute.description },
        }
    }
end

Tooltips.birthSignRecipe = function(tooltip)
    local sign = types.Player.birthSigns.records[tooltip.key]
    if not sign then return end

    return {
        type = Tooltips.TYPE.BirthSign,
        arrange = ui.ALIGNMENT.Center,
        gap = 2,
        items = {
            { type = 'banner',    image = sign.texture },
            { type = 'header',    title = sign.name },
            { type = 'paragraph', text = sign.description },
            { type = 'spellList', spells = sign.spells }
        }
    }
end

Tooltips.captionRecipe = function(tooltip)
    if not tooltip.caption then return end

    return {
        type = Tooltips.TYPE.Caption,
        items = {
            { type = 'paragraph', text = tooltip.caption },
        },
    }
end

Tooltips.captionOneLineRecipe = function(tooltip)
    if not tooltip.caption then return end

    return {
        type = Tooltips.TYPE.CaptionOneLine,
        items = {
            { text = tooltip.caption },
        },
    }
end

Tooltips.classRecipe = function(tooltip)
    if not tooltip.key then return end
    local class = types.NPC.classes.records[tooltip.key]
    if not class then return end
    local items = {
        { type = 'header', title = class.name },
    }
    if class.description and #class.description > 0 then
        items[#items + 1] = { type = 'paragraph', text = class.description }
    end
    if class.specialization then
        items[#items + 1] = { text = l10n('Specialization') .. ': ' .. class.specialization }
    end

    return {
        type = Tooltips.TYPE.Class,
        arrange = ui.ALIGNMENT.Center,
        gap = 4,
        items = items,
    }
end

Tooltips.factionRecipe = function(tooltip)
    if not tooltip.observer or not NPC.objectIsInstance(tooltip.observer) then
        -- Only NPCs and Players can have a faction
        return
    end
    local faction = core.factions.records[tooltip.key]
    if not faction then return end
    local isExpelled = types.NPC.isExpelled(tooltip.observer, tooltip.key)
    local rank = types.NPC.getFactionRank(tooltip.observer, tooltip.key)

    local items = {
        { type = 'header', title = faction.name },
    }
    local recipe = {
        type = Tooltips.TYPE.Faction,
        items = items
    }

    if rank == 0 then
        return recipe
    end

    if isExpelled then
        items[#items + 1] = { text = l10n('EXPELLED'), name = CONTENT.EXPELLED }
        -- Rest of tooltip is skipped when expelled
        return recipe
    end

    items[#items + 1] = { type = 'factionRank', rank = rank, faction = faction.id }

    -- The rest of the tooltip is only included if not max rank
    rank = rank + 1
    if faction.ranks[rank] then
        -- Each section of the faction tooltip is separatet by an empty line
        items[#items + 1] = { type = 'gap' }
        items[#items + 1] = { type = 'factionNextRank', rank = rank, faction = faction.id }
        items[#items + 1] = { type = 'gap' }
        items[#items + 1] = { type = 'factionNextRankSkills', rank = rank, faction = faction.id }
        items[#items + 1] = { type = 'gap' }
        items[#items + 1] = { type = 'factionFavoriteSkills', rank = rank, faction = faction.id }
    end

    return recipe
end

Tooltips.handToHandRecipe = function(tooltip)
    local image = icons.handToHandNormal
    if tooltip.observer and NPC.objectIsInstance(tooltip.observer) and types.NPC.isWerewolf(tooltip.observer) then
        image = icons.handToHandWerewolf
    end

    return {
        type = Tooltips.TYPE.HandToHand,
        arrange = ui.ALIGNMENT.Center,
        items = {
            { type = 'header', subtitle = l10n('SkillHandToHand'), image = image, name = CONTENT.Header },
        },
    }
end

Tooltips.levelRecipe = function(tooltip)
    if not tooltip.observer or not Player.objectIsInstance(tooltip.observer) then
        -- Only Players can have level progress
        return
    end
    local level = types.Actor.stats.level(tooltip.observer)
    local items = {
        { type = 'header',      title = l10n('LevelProgress') },
        { type = 'progressBar', current = level.progress,     max = 10 },
    }
    for _, v in pairs(core.stats.Attribute.records) do
        local multiplier = attributeMultiplier(v.id, tooltip.observer)
        if multiplier > 1 then
            items[#items + 1] = { text = v.name .. ' x' .. tostring(multiplier) }
        end
    end

    return {
        type = Tooltips.TYPE.Level,
        gap = 4,
        arrange = ui.ALIGNMENT.Center,
        items = items,
    }
end

Tooltips.magicEffectRecipe = function(tooltip)
    if not tooltip.key then return end
    local mgef = core.magic.effects.records[tooltip.key]
    if not mgef then return end
    local school = core.stats.Skill.record(mgef.school or 'alteration')
    local schoolText = l10n('School') .. ': ' .. school.name

    return {
        type = Tooltips.TYPE.MagicEffect,
        gap = 4,
        items = {
            { type = 'header',    image = mgef.icon,      title = mgef.name, subtitle = schoolText },
            { type = 'paragraph', text = mgef.description }
        },
    }
end

Tooltips.mapMarkerRecipe = function(tooltip)
    local items = {}
    if tooltip.caption then
        items[#items + 1] = { text = tooltip.caption }
    end

    for _, note in ipairs(tooltip.notes or {}) do
        items[#items + 1] = { type = 'note', text = note }
    end

    return {
        type = Tooltips.TYPE.MapMarker,
        gap = 4,
        arrange = ui.ALIGNMENT.Center,
        items = items,
    }
end

Tooltips.raceRecipe = function(tooltip)
    if not tooltip.key then return end
    local race = types.NPC.races.records[tooltip.key]
    if not race then return end
    local items = {
        { type = 'header', title = race.name },
    }
    if race.description and #race.description > 0 then
        items[#items + 1] = { type = 'paragraph', text = race.description }
    end

    return {
        type = Tooltips.TYPE.Class,
        arrange = ui.ALIGNMENT.Center,
        gap = 4,
        items = items,
    }
end

Tooltips.skillRecipe = function(tooltip)
    if not tooltip.key then return end
    local record = core.stats.Skill.records[tooltip.key]
    if not record then return end

    local subtitle = nil
    local governingAttribute = record.attribute and core.stats.Attribute.record(record.attribute)
    if governingAttribute then
        subtitle = l10n('GoverningAttribute') .. ': ' .. governingAttribute.name
    end
    local items = {
        { type = 'header',    title = record.name,      subtitle = subtitle, image = record.icon },
        { type = 'paragraph', text = record.description },
    }

    if tooltip.observer and NPC.objectIsInstance(tooltip.observer) then
        local skill = NPC.stats.skills[record.id](tooltip.observer)
        if skill.base < 100 then
            local current = math.floor(skill.progress * 100)
            local theme = I.UIToolkit.getTheme()

            items[#items + 1] = { type = 'header', title = l10n('SkillProgress'), align = ui.ALIGNMENT.Center }
            items[#items + 1] = {
                type = 'progressBar',
                current = current,
                color = theme.Colors.HEALTH,
                align = ui
                    .ALIGNMENT.Center
            }
        else
            items[#items + 1] = { type = 'gap' }
            items[#items + 1] = { text = l10n('SkillMaxed'), align = ui.ALIGNMENT.Center }
        end
    end

    return {
        type = Tooltips.TYPE.Skill,
        gap = 4,
        items = items,
    }
end

Tooltips.specializationRecipe = function(tooltip)
    if not tooltip.key then return end

    local list = {}
    for _, skill in pairs(core.stats.Skill.records) do
        if skill.specialization == tooltip.key then
            list[#list + 1] = skill.name
        end
    end

    return {
        type = Tooltips.TYPE.Specialization,
        gap = 4,
        items = {
            { type = 'header', title = l10n(tooltip.key), align = ui.ALIGNMENT.Center },
            { type = 'list',   list = list }
        }
    }
end

Tooltips.spellRecipe = function(tooltip)
    if not tooltip.key then return end
    local spell = core.magic.spells.records[tooltip.key]
    if not spell then return end

    -- TODO: Accurately compute school
    local mgef = spell.effects[1].effect
    if not mgef then return end
    local school = core.stats.Skill.record(mgef.school or 'alteration')
    local schoolText = l10n('School') .. ': ' .. school.name

    return {
        type = Tooltips.TYPE.Spell,
        arrange = ui.ALIGNMENT.Center,
        items = {
            { type = 'header',       title = spell.name },
            { text = schoolText },
            { type = 'magicEffects', effects = spell.effects, name = CONTENT.MagicEffects },
        },
    }
end

Tooltips.statRecipe = function(tooltip)
    if not tooltip.key then return end
    local description = l10n(tooltip.key .. 'Description')
    if tooltip.observer and Actor.objectIsInstance(tooltip.observer) then
        local stat = types.Actor.stats.dynamic[tooltip.key](tooltip.observer)
        description = description .. '\n' .. stat.base .. ' / ' .. math.floor(stat.current)
    end
    return {
        type = Tooltips.TYPE.Stat,
        items = {
            { type = 'header', subtitle = description, image = icons[tooltip.key], name = CONTENT.Header }
        }
    }
end

Tooltips.recipes = {
    [Tooltips.TYPE.Activator] = Tooltips.activatorRecipe,
    [Tooltips.TYPE.Apparatus] = Tooltips.apparatusRecipe,
    [Tooltips.TYPE.Armor] = Tooltips.armorRecipe,
    [Tooltips.TYPE.Book] = Tooltips.bookRecipe,
    [Tooltips.TYPE.Clothing] = Tooltips.clothingRecipe,
    [Tooltips.TYPE.Container] = Tooltips.containerRecipe,
    [Tooltips.TYPE.Creature] = Tooltips.creatureRecipe,
    [Tooltips.TYPE.Door] = Tooltips.doorRecipe,
    [Tooltips.TYPE.Ingredient] = Tooltips.ingredientRecipe,
    [Tooltips.TYPE.Light] = Tooltips.lightRecipe,
    [Tooltips.TYPE.Lockpick] = Tooltips.lockpickRecipe,
    [Tooltips.TYPE.Miscellaneous] = Tooltips.miscellaneousRecipe,
    [Tooltips.TYPE.NPC] = Tooltips.npcRecipe,
    [Tooltips.TYPE.Player] = Tooltips.playerRecipe,
    [Tooltips.TYPE.Potion] = Tooltips.potionRecipe,
    [Tooltips.TYPE.Probe] = Tooltips.probeRecipe,
    [Tooltips.TYPE.Repair] = Tooltips.repairRecipe,
    [Tooltips.TYPE.Static] = Tooltips.staticRecipe,
    [Tooltips.TYPE.Weapon] = Tooltips.weaponRecipe,
    [Tooltips.TYPE.ActiveSpellEffect] = Tooltips.activeEffectRecipe,
    [Tooltips.TYPE.Attribute] = Tooltips.attributeRecipe,
    [Tooltips.TYPE.BirthSign] = Tooltips.birthSignRecipe,
    [Tooltips.TYPE.CaptionOneLine] = Tooltips.captionOneLineRecipe,
    [Tooltips.TYPE.Caption] = Tooltips.captionRecipe,
    [Tooltips.TYPE.Class] = Tooltips.classRecipe,
    [Tooltips.TYPE.Faction] = Tooltips.factionRecipe,
    [Tooltips.TYPE.HandToHand] = Tooltips.handToHandRecipe,
    [Tooltips.TYPE.Level] = Tooltips.levelRecipe,
    [Tooltips.TYPE.MagicEffect] = Tooltips.magicEffectRecipe,
    [Tooltips.TYPE.MapMarker] = Tooltips.mapMarkerRecipe,
    [Tooltips.TYPE.Race] = Tooltips.raceRecipe,
    [Tooltips.TYPE.Skill] = Tooltips.skillRecipe,
    [Tooltips.TYPE.Specialization] = Tooltips.specializationRecipe,
    [Tooltips.TYPE.Spell] = Tooltips.spellRecipe,
    [Tooltips.TYPE.Stat] = Tooltips.statRecipe,
}

return Tooltips
