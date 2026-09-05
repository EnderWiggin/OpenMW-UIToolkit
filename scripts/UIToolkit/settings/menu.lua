---@omw-context menu
local core = require 'openmw.core'
local I = require 'openmw.interfaces'
local H = require 'scripts.UIToolkit.helpers'
local D = require 'scripts.UIToolkit.config.defaults'

local l10n = core.l10n(D.L10N)

I.Settings.registerPage {
    key = D.PageKey,
    l10n = D.L10N,
    name = 'SettingPageName',
    description = l10n('SettingPageDesc', { version = D.Version, api = D.API, tooltips = D.Tooltips }),
}

I.Settings.registerGroup {
    key = D.Section.Interface,
    page = D.PageKey,
    l10n = D.L10N,
    name = 'InterfaceSettingsName',
    description = 'InterfaceSettingsDesc',
    order = 2,
    permanentStorage = true,
    settings = {
        {
            key = 's_NumberSeparators',
            renderer = 'UIToolkit/Dropbox',
            name = 'SettingNumberSeparatorsName',
            description = l10n('SettingNumberSeparatorsDesc', H.TextColorParams),
            default = D.Separators.Space,
            argument = {
                l10n = D.L10N,
                items = { D.Separators.None, D.Separators.Space, D.Separators.Comma },
            }
        },
        {
            key = 'b_ScaleScrollbarWidthWithText',
            renderer = 'checkbox',
            name = 'SettingScaleScrollbarWidthWithTextName',
            description = 'SettingScaleScrollbarWidthWithTextDesc',
            default = false,
        },
    },
}

I.Settings.registerGroup {
    key = D.Section.Controller,
    page = D.PageKey,
    l10n = D.L10N,
    name = 'ControllerSettingsName',
    description = 'ControllerSettingsDesc',
    order = 4,
    permanentStorage = true,
    settings = {
        {
            key = 'b_RepeatingButtons',
            renderer = 'checkbox',
            name = 'SettingRepeatingButtons',
            description = 'SettingRepeatingButtonsDesc',
            default = true,
        },
        {
            key = 'n_RepeatingButtonsThreshold',
            renderer = 'UIToolkit/Slider',
            name = 'SettingRepeatingButtonsThreshold',
            description = l10n('SettingRepeatingButtonsThresholdDesc',
                H.mergeTables(H.TextColorParams, D.RepeatThreshold)),
            default = D.RepeatThreshold.default,
            ---@type UIToolkit.SettingRenderer.Slider
            argument = {
                min = D.RepeatThreshold.min,
                max = D.RepeatThreshold.max,
                default = D.RepeatThreshold.default,
                step = 0.005,
            }
        },
        {
            key = 'n_RepeatingButtonsStep',
            renderer = 'UIToolkit/Slider',
            name = 'SettingRepeatingButtonsStep',
            description = l10n('SettingRepeatingButtonsStepDesc',
                H.mergeTables(H.TextColorParams, D.RepeatStep)),
            default = D.RepeatStep.default,
            ---@type UIToolkit.SettingRenderer.Slider
            argument = {
                min = D.RepeatStep.min,
                max = D.RepeatStep.max,
                default = D.RepeatStep.default,
                step = 0.005,
            }
        },
    },
}
