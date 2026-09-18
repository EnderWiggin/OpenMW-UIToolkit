---@omw-context menu
local ui = require('openmw.ui')
local util = require('openmw.util')
local auxUi = require('openmw_aux.ui')
local I = require('openmw.interfaces')
local D = require('scripts.UIToolkit.config.defaults')
local builders = require('scripts.UIToolkit.tooltips.builders')

local tooltipElement = ui.create {
    type = ui.TYPE.Container,
    props = {},
    layer = 'Popup'
}
---@type UTKTooltips.MenuTooltip?
local currentTooltip
---@type openmw.ui.Element?
local currentTipElement

---@type UTKTooltips.ExtraParams?
local extraParams


local boxTemplateNormal = I.MWUI.templates.boxSolid
local boxTemplateOwned = auxUi.deepLayoutCopy(I.MWUI.templates.boxSolid)
---@cast boxTemplateOwned openmw.ui.Template
boxTemplateOwned.content[1].props.color = util.color.rgb(0.15, 0, 0)
boxTemplateOwned.content[1].props.alpha = 1.0


local fixedTooltips = false --TODO: read from settings
local fixedPositionSet = false

---@param tooltip UTKTooltips.MenuTooltip
---@return openmw.ui.Layout?
local function createTooltipLayout(tooltip)
    local layout = nil
    local recipe = tooltip.recipe
    assert(recipe)


    if recipe.items and #recipe.items > 0 then
        layout = builders.root(recipe, tooltip)
    end
    if layout then
        local template = boxTemplateNormal

        layout = {
            template = template,
            content = ui.content { {
                template = I.UIToolkit.Templates.padding(8),
                content = ui.content { layout }
            } },
            props = {},
            layer = 'Popup',
        }
    end

    return layout
end

local function updatePosition()
    if not currentTooltip then return end
    local props = tooltipElement.layout.props
    if currentTooltip.position then
        local position, anchor = currentTooltip.position()
        if position then
            props.position = position
            props.anchor = anchor
            return
        end
    end

    local mousePos = I.UIToolkit.getCursorPos()
    local screenSize = ui.screenSize()
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

---@param tip UTKTooltips.AnyMenuTooltip?
---@return UTKTooltips.MenuTooltip?
local function processAnyTooltip(tip)
    if not tip then return nil end
    if type(tip) == 'string' then
        ---@type UTKTooltips.MenuTooltip
        return { recipe = { items = { { text = tip --[[@as string]] } } } }
    end
    if tip.recipe or tip.layout then
        return tip --[[@as UTKTooltips.MenuTooltip]]
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
    ---@type UTKTooltips.MenuTooltip
    return { recipe = { items = items, arrange = ui.ALIGNMENT.Center } }
end

---@param newTooltip? UTKTooltips.AnyMenuTooltip
---@param extra UTKTooltips.ExtraParams?
local function setTooltip(newTooltip, extra)
    clear()
    newTooltip = processAnyTooltip(newTooltip)
    if newTooltip then
        if not newTooltip.layout and not newTooltip.recipe then
            error('Cannot use new tooltip: no layout or recipe')
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
    },
}
