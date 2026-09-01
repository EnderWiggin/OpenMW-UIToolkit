---@omw-context player

local async = require 'openmw.async'
local storage = require 'openmw.storage'

local D = require 'scripts.UIToolkit.config.defaults'

---@class UIToolkit.Config.Player.Interface
---@field s_NumberSeparators string

---@class UIToolkit.Config.Player.Controller
---@field b_RepeatingButtons boolean
---@field n_RepeatingButtonsThreshold number
---@field n_RepeatingButtonsStep number

---@class UIToolkit.Config.Player
---@field interface UIToolkit.Config.Player.Interface
---@field controller UIToolkit.Config.Player.Controller

local config = {}

---@param section openmw.storage.StorageSection
local function subscribe(section, name)
    section:subscribe(async:callback(function() config[name] = section:asTable() end))
    config[name] = section:asTable()
end

subscribe(storage.playerSection(D.Section.Interface), 'interface')
subscribe(storage.playerSection(D.Section.Controller), 'controller')


return config --[[@as UIToolkit.Config.Player]]
