---@meta

---@class openmw.interfaces
---@field UIToolkit openmw.interfaces.UIToolkit
---@field UTKTooltips openmw.interfaces.UTKTooltips

---@class openmw.interfaces.UIToolkit
---@field getCtx fun():UIToolkit.Context
---@field getTheme fun():UIToolkit.Theme
---@field queueUpdate fun(element:openmw.ui.Element, deep:boolean?) queues element to be updated on next frame
---@field queueDestroy fun(element:openmw.ui.Element, deep:boolean) queues element to be destroyed on next frame
---@field getInteractiveColor fun(state:UIToolkit.InteractiveState, custom:UIToolkit.InteractiveColors?):openmw.util.Color?
---@field applyInteractiveState fun(layout:openmw.ui.Layout, state:UIToolkit.InteractiveState)
---@field updateInteractiveState fun(layoutOrElement:openmw.ui.Layout|openmw.ui.Element, state:UIToolkit.InteractiveState?)
---@field texture fun(path:string, size:openmw.util.Vector2?, offset:openmw.util.Vector2?):openmw.ui.TextureResource
---@field Components UIToolkit.Components
---@field WindowManager UIToolkit.WindowManager

---@class UIToolkit.Context
---@field lastMousePos openmw.util.Vector2? last mouse position detected by interactive elements. Needed until `ui.mousePosition()` is merged (0.52?)

---@class UIToolkit.Theme
---@field Colors UIToolkit.Theme.Colors
---@field Sizes UIToolkit.Theme.Sizes

---@class UIToolkit.InteractiveState
---@field active boolean? element is active - e.g. currently equipped spell in the spell list
---@field pressed boolean? element is currently being pressed
---@field hovering boolean? element is currently being hovered over
---@field disabled boolean? element is disabled

---@class UIToolkit.InteractiveOpts
---@field tooltip? UTKTooltips.Tooltip|UIToolkit.TooltipProvider|nil optional tooltip or tooltip provider function
---@field onClick? fun() optional function to be called when element is clicked. Note: element won't change colors if there's no click callback set
---@field canClick? fun():boolean
---@field onMouseMove? fun(e, tgt, element)

---@class UIToolkit.Components
local Components = {}

---@param opts UIToolkit.TextButtonOpts
---@return UIToolkit.TextButton
function Components.textButton(opts) end

---@param opts UIToolkit.TextEditOpts
---@return UIToolkit.TextEdit
function Components.textEdit(opts) end

---@param opts UIToolkit.ScrollBarOpts
---@return UIToolkit.ScrollBar
function Components.scrollBar(opts) end

---@class UIToolkit.Component
---@field new fun():UIToolkit.Component
---@field init fun(self:UIToolkit.Component, element:openmw.ui.Element)
---@field isDestroyed fun(self:UIToolkit.Component):boolean
---@field element openmw.ui.Element
---@field active fun(self:UIToolkit.Component, value: boolean?):boolean|nil  If value is set - will update active state of the control. Returns active flag. If element is destroyed - returns nil.
---@field disabled fun(self:UIToolkit.Component, value: boolean?):boolean|nil  If value is set - will update disabled state of the control. Returns disabled flag. If element is destroyed - returns nil.

---@class UIToolkit.ButtonOpts : UIToolkit.InteractiveOpts
---@field name string? name to give to button layout
---@field bgrAlpha number? Alpha for background. No background if nil

---@class UIToolkit.TextButtonOpts : UIToolkit.ButtonOpts
---@field text string text on the button
---@field width number? if set, button will be fixed-width, not scale with text length

---@class UIToolkit.TextButton : UIToolkit.Component
---@field new fun():UIToolkit.TextButton
---@field init fun(self:UIToolkit.TextButton, opts:UIToolkit.TextButtonOpts)
---@field setText fun(self:UIToolkit.TextButton, text:string)

---@generic T
---@class UIToolkit.TextEditOpts<T>
---@field default T?
---@field textSize number?
---@field textAlignH openmw.ui.ALIGNMENT?
---@field textColorNormal openmw.util.Color? defaults to DEFAULT_LIGHT
---@field textColorPlaceholder openmw.util.Color? defaults to DISABLED
---@field placeholder string? will be shown when edit is not in focus and text is empty
---@field validate? fun(text:string|T|nil):boolean,T
---@field onValueChanged? fun() will be called when entered value is changed
---@field width number? defaults to 200
---@field showClearButton boolean?

