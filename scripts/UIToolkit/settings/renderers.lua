---@omw-context menu
local input = require 'openmw.input'
local I = require 'openmw.interfaces'
local BUTTON = input.CONTROLLER_BUTTON

I.Settings.registerRenderer('UIToolkit/Dropbox', require('scripts.UIToolkit.settings.renderer.dropbox'))
I.Settings.registerRenderer('UIToolkit/Slider', require('scripts.UIToolkit.settings.renderer.slider'))

---@param key openmw.input.KeyboardEvent
local function onKeyPress(key)
    if key.code == input.KEY.Escape then
        I.UIToolkit.Layers.closeDropbox()
    end
end

---@param button number
local function onControllerButtonPress(button)
    --other buttons?
    if button == BUTTON.Start or button == BUTTON.B then
        I.UIToolkit.Layers.closeDropbox()
    end
end

return {
    engineHandlers = {
        onKeyPress = onKeyPress,
        onControllerButtonPress = onControllerButtonPress,
    },
    eventHandlers = {
        ['UIToolkit:Menu:closeDropdown'] = I.UIToolkit.Layers.closeDropbox,
    },
}
