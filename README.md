# OpenMW UI Toolkit
Library to make creating LUA UI for OpenMW easier. Contains basic templates, interactivity, components and tooltip support.

`libs/ui-toolkit.lua` - meta file for the [Cod3x](https://www.nexusmods.com/morrowind/mods/59122) LLS plugin. You can copy it to your projects that use Cod3x to get code completion for the public API of the UI Toolkit.

# Interactivity
`I.UIToolkit.Interactive` can make any Element or Layout "interactive" – react to mouse hovers, clicks, have tooltips. And has methods to just apply interactive state style changes to a Layout/Element. Supports `hovering`, `disabled`, `pressed` and `active` states, with separate coloring for each.

Add `colorable = true` to the userData of layout to make it react to the interactivity states in parent's `userData`.

# Components
`I.UIToolkit.Components` contains functions that create various UI components.

## Text Button
`textButton(opts)` - creates a text button. Can have tooltip, onClick callback. Can be fixed-width.

## Text Edit
`textEdit(opts)` - creates a text edit. With optional placeholder text, clear button, value validation and on change callback.

## Scroll Bar
`scrollBar(opts)` - creates a scrollbar. Can be horizontal or vertical. Has callback for position change.

## Item List
`itemList(opts)` - creates a list of items. Uses item provider to get Components representing items. Items can have tooltips.

## Windows
`I.UIToolkit.WindowManager` handles registering, opening and closing windows. Windows can be draggable, resizable. They store their position and size between opens.


# Tooltips
Taken almost as-is from the [Dehardcode tooltips MR](https://gitlab.com/OpenMW/openmw/-/merge_requests/5336). Only some small tweaks to accommodate for the lack of newer API in 0.51. The idea is to allow modders to play with the dehardcode API before it is released and, hopefully, make transition to it easier when it happens.

Unlike the Dehardode MR version, This API cannot replace any existing tooltips but allows creating and displaying custom ones with the same customization API.
To allow tooltip positioning without `ui.mousePosition()` - interactive elements in this library are storing the last mouse position when hovered, and it is used when positioning tooltips.

You can read [Dehardcode tooltips MR docs](https://openmw-vr.readthedocs.io/en/dehardcode-tooltips/reference/lua-scripting/interface_tooltips.html) for more info – most of the API is the same, only replace `I.Tooltips` with `I.UTKTooltips`.

# Planned Features
- [ ] Add controller support
  - [ ] for list scrolling 
  - [ ] send button events to windows
  - other stuff?
- [ ] Add list item provider with columns
- [ ] Make `Controls` able to subscribe to `onUpdate` event
- [ ] Settings menu to customize templates


# Credits
- [Mads](https://gitlab.com/madsbuvi) - tooltip code is almost fully taken from his [Dehardcode tooltips MR](https://gitlab.com/OpenMW/openmw/-/merge_requests/5336)
- [Ralts](https://gitlab.com/therealralts) - many UI templates are based on his templates from Inventory Extender
- OpenMW Discord for lots of advice