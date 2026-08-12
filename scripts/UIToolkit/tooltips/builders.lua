---@omw-context player

local core = require('openmw.core')
local util = require('openmw.util')
local ui = require('openmw.ui')
local I = require('openmw.interfaces')
local helpers = require('scripts.UIToolkit.tooltips.utils')

-- Short-hands
local V2 = util.vector2
local T = {
    Base = require('scripts.UIToolkit.templates.base'),
}
local Builders = {}

local resources =
{
    handToHandNormal = ui.texture { path = 'icons/k/stealth_handtohand.dds' },
    handToHandWerewolf = ui.texture { path = 'icons/k/tx_werewolf_hand.dds' },
    healthIcon = ui.texture { path = 'icons/k/health.dds' },
    magickaIcon = ui.texture { path = 'icons/k/magicka.dds' },
    fatigueIcon = ui.texture { path = 'icons/k/fatigue.dds' },
    doorIcon = ui.texture { path = 'textures/door_icon.dds', size = V2(8, 8) }
}

local l10n = core.l10n('UTKTooltips')

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

local function textHeader(text, name)
    return {
        template = I.MWUI.templates.textHeader,
        name = name,
        props = {
            text = text,
            textAlignH = ui.ALIGNMENT.Center
        }
    }
end

local function textNormal(text, name)
    return {
        template = I.MWUI.templates.textNormal,
        name = name,
        props = {
            text = text,
            textAlignH = ui.ALIGNMENT.Center
        }
    }
end

local function textParagraph(text, name)
    return {
        template = I.MWUI.templates.textParagraph,
        name = name,
        props = {
            text = text,
            size = V2(400, 0),
        }
    }
end

local nameWithArgument = {
    [core.magic.EFFECT_TYPE.AbsorbAttribute] = 'AbsorbEffectName',
    [core.magic.EFFECT_TYPE.AbsorbSkill] = 'AbsorbEffectName',
    [core.magic.EFFECT_TYPE.DamageAttribute] = 'DamageEffectName',
    [core.magic.EFFECT_TYPE.DamageSkill] = 'DamageEffectName',
    [core.magic.EFFECT_TYPE.DrainAttribute] = 'DrainEffectName',
    [core.magic.EFFECT_TYPE.DrainSkill] = 'DrainEffectName',
    [core.magic.EFFECT_TYPE.FortifyAttribute] = 'FortifyEffectName',
    [core.magic.EFFECT_TYPE.FortifySkill] = 'FortifyEffectName',
    [core.magic.EFFECT_TYPE.RestoreAttribute] = 'RestoreEffectName',
    [core.magic.EFFECT_TYPE.RestoreSkill] = 'RestoreEffectName',
}

local function magicEffectName(effect)
    local mgef = effect.effect
    local namePattern = nameWithArgument[mgef.id]
    if not namePattern then
        return mgef.name
    end
    local argument = "Unknown"
    if mgef.hasAttribute then
        local record = core.stats.Attribute.record(effect.affectedAttribute)
        if record then
            argument = record.name
        end
    elseif mgef.hasSkill then
        local record = core.stats.Skill.record(effect.affectedSkill)
        if record then
            argument = record.name
        end
    end
    return l10n(namePattern, { argument = argument })
end

