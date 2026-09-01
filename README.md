# OpenMW UI Toolkit
Library to make creating LUA UI for OpenMW easier. Contains basic templates, interactivity, components and tooltip support.

`libs/ui-toolkit.lua` - meta file for the [Cod3x](https://www.nexusmods.com/morrowind/mods/59122) LLS plugin. You can copy it to your projects that use Cod3x to get code completion for the public API of the UI Toolkit.

# Interactivity
`I.UIToolkit.Interactive` can make any Element or Layout "interactive" – react to mouse hovers, clicks, have tooltips. And has methods to just apply interactive state style changes to a Layout/Element. Supports `hovering`, `disabled`, `pressed` and `active` states, with separate coloring for each.

Add `colorable = true` to the userData of layout to make it react to the interactivity states in parent's `userData`.

## Example
Create an Element that behaves like 'icon' button with tooltip and a click callback:
```lua
I.UIToolkit.Interactive.makeInteractive({
    onClick = function() print('Hello World!') end,
    tooltip = 'Hello World!',
}, {
    type = ui.TYPE.Image,
    props = {
        --white rectangle, use your own texture here 
        --should be white or grayscale for coloring to look good
        resource = ui.texture {path = 'white'},
        size = v2(16, 16),
    },
    userData = { colorable = true, },
})
```

Create an interactive text Element that shows a tooltip with how many potions the player has:
```lua
local function getPlayerPotionCount()
    return #types.Actor.inventory(player):getAll(types.Potion)
end

I.UIToolkit.Interactive.makeInteractive({
    tooltip = function() return 'Potions: ' .. getPlayerPotionCount() end,
}, {
    template = I.MWUI.templates.textNormal,
    props = {
        text = 'Player potions',
    },
    userData = { colorable = true, },
})
```
# Components
`I.UIToolkit.Components` contains functions that create various UI components.

Note that all component creation methods return `UIToolkit.Component` objects, not `Element` or `Layout`. To add them to layout use `component.element`.

Component objects have methods to get/set their visibility, active and disables states:
```lua
-- returns whether component is visible
component:isVisible()
-- makes component invisible, returns `self`
component:setVisible(false)

-- returns whether component is active
component:isActive()
-- makes component active (will look like selected spell in magic list does), returns `self`
component:setActive(true)

-- returns whether component is disabled
component:isDisabled()
-- makes component look disabled - still can be clicked or hovered, returns `self`
component:setDisabled(true)

-- updates component's props, returns `self`
component:updateProps {position = v2(100,200)}

-- returns true if component's element is destroyed (or empty)
component:isDestroyed()
```

## Text Button
`textButton(opts)` - creates a text button. Can have tooltip, onClick callback. Can be fixed-width.

### Example
create a button with text `Hello`, tooltip `World!` and that prints `Hello World!` when clicked:
```lua
I.UIToolkit.Components.textButton { text = "Hello", tooltip = 'World!', onClick = function()
    print('Hello World!')
end}
```

## Text Edit
`textEdit(opts)` - creates a text edit. With optional placeholder text, clear button, value validation and on change callback.

### Examples
Create text edit with placeholder text, clear button and callback that prints the value when changed:
```lua
I.UIToolkit.Components.textEdit {
        placeholder = 'enter something!',
        onValueChanged = function(value) print('Value changed:', value) end,
        showClearButton = true,
}
```

Create a text edit that accepts only positive numbers:
```lua
I.UIToolkit.Components.textEdit {
    default = 1,
    validate = function(text)
        local number = tonumber(text)
        if not number then return false end
        return true, math.max(1, number)
    end,
    width = 60,
    textAlignH = ui.ALIGNMENT.Center,
    showClearButton = true,
}
```

## Scroll Bar
`scrollBar(opts)` - creates a scrollbar. Can be horizontal or vertical. Has callback for position change.

## Item List
`itemList(opts)` - creates a list of items. Uses item provider to get Components representing items. Items can have tooltips.

### Example
Create a list of items in player's inventory with icon, name, weight, value and value-per-weight columns:
```lua
local player     = require 'openmw.self'
local types      = require 'openmw.types'
local ui         = require 'openmw.ui'
local util       = require 'openmw.util'
local I          = require 'openmw.interfaces'
local H          = require 'scripts.UIToolkit.helpers'
local ColumnItem = require 'scripts.UIToolkit.components.list_items.column_item'

local textSize   = I.UIToolkit.getTheme().Sizes.textNormal
local rowHeight  = 1.5 * (textSize + 2)

local provider   = ColumnItem:new()
provider:init({
    { id = 'icon',   render = ColumnItem.renderIcon, arg = { sz = 1.5 * textSize },           width = rowHeight + 5 },
    { id = 'name',   render = ColumnItem.renderText, },
    { id = 'weight', render = ColumnItem.renderText, arg = { textAlignH = ui.ALIGNMENT.End }, width = 1.5 * rowHeight },
    { id = 'value',  render = ColumnItem.renderText, arg = { textAlignH = ui.ALIGNMENT.End, textSize = textSize-1 }, width = 2 * rowHeight },
    { id = 'V/W',    render = ColumnItem.renderText, arg = { textAlignH = ui.ALIGNMENT.End }, width = 2 * rowHeight },
}, rowHeight)

---@type UIToolkit.ListData.Column[]
local rows = {}
local items = types.Actor.inventory(player):getAll()
for i = 1, #items do
    ---@type openmw.Object
    local item = items[i]
    local record = item.type.records[item.recordId]
    rows[#rows + 1] = {
        id = item.id,
        icon = record.icon,
        name = record.name .. (item.count > 1 and ' (' .. H.addSeparators(item.count) .. ")" or ''),
        weight = record.weight,
        value = record.value,
        ['V/W'] = function() return record.weight > 0 and record.value / record.weight or '--' end,
        tooltip = { object = item, observer = player }
    }
end

local list = I.UIToolkit.Components.itemList {
    provider = provider,
    size = util.vector2(300, 400),
    onItemClicked = function(data, idx) print('Clicked on', idx, data.id) end,
}
list:setItems(rows)
```

## Sorted List
`sortedList(opts)` - creates an item list with a clickable header for sorting its columns. Set `sort = { numeric = true }` for numeric values, or provide a comparator function for custom sorting. Columns without `sort` are displayed but cannot be sorted. Clicking a sortable column toggles between ascending and descending order.

`setSize` and `setItems` need to be called on this component and not on a list child of it. Other methods can be safely called on the child list.

### Example
Create a list of items with sortable name, weight and value columns:
```lua
local ui         = require 'openmw.ui'
local util       = require 'openmw.util'
local I          = require 'openmw.interfaces'
local ColumnItem = require 'scripts.UIToolkit.components.list_items.column_item'

local textSize  = I.UIToolkit.getTheme().Sizes.textNormal
local rowHeight = 1.5 * (textSize + 2)

local list = I.UIToolkit.Components.sortedList {
    size = util.vector2(300, 400),
    columns = {
        -- No `sort` makes this column display-only.
        { id = 'icon',   name = nil,      render = ColumnItem.renderIcon, width = rowHeight + 5 },
        { id = 'name',   name = 'Name',   render = ColumnItem.renderText, sort = {} },
        { id = 'weight', name = 'Weight', render = ColumnItem.renderText, sort = { numeric = true }, align = ui.ALIGNMENT.End },
        { id = 'value',  name = 'Value',  render = ColumnItem.renderText, sort = { numeric = true }, align = ui.ALIGNMENT.End },
    },
    onItemClicked = function(data, index)
        print('Clicked on', index, data.id)
    end,
}

list:setItems {
    { id = 'iron-sword', icon = 'icons/w/tx_iron_longsword.dd', name = 'Iron Sword', weight = 12, value = 25 },
    { id = 'healing-potion', icon = 'icons/m/tx_potion_bargain_01.dds', name = 'Potion', weight = 0.5, value = 20 },
}
```

The header can also be controlled in code. For example, `list.header:toggleColumn('value', false)` selects the value column and sorts it in descending order. Use `defaultSort` when a secondary or initial ordering is needed; items with equal sort values are ordered by their `id`.

## Windows
`I.UIToolkit.WindowManager` handles registering, opening and closing windows. Windows can be draggable, resizable. They store their position and size between opens.

Register a window once, then open it by its ID. The window handler is called when the window opens and can populate it with any UI content:
```lua
local input = require 'openmw.input'
local ui    = require 'openmw.ui'
local util  = require 'openmw.util'
local I     = require 'openmw.interfaces'

local windowId = 'my-simple-window'

local handler = {}

function handler:onOpened(wnd)
    wnd:setContent(ui.content {
        {
            template = I.MWUI.templates.textNormal,
            props = { text = 'Hello from my window!' },
        },
    })
end

I.UIToolkit.WindowManager.register(windowId, {
    title = 'My Window',
    handler = handler,
    size = util.vector2(300, 120),
    position = util.vector2(300, 300),
    draggable = true,
})

local function onKeyRelease(key)
    if key.code ~= input.KEY.Backspace then return end

    local windows = I.UIToolkit.WindowManager
    if windows.isOpen(windowId) then
        windows.close(windowId)
    else
        windows.open(windowId)
    end
end

return {
    engineHandlers = {
        onKeyRelease = onKeyRelease,
    },
}
```

`I.UIToolkit.WindowManager.register` only defines the window. Call `I.UIToolkit.WindowManager.open(windowId)` to create it; `I.UIToolkit.WindowManager.close(windowId)` destroys it while preserving its position and size for the next open.


# Tooltips
Taken almost as-is from the [Dehardcode tooltips MR](https://gitlab.com/OpenMW/openmw/-/merge_requests/5336). Only some small tweaks to accommodate for the lack of newer API in 0.51. The idea is to allow modders to play with the dehardcode API before it is released and, hopefully, make transition to it easier when it happens.

Unlike the Dehardode MR version, This API cannot replace any existing tooltips but allows creating and displaying custom ones with the same customization API.

To allow tooltip positioning without `ui.mousePosition()` (part of the tooltip dehardoce MR) - interactive elements in this library are storing the last mouse position when hovered, and it is used when positioning tooltips.

To allow tooltips to be automatically hidden when element that spawned it is destroyed, the `setTooltip` accepts `isAlive` function as a second parameter - if it is present and returns false - tooltip will be destroyed. This won't be necessary in the future when `focusLoss` event handler would fire on destruction (see [Issue #9051](https://gitlab.com/OpenMW/openmw/-/work_items/9051) and [MR #5324](https://gitlab.com/OpenMW/openmw/-/merge_requests/5324)).

You can read [Dehardcode tooltips MR docs](https://openmw-vr.readthedocs.io/en/dehardcode-tooltips/reference/lua-scripting/interface_tooltips.html) for more info – most of the API is the same, only replace `I.Tooltips` with `I.UTKTooltips`.

## Simplified tooltip formats
UI Toolkit adds support simplified tooltip formats that can be used in most places where UTKTooltips.Tooltip is used:
  - Plain string will create a simple text line tooltip, equivalent to: 
    ```lua
    { recipe = { items = { { text = 'your string' } } } }
    ```
  - `{ body = 'your text' }` will create a text paragraph tooltip, equivalent to:
    ```lua
    { recipe = { items = { { type ='paragraph', text = 'your text' } } } }
    ```
  - `{ title = 'your title' }` will create a header with a title, equivalent to:
    ```lua
    { recipe = { items = { { type ='header', title = 'your title' } } } }
    ```
  - `{ title = 'your title', body = 'your text' }` will create a centered header with a title, followed by a paragraph, equivalent to:
    ```lua
    { recipe = { items = { 
      { type ='header', title = 'your title' }, 
      { type ='paragraph', text = 'your text' }, 
    } } }
    ```
## Tooltip examples
```lua
-- tooltip for the "Resist Poison" magic effect
{ key = 'resistpoison', type = I.UTKTooltips.TYPE.MagicEffect }

-- tooltip for the "Bonemeal" ingredient
{ key = 'ingred_bonemeal_01', type = I.UTKTooltips.TYPE.Ingredient, observer = player }

-- tooltip for the first found potion in player's inventory
{ object = types.Actor.inventory(player):getAll(types.Potion)[1], observer = player }
```
The `type` field is optional in these cases, but it will make the tooltip creation faster, as it won't need to seek for the record in all types.

The `observer` field is optional, it is used to determine how many effects potions/ingredients will show. If omitted, all info is shown.

# Planned Features
- [ ] Add controller support
  - [x] for list scrolling 
  - [x] send button events to windows
  - other stuff?
- [x] Add list item provider with columns
- [x] Add `Column Sorter` component that can display columns with sorting and provide events for List to use
- [ ] Make `Component` able to subscribe to `onUpdate` event
- [x] Make `Component` able to subscribe to `elementUpdated` event
- [x] Make `Component` able to subscribe to `elementDestroyed` event
- [x] Option to make `Interactives` not react to hovers/clicks when disabled 
- [ ] Add `Checkbox` component
- [ ] Add `Dropbox` component
- [ ] Add `Tabs`/`Radio group` style component?
- [ ] Settings menu to customize templates
- [x] Helper methods to create Tooltip objects for common types of custom tooltips (solved by making `setTooltip` accept simplified objects and new method `convertAnyTooltip`)
  - [x] Text line
  - [x] Text paragraph (with optional title)
- [x] Modal popups?


# Credits
- [Mads](https://gitlab.com/madsbuvi) - tooltip code is almost fully taken from his [Dehardcode tooltips MR](https://gitlab.com/OpenMW/openmw/-/merge_requests/5336)
- [Ralts](https://gitlab.com/therealralts) - many UI templates are based on his templates from Inventory Extender
- OpenMW Discord for lots of advice
