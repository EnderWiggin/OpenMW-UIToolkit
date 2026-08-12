---@omw-context player

local camera = require('openmw.camera')
local core = require('openmw.core')
local util = require('openmw.util')
local types = require('openmw.types')
local Creature = types.Creature
local Item = types.Item
local Lockable = types.Lockable
local NPC = types.NPC

local l10n = core.l10n('UTKTooltips')
local Utils = {}

function Utils.determineType(object, recordId)
    if object then return object.type end
    for _, table in pairs(types) do
        if table.records[recordId] then return table end
    end
    return nil
end

function Utils.formatActiveEffectName(name, mgef, aef)
    local text = name
    if mgef.hasAttribute then
        local attribute = core.stats.Attribute.record(aef.affectedAttribute)
        text = text .. ' (' .. attribute.name .. ')'
    elseif mgef.hasSkill then
        local skill = core.stats.Skill.record(aef.affectedSkill)
        text = text .. ' (' .. skill.name .. ')'
    end
    return text
end

local magnitudeDisplayTypes =
{
    None = 'None',
    TimesInt = 'TimesInt',
    Feet = 'Feet',
    Level = 'Level',
    Percentage = 'Percentage',
    Points = 'Points',
}

-- To keep from going mad filling out this table
-- only fill out effects that DON'T return 'Points'
-- Leaving None to be determined by .hasMagnitude
local mgefMagnitudeDisplayType =
{
    -- Feet
    [core.magic.EFFECT_TYPE.DetectAnimal] = magnitudeDisplayTypes.Feet,
    [core.magic.EFFECT_TYPE.DetectEnchantment] = magnitudeDisplayTypes.Feet,
    [core.magic.EFFECT_TYPE.DetectKey] = magnitudeDisplayTypes.Feet,
    [core.magic.EFFECT_TYPE.Telekinesis] = magnitudeDisplayTypes.Feet,
    -- Level
    [core.magic.EFFECT_TYPE.CommandCreature] = magnitudeDisplayTypes.Level,
    [core.magic.EFFECT_TYPE.CommandHumanoid] = magnitudeDisplayTypes.Level,
    -- Times Int
    [core.magic.EFFECT_TYPE.FortifyMaximumMagicka] = magnitudeDisplayTypes.TimesInt,
    -- Percentage
    [core.magic.EFFECT_TYPE.Blind] = magnitudeDisplayTypes.Percentage,
    [core.magic.EFFECT_TYPE.Chameleon] = magnitudeDisplayTypes.Percentage,
    [core.magic.EFFECT_TYPE.Dispel] = magnitudeDisplayTypes.Percentage,
    [core.magic.EFFECT_TYPE.Reflect] = magnitudeDisplayTypes.Percentage,
    [core.magic.EFFECT_TYPE.ResistBlightDisease] = magnitudeDisplayTypes.Percentage,
    [core.magic.EFFECT_TYPE.ResistCommonDisease] = magnitudeDisplayTypes.Percentage,
    [core.magic.EFFECT_TYPE.ResistCorprusDisease] = magnitudeDisplayTypes.Percentage,
    [core.magic.EFFECT_TYPE.ResistFire] = magnitudeDisplayTypes.Percentage,
    [core.magic.EFFECT_TYPE.ResistFrost] = magnitudeDisplayTypes.Percentage,
    [core.magic.EFFECT_TYPE.ResistMagicka] = magnitudeDisplayTypes.Percentage,
    [core.magic.EFFECT_TYPE.ResistNormalWeapons] = magnitudeDisplayTypes.Percentage,
    [core.magic.EFFECT_TYPE.ResistParalysis] = magnitudeDisplayTypes.Percentage,
    [core.magic.EFFECT_TYPE.ResistPoison] = magnitudeDisplayTypes.Percentage,
    [core.magic.EFFECT_TYPE.ResistShock] = magnitudeDisplayTypes.Percentage,
    [core.magic.EFFECT_TYPE.WeaknessToBlightDisease] = magnitudeDisplayTypes.Percentage,
    [core.magic.EFFECT_TYPE.WeaknessToCommonDisease] = magnitudeDisplayTypes.Percentage,
    [core.magic.EFFECT_TYPE.WeaknessToCorprusDisease] = magnitudeDisplayTypes.Percentage,
    [core.magic.EFFECT_TYPE.WeaknessToFire] = magnitudeDisplayTypes.Percentage,
    [core.magic.EFFECT_TYPE.WeaknessToFrost] = magnitudeDisplayTypes.Percentage,
    [core.magic.EFFECT_TYPE.WeaknessToMagicka] = magnitudeDisplayTypes.Percentage,
    [core.magic.EFFECT_TYPE.WeaknessToNormalWeapons] = magnitudeDisplayTypes.Percentage,
    [core.magic.EFFECT_TYPE.WeaknessToPoison] = magnitudeDisplayTypes.Percentage,
    [core.magic.EFFECT_TYPE.WeaknessToShock] = magnitudeDisplayTypes.Percentage,
    -- None
    [core.magic.EFFECT_TYPE.Paralyze] = magnitudeDisplayTypes.None,
    [core.magic.EFFECT_TYPE.AlmsiviIntervention] = magnitudeDisplayTypes.None,
    [core.magic.EFFECT_TYPE.CureBlightDisease] = magnitudeDisplayTypes.None,
    [core.magic.EFFECT_TYPE.CureCommonDisease] = magnitudeDisplayTypes.None,
    [core.magic.EFFECT_TYPE.CureCorprusDisease] = magnitudeDisplayTypes.None,
    [core.magic.EFFECT_TYPE.CureParalyzation] = magnitudeDisplayTypes.None,
    [core.magic.EFFECT_TYPE.CurePoison] = magnitudeDisplayTypes.None,
    [core.magic.EFFECT_TYPE.Corprus] = magnitudeDisplayTypes.None,
    [core.magic.EFFECT_TYPE.DivineIntervention] = magnitudeDisplayTypes.None,
    [core.magic.EFFECT_TYPE.Paralyze] = magnitudeDisplayTypes.None,
    [core.magic.EFFECT_TYPE.Invisibility] = magnitudeDisplayTypes.None,
    [core.magic.EFFECT_TYPE.Mark] = magnitudeDisplayTypes.None,
    [core.magic.EFFECT_TYPE.Recall] = magnitudeDisplayTypes.None,
    [core.magic.EFFECT_TYPE.RemoveCurse] = magnitudeDisplayTypes.None,
    [core.magic.EFFECT_TYPE.Vampirism] = magnitudeDisplayTypes.None,
}

