---@omw-context player|menu

local ui = require('openmw.ui')
local util = require('openmw.util')
local async = require('openmw.async')

local v2 = util.vector2
local C = require('scripts.UIToolkit.constants')

local Component = require('scripts.UIToolkit.components.component')

---@class UIToolkit.Layers
local M = {}


---@type openmw.ui.Element?
local dropbox

---@type openmw.ui.Layout
local _dropBoxHolder

---@return openmw.ui.Layout
local function dropBoxHolder()
    if not _dropBoxHolder then
        _dropBoxHolder = {
            name = 'dropbox-holder',
            props = {
                relativeSize = v2(1, 1),
            },
        }
    end
    return _dropBoxHolder
end

---@type UIToolkit.Component
local _dropBoxLayer

---@return UIToolkit.Component
local function dropBoxLayer()
    if not _dropBoxLayer then
        _dropBoxLayer = Component:new()
        _dropBoxLayer:init(ui.create {
            name = C.Layers.Dropbox,
            layer = C.Layers.Dropbox,

            props = {
                relativeSize = v2(1, 1),
                visible = false,
            },
            content = ui.content {
                dropBoxHolder(),
            },
            events = {
                mousePress = async:callback(function() M.closeDropbox() end),
            },
        })
    end
    return _dropBoxLayer
end

function M.closeDropbox()
    if not dropbox then return end
    dropBoxHolder().content = nil
    dropBoxLayer():setVisible(false)
    dropbox = nil
end

function M.addDropbox(box)
    M.closeDropbox()
    if box then
        dropbox = box
        dropBoxHolder().content = ui.content { box }
        dropBoxLayer():setVisible(true)
    end
end

return M
