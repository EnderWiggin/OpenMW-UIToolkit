---@omw-context none

local MOD = 'UIToolkit'
local function section(name)
    return 'Settings/' .. MOD .. '/' .. name
end

---@class UIToolkit.Config.Defaults
local M = {
    PageKey = MOD,
    L10N = 'UIToolkitLib',
    Version = '1.0-alpha',
    API = 1,
    Tooltips = 1,
    Section = {
        Interface = section 'Interface',
        Controller = section 'Controller',
    },

    RepeatThreshold = {
        default = 0.5,
        min = 0.2,
        max = 1,
    },

    RepeatStep = {
        default = 0.125,
        min = 0.05,
        max = 0.5,
    },

    Separators = {
        None = 'ConfigNumberSeparators_None',
        Comma = 'ConfigNumberSeparators_Comma',
        Space = 'ConfigNumberSeparators_Space',
    }
}

return M
