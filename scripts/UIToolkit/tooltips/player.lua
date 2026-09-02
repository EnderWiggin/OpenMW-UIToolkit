---@omw-context player
local ui = require('openmw.ui')
local util = require('openmw.util')
local auxUi = require('openmw_aux.ui')
local auxUtil = require('openmw_aux.util')
local I = require('openmw.interfaces')
local types = require('openmw.types')
local core = require('openmw.core')
local self = require('openmw.self')
local helpers = require('scripts.UIToolkit.tooltips.utils')
local Tooltips = require('scripts.UIToolkit.tooltips.tooltips')
local T = require('scripts.UIToolkit.templates.base')
local D = require('scripts.UIToolkit.config.defaults')

local tooltipElement = ui.create {
    type = ui.TYPE.Container,
    props = {},
    layer = 'Popup'
}
---@type UTKTooltips.Tooltip?
local currentTooltip
---@type openmw.ui.Element?
local currentTipElement

---@type UTKTooltips.ExtraParams?
local extraParams


---@type UTKTooltips.PreCreateHandler[]
local preCreateTooltipHandlers = {}
---@type UTKTooltips.PostCreateHandler[]
local postCreateTooltipHandlers = {}

local boxTemplateNormal = I.MWUI.templates.boxSolid
local boxTemplateOwned = auxUi.deepLayoutCopy(I.MWUI.templates.boxSolid)
---@cast boxTemplateOwned openmw.ui.Template
boxTemplateOwned.content[1].props.color = util.color.rgb(0.15, 0, 0)
boxTemplateOwned.content[1].props.alpha = 1.0


local showOwnedObjects = true --TODO: read from settings
local fixedTooltips = false   --TODO: read from settings
local fixedPositionSet = false

local function isOwned(obj)
    if not obj then
        return false
    end

    local owner = obj.owner
    if owner.recordId and owner.recordId ~= self.object.recordId then
        return true
    end

    local faction = owner.factionId
    if faction then
        local rank = types.NPC.getFactionRank(self.object, owner.factionId)
        if rank == 0 then
            -- Not in faction.
            return true
        else
            return rank < (owner.factionRank or 0)
        end
    end

    return false
end

local function isKnockedOut(obj)
    local isParalyzed = types.Actor.activeEffects(obj):getEffect(core.magic.EFFECT_TYPE.Paralyze) ~= 0
    local isDead = types.Actor.isDead(obj)
    local canMove = types.Actor.canMove(obj)
    -- If the actor can't move, but is neither paralyzed nor dead, then the actor must be knocked out
    return not canMove and not isDead and not isParalyzed
end

local function isAllowedToUse(obj, actor)
    if not obj or not actor then
        return true
    end

    if types.Door.objectIsInstance(obj) and not types.Lockable.isLocked(obj) then
        return true
    end

    local record = obj.type.record(obj)

    -- This is the current engine implementation for detecting a bed, the following comment is copied from the engine:
    -- TODO: implement a better check to check if target is owned bed
    if types.Activator.objectIsInstance(obj) and string.sub(tostring(record.mwscript), 1, 3) ~= 'bed' then
        return true
    end

    if types.NPC.objectIsInstance(obj) then
        if types.Actor.isDead(obj) then
            return true
        end

        return not (isKnockedOut(obj) or self.controls.sneak)
    end

    if isOwned(obj) then
        return false
    end

    return obj.recordId ~= 'stolen_goods'
end

local function autoType(tooltip)
    if not tooltip then return end
    if tooltip.object then
        local t = Tooltips.objectType[tooltip.object.type]
        if t then
            tooltip.type = t
            return true
        end
    end
    if tooltip.key then
        for k, v in pairs(Tooltips.objectType) do
            if k.records[tooltip.key] then
                tooltip.type = v
                return true
            end
        end
    end
    return false
end

