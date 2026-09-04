---@meta

-- UIToolkit version: 1
-- UTKTooltips version: 1

---@class openmw.interfaces
---@field UIToolkit openmw.interfaces.UIToolkit
---@field UTKTooltips openmw.interfaces.UTKTooltips

---@class openmw.interfaces.UIToolkit
---@field version number
---@field getCtx fun():UIToolkit.Context
---@field getTheme fun():UIToolkit.Theme
---@field update fun(element:openmw.ui.Element, deep:boolean?) updates element. If `deep` is `true` will also update all descendant elements.
---@field destroy fun(element:openmw.ui.Element, deep:boolean?) destroys element, calling destructors on components.  If `deep` is `true` will also destroy all descendant elements.
---@field queueUpdate fun(element:openmw.ui.Element, deep:boolean?) queues element to be updated on next frame. If `deep` is `true` will also update all descendant elements.
---@field queueDestroy fun(element:openmw.ui.Element, deep:boolean?) queues element to be destroyed on next frame, calling destructors on components. If `deep` is `true` will also delete all descendant elements.
---@field texture fun(path:string, size:openmw.util.Vector2?, offset:openmw.util.Vector2?):openmw.ui.TextureResource
---@field Templates UIToolkit.Templates
---@field Interactive UIToolkit.Interactive
---@field Components UIToolkit.Components
---@field WindowManager UIToolkit.WindowManager
---@field Popups UIToolkit.Popups

---@class UIToolkit.Context
---@field lastMousePos openmw.util.Vector2? last mouse position detected by interactive elements. Needed until `ui.mousePosition()` is merged (0.52?)
---@field focusedScrollable UIToolkit.Scrollable?

---@class UIToolkit.Theme
---@field Colors UIToolkit.Theme.Colors
---@field Sizes UIToolkit.Theme.Sizes

---@class UIToolkit.Interactive
local Interactive = {}

---Makes layout or element interactive - react to hovers and clicks and have a tooltip
---@param opts UIToolkit.InteractiveOpts
---@param layoutOrElement openmw.ui.Element|openmw.ui.Layout
---@return openmw.ui.Element
function Interactive.makeInteractive(opts, layoutOrElement) end

---Applies interactive state to the layout
---@param state UIToolkit.InteractiveState
---@param custom UIToolkit.InteractiveColors?
---@return openmw.util.Color?
function Interactive.getColor(state, custom) end

---Applies interactive state to the layout
---@param layout openmw.ui.Layout
---@param state UIToolkit.InteractiveState
function Interactive.applyState(layout, state) end

---Recursively updates interactive state of the element and its children
---@param layoutOrElement openmw.ui.Layout|openmw.ui.Element
---@param state UIToolkit.InteractiveState?
function Interactive.updateState(layoutOrElement, state) end

---@class UIToolkit.InteractiveState
---@field active boolean? element is active - e.g. currently equipped spell in the spell list
---@field pressed boolean? element is currently being pressed
---@field hovering boolean? element is currently being hovered over
---@field disabled boolean? element is disabled

---@class UIToolkit.InteractiveOpts
---@field tooltip? UTKTooltips.AnyTooltip|UIToolkit.TooltipProvider|nil optional tooltip or tooltip provider function
---@field onClick? fun(e:openmw.ui.MouseEvent) optional function to be called when element is clicked.
---@field canClick? fun():boolean
---@field onMouseMove? fun(e, tgt, element)
---@field interactiveDisabled? boolean default to `false`

---@class UIToolkit.Components
local Components = {}

---@param opts UIToolkit.TextButtonOpts
---@return UIToolkit.TextButton
function Components.textButton(opts) end

---@param opts UIToolkit.CheckboxOpts
---@return UIToolkit.Checkbox
function Components.checkbox(opts) end

---@param opts UIToolkit.TextEditOpts
---@return UIToolkit.TextEdit
function Components.textEdit(opts) end

---@param opts UIToolkit.DropboxOpts
---@return UIToolkit.Dropbox
function Components.dropbox(opts) end

---@param opts UIToolkit.ScrollBarOpts
---@return UIToolkit.ScrollBar
function Components.scrollBar(opts) end

---@param opts UIToolkit.ItemListOpts
---@return UIToolkit.ItemList
function Components.itemList(opts) end

---@param opts UIToolkit.ColumnSorterOpts
---@return UIToolkit.ColumnSorter
function Components.columnSorter(opts) end

---@param opts UIToolkit.SortedListOpts
---@return UIToolkit.SortedList
function Components.sortedList(opts) end

