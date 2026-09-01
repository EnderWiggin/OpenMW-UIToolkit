---@omw-context runtime

local core = require 'openmw.core'

local C = {}

---Describes if certain APIs are available
C.API = {
    -- `gap` prop in Flexes
    GAP = core.API_REVISION >= 132,

    -- `padding` prop in Widgets/Images/Flexes
    PADDING = core.API_REVISION >= 143,
}

return C
