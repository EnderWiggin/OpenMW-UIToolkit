---@omw-context none


local MOD = 'UTKTooltips'
local function section(name)
    return 'Settings/' .. MOD .. '/' .. name
end

---@class UTKTooltips.Config.Defaults
local M = {
    PageKey = MOD,
    L10N = 'UTKTooltips',
    Section = {
        Main = section 'Main',
    },
}

return M
