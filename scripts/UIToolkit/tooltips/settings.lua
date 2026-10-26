---@omw-context menu

local I       = require 'openmw.interfaces'
local storage = require 'openmw.storage'


local O = require 'scripts.UIToolkit.config.defaults'
local D = require 'scripts.UIToolkit.tooltips.defaults'


--#region IMPORT

local old = storage.playerSection(O.Section.Interface)
local new = storage.playerSection(D.Section.Main)

---@param from string
---@param to string?
local function import(from, to)
    to = to or from
    if new:get(to) ~= nil then return end
    local value = old:get(from)
    if value == nil then return end
    new:set(to, value)
end

import('b_SoulGemValueRebalance')
import('b_ShowSoulValue')
import('b_CompactWeightValue')
import('b_ConditionAsBar')

--#endregion IMPORT

I.Settings.registerPage {
    key = D.PageKey,
    l10n = D.L10N,
    name = 'SettingPageName',
    description = 'SettingPageDesc',
}

I.Settings.registerGroup {
    page = D.PageKey,
    key = D.Section.Main,
    l10n = D.L10N,
    name = 'MainSettingsName',
    description = 'MainSettingsDesc',
    order = 1,
    permanentStorage = true,
    settings = {
        {
            key = 'b_SoulGemValueRebalance',
            renderer = 'checkbox',
            name = 'SettingSoulGemValueRebalanceName',
            description = 'SettingSoulGemValueRebalanceDesc',
            default = false,
        },
        {
            key = 'b_ShowSoulValue',
            renderer = 'checkbox',
            name = 'SettingShowSoulValueName',
            description = 'SettingShowSoulValueDesc',
            default = false,
        },
        {
            key = 'n_ShowSoulCapacity',
            renderer = 'UIToolkit/Dropbox',
            name = 'SettingShowSoulCapacityName',
            description = 'SettingShowSoulCapacityDesc',
            default = 0,
            argument = {
                l10n = D.L10N,
                items = {
                    { id = 0, text = 'SC_Never' },
                    { id = 1, text = 'SC_Empty' },
                    { id = 2, text = 'SC_Always' },
                },
            }
        },
        {
            key = 'n_ShowEnchantCapacity',
            renderer = 'UIToolkit/Dropbox',
            name = 'SettingShowEnchantCapacityName',
            description = 'SettingShowEnchantCapacityDesc',
            default = 0,
            argument = {
                l10n = D.L10N,
                items = {
                    { id = 0, text = 'EC_Never' },
                    { id = 1, text = 'EC_Empty' },
                    { id = 2, text = 'EC_Always' },
                },
            }
        },
        {
            key = 'b_ShowEnchantUseCost',
            renderer = 'checkbox',
            name = 'SettingShowEnchantUseCostName',
            description = 'SettingShowEnchantUseCostDesc',
            default = false,
        },
        {
            key = 'b_CompactWeightValue',
            renderer = 'checkbox',
            name = 'SettingCompactWeightValueName',
            description = 'SettingCompactWeightValueDesc',
            default = false,
        },
        {
            key = 'b_ConditionAsBar',
            renderer = 'checkbox',
            name = 'SettingConditionAsBarName',
            description = 'SettingConditionAsBarDesc',
            default = false,
        },
        {
            key = 'b_ShowMeleeInfo',
            renderer = 'checkbox',
            name = 'SettingShowMeleeInfoName',
            description = 'SettingShowMeleeInfoDesc',
            default = false,
        },
    },
}