---@class UIToolkit.Component
---@field new fun():UIToolkit.Component
---@field init fun(self:UIToolkit.Component, element:openmw.ui.Element)
---@field isDestroyed fun(self:UIToolkit.Component):boolean
---@field beforeElementDestroy fun(self:UIToolkit.Component)
---@field element openmw.ui.Element
---@field isVisible fun(self:UIToolkit.Component):boolean|nil Returns whether component is visible or `nil` if destroyed.
---@field setVisible fun(self:UIToolkit.Component, value: boolean?):UIToolkit.Component Sets component's visibility and queues update, return self.
---@field isActive fun(self:UIToolkit.Component):boolean|nil Returns active flag. If component is destroyed - returns nil.
---@field setActive fun(self:UIToolkit.Component, value: boolean?, deep: boolean?):self:UIToolkit.Component Sets active state of the component and queues update, return self.
---@field isDisabled fun(self:UIToolkit.Component):boolean|nil Returns disabled flag. If component is destroyed - returns nil.
---@field setDisabled fun(self:UIToolkit.Component, value: boolean?, deep: boolean?):self:UIToolkit.Component Sets disabled state of the component and queues update, return self.
---@field updateProps fun(self:UIToolkit.Component, props: table):UIToolkit.Component update props, return self.

---@class UIToolkit.Scrollable : UIToolkit.Component
---@field onMouseScrolled fun(self:UIToolkit.Scrollable, delta:number)

---@class UIToolkit.ButtonOpts : UIToolkit.InteractiveOpts
---@field name string? name to give to button layout
---@field style UIToolkit.BoxStyle? defaults to 'button'
---@field thickness number?
---@field background UIToolkit.BoxBackground? defaults to 'solid'
---@field padding? openmw.util.Vector2|number defaults to v2(8, 0) for auto sized buttons

---@class UIToolkit.TextButtonOpts : UIToolkit.ButtonOpts
---@field text string text on the button
---@field width number? if set, button will be fixed-width, not scale with text length

---@class UIToolkit.TextButton : UIToolkit.Component
---@field new fun():UIToolkit.TextButton
---@field init fun(self:UIToolkit.TextButton, opts:UIToolkit.TextButtonOpts)
---@field setText fun(self:UIToolkit.TextButton, text:string)

---@class UIToolkit.CheckboxOpts : UIToolkit.InteractiveOpts
---@field text? string optional label displayed beside the checkbox
---@field default? boolean|fun():boolean initial value; defaults to false
---@field onValueChanged? fun(value:boolean) called when the value is changed by a click
---@field name? string name assigned to the checkbox layout
---@field boxSize? number defaults to the theme's normal text size
---@field accentedCheckmark? boolean if set to true, checkmark will be colored in active-style colors (like selected spell in the spell list).

---@class UIToolkit.Checkbox : UIToolkit.Component
---@field new fun(self:UIToolkit.Checkbox):UIToolkit.Checkbox
---@field init fun(self:UIToolkit.Checkbox, opts:UIToolkit.CheckboxOpts)
---@field getValue fun(self:UIToolkit.Checkbox):boolean
---@field setValue fun(self:UIToolkit.Checkbox, value:boolean):UIToolkit.Checkbox

---@generic T
---@class UIToolkit.TextEditOpts<T>
---@field default? T|fun():T|nil
---@field textSize number?
---@field textAlignH openmw.ui.ALIGNMENT?
---@field textColorNormal openmw.util.Color? defaults to DEFAULT_LIGHT
---@field textColorPlaceholder openmw.util.Color? defaults to DISABLED
---@field placeholder? string|fun():string will be shown when edit is not in focus and text is empty
---@field validate? fun(text:string|T|nil):boolean,T
---@field onValueChanged? fun(value:T) will be called when entered value is changed
---@field width number? defaults to 200
---@field showClearButton boolean?
---@field onClearClicked? fun()

---@generic T
---@class UIToolkit.TextEdit<T> : UIToolkit.Component
---@field new fun():UIToolkit.TextEdit
---@field init fun(self:UIToolkit.TextEdit, opts:UIToolkit.TextEditOpts)
---@field getValue fun(self:UIToolkit.TextEdit):T
---@field setValue fun(self:UIToolkit.TextEdit, value:T)
---@field setPlaceholder fun(self:UIToolkit.TextEdit, value:string?)
---@field getPlaceholder fun(self:UIToolkit.TextEdit):T Returns value of the placeholder.
---@field setWidth fun(self:UIToolkit.TextEdit, width:number):UIToolkit.TextEdit
---@field isEmpty fun(self:UIToolkit.TextEdit):boolean

---@class UIToolkit.DropboxOpts
---@field items UIToolkit.ListData.Text[]
---@field onItemSelected? fun(item:UIToolkit.ListData.Text, idx: integer)
---@field width number? defaults to 150
---@field maxVisibleItems integer? defaults to all

---@class UIToolkit.Dropbox : UIToolkit.Component
---@field getSelectedItem fun(self:UIToolkit.Dropbox):UIToolkit.ListData.Text
---@field selectItem fun(self:UIToolkit.Dropbox, item:UIToolkit.ListData.Text)
---@field selectById fun(self:UIToolkit.Dropbox, id:string)
---@field selectByIndex fun(self:UIToolkit.Dropbox, idx:integer)

---@class UIToolkit.ScrollBarOpts
---@field horizontal boolean?
---@field scrollStep number
---@field maxScroll number
---@field length number
---@field width number?
---@field slim boolean? scrollbar will have no borders around arrows or handle
---@field handleSize number? if set, handle will be this size, if not - it will auto-calculate
---@field onScroll fun(position:number, progress:number)