---@param mgef openmw.core.MagicEffect
---@param plural boolean
function Utils.getMagicEffectUnits(mgef, plural)
    local displayType = mgefMagnitudeDisplayType[mgef.id]
    local unit = ''
    if displayType == magnitudeDisplayTypes.TimesInt then
        unit = l10n('XTimesINT')
    elseif displayType == magnitudeDisplayTypes.Percentage then
        unit = l10n('Percent')
    elseif displayType == magnitudeDisplayTypes.Feet then
        unit = l10n('Feet')
    elseif displayType == magnitudeDisplayTypes.Level then
        unit = plural and l10n('Levels') or l10n('Level')
    elseif displayType == nil or displayType == magnitudeDisplayTypes.Points then
        unit = plural and l10n('Points') or l10n('Point')
    end
    return unit == '' and unit or ' ' .. unit
end

function Utils.getAnyRecord(id)
    -- We do not have a convenient way to translate a record ID to a record without knowing its type.
    -- So iterate over all existing types until we find the right one
    for _, t in pairs(types) do
        if t.records then
            local record = t.records[id]
            if record then
                return record, t
            end
        end
    end
end

function Utils.getSkill(actor, skillId)
    if actor and NPC.objectIsInstance(actor) then
        return NPC.stats.skills[skillId](actor).modified
    elseif actor and Creature.objectIsInstance(actor) then
        local specialization = core.stats.Skill.record(skillId).specialization
        local creatureRecord = Creature.record(actor)
        return creatureRecord[specialization .. 'Skill']
    end
end

function Utils.getSoul(object)
    if object and Item.objectIsInstance(object) then
        local soul = Item.itemData(object).soul
        if soul then
            return Utils.getAnyRecord(soul)
        end
    end
end

function Utils.isTrapped(object)
    if object
        and Lockable.objectIsInstance(object)
        and Lockable.getTrapSpell(object) then
        return true
    end
end

function Utils.soulGemValue(soulValue, baseValue, rebalanced)
    if not soulValue then return baseValue end
    if rebalanced then
        -- use the 'soul gem value rebalance' formula from the Morrowind Code Patch
        return 0.0001 * math.pow(soulValue, 3) + 2 * soulValue
    else
        return (baseValue or 0) * soulValue
    end
end

function Utils.maxEffectIndex(effects)
    local idx = 0
    for _, effect in pairs(effects) do
        -- effect.index is the c++ index, so we had to add 1
        idx = math.max(idx, effect.index + 1)
    end
    return idx
end

function Utils.unknownEffects(effects, max)
    local maxIndex = Utils.maxEffectIndex(effects)
    if max < maxIndex then
        local unknown = {}
        for i = max + 1, maxIndex do
            unknown[i] = true
        end
        return unknown
    end
end

function Utils.objectTooltipViewportCoords(object)
    local bb = object:getBoundingBox()
    if bb then
        local worldPos = bb.center + util.vector3(0, 0, bb.halfSize.z)
        local viewport = camera.worldToViewportVector(worldPos)
        return viewport
    end
end

return Utils
