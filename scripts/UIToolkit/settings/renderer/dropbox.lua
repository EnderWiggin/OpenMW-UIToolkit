---@omw-context menu

local core = require 'openmw.core'
local I = require 'openmw.interfaces'

---@param value string
---@param set fun(value:string)
---@param args UIToolkit.SettingRenderer.Dropbox
return function(value, set, args)
    local l10n
    if args.l10n then l10n = core.l10n(args.l10n) end

    ---@type UIToolkit.ListData.Text[]
    local items = {}
    local selected
    for i = 1, #args.items do
        local item = args.items[i]
        if type(item) == 'string' then
            item = { id = item }
        end

        item.text = item.text or item.id
        if l10n then item.text = l10n(item.text) end

        items[#items + 1] = item

        if item.id == value then
            selected = item
        end
    end

    local dropbox = I.UIToolkit.Components.dropbox {
        items = items,
        onItemSelected = function(item)
            set(item.id)
        end
    }

    if args.disabled then
        dropbox:setDisabled(true)
    end

    --old removed value?
    --reset to first one
    if not selected then
        selected = items[1]
        set(selected.id)
    end
    dropbox:selectItem(selected)

    return dropbox.element
end
