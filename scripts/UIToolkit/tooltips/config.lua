---@omw-context player|menu

local async = require 'openmw.async'
local storage = require 'openmw.storage'

local D = require 'scripts.UIToolkit.tooltips.defaults'

---@class UTKTooltips.Config.Main
---@field b_SoulGemValueRebalance boolean
---@field n_ShowSoulCapacity 0|1|2
---@field b_ShowSoulValue boolean
---@field n_ShowEnchantCapacity boolean
---@field b_ShowEnchantUseCost boolean
---@field b_CompactWeightValue boolean
---@field b_ConditionAsBar boolean
---@field b_ShowMeleeInfo boolean

---@class UIToolkit.Config.Player
---@field main UTKTooltips.Config.Main

local config = {}

---@param section openmw.storage.StorageSection
local function subscribe(section, name)
    section:subscribe(async:callback(function() config[name] = section:asTable() end))
    config[name] = section:asTable()
end

subscribe(storage.playerSection(D.Section.Main), 'main')


return config --[[@as UIToolkit.Config.Player]]
