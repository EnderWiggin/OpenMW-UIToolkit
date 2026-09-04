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

local dropBoxLayer = Component:new()

local dropBoxHolder = {
    name = 'dropbox-holder',
    props = {
        relativeSize = v2(1, 1),
    },
}

dropBoxLayer:init(ui.create {
    name = C.Layers.Dropbox,
    layer = C.Layers.Dropbox,

    props = {
        relativeSize = v2(1, 1),
        visible = false,
    },
    content = ui.content {
        dropBoxHolder,
    },
    events = {
        mousePress = async:callback(function() M.closeDropbox() end),
    },
})

function M.closeDropbox()
    if not dropbox then return end
    dropBoxHolder.content = nil
    dropBoxLayer:setVisible(false)
    dropbox = nil
end

function M.addDropbox(box)
    M.closeDropbox()
    if box then
        dropbox = box
        dropBoxHolder.content = ui.content { box }
        dropBoxLayer:setVisible(true)
    end
end

return M
