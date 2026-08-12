---@omw-context player

local camera = require('openmw.camera')
local core = require('openmw.core')
local util = require('openmw.util')
local types = require('openmw.types')
local Creature = types.Creature
local Item = types.Item
local Lockable = types.Lockable
local NPC = types.NPC

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
