---@omw-context menu

local ui = require 'openmw.ui'
local C  = require 'scripts.UIToolkit.constants'


if not ui.layers.indexOf(C.Layers.Popup) then
    ui.layers.insertAfter('Windows', C.Layers.Popup, { interactive = true })
end

if not ui.layers.indexOf(C.Layers.Dropbox) then
    ui.layers.insertAfter('Settings', C.Layers.Dropbox, { interactive = true })
end
