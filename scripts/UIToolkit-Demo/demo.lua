---@omw-context player

local core          = require 'openmw.core'
local input         = require 'openmw.input'
local types         = require 'openmw.types'
local player        = require 'openmw.self'
local ui            = require 'openmw.ui'
local util          = require 'openmw.util'
local auxUtil       = require 'openmw_aux.util'

local I             = require 'openmw.interfaces'
local H             = require 'scripts.UIToolkit.helpers'
local cfgUtils      = require 'scripts.UIToolkit.config.utils'
local Device        = require 'scripts.UIToolkit.config.defaults'.Device
local tipUtils      = require 'scripts.UIToolkit.tooltips.utils'

local Class         = require 'scripts.UIToolkit.class'
local Filter        = require 'scripts.UIToolkit.compound_filter'
local WindowHandler = require 'scripts.UIToolkit.window_handler'
local ColumnItem    = require 'scripts.UIToolkit.components.list_items.column_item'

local v2            = util.vector2
local WND_NAME      = 'uitoolkit-demo'
local BUTTON        = input.CONTROLLER_BUTTON
local Toolkit       = I.UIToolkit
local C             = Toolkit.Components
local T             = Toolkit.Templates


local textSize  = Toolkit.getTheme().Sizes.textNormal
local rowHeight = 1.5 * (textSize + 2)


local SETTINGS   = 'Settings/UIToolkitDemo/Main'
local BIND_POPUP = 'c_BindPopup'


local async = require 'openmw.async'
local storage = require 'openmw.storage'
local section = storage.playerSection(SETTINGS)
local binds = section:asTable()

local function updateSettings()
    binds = section:asTable()
end
section:subscribe(async:callback(updateSettings))


---@type UIToolkit.SortedList?
local list
---@type UIToolkit.SortedList.Column[]
local columns = {
    { id = 'icon',   name = nil,    sort = { col = 'id' },     render = ColumnItem.renderIcon, width = rowHeight + 5,   arg = { sz = 1.5 * textSize } },
    { id = 'name',   name = 'Name', sort = {},                 render = ColumnItem.renderText, },
    { id = 'damage', name = 'Dmg.', sort = { numeric = true }, render = ColumnItem.renderText, width = 2 * rowHeight,   arg = { textAlignH = ui.ALIGNMENT.End }, align = ui.ALIGNMENT.End },
    { id = 'weight', name = 'Wgt.', sort = { numeric = true }, render = ColumnItem.renderText, width = 2 * rowHeight,   arg = { textAlignH = ui.ALIGNMENT.End }, align = ui.ALIGNMENT.End },
    { id = 'value',  name = 'Val.', sort = { numeric = true }, render = ColumnItem.renderText, width = 2.7 * rowHeight, arg = { textAlignH = ui.ALIGNMENT.End }, align = ui.ALIGNMENT.End },
    { id = 'V/W',    name = 'V/W',  sort = { numeric = true }, render = ColumnItem.renderText, width = 2.7 * rowHeight, arg = { textAlignH = ui.ALIGNMENT.End }, align = ui.ALIGNMENT.End },
}


---@type UIToolkit.SortedList.Column[]
local spellColumns = {
    { id = 'icon',   name = nil,      sort = nil, render = ColumnItem.renderIcon, width = rowHeight + 5,                      arg = { sz = 1.5 * textSize } },
    { id = 'name',   name = 'Name',   sort = {},  render = ColumnItem.renderText, auto = 2.5 },
    { id = 'school', name = 'School', sort = {},  render = ColumnItem.renderText, arg = { textAlignH = ui.ALIGNMENT.Center }, align = ui.ALIGNMENT.Center },
}