local function effectDescription(content, effect, noTarget, noMagnitude, noDuration)
    local mgef = effect.effect
    local tex = ui.texture { path = mgef.icon }
    local icon = {
        template = T.Base.padding(4),
        content = ui.content { {
            type = ui.TYPE.Image,
            props = {
                resource = tex,
                size = util.vector2(16, 16),
            },
        } },
    }

    local effectString = magicEffectName(effect)
    if mgef.hasMagnitude and not noMagnitude then
        effectString = effectString .. ' '
        local min = effect.magnitudeMin
        local max = effect.magnitudeMax
        if min ~= max then
            effectString = effectString .. tostring(min) .. ' ' .. l10n('To') .. ' '
        end
        effectString = effectString .. tostring(max) .. ' '
        if not mgefMagnitudeDisplayType[mgef.id] then
            -- Points
            if max == 1 then
                effectString = effectString .. l10n('point')
            else
                effectString = effectString .. l10n('points')
            end
        elseif mgefMagnitudeDisplayType[mgef.id] == magnitudeDisplayTypes.Feet then
            effectString = effectString .. l10n('feet')
        elseif mgefMagnitudeDisplayType[mgef.id] == magnitudeDisplayTypes.Level then
            if max == 1 then
                effectString = effectString .. l10n('Level')
            else
                effectString = effectString .. l10n('Levels')
            end
        elseif mgefMagnitudeDisplayType[mgef.id] == magnitudeDisplayTypes.Percentage then
            effectString = effectString .. l10n('percent')
        elseif mgefMagnitudeDisplayType[mgef.id] == magnitudeDisplayTypes.TimesInt then
            effectString = effectString .. l10n('XTimesINT')
        end
    end

    if mgef.hasDuration and not noDuration then
        effectString = effectString .. ' ' .. tostring(effect.duration) .. ' '
        if effect.duration == 1 then
            effectString = effectString .. l10n('second')
        else
            effectString = effectString .. l10n('seconds')
        end
    end

    if not noTarget then
        effectString = effectString .. ' ' .. l10n('On') .. ' '
        if effect.range == core.magic.RANGE.Self then
            effectString = effectString .. l10n('RangeSelf')
        elseif effect.range == core.magic.RANGE.Target then
            effectString = effectString .. l10n('RangeTarget')
        elseif effect.range == core.magic.RANGE.Touch then
            effectString = effectString .. l10n('RangeTouch')
        end
    end

    local text = textNormal(effectString)
    local flex = {
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
            arrange = ui.ALIGNMENT.Center,
        },
        content = ui.content {
            icon,
            text,
        }
    }
    content:add(flex)
end

local function centerFlex(content, gap)
    return {
        type = ui.TYPE.Flex,
        props = {
            arrange = ui.ALIGNMENT.Center,
            gap = gap,
        },
        content = content,
    }
end

local spellTypeToString = {
    [core.magic.SPELL_TYPE.Ability] = l10n('Abilities'),
    [core.magic.SPELL_TYPE.Power] = l10n('Powers'),
    [core.magic.SPELL_TYPE.Spell] = l10n('Spells'),
}

