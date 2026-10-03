---@omw-context player|menu

local ui = require('openmw.ui')
local util = require('openmw.util')

local v2 = util.vector2

local M = {}

local CURSOR = {}
if ui.cursor then
    CURSOR['arrow'] = nil --will use default cursor

    CURSOR['hresize'] = ui.cursor {
        path = 'textures/tx_cursormove.dds',
        size = v2(32, 32),
        hotspot = v2(16, 14),
    }

    CURSOR['vresize'] = ui.cursor {
        path = 'textures/tx_cursormove.dds',
        size = v2(32, 32),
        hotspot = v2(17, 16),
        rotation = -math.pi / 2,
    }

    CURSOR['dresize'] = ui.cursor {
        path = 'textures/tx_cursormove.dds',
        size = v2(32, 32),
        hotspot = v2(17, 15),
        rotation = math.pi / 4,
    }

    CURSOR['dresize2'] = ui.cursor {
        path = 'textures/tx_cursormove.dds',
        size = v2(32, 32),
        hotspot = v2(15, 15),
        rotation = -math.pi / 4,
    }

    CURSOR['drop_ground'] = ui.cursor {
        path = 'textures/cursor_drop_ground.dds',
        size = v2(32, 32),
        hotspot = v2(0, 24),
        rotation = -math.pi / 4,
    }
end

--Depending on available API applies a named cursor to props
---@param props table
---@param cursor string
function M.applyCursor(props, cursor)
    if not ui.cursor then
        props.pointer = cursor
        return
    end
    props.cursor = CURSOR[cursor]
end

return M