---@class UIToolkit.ScrollBar : UIToolkit.Component
---@field new fun():UIToolkit.ScrollBar
---@field init fun(self:UIToolkit.ScrollBar, opts:UIToolkit.ScrollBarOpts)
---@field getPosition fun(self:UIToolkit.ScrollBar):number actual position of the scroll
---@field setPosition fun(self:UIToolkit.ScrollBar, position:number, silent:boolean?) set scroll position. If `silent` is true - onScrolled will not be called.
---@field getProgress fun(self:UIToolkit.ScrollBar):number [0-1] progress of the scroll
---@field setProgress fun(self:UIToolkit.ScrollBar, progress:number, silent:boolean?) set [0-1] progress of the scroll. If `silent` is true - onScrolled will not be called.
---@field scroll fun(self:UIToolkit.ScrollBar, steps:number) scroll the bar by steps
---@field getSize fun(self:UIToolkit.ScrollBar):openmw.util.Vector2
---@field setLength fun(self:UIToolkit.ScrollBar, length:number) set scroll length
---@field setMaxScroll fun(self:UIToolkit.ScrollBar, maxScroll:number, preserveProgress:boolean?)

---@class UIToolkit.ListData.Base
---@field id string

---@generic T: UIToolkit.ListData.Base
---@class UIToolkit.ListItem.Base<T>
---@field getItemHeight fun(self:UIToolkit.ListItem.Base<T>):number
---@field getComponent fun(self:UIToolkit.ListItem.Base<T>, data:T):UIToolkit.Component
---@field getCachedComponent fun(self:UIToolkit.ListItem.Base<T>, id:string):UIToolkit.Component?
---@field makeComponent fun(self:UIToolkit.ListItem.Base<T>, data:T):UIToolkit.Component
---@field getTooltip fun(self:UIToolkit.ListItem.Base<T>, data:T):UTKTooltips.AnyTooltip?
---@field getView fun(self:UIToolkit.ListItem.Base<T>, data:T):openmw.ui.Element
---@field getCachedView fun(self:UIToolkit.ListItem.Base<T>, id:string):openmw.ui.Element?
---@field remove fun(self:UIToolkit.ListItem.Base<T>, id:string) removes cached item
---@field clear fun(self:UIToolkit.ListItem.Base<T>) removes all cached items

---@class UIToolkit.ListData.Text : UIToolkit.ListData.Base
---@field text string
---@field tooltip UTKTooltips.AnyTooltip?

---@class UIToolkit.ListItem.Text : UIToolkit.ListItem.Base<UIToolkit.ListData.Text>
---@field new fun(self:UIToolkit.ListItem.Text):UIToolkit.ListItem.Text
---@field getItemHeight fun(self:UIToolkit.ListItem.Text):number
---@field makeComponent fun(self:UIToolkit.ListItem.Text, data:UIToolkit.ListData.Text):UIToolkit.Component
---@field getTooltip fun(self:UIToolkit.ListItem.Text, data:UIToolkit.ListData.Text):UTKTooltips.AnyTooltip?

---@alias UIToolkit.ListItem.Column.Renderer fun(data:UIToolkit.ListData.Column, cfg:UIToolkit.ListData.ColumnConfig, height:number):openmw.ui.Element

---@class UIToolkit.ListData.ColumnConfig
---@field id string
---@field width number?
---@field auto number?
---@field render UIToolkit.ListItem.Column.Renderer
---@field arg any? additional info for renderer

---@class UIToolkit.ListData.Column: UIToolkit.ListData.Base
---@field isActive? fun():boolean
---@field tooltip? UTKTooltips.AnyTooltip|UIToolkit.TooltipProvider

---@class UIToolkit.ListItem.Column: UIToolkit.ListItem.Base
---@field new fun(self:UIToolkit.ListItem.Column):UIToolkit.ListItem.Column
---@field init fun(self:UIToolkit.ListItem.Column, columns:UIToolkit.ListData.ColumnConfig[], rowHeight:number)
---@field refreshColumns fun(self:UIToolkit.ListItem.Column, idOrData:string|UIToolkit.ListData.Column, ...:string|integer)
---@field refreshActiveState fun(self:UIToolkit.ListItem.Column, idOrData:string|UIToolkit.ListData.Column)
---@field renderText UIToolkit.ListItem.Column.Renderer
---@field renderIcon UIToolkit.ListItem.Column.Renderer

---@generic T : UIToolkit.ListItem.Base
---@class UIToolkit.ItemListOpts<T>
---@field size openmw.util.Vector2
---@field provider T
---@field onItemClicked? fun(data:T, idx:integer)
---@field scrollWidth number?
---@field slimScroll boolean? scrollbar will have no borders around arrows or handle
---@field noBorder boolean?