local spellsByType = function(spells)
    local spellsByType = {}
    for _, V in pairs(spells) do
        local spell = core.magic.spells.record(V)
        if spell then
            local type = spellTypeToString[spell.type]
            local list = spellsByType[type] or {}
            list[#list + 1] = spell.name
            spellsByType[type] = list
        end
    end
    return spellsByType
end

local function getFactionAndRank(item)
    assert(item.faction ~= nil)
    assert(item.rank ~= nil)
    assert(item.rank > 0)
    local faction = core.factions.record(item.faction)
    assert(faction)
    assert(faction.ranks[item.rank])
    return faction, faction.ranks[item.rank]
end

local function mapMarkerNoteText(text)
    local maxLength = 60
    local newlineIndex = string.find(text, '\n')
    maxLength = math.min(newlineIndex or maxLength, maxLength)
    if maxLength < #text then
        text = string.sub(text, 0, maxLength) .. ' ...'
    end
    return textNormal(text, 'map marker note text')
end

local mapMarkerNoteBox = {
    type = ui.TYPE.Image,
    name = 'map marker note icon',
    props = {
        resource = resources.doorIcon,
        size = V2(8, 8),
        color = util.color.rgb(1, 0.3, 0.3)
    },
}

function Builders.banner(item)
    assert(item.image)
    local size = item.size or V2(259, 133)
    return {
        template = I.MWUI.templates.box,
        content = ui.content { {
            type = ui.TYPE.Image,
            props = {
                resource = ui.texture { path = item.image },
                size = size,
            },
        } },
    }
end

local effectUnknownLayout = {
    type = ui.TYPE.Flex,
    props = { arrange = ui.ALIGNMENT.Center },
    external = { stretch = 1 },
    content = ui.content { textNormal('?') },
}

function Builders.magicEffects(item)
    assert(item.effects)
    local effectLines = ui.content {}
    for i = 1, helpers.maxEffectIndex(item.effects) do
        local effect = item.effects[i]
        if effect then
            if item.unknown and item.unknown[i] then
                effectLines:add(effectUnknownLayout)
            else
                effectDescription(effectLines, effect, item.skipTarget, item.skipMagnitude, item.skipDuration)
            end
        end
    end
    return {
        type = ui.TYPE.Flex,
        content = effectLines,
    }
end

function Builders.factionRank(item)
    local _, rank = getFactionAndRank(item)
    return textNormal(rank.name)
end

function Builders.factionNextRank(item)
    local faction, rank = getFactionAndRank(item)

    -- Attribute requirement
    local attributesText = ''
    for i, attributeId in ipairs(faction.attributes) do
        local attribute = core.stats.Attribute.record(attributeId)
        local requirement = rank.attributeValues[i]
        if i > 1 then
            attributesText = attributesText .. ', '
        end
        attributesText = attributesText .. attribute.name .. ': ' .. tostring(requirement)
    end

    return {
        type = ui.TYPE.Flex,
        content = ui.content {
            textHeader(l10n('NextRank') .. ': ' .. rank.name),
            textParagraph(attributesText),
        }
    }
end

function Builders.factionNextRankSkills(item)
    local faction = getFactionAndRank(item)
    local skillsText = ''
    for i, skillId in ipairs(faction.skills) do
        local skill = core.stats.Skill.record(skillId)
        if i > 1 then
            skillsText = skillsText .. ', '
        end
        skillsText = skillsText .. skill.name
    end
    return {
        type = ui.TYPE.Flex,
        content = ui.content {
            textHeader(l10n('FavoriteSkills')),
            textParagraph(skillsText),
        }
    }
end

function Builders.factionFavoriteSkills(item)
    local _, rank = getFactionAndRank(item)
    local textKey = (rank.favouredSkillValue > 0) and 'NextRankTwoSkills' or 'NextRankOneSkill'
    local skillRequirementText = l10n(textKey, {
        primary = rank.primarySkillValue,
        secondary = rank.favouredSkillValue,
    })
    return {
        type = ui.TYPE.Flex,
        content = ui.content {
            textHeader(l10n('FavoriteSkills')),
            textParagraph(skillRequirementText),
        }
    }
end

function Builders.gap(item)
    local size = item.size or 16
    return {
        type = ui.TYPE.Widget,
        props = {
            size = util.vector2(size, size)
        },
        external = {
            grow = item.grow,
        },
    }
end

function Builders.header(item)
    local title = item.title
    local subtitle = item.subtitle
    local icon = item.image
    local iconSize = item.iconSize or V2(32, 32)
    local header = ui.content {}
    if icon then
        header:add {
            type = ui.TYPE.Image,
            props = {
                resource = ui.texture { path = icon },
                size = iconSize,
            }
        }
    end
    local textContent = ui.content {}
    header:add {
        type = ui.TYPE.Flex,
        props = {
            arrange = ui.ALIGNMENT.Start,
        },
        content = textContent,
    }
    if title then
        textContent:add(textHeader(title, 'Title'))
    end
    if subtitle then
        textContent:add(textParagraph(subtitle, 'Subtitle'))
    end
    local theme = I.UIToolkit.getTheme()
    return {
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
            arrange = ui.ALIGNMENT.Center,
            gap = theme.Sizes.standardGap,
        },
        content = header
    }
end

function Builders.list(item)
    assert(item.list ~= nil)
    local listContent = ui.content {}
    for _, v in pairs(item.list) do
        listContent:add(textNormal(tostring(v)))
    end
    return {
        type = ui.TYPE.Flex,
        content = listContent,
        props = {
            arrange = item.arrange,
            align = item.align,
            horizontal = item.horizontal,
        },
        external = {
            stretch = item.stretch or 1,
            grow = item.grow,
        },
    }