---@generic T
---@class UIToolkit.TextEdit<T> : UIToolkit.Component
---@field new fun():UIToolkit.TextEdit
---@field init fun(self:UIToolkit.TextEdit, opts:UIToolkit.TextEditOpts)
---@field getValue fun(self:UIToolkit.TextEdit):T
---@field setValue fun(self:UIToolkit.TextEdit, value:T)
---@field setPlaceholder fun(self:UIToolkit.TextEdit, value:string?)
---@field setSize fun(self:UIToolkit.TextEdit, width:number)

---@class UIToolkit.ScrollBarOpts
---@field horizontal boolean?
---@field scrollStep number
---@field maxScroll number
---@field size number
---@field handleSize number? if set, handle will be this size, if not - it will auto-calculate
---@field onScroll fun(position:number, progress:number)

---@class UIToolkit.ScrollBar : UIToolkit.Component
---@field new fun():UIToolkit.ScrollBar
---@field init fun(self:UIToolkit.ScrollBar, opts:UIToolkit.ScrollBarOpts)
---@field getPosition fun(self:UIToolkit.ScrollBar):number actual position of the scroll
---@field setPosition fun(self:UIToolkit.ScrollBar, position:number) set scroll position
---@field getProgress fun(self:UIToolkit.ScrollBar):number [0-1] progress of the scroll
---@field setProgress fun(self:UIToolkit.ScrollBar, progress:number) set [0-1] progress of the scroll
---@field scroll fun(self:UIToolkit.ScrollBar, steps:number) scroll the bar by steps
---@field setSize fun(self:UIToolkit.ScrollBar, size:number) set scroll size
---@field setMaxScroll fun(self:UIToolkit.ScrollBar, maxScroll:number, preserveProgress:boolean?)

---@class UIToolkit.WindowManager
---@field register fun(id: string, opts: UIToolkit.WindowOpts)
---@field open fun(id: string):UIToolkit.Window
---@field close fun(id: string)
---@field isOpen fun(id: string):boolean

---@class UIToolkit.WindowOpts
---@field title string
---@field content openmw.ui.Content?
---@field pinnable boolean?
---@field pinned boolean?
---@field position openmw.util.Vector2?
---@field size openmw.util.Vector2?
---@field draggable boolean?
---@field resizing boolean?
---@field minSize openmw.util.Vector2?
---@field onOpen fun(wnd:UIToolkit.Window)?
---@field onClosed fun()?
---@field onResized fun()?

---@class UIToolkit.WindowSaveData
---@field pinned boolean
---@field position openmw.util.Vector2
---@field size openmw.util.Vector2

---@class UIToolkit.Window:UIToolkit.Component
---@field new fun():UIToolkit.Window
---@field init fun(self:UIToolkit.Window, opts:UIToolkit.WindowOpts, saved:UIToolkit.WindowSaveData?)
---@field setTitle fun(self:UIToolkit.Window, newTitle:string)
---@field getPosition fun(self:UIToolkit.Window):openmw.util.Vector2
---@field getSize fun(self:UIToolkit.Window):openmw.util.Vector2
---@field getInnerSize fun(self:UIToolkit.Window):openmw.util.Vector2
---@field isPinned fun(self:UIToolkit.Window):boolean
---@field setPinnable fun(self:UIToolkit.Window, pinnable:boolean)
---@field setMinSize fun(self:UIToolkit.Window, minSz: openmw.util.Vector2)

---@class UIToolkit.InteractiveColors
---@field pressColor openmw.util.Color?
---@field hoverColor openmw.util.Color?
---@field baseColor openmw.util.Color?

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

---@class openmw.interfaces.UTKTooltips
---@field version number
---@field currentTooltip fun():UTKTooltips.Tooltip?
---@field setTooltip fun(tooltip:UTKTooltips.Tooltip?, isAlive:UTKTooltips.CurrentTipIsAlive?)
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
---@field object GameObject? (Optional) object to construct a tooltip from.
---@field observer openmw.types.Actor? (Optional) Actor used to read dynamic values, such as current/max health, skill progression, etc.
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

--- Table defining a single recipe item, to form one entry in the final tooltip
-- Required/ignored fields depend on the recipe item type.
---@class UTKTooltips.RecipeItem
---@field type UTKTooltips.RecipeItemType defines which builder is used to create the layout for this item. (default=default)
---@field align openmw.ui.ALIGNMENT? Re-aligns this item. Not used by any default builders.
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

---@alias UTKTooltips.PreCreateHandler fun(recipe:UTKTooltips.Recipe, tooltip:UTKTooltips.Tooltip)
---@alias UTKTooltips.PostCreateHandler fun(layout:openmw.ui.Layout, tooltip:UTKTooltips.Tooltip)
---@alias UTKTooltips.CurrentTipIsAlive fun():boolean
---@alias UIToolkit.TooltipProvider fun():UTKTooltips.Tooltip?