---@param tooltip UTKTooltips.Tooltip
---@return openmw.ui.Layout?
local function createTooltipLayout(tooltip)
    local layout = nil
    local recipe = tooltip.recipe
    if not tooltip.recipe then
        if not tooltip.type and not autoType(tooltip) then
            error('Cannot use new tooltip: Unable to determine type')
        end

        local func = Tooltips.recipes[tooltip.type]
        if func then
            recipe = func(tooltip)
        end
    end
    recipe = recipe or {}
    recipe.items = recipe.items or {}
    auxUtil.callEventHandlers(preCreateTooltipHandlers, recipe, tooltip)

    if recipe.items and #recipe.items > 0 then
        layout = Tooltips.buildTooltip(recipe, tooltip)
    end
    if layout then
        local template = boxTemplateNormal
        if showOwnedObjects and not isAllowedToUse(tooltip.object, tooltip.observer) then
            template = boxTemplateOwned
        end

        layout = {
            template = template,
            content = ui.content { {
                template = T.padding(8),
                content = ui.content { layout }
            } },
            props = {},
            layer = 'Popup',
        }
    end

    auxUtil.callEventHandlers(postCreateTooltipHandlers, layout, tooltip)

    return layout
end

local function getMousePosition()
    if extraParams and extraParams.fixedTipPos then return extraParams.fixedTipPos end
    ---@diagnostic disable-next-line: undefined-field
    if ui.mousePosition then return ui.mousePosition() end

    local ctx = I.UIToolkit.getCtx()
    return ctx.lastMousePos
end

local function updatePosition()
    if not currentTooltip then return end
    local mousePos = getMousePosition()
    local screenSize = ui.screenSize()
    local props = tooltipElement.layout.props
    if mousePos then
        -- UI move is active

        if fixedTooltips and fixedPositionSet then
            -- User wants tooltips to stay in place
            return
        end
        -- The tooltip should follow the mouse

        -- Offset the tooltip widget to make sure we don't overrun edges.
        local anchorX = mousePos.x / screenSize.x

        -- With fixed tooltips, we increase the offset to ensure the tooltip doesn't overlap
        -- the inventory icon it's active for.
        local offsetY = fixedTooltips and 50 or 30
        local anchorY = 0

        -- Normally tooltips are below the cursor, and we have to flip that and place it above
        -- the cursor if we are too far down the screen.
        -- This flip should depend on the tooltip size, but we don't have access to that information
        -- so we flip it about 3/4 of the way down the screen instead.
        if (mousePos.y / screenSize.y) > 0.75 then
            offsetY = -offsetY
            anchorY = 1
        end

        props.position = util.vector2(mousePos.x, util.clamp(mousePos.y + offsetY, 0, screenSize.y))
        props.anchor = util.vector2(anchorX, anchorY)
    else
        if currentTooltip.object and not fixedTooltips then
            local viewport = helpers.objectTooltipViewportCoords(currentTooltip.object)
            if viewport then
                -- Subtract a bit from y to raise the tooltip slightly, to help avoid the tooltip overlapping the crosshair
                -- in most cases. Note that this subtracts more than the original engine implementation, this is because in
                -- most cases the anchor lowers the tooltip relative to the original engine implementation.
                local y = math.max(0, math.min(screenSize.y, viewport.y - 50))
                props.position = util.vector2(screenSize.x / 2, y)
                -- Since we do not have access to the final size of the tooltip element, we have to use the anchor
                -- to ensure the tooltip does not disappear off the screen near the top/bottom of the screen.
                props.anchor = util.vector2(0.5, math.min(y / screenSize.y, 1))
            else
                -- Couldn't get in-world position - place below crosshair
                props.position = (ui.screenSize() / 2) - util.vector2(0, 50)
                props.anchor = util.vector2(0.5, 1)
            end
        else
            -- User wants tooltips to stay in place
            props.position = (ui.screenSize() / 2) - util.vector2(0, 50)
            props.anchor = util.vector2(0.5, 1)
        end
    end
    if extraParams and extraParams.fixedTipAnchor then
        props.anchor = extraParams.fixedTipAnchor
    end
    fixedPositionSet = true