local function makeSpellList()
    local known = auxUtil.mapFilter(types.Actor.spells(player), function(spell)
        return spell.type == core.magic.SPELL_TYPE.Spell
    end)
    local spells = {}
    for i = 1, #known do
        ---@type openmw.core.Spell
        local spell = known[i]
        local effect = spell.effects[1]
        ---@type openmw.core.MagicEffect
        local effectRecord = effect and core.magic.effects.records[effect.id]
        spells[#spells + 1] = {
            id = spell.id,
            icon = effectRecord and effectRecord.icon,
            name = spell.name,
            school = core.stats.Skill.record(tipUtils.getSpellEffectiveSchool(spell, player)).name,
            tooltip = { key = spell.id, type = I.UTKTooltips.TYPE.Spell, observer = player },
            isActive = function()
                local selected = types.Actor.getSelectedSpell(player)
                return selected and selected.id == spell.id
            end,
        }
    end
    local spellList
    local onClicked = function(data)
        local selected = types.Actor.getSelectedSpell(player)
        if selected then
            local cached = spellList.provider:getCachedComponent(selected.id)
            if cached then
                cached:setActive(false)
                Toolkit.queueUpdate(cached.element, true)
            end
        end
        types.Actor.setSelectedSpell(player, data.id)
        local cached = spellList.provider:getCachedComponent(data.id)
        if cached then
            cached:setActive(true)
            Toolkit.queueUpdate(cached.element, true)
        end
    end
    spellList = C.sortedList {
        size = v2(400, 300),
        onItemClicked = onClicked,
        columns = spellColumns,
    }
    spellList:setItems(spells)
    spellList.header:toggleColumn('name')

    return spellList, onClicked
end

local function onShowPopupClicked()
    local closePopup
    closePopup = Toolkit.Popups.show {
        title = 'THE POPUP',
        body =
        'This is a very cool popup. It has a long text on it. Very good, very long text.\nIt probably takes up several lines on this popup, wow!',
        controllerHints = { { text = 'Close Popup', input = cfgUtils.getControllerInputs(binds[BIND_POPUP]) } },
        onControllerButtonPress = function(button)
            if cfgUtils.controllerMatches(button, binds[BIND_POPUP]) then
                closePopup()
            end
        end,
        buttons = {
            {
                text = 'Select Spell',
                onClicked = function()
                    local spellList, clicked = makeSpellList()
                    local function onButton(button)
                        if button == BUTTON.DPadDown then
                            spellList.list:shiftHoveredItem(1)
                        elseif button == BUTTON.DPadUp then
                            spellList.list:shiftHoveredItem(-1)
                        elseif button == BUTTON.A then
                            local hovered = spellList.list:getHovered()
                            if hovered then clicked(hovered) end
                        end
                    end

                    Toolkit.Popups.show {
                        title = 'Select the spell',
                        body = spellList,
                        buttons = { { text = 'Close' } },
                        getFocusedScrollable = function() return spellList.list end,
                        onControllerButtonPress = onButton,
                        onControllerButtonRepeat = function(button)
                            if button == BUTTON.DPadDown or button == BUTTON.DPadUp then
                                onButton(button)
                            end
                        end,
                    }
                end,
            },
            {
                text = 'Queue Popup',
                noClose = true,
                style = 'thin',
                onClicked = function()
                    local attrs = {}
                    for id, record in pairs(core.stats.Attribute.records) do
                        attrs[#attrs + 1] = {
                            id = id,
                            text = record.name,
                            tooltip = { key = id, type = I.UTKTooltips.TYPE.Attribute },
                        }
                    end

                    Toolkit.Popups.show {
                        body = {
                            type = ui.TYPE.Flex,
                            props = {},
                            content = ui.content {
                                {
                                    template = T.paragraph(),
                                    props = {
                                        size = v2(300, 0),
                                        text = 'Press OK to close this popup an return to the previous one!\nOr select attribute for some fun:',
                                    },
                                },
                                T.intervalV(5),
                                C.dropbox {
                                    width = 150,
                                    items = attrs,
                                    onItemSelected = function(item, idx)
                                        print('Attribute:', item.text)
                                    end
                                }.element
                            },
                        },
                        borderStyle = 'thin',
                        buttons = { { text = 'OK' }, }
                    }
                end,
                tooltip = { body = 'Will open new popup without closing this one.', width = 200 }
            },
            { text = 'Cancel', tooltip = 'Closes this popup' },
        }
    }