---@class UIToolkit.ItemList : UIToolkit.Scrollable
---@field new fun():UIToolkit.ItemList
---@field init fun(self:UIToolkit.ItemList, opts:UIToolkit.ItemListOpts)
---@field getContentWidth fun(self:UIToolkit.ItemList):number
---@field getItems fun(self:UIToolkit.ItemList):UIToolkit.ListData.Base[]
---@field setItems fun(self:UIToolkit.ItemList, items:UIToolkit.ListData.Base[])
---@field setSize fun(self:UIToolkit.ItemList, size:openmw.util.Vector2)
---@field getIndexByYPos fun(self:UIToolkit.ItemList, y:number):integer
---@field updateHoveredItem fun(self:UIToolkit.ItemList)
---@field getHovered fun(self:UIToolkit.ItemList):UIToolkit.ListData.Base?, integer?
---@field getItemById fun(self:UIToolkit.ItemList, id:string):UIToolkit.ListData.Base?, integer?
---@field getPosition fun(self:UIToolkit.ItemList):number actual position of the scroll
---@field setPosition fun(self:UIToolkit.ItemList, position:number) set scroll position
---@field getProgress fun(self:UIToolkit.ItemList):number [0-1] progress of the scroll
---@field setProgress fun(self:UIToolkit.ItemList, progress:number) set [0-1] progress of the scroll
---@field getVisibleItemRange fun(self:UIToolkit.ItemList, strict:boolean?):integer, integer
---@field getVisibleItemCount fun(self:UIToolkit.ItemList):integer
---@field setHovered fun(self:UIToolkit.ItemList, idOrIndex:string|integer|nil, fixedTipPos:openmw.util.Vector2?, fixedTipAnchor:openmw.util.Vector2?)
---@field shiftHoveredItem fun(self:UIToolkit.ItemList, shift:integer, fixedTipPos:openmw.util.Vector2?, fixedTipAnchor:openmw.util.Vector2?)

---@class UIToolkit.ColumnSorter.Column
---@field id string?
---@field name string?
---@field width number?
---@field auto number?
---@field align? openmw.ui.ALIGNMENT
---@field inactive boolean? if true - can't be clicked

---@class UIToolkit.ColumnSorterOpts
---@field columns UIToolkit.ColumnSorter.Column[]
---@field default string?
---@field onChanged fun(id: string, ascending: boolean)

---@class UIToolkit.ColumnSorter : UIToolkit.Component
---@field new fun(self:UIToolkit.ColumnSorter):UIToolkit.ColumnSorter
---@field init fun(self:UIToolkit.ColumnSorter, opts:UIToolkit.ColumnSorterOpts)
---@field toggleColumn fun(self:UIToolkit.ColumnSorter, id:string, asc:boolean?)
---@field getColumnConfig fun(self:UIToolkit.ColumnSorter, id:string?):UIToolkit.ColumnSorter.Column?
---@field getActiveColumn fun(self:UIToolkit.ColumnSorter):string?, boolean

---@class UIToolkit.SortedList.Column
---@field id string
---@field name string?
---@field width number?
---@field auto number?
---@field render UIToolkit.ListItem.Column.Renderer
---@field arg any? additional info for renderer
---@field align? openmw.ui.ALIGNMENT
---@field sort? UIToolkit.ColumnComparator|UIToolkit.SimpleColumnComparatorConfig comparator function to use for sorting by this column

---@class UIToolkit.SortedListOpts
---@field size openmw.util.Vector2
---@field defaultSort? UIToolkit.ColumnComparator|UIToolkit.SimpleColumnComparatorConfig
---@field columns UIToolkit.SortedList.Column[]
---@field rowHeight number? Defaults to 1.5 * (textNormal + 2)
---@field onItemClicked? fun(data:UIToolkit.ListData.Base, idx:integer)
---@field scrollWidth number?
---@field slimScroll boolean? scrollbar will have no borders around arrows or handle
---@field noBorder boolean?

---@class UIToolkit.SortedList : UIToolkit.Component
---@field new fun(self:UIToolkit.SortedList):UIToolkit.SortedList
---@field init fun(self:UIToolkit.SortedList, opts:UIToolkit.SortedListOpts)
---@field sortItems fun(self:UIToolkit.SortedList, items:UIToolkit.ListData.Column[]?)
---@field setItems fun(self:UIToolkit.SortedList, items:UIToolkit.ListData.Column[])
---@field setSize fun(self:UIToolkit.SortedList, size:openmw.util.Vector2)
---@field getListSize fun(self:UIToolkit.SortedList):openmw.util.Vector2
---@field getHeaderSize fun(self:UIToolkit.SortedList):openmw.util.Vector2

---@class UIToolkit.WindowManager
---@field register fun(id: string, opts: UIToolkit.WindowOpts)
---@field open fun(id: string, data:any?):UIToolkit.Window
---@field close fun(id: string)
---@field isOpen fun(id: string):boolean
---@field getFocusedWindowHandler fun():UIToolkit.WindowHandler?, string?

---@class UIToolkit.WindowOpts
---@field title string
---@field handler UIToolkit.WindowHandler|fun():UIToolkit.WindowHandler if it is a function - it will be called each time the window opens
---@field pinnable boolean?
---@field pinned boolean?
---@field position openmw.util.Vector2?
---@field size openmw.util.Vector2?
---@field draggable boolean?
---@field resizing boolean?
---@field minSize openmw.util.Vector2?