end

function Builders.note(item)
    local theme = I.UIToolkit.getTheme()
    return {
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
            arrange = ui.ALIGNMENT.Center,
            gap = theme.Sizes.smallGap,
        },
        content = ui.content {
            mapMarkerNoteBox,
            mapMarkerNoteText(item.text),
        }
    }
end

function Builders.paragraph(item)
    assert(item.text ~= nil)
    return textParagraph(item.text)
end

function Builders.progressBar(item)
    local theme = I.UIToolkit.getTheme()
    local current = item.current or 0
    local max = item.max or 100
    local color = item.color or theme.Colors.HEALTH
    local barWidth = item.barWidth or 204
    barWidth = math.max(0, math.min(1, current / max)) * barWidth
    local barText = tostring(math.floor(current)) .. '/' .. tostring(math.floor(max))
    return {
        template = I.MWUI.templates.box,
        content = ui.content { {
            type = ui.TYPE.Widget,
            props = {
                size = V2(204, 16),
            },
            content = ui.content {
                {
                    template = I.MWUI.templates.textNormal,
                    props = {
                        text = barText,
                        textShadow = true,
                        textAlignH = ui.ALIGNMENT.Center,
                        textAlignV = ui.ALIGNMENT.Center,
                        -- relativePosition + anchor would have been simpler, but text coming out of
                        -- text widgets are slightly misaligned and need to be manually raised 2 pixels
                        autoSize = false,
                        relativeSize = V2(1, 1),
                        position = V2(0, -2),
                    }
                },
                {
                    type = ui.TYPE.Image,
                    props = {
                        size = V2(barWidth, 16),
                        resource = theme.Colors.menuBarGray,
                        color = color,
                    },
                },
            },
        } }
    }
end

function Builders.root(recipe, tooltip)
    if not recipe then return end
    assert(recipe.items ~= nil)
    if #recipe.items == 0 then return end

    local arrange = recipe.arrange or ui.ALIGNMENT.Start

    local content = ui.content {}
    local layout = {
        type = ui.TYPE.Flex,
        props = {
            arrange = recipe.arrange,
            align = recipe.align,
            gap = recipe.gap,
            horizontal = recipe.horizontal,
        },
        external = {
            stretch = recipe.stretch,
            grow = recipe.grow,
        },
        content = content,
    }

    for _, item in ipairs(recipe.items) do
        local type = item.type
        if not type or type == '' then type = 'default' end
        local func = Builders[type]
        assert(func ~= nil)
        local itemLayout = func(item, tooltip)
        itemLayout.name = item.name
        if itemLayout and item.align and item.align ~= arrange then
            -- Accomodate for some tooltip entries in vanilla being centered when the rest of the tooltip is aligned left
            -- and vice versa.
            content:add {
                type = ui.TYPE.Flex,
                props = { arrange = item.align },
                content = ui.content { itemLayout },
                external = { stretch = 1 },
            }
        else
            content:add(itemLayout)
        end
    end

    return layout
end

function Builders.spellList(item)
    assert(item.spells ~= nil)

    local spells = spellsByType(item.spells)
    local content = ui.content {}
    for name, list in pairs(spells) do
        content:add(centerFlex(ui.content {
            textHeader(name),
            Builders.list({ list = list })
        }))
    end
    return centerFlex(content, 2)
end

function Builders.text(item)
    assert(item.text ~= nil)
    return textNormal(item.text)
end

function Builders.default(item)
    local str = item.text or ''
    if item.value and item.value ~= '' then
        if str ~= '' then str = str .. ': ' end
        str = str .. tostring(item.value)
    elseif item.min and item.max then
        if str ~= '' then str = str .. ': ' end
        str = str .. tostring(item.min) .. ' - ' .. tostring(item.max)
    end
    return textNormal(str, item.name)
end

return Builders