end

local selectedType = nil
local function ofType(item)
    return selectedType == nil or selectedType == item.type
end

---@class Handler: UIToolkit.WindowHandler
local Handler = Class(WindowHandler)

local state

---@param wnd UIToolkit.Window
function Handler:onOpened(wnd, _, saved)
    state = saved or {}
    local theme = Toolkit.getTheme()
    I.UI.setMode(I.UI.MODE.Interface, { windows = {} })

    wnd:setControllerHints {
        { text = 'Show Popup', input = cfgUtils.getControllerInputs(binds[BIND_POPUP]) },
    }

    list = C.sortedList {
        size = v2(200, 300),
        onItemClicked = function(data)
            if not list then return end
            local cached = list.provider:getCachedComponent(data.id)
            if not cached then return end
            cached:setActive(not cached:isActive())
        end,
        columns = columns,
        hiddenColumns = { damage = true, ['V/W'] = true }
    }
    list.header:toggleColumn('name')

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
            name = item.count > 1
                and record.name .. ' (' .. H.addSeparators(item.count) .. ')'
                or record.name,
            type = item.type,
            damage = function()
                if not types.Weapon.objectIsInstance(item) then return '-' end

                local wRecord = item.type.record(item)
                return math.max(wRecord.chopMaxDamage, wRecord.slashMaxDamage, wRecord.thrustMaxDamage)
            end,
            weight = record.weight > 0 and record.weight or '-',
            value = record.value > 0 and record.value or '-',
            ['V/W'] = record.value > 0 and record.weight > 0 and util.round(record.value / record.weight) or '-',
            tooltip = { object = item, observer = player }
        }
    end

    ---@type UIToolkit.CompoundFilter<UIToolkit.SortedList.Filter>
    local f = Filter:new()
    f:add('type', ofType)
    f:add('weight', function(item)
        return type(item.weight) == 'number' and item.weight > 0
    end)
    f:disable('weight', state.hideWeightless ~= true)

    list:setFilter(f)
    list:setItems(rows)

    local tabs = {
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
            arrange = ui.ALIGNMENT.Center,
        },
        content = ui.content {
            T.intervalH(5),
            C.textButton { text = 'All', onClick = function()
                selectedType = nil
                list:setHiddenColumns { damage = true, ['V/W'] = true }
                list:filter()
            end, style = 'thin' }.element,
            T.intervalH(5),
            C.textButton { text = 'Weapons', onClick = function()
                selectedType = types.Weapon
                list:setHiddenColumns { ['V/W'] = true }
                list:filter()
            end, style = 'thin' }.element,
            T.intervalH(5),
            C.textButton { text = 'Misc', onClick = function()
                selectedType = types.Miscellaneous
                list:setHiddenColumns { damage = true }
                list:filter()
            end, style = 'thin' }.element,
            T.intervalH(10),
            C.checkbox {
                text = 'No Weightless',
                default = state.hideWeightless == true,
                onValueChanged = function(value)
                    state.hideWeightless = value
                    f:disable('weight', not value)
                    list:filter()
                end,
            }.element,
        },
    }

    -- slider+text combo that allows entering value in range [1 - 100]
    local slider
    local edit

    slider = C.scrollBar {
        horizontal = true,
        length = 250,
        handleSize = 20,
        scrollStep = 2,
        maxScroll = 198, -- we have 100 values (1-100), position goes from 0 to maxScroll, so it must be scrollStep*(range-1) for our case
        onScroll = function(position)
            local value = math.floor(position / 2) + 1
            state.slider = value
            edit:setValue(value)
        end,
    }

    edit = C.textEdit {
        default = 1,
        width = 55,
        textAlignH = ui.ALIGNMENT.Center,
        validate = function(text)
            local number = tonumber(text)
            if not number then
                return false, nil
            else
                return true, util.clamp(number, 1, 100)
            end
        end,
        onValueChanged = function(value)
            local pos = 2 * (value - 1)
            state.slider = value
            slider:setPosition(pos, true)
        end
    }
    if state.slider then slider:setPosition(2 * (state.slider - 1)) end

    local skills = {}
    for id, record in pairs(core.stats.Skill.records) do
        skills[#skills + 1] = {
            id = id,
            text = record.name,
            tooltip = { key = id, type = I.UTKTooltips.TYPE.Skill },
        }
    end
    table.sort(skills, function(a, b) return a.text < b.text end)

    local dropbox = C.dropbox {
        width = 150,
        items = skills,
        maxVisibleItems = 10,
        onItemSelected = function(item, idx)
            print('Selected: ', item.text)
            state.dropbox = item.id
        end
    }
    if state.dropbox then dropbox:selectById(state.dropbox) end

    local progressBar
    progressBar = C.progressBar {
        value = 50,
        onClick = function()
            if input.isShiftPressed() then
                local max = progressBar:getMax()
                if max < 150 then
                    progressBar:setMax(max + 5)
                end
            else
                progressBar:setValue(progressBar:getValue() + 10)
            end
        end,
        onRClick = function()
            if input.isShiftPressed() then
                local max = progressBar:getMax()
                if max > 50 then
                    progressBar:setMax(max - 5)
                end
            else
                progressBar:setValue(progressBar:getValue() - 10)
            end
        end,
        tooltip = { body = 'Lift-click to increase progress.\nRight click to decrease progress.\nHold shift when clicking to change max.', width = 200 },
    }

    wnd:setContent(ui.content {
        {
            type = ui.TYPE.Flex,
            props = {},
            content = ui.content {
                T.intervalV(5),
                tabs,
                list.element,
            },
        },
        {
            template = T.border { padding = 5 },
            props = {
                size = v2(330, -10),
                position = v2(-5, 5),
                relativeSize = v2(0, 1),
                anchor = v2(1, 0),
                relativePosition = v2(1, 0),
            },
            content = ui.content {
                {
                    type = ui.TYPE.Flex,
                    props = {},
                    content = ui.content {
                        {
                            template = T.text(),
                            props = { text = "Examples:" },
                        },
                        T.intervalV(15),
                        {
                            type = ui.TYPE.Flex,
                            props = {
                                horizontal = true,
                            },
                            content = ui.content {
                                {
                                    template = T.box { padding = v2(10, 5), background = { color = theme.Colors.DAMAGED, opacity = 'transparent' } },
                                    props = {},
                                    content = ui.content {
                                        {
                                            type = ui.TYPE.Image,
                                            props = {
                                                resource = theme.Colors.whiteTexture,
                                                color = theme.Colors.ACTIVE_LIGHT,
                                                size = v2(10, 10),
                                            },
                                        }
                                    },
                                },
                                T.intervalH(5),
                                {
                                    template = T.box { padding = 5, background = { color = theme.Colors.MAGICK, opacity = 'transparent' } },
                                    props = {},
                                    content = ui.content {
                                        {
                                            type = ui.TYPE.Image,
                                            props = {
                                                resource = theme.Colors.whiteTexture,
                                                color = theme.Colors.DISABLED_LIGHT,
                                                size = v2(10, 10),
                                            },
                                        }
                                    },
                                },
                                T.intervalH(5),
                                progressBar.element,
                            },
                        },
                        T.intervalV(5),
                        C.textButton { text = 'Show Popup', onClick = onShowPopupClicked }.element,
                        T.intervalV(5),
                        C.textButton { text = 'Width=110', width = 110 }.element,
                        T.intervalV(5),
                        {
                            type = ui.TYPE.Flex,
                            props = { horizontal = true },
                            content = ui.content {
                                C.textButton { text = 'Disabled' }:setDisabled(true).element,
                                T.intervalH(5),
                                C.textButton { text = 'Active' }:setActive(true).element,
                            },
                        },
                        T.intervalV(5),
                        {
                            type = ui.TYPE.Flex,
                            props = { horizontal = true },
                            content = ui.content {
                                C.textButton { text = 'Thin', style = 'thin' }.element,
                                T.intervalH(5),
                                C.textButton { text = 'Thick', style = 'thick' }.element,
                                T.intervalH(5),
                                C.textButton { text = 'Colored', background = { opacity = 0.5, color = theme.Colors.FATIGUE } }.element,
                            },
                        },
                        T.intervalV(5),
                        {
                            template = T.paragraph(),
                            props = {
                                text = "slider+text combo that allows entering value in range [1 - 100]:",
                                size = v2(300, 0),
                            },
                        },
                        {
                            type = ui.TYPE.Flex,
                            props = { horizontal = true, arrange = ui.ALIGNMENT.Center },
                            content = ui.content {
                                slider.element,
                                T.intervalH(5),
                                edit.element,
                            },
                        },
                        T.intervalV(5),
                        dropbox.element,
                        T.intervalV(5),
                        {
                            type = ui.TYPE.Flex,
                            props = { horizontal = true, arrange = ui.ALIGNMENT.Center },
                            content = ui.content {
                                C.checkbox {
                                    text = 'Checkbox',
                                    default = state.chbox1,
                                    onValueChanged = function(value)
                                        print('Checkbox:', value)
                                        state.chbox1 = value
                                    end,
                                }.element,
                                T.intervalH(5),
                                C.checkbox {
                                    text = 'Accented',
                                    default = state.chbox2,
                                    accentedCheckmark = true,
                                    onValueChanged = function(value)
                                        state.chbox2 = value
                                    end,
                                }.element,
                                T.intervalH(5),
                                C.checkbox {
                                    text = 'Disabled',
                                    default = true,
                                }:setDisabled(true).element,
                            },
                        },
                    }
                }
            },
        }
    })

    Handler:onResized(wnd:getInnerSize())