---@class UIToolkit.WindowSaveData
---@field pinned boolean
---@field position openmw.util.Vector2
---@field size openmw.util.Vector2
---@field custom table?

---@class UIToolkit.WindowHandler
---@field onOpened fun(self:UIToolkit.WindowHandler, wnd:UIToolkit.Window, data:any?, saved:table?)
---@field onClosed fun(self:UIToolkit.WindowHandler):table? Should return custom data to be saved. This data would be passed as `saved` to `onOpened`
---@field onResized fun(self:UIToolkit.WindowHandler, innerSize:openmw.util.Vector2)
---@field onFrame fun(self:UIToolkit.WindowHandler, dt:number) called each frame
---@field onControllerButtonPress fun(self:UIToolkit.WindowHandler, button:number) called on focused window when controller button is pressed
---@field onControllerButtonRepeat fun(self:UIToolkit.WindowHandler, button:number) called on focused window when controller button is held and repeating buttons is on
---@field getFocusedScrollable fun(self:UIToolkit.WindowHandler):UIToolkit.Scrollable? this scrollable will be scrolled by Right Stick if window is focused and no other scrollable is in focus

---@class UIToolkit.Window:UIToolkit.Component
---@field new fun():UIToolkit.Window
---@field init fun(self:UIToolkit.Window, opts:UIToolkit.WindowOpts, id:string, saved:UIToolkit.WindowSaveData?)
---@field setTitle fun(self:UIToolkit.Window, newTitle:string)
---@field setContent fun(self:UIToolkit.Window, content:openmw.ui.Content)
---@field getPosition fun(self:UIToolkit.Window):openmw.util.Vector2
---@field getSize fun(self:UIToolkit.Window):openmw.util.Vector2
---@field getInnerSize fun(self:UIToolkit.Window):openmw.util.Vector2
---@field isPinned fun(self:UIToolkit.Window):boolean
---@field setPinnable fun(self:UIToolkit.Window, pinnable:boolean)
---@field setMinSize fun(self:UIToolkit.Window, minSz: openmw.util.Vector2)


---@class UIToolkit.Popups
---@field show fun(opts:UIToolkit.PopupOpts):fun()
---@field hasActivePopup fun():boolean
---@field getActivePopup fun():UIToolkit.Popups.Entry?

---@class UIToolkit.PopupOpts : UIToolkit.Popups.Handler
---@field title string?
---@field body string|openmw.ui.Layout|openmw.ui.Element|UIToolkit.Component
---@field borderStyle UIToolkit.BoxStyle?
---@field buttons? UIToolkit.PopupButtonOpts[]

---@class UIToolkit.PopupButtonOpts
---@field text string text on the button
---@field onClicked? fun() will be called when button is clicked
---@field tooltip? UTKTooltips.AnyTooltip|UIToolkit.TooltipProvider tooltip or tooltip provider to show on a button
---@field noClose? boolean if set to true popup won't be closed when this button is clicked. Defaults to false.
---@field style UIToolkit.BoxStyle?

---@class UIToolkit.Popups.Handler
---@field onControllerButtonPress? fun(button:number) called on focused window when controller button is pressed
---@field onControllerButtonRepeat? fun(button:number) called on focused window when controller button is held and repeating buttons is on
---@field getFocusedScrollable? fun():UIToolkit.Scrollable? this scrollable will be scrolled by Right Stick if window is focused and no other scrollable is in focus
---@field onClosed? fun()

---@class UIToolkit.Popups.Entry
---@field handler UIToolkit.Popups.Handler
---@field element openmw.ui.Element
---@field close fun() closes popup

---@class UIToolkit.InteractiveColors
---@field pressColor openmw.util.Color?
---@field hoverColor openmw.util.Color?
---@field baseColor openmw.util.Color?

---@class UIToolkit.Templates
local Templates = {}

---@return openmw.ui.Template
function Templates.text() end

---@return openmw.ui.Template
function Templates.header() end

---@return openmw.ui.Template
function Templates.paragraph() end

---@return openmw.ui.Template
function Templates.editLine() end

---@return openmw.ui.Template
function Templates.editBox() end

---@param padX number
---@param padY number?
---@return openmw.ui.Template
function Templates.padding(padX, padY) end

---@return openmw.ui.Layout
function Templates.intervalH(size) end

---@return openmw.ui.Layout
function Templates.intervalV(size) end

---@return openmw.ui.TextureResource
function Templates.effectIconTexture(effectId) end

---Rectangular borders.
---Can have padding and background.
---Has size of its own, dictates size to children.
---@param opts UIToolkit.Templates.BoxOpts?
---@return openmw.ui.Template
function Templates.border(opts) end

---Container wrapping the content with borders.
---Can have padding and background.
---Has no size of its own - wraps around children.
---@param opts UIToolkit.Templates.BoxOpts?
---@return openmw.ui.Template
function Templates.box(opts) end

---@param effectId string
---@param sz number
---@return openmw.ui.Layout
function Templates.effectIcon(effectId, sz) end

---@param style UIToolkit.BoxStyle
---@return number
function Templates.getBorderSize(style) end

