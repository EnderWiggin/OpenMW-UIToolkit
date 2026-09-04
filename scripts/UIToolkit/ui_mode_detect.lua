---@omw-context player

local types  = require 'openmw.types'
local player = require 'openmw.self'


--Used as fallback in case menu script renderers didn't close dropdown list
local function onUIModeChanged()
    types.Player.sendMenuEvent(player, 'UIToolkit:Menu:closeDropdown')
end

return {
    eventHandlers = {
        UiModeChanged = onUIModeChanged,
    },
}