end

function Handler:onClosed()
    I.UI.setMode()
    list = nil
    return state
end

---@param inner openmw.util.Vector2
function Handler:onResized(inner)
    if list then
        list:setSize(inner - v2(340, 30))
    end
end

---@param button number
function Handler:onControllerButtonPress(button)
    local bind = cfgUtils.findMatchingController(button, binds)
    if bind == BIND_POPUP then
        onShowPopupClicked()
    end
end

Toolkit.WindowManager.register(WND_NAME, {
    title = 'UI Toolkit Demo',
    handler = Handler,
    draggable = true,
    resizing = true,
    position = v2(300, 300),
    minSize = v2(800, 450),
})


---@param key openmw.input.KeyboardEvent
local function onKeyRelease(key)
    if key.code ~= input.KEY.ScrollLock then return end

    if Toolkit.WindowManager.isOpen(WND_NAME) then
        Toolkit.WindowManager.close(WND_NAME)
    else
        Toolkit.WindowManager.open(WND_NAME)
    end
end

I.Settings.registerPage {
    key = 'UIToolkit-Demo',
    l10n = 'UIToolkitLib',
    name = 'UI Toolkit Demo',
}

I.Settings.registerGroup {
    key = SETTINGS,
    page = 'UIToolkit-Demo',
    l10n = 'UIToolkitLib',
    name = 'Main',
    order = 1,
    permanentStorage = true,
    settings = {
        {
            key = BIND_POPUP,
            renderer = 'UIToolkit/BindCustom',
            name = 'Toggle Popup',
            description = 'Pressing this button will open or close the popup.\nOnly controller buttons allowed.',
            default = {
                { device = Device.Controller, code = input.CONTROLLER_BUTTON.Y },
            },
            argument = { devices = { [Device.Controller] = true } },
        },
    },
}

return {
    engineHandlers = {
        onKeyRelease = onKeyRelease
    },
}