---@class UIToolkit.Templates.BoxOpts
---@field style? UIToolkit.BoxStyle defaults to 'thin'
---@field thickness? number defaults to a value defined by style (see `Templates.getBorderSize(style)`)
---@field padding? number|openmw.util.Vector2 defaults to 0
---@field background? UIToolkit.BoxBackground

---@class UIToolkit.Theme.Colors
---@field DEFAULT openmw.util.Color
---@field DEFAULT_LIGHT openmw.util.Color
---@field DEFAULT_PRESSED openmw.util.Color
---@field ACTIVE openmw.util.Color
---@field ACTIVE_LIGHT openmw.util.Color
---@field ACTIVE_PRESSED openmw.util.Color
---@field DISABLED openmw.util.Color
---@field DISABLED_LIGHT openmw.util.Color
---@field DISABLED_PRESSED openmw.util.Color
---@field POSITIVE openmw.util.Color
---@field DAMAGED openmw.util.Color
---@field HEADER openmw.util.Color
---@field BACKGROUND openmw.util.Color
---@field HEALTH openmw.util.Color
---@field MAGICK openmw.util.Color
---@field FATIGUE openmw.util.Color
---@field whiteTexture openmw.ui.TextureResource
---@field menuBarGray openmw.ui.TextureResource

---@class UIToolkit.Theme.Sizes
---@field textNormal number
---@field textHeader number
---@field border number
---@field thickBorder number
---@field tooltipPadding number
---@field smallGap number
---@field standardGap number
---@field padding number

--- Setting Renderers
---@class UIToolkit.SettingRenderer.Dropbox
---@field l10n string?
---@field items UIToolkit.SettingRenderer.DropboxItem[]

---@alias UIToolkit.SettingRenderer.DropboxItem string|{id:string, text:string?}

---@class UTKTooltips.ExtraParams
---@field isAlive UTKTooltips.CurrentTipIsAlive?
---@field fixedTipPos openmw.util.Vector2?
---@field fixedTipAnchor openmw.util.Vector2?

---@class openmw.interfaces.UTKTooltips
---@field version number
---@field currentTooltip fun():UTKTooltips.Tooltip?
---@field setTooltip fun(tooltip:UTKTooltips.AnyTooltip?, extra:UTKTooltips.ExtraParams?)
---@field convertAnyTooltip fun(tip:UTKTooltips.AnyTooltip?):UTKTooltips.Tooltip?
---@field createTooltipLayout fun(tooltip:UTKTooltips.Tooltip):openmw.ui.Layout?
---@field addPreCreateTooltipHandler fun(handler:UTKTooltips.PreCreateHandler)
---@field addPostCreateTooltipHandler fun(handler:UTKTooltips.PostCreateHandler)
---@field registerBuilder fun(handler:fun())
---@field CONTENT UTKTooltips.ContentNames
---@field TYPE UTKTooltips.TooltipTypes
---@field builders table<UTKTooltips.RecipeItemType, UTKTooltips.RecipeItemBuilder>

