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
component:visible()
-- makes component invisible
component:visible(false)

-- returns whether component is active
component:active()
-- makes component active (will look like selected spell in magic list does)
component:active(true)

-- returns whether component is disabled
component:disabled()
-- makes component look disabled - still can be clicked or hovered
component:disabled(true)

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

## Windows
`I.UIToolkit.WindowManager` handles registering, opening and closing windows. Windows can be draggable, resizable. They store their position and size between opens.


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

-- tooltip for the fisrt found potion in player's inventory
{ object = types.Actor.inventory(player):getAll(types.Potion)[1], observer = player }
```


# Planned Features
- [ ] Add controller support
  - [ ] for list scrolling 
  - [ ] send button events to windows
  - other stuff?
- [ ] Add list item provider with columns
- [ ] Make `Controls` able to subscribe to `onUpdate` event
- [ ] Option to make `Interactives` not react to hovers/clicks when disabled 
- [ ] Settings menu to customize templates
- [ ] Helper methods to create Tooltip objects for common types of custom tooltips
  - [ ] Text line
  - [ ] Text paragraph (with optional title)
- [ ] Modal popups?


# Credits
- [Mads](https://gitlab.com/madsbuvi) - tooltip code is almost fully taken from his [Dehardcode tooltips MR](https://gitlab.com/OpenMW/openmw/-/merge_requests/5336)
- [Ralts](https://gitlab.com/therealralts) - many UI templates are based on his templates from Inventory Extender
- OpenMW Discord for lots of advice