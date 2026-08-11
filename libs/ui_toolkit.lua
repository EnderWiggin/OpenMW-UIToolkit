---@meta

---@class openmw.interfaces
---@field UIToolkit openmw.interfaces.UIToolkit

---@class openmw.interfaces.UIToolkit
---@field getCtx fun():table
---@field getTheme fun():UIToolkit.Theme
---@field queueUpdate fun(element:openmw.ui.Element) queues element to be updated on next frame
---@field getInteractiveColor fun(state:UIToolkit.InteractiveState, custom:UIToolkit.InteractiveColors?):openmw.util.Color?
---@field applyInteractiveState fun(layout:openmw.ui.Layout, state:UIToolkit.InteractiveState)
---@field updateInteractiveState fun(layoutOrElement:openmw.ui.Layout|openmw.ui.Element, state:UIToolkit.InteractiveState?)

---@class UIToolkit.Theme
---@field Colors table
---@field Sizes table

---@class UIToolkit.InteractiveState
---@field active boolean? element is active - e.g. currently equipped spell in the spell list
---@field pressed boolean? element is currently being pressed
---@field hovering boolean? element is currently being hovered over
---@field disabled boolean? element is disabled


---@class UIToolkit.InteractiveColors
---@field pressColor openmw.util.Color?
---@field hoverColor openmw.util.Color?
---@field baseColor openmw.util.Color?