--- Table of information defining a tooltip
---@class UTKTooltips.Tooltip
---@field type UTKTooltips.TooltipType? (Optional) Tooltip type. If not set, will be automatically determined based on object or key. Type can only be determined automatically for objects and records in openmw.types. Not needed if tooltip has pre-set recipe or layout.
---@field key string? (Optional) key defining specifics of the tooltip. See @{#TooltipType}
---@field object openmw.Object? (Optional) object to construct a tooltip from.
---@field observer openmw.Object? (Optional) Actor used to read dynamic values, such as current/max health, skill progression, etc.
---@field caption string? (Optional) caption, used by @{#TooltipType.MapMarker} and @{#TooltipType.Caption}
---@field notes string[]? (Optional) notes, used by @{#TooltipType.MapMarker}.
---@field recipe UTKTooltips.Recipe? (Optional) recipe. If set, this recipe is used directly.
---@field layout openmw.ui.Layout? (Optional) layout. If set, this layout is used directly, skipping all builders.

--- Recipe item type. Decides which builder is used to create the layout.
---@alias UTKTooltips.RecipeItemBuilder fun(item:UTKTooltips.RecipeItem):openmw.ui.Layout

---@alias UTKTooltips.RecipeItemType
---|'banner' # Recipe for a large image, normally preceding the header
---|'default' # The default recipe item type, for regular 'text: value' and 'text: min-max' items. Can be used to create a simple line of text by passing only text.
---|'magicEffects' # Recipe for a list of magic effects
---|'factionRank' # A rank name
---|'factionNextRank' # The next rank, and the attribute requirements for it
---|'factionNextRankSkills' # The skill requirements for the next rank
---|'factionFavoriteSkills' # The favored skills of a faction
---|'gap' # A single empty line
---|'header' # Header. Can optionally contain an icon and a subtitle.
---|'list' # A simple list. Can optionally take arrange, align, horizontal, stretch, and grow parameters.
---|'note' # Intended for map marker notes. A single note including the red note icon.
---|'paragraph' # Multiline text
---|'progressBar' # A progress bar, filled up to 'current' out of 'max'
---|'root' # Another @{#Recipe} instance
---|'spellList' # Takes a list of spells and outputs a list spells divided by type (Spell, Ability, Power, etc.)
---|'value' # renders as an item.image + item.value

--- Table defining a single recipe item, to form one entry in the final tooltip
-- Required/ignored fields depend on the recipe item type.
---@class UTKTooltips.RecipeItem
---@field type UTKTooltips.RecipeItemType? defines which builder is used to create the layout for this item. (default='default')
---@field align openmw.ui.ALIGNMENT? Re-aligns this item. Used by paragraph item to set horizontal text alignment.
---@field text string? (used in default, note, paragraph)
---@field value any? (used in default) Value used by the value type. Is passed through tostring() so can be any type.
---@field min number? (used in default, progressBar) Min used by the value type, ignored if max is not set.
---@field max number? (used in default, progressBar) Max used by the value type, ignored if min is not set. Also used by progressBar
---@field current number? (used in progressBar) current value of progressBar(default 0)
---@field color openmw.util.Color? (used in progressBar) The color of the progressBar
---@field title string? (used in header) Title of a header
---@field subtitle string? (used in header) Subtitle of a header
---@field image string? (used in header, banner) Path to an image resource, used by header and banner types
---@field effects openmw.core.MagicEffectWithParams[]? (used in magicEffects) Used by the effects recipe
---@field unknown table<integer, boolean>? (used in magicEffects) A table mapping from effect index to boolean indicating if the effect should be hidden. Can be nil.
---@field skipTarget boolean? (used in magicEffects) Skips "on self", "on touch", and "on target" information for spell effects
---@field skipMagnitude boolean? (used in magicEffects) Skips magnitude information for spell effects
---@field skipDuration boolean? (used in magicEffects) Skips duration information for spell effects
---@field spells string[]? (used in magicEffects) List of spell record IDs, used by the spellList recipe
---@field faction string? (used in faction) Faction ID. Used by the faction recipes
---@field rank number? (used in faction) Faction rank. Used by the faction recipes. Note that NextRank recipes use the passed in rank as-is, so the current rank + 1 should be passed in the recipe.
---@field width number? (used in paragraph and header's subtitle) overrides paragraph width.
---@field iconSize openmw.util.Vector2? (used in heder) overrides icon size.

--- Table of information defining a tooltip recipe
---@class UTKTooltips.Recipe
---@field type UTKTooltips.TooltipType? The type of tooltip this is a recipe for.
---@field arrange openmw.ui.ALIGNMENT? (Optional) Equivalent to the arrange option of a Flex (See UI documentation).
---@field align openmw.ui.ALIGNMENT? (Optional) Equivalent to the align option of a Flex (See UI documentation).
---@field gap number? (Optional) Equivalent to the gap property of a Flex (See UI documentation). The default gap between each item.
---@field grow number? (Optional) Equivalent to the grow property (See UI documentation)
---@field stretch number? (Optional) Equivalent to the stretch property (See UI documentation)
---@field items UTKTooltips.RecipeItem[] List of items to be included in the final tooltip

---Tooltip type, usually a string
---@class UTKTooltips.TooltipType

--- Table of possible base tooltip types
---@class UTKTooltips.TooltipTypes
---@field Activator UTKTooltips.TooltipType @{openmw.types#Activator} tooltip. Requires either a key or an object. Note that most activators have empty names, and consequentially do not show a tooltip by default.
---@field ActiveSpellEffect UTKTooltips.TooltipType Active spell effect tooltip. Key must be the record ID of a magic effect, and observer must be set to a valid actor.
---@field Apparatus UTKTooltips.TooltipType @{openmw.types#Apparatus} tooltip. Requires either a key or an object
---@field Armor UTKTooltips.TooltipType @{openmw.types#Armor} tooltip. Requires either a key or an object
---@field Attribute UTKTooltips.TooltipType Attribute tooltip. Attribute must be a valid attribute record id
---@field BirthSign UTKTooltips.TooltipType BirthSign tooltip. Key must be a valid types.Player.birthSigns record id
---@field Book UTKTooltips.TooltipType @{openmw.types#Book} tooltip. Requires either a key or an object
---@field Caption UTKTooltips.TooltipType Caption tooltip. Displays the caption as plain text.
---@field CaptionOneLine UTKTooltips.TooltipType Caption one-line tooltip. Displays the caption as plain text, never breaking the text across lines.
---@field Class UTKTooltips.TooltipType Class tooltip. Key must be a valid types.NPC.classes record id
---@field Clothing UTKTooltips.TooltipType @{openmw.types#Clothing} tooltip. Requires either a key or an object
---@field Container UTKTooltips.TooltipType @{openmw.types#Container} tooltip. Requires either a key or an object
---@field Creature UTKTooltips.TooltipType @{openmw.types#Creature} tooltip. Requires either a key or an object
---@field Door UTKTooltips.TooltipType @{openmw.types#Door} tooltip. Requires either a key or an object
---@field Faction UTKTooltips.TooltipType Faction tooltip. Key must be a valid core.factions record id
---@field HandToHand UTKTooltips.TooltipType HandToHand tooltip. If observer is set to a valid NPC, the icon changes when the observer is a werewolf.
---@field Ingredient UTKTooltips.TooltipType @{openmw.types#Ingredient} tooltip. Requires either a key or an object
---@field Level UTKTooltips.TooltipType Level tooltip. Shows info about the player's current level progression. observer must be set to a valid player.
---@field Light UTKTooltips.TooltipType @{openmw.types#Light} tooltip. Requires either a key or an object
---@field Lockpick UTKTooltips.TooltipType @{openmw.types#Lockpick} tooltip. Requires either a key or an object
---@field MagicEffect UTKTooltips.TooltipType MagicEffect tooltip. Key must be a valid magic effect record id
---@field MapMarker UTKTooltips.TooltipType Map marker tooltip. Caption is the marker text, and may optionally include a list of notes.
---@field Miscellaneous UTKTooltips.TooltipType @{openmw.types#Miscellaneus} tooltip. Requires either a key or an object
---@field None UTKTooltips.TooltipType
---@field NPC UTKTooltips.TooltipType @{openmw.types#NPC} tooltip. Requires either a key or an object
---@field Player UTKTooltips.TooltipType @{openmw.types#Player} tooltip. Requires either a key or an object. By default shows nothing.
---@field Potion UTKTooltips.TooltipType @{openmw.types#Potion} tooltip. Requires either a key or an object
---@field Probe UTKTooltips.TooltipType @{openmw.types#Probe} tooltip. Requires either a key or an object
---@field Race UTKTooltips.TooltipType Race tooltip. Key must be a valid types.NPC.races record id
---@field Skill UTKTooltips.TooltipType Skill tooltip. Skill must be a valid skill record id. Includes skill progress if observer is set to a valid player.
---@field Specialization UTKTooltips.TooltipType Specialization tooltip. This is the tooltip that appears detailing the specializations. Key must be a valid specialization.
---@field Spell UTKTooltips.TooltipType Spell tooltip. Key must be a valid spell record id. Includes casting cost if observer is set to a valid NPC.
---@field Stat UTKTooltips.TooltipType Stat tooltip. This is the tooltip that appears when hovering over player stats in the stats menu. Key must be a valid key into types.Actor.stats.dynamic. observer must be set to a valid actor
---@field Static UTKTooltips.TooltipType @{openmw.types#Static} tooltip. Requires either a key or an object. By default shows nothing.
---@field Weapon UTKTooltips.TooltipType @{openmw.types#Weapon} tooltip. Requires either a key or an object

---@class UTKTooltips.ContentNames
---@field ActiveEffects string
---@field ArmorRating string
---@field LevelAttributeIncreases string
---@field Banner string
---@field Caption string
---@field CastCost string
---@field ChargeMeter string
---@field ChopDamage string
---@field Condition string
---@field Damage string
---@field EmptyLine string
---@field EnchantmentType string
---@field EXPELLED string
---@field FactionFavoriteSkills string
---@field FactionFavoriteSkillsList string
---@field FactionNextRank string
---@field FactionNextRankAttributes string
---@field FactionNextRankSkills string
---@field FactionRank string
---@field Header string
---@field Icon string
---@field List string
---@field Lock string
---@field MagicEffects string
---@field MainFlex string
---@field MapNote string
---@field Paragraph string
---@field ProgressBar string
---@field Quality string
---@field Root string
---@field School string
---@field Specialization string
---@field SkillList string
---@field SkillMaxed string
---@field SpellList string
---@field SlashDamage string
---@field Teleport string
---@field Text string
---@field ThrustDamage string
---@field Trap string
---@field Value string
---@field WeaponType string
---@field Weight string

---@alias UIToolkit.BoxStyle 'thin' | 'thick' | 'button'
---@alias UIToolkit.BackgroundOpacity 'solid'|'transparent'|number
---@alias UIToolkit.BoxBackground {opacity:UIToolkit.BackgroundOpacity, color:openmw.util.Color?}|UIToolkit.BackgroundOpacity
---@alias UIToolkit.ColumnComparator fun(a:UIToolkit.ListData.Column, b:UIToolkit.ListData.Column, col: string?):number
---@alias UIToolkit.SimpleColumnComparatorConfig {col:string?, numeric:boolean?}
---@alias UTKTooltips.PreCreateHandler fun(recipe:UTKTooltips.Recipe, tooltip:UTKTooltips.Tooltip)
---@alias UTKTooltips.PostCreateHandler fun(layout:openmw.ui.Layout, tooltip:UTKTooltips.Tooltip)
---@alias UTKTooltips.CurrentTipIsAlive fun():boolean
---@alias UIToolkit.TooltipProvider fun():UTKTooltips.AnyTooltip?
---@alias UTKTooltips.SimpleTextTooltip string
---@alias UTKTooltips.SimpleTooltip {title:string?, body:string?, width:number?}
---@alias UTKTooltips.AnyTooltip UTKTooltips.Tooltip|UTKTooltips.SimpleTooltip|UTKTooltips.SimpleTextTooltip