end

local function clear()
    currentTooltip = nil
    extraParams = nil
    tooltipElement.layout.content = nil
    fixedPositionSet = false
    if currentTipElement then
        I.UIToolkit.queueDestroy(currentTipElement, true)
        currentTipElement = nil
    end
end

local function tooltipIsDead()
    if not extraParams then return false end
    if not extraParams.isAlive then return false end
    return not extraParams.isAlive()
end

local function update()
    if tooltipIsDead() then
        clear()
    end
    if currentTooltip ~= nil then
        tooltipElement.layout.props.visible = true
        if not currentTipElement then
            local layout = currentTooltip.layout
            if not layout then
                layout = createTooltipLayout(currentTooltip)
            end
            if layout then
                currentTipElement = ui.create(layout)
            end
        end
        if not tooltipElement.layout.content and currentTipElement then
            tooltipElement.layout.content = ui.content { currentTipElement }
        end
        updatePosition()
        tooltipElement:update()
    elseif tooltipElement.layout.props.visible then
        tooltipElement.layout.props.visible = false
        tooltipElement:update()
    end
end

---@param tip UTKTooltips.AnyTooltip?
---@return UTKTooltips.Tooltip?
local function processAnyTooltip(tip)
    if not tip then return nil end
    if type(tip) == 'string' then
        ---@type UTKTooltips.Tooltip
        return { recipe = { items = { { text = tip --[[@as string]] } } } }
    end
    if tip.key or tip.object or tip.recipe or tip.layout then
        return tip --[[@as UTKTooltips.Tooltip]]
    end
    ---@type UTKTooltips.RecipeItem[]
    local items = {}
    if tip.title then items[#items + 1] = { type = 'header', text = tip.title } end
    if tip.body then
        items[#items + 1] = {
            type = 'paragraph',
            text = tip.body,
            width = tip.width,
            align = ui.ALIGNMENT.Center
        }
    end
    if #items <= 0 then return nil end
    ---@type UTKTooltips.Tooltip
    return { recipe = { items = items, arrange = ui.ALIGNMENT.Center } }
end

---@param newTooltip? UTKTooltips.AnyTooltip
---@param extra UTKTooltips.ExtraParams?
local function setTooltip(newTooltip, extra)
    clear()
    newTooltip = processAnyTooltip(newTooltip)
    if newTooltip then
        if not newTooltip.layout and not newTooltip.recipe and not newTooltip.type and not autoType(newTooltip) then
            error('Cannot use new tooltip: Unable to determine type')
        end
        currentTooltip = newTooltip
        extraParams = extra
    end
end


return {
    engineHandlers = {
        onFrame = update,
    },
    interfaceName = 'UTKTooltips',
    interface = {
        version = D.Tooltips,

        currentTooltip = function() return currentTooltip end,
        setTooltip = setTooltip,
        convertAnyTooltip = processAnyTooltip,
        createTooltipLayout = createTooltipLayout,
        addPreCreateTooltipHandler = function(handler)
            preCreateTooltipHandlers[#preCreateTooltipHandlers + 1] = handler
        end,
        addPostCreateTooltipHandler = function(handler)
            postCreateTooltipHandlers[#postCreateTooltipHandlers + 1] = handler
        end,
        registerBuilder = function(type, func)
            Tooltips.builders[type] = func
        end,

        --- A list of all built-in tooltip contents. use view(I.Tooltips.CONTENT) in luap in the in-game console to see the full list.
        -- These are the names of layouts within the tooltips, to be used to index into content by name
        CONTENT = Tooltips.CONTENT,

        --- A list of all built-in tooltip types.
        TYPE = Tooltips.TYPE,

        --- A map of UTKTooltips.RecipeItemType to builder functions
        builders = Tooltips.builders,
    },
}
