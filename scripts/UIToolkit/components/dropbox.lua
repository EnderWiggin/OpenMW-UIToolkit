---@omw-context player|menu

local ui = require('openmw.ui')
local util = require('openmw.util')
local ambient = require('openmw.ambient')
local I = require('openmw.interfaces')

local v2 = util.vector2
local Class = require('scripts.UIToolkit.class')
local Component = require('scripts.UIToolkit.components.component')
local TextProvider = require('scripts.UIToolkit.components.list_items.text_item')

---@class UIToolkit.Dropbox : UIToolkit.Component
---@field new fun(self:UIToolkit.Dropbox):UIToolkit.Dropbox
local Dropbox = Class(Component)

---@param opts UIToolkit.DropboxOpts
function Dropbox:init(opts)
    local T = I.UIToolkit.Templates
    local theme = I.UIToolkit.getTheme()
    local pad = theme.Sizes.padding
    local border = T.getBorderSize('thin')
    local outer = 2 * (pad + border)

    self.width = opts.width or 150
    local height = theme.Sizes.textNormal + outer

    self.provider = TextProvider:new()
    ---@type UIToolkit.ListData.Text[]
    self.items = opts.items
    self.selected = self.items[1]
    self._textProps = {
        text = self.selected.text,
        autoSize = false,
        textAlignV = ui.ALIGNMENT.Center,
        relativeSize = v2(1, 1),
    }
    local visibleItems = opts.maxVisibleItems or #self.items
    visibleItems = math.min(visibleItems, #self.items)
    local listHeight = visibleItems * self.provider:getItemHeight()
    local list = I.UIToolkit.Components.itemList {
        provider = self.provider,
        size = v2(self.width - outer, listHeight),
        noBorder = true,
        scrollWidth = 10,
        slimScroll = true,
        onItemClicked = function(data, idx)
            ambient.playSound('menu click', { scale = false })
            self:selectItem(data)
            self:closePopup()
            if opts.onItemSelected then
                opts.onItemSelected(data, idx)
            end
        end
    }
    list:setItems(self.items)
    list:updateProps {
        anchor = v2(0.5, 1),
        relativePosition = v2(0.5, 1),
    }
    self.popup = ui.create {
        template = I.UIToolkit.Templates.border { padding = 2, background = 'solid' },
        props = {
            position = v2(0, 0),
            size = v2(self.width, listHeight + height + 2 * pad + border),
        },
        content = ui.content {
            {
                props = {
                    size = v2(self.width - outer, height - outer),
                },
                content = ui.content {
                    {
                        template = T.header(),
                        props = self._textProps,
                    },
                    {
                        type = ui.TYPE.Image,
                        props = {
                            resource = I.UIToolkit.texture 'textures/omw_menu_scroll_left.dds',
                            size = v2(16, 16), --TODO: size with text?
                            anchor = v2(1, 0.5),
                            relativePosition = v2(1, 0.5),
                            alpha = 0.65,
                        },
                    }
                },
            },
            {
                template = I.MWUI.templates.horizontalLine,
                props = {
                    position = v2(0, height - 2 * pad - border),
                },
            },
            list.element,
        }
    }

    local element = I.UIToolkit.Interactive.makeInteractive({
        onClick = function(e) self:_onClicked(e) end,
    }, {
        template = T.border { padding = theme.Sizes.padding },
        props = {
            size = v2(self.width, height),
        },
        content = ui.content {
            {
                template = T.text(),
                props = self._textProps,
                userData = { colorable = true },
            },
            {
                type = ui.TYPE.Image,
                props = {
                    resource = I.UIToolkit.texture 'textures/omw_menu_scroll_down.dds',
                    size = v2(16, 16), --TODO: size with text?
                    anchor = v2(1, 0.5),
                    relativePosition = v2(1, 0.5),
                },
            }
        },
    })
    Component.init(self, element)
end

function Dropbox:beforeElementDestroy()
    self:closePopup()
    I.UIToolkit.queueDestroy(self.popup, true)
end

---@param id string
function Dropbox:selectById(id)
    for i = 1, #self.items do
        local item = self.items[i]
        if item.id == id then
            self:selectItem(item)
            break
        end
    end
end

---@param idx integer
function Dropbox:selectByIndex(idx)
    local item = self.items[idx]
    if not item then return end
    self:selectItem(item)
end

---@param item UIToolkit.ListData.Text
function Dropbox:selectItem(item)
    self.selected = item
    self._textProps.text = item.text
    I.UIToolkit.queueUpdate(self.element)
end

---@return UIToolkit.ListData.Text
function Dropbox:getSelectedItem()
    return self.selected
end

---@param e openmw.ui.MouseEvent
function Dropbox:_onClicked(e)
    self.popup.layout.props.position = e.position - e.offset
    I.UIToolkit.queueUpdate(self.popup)
    I.UIToolkit.Layers.addDropbox(self.popup)
end

function Dropbox:closePopup()
    I.UIToolkit.Layers.closeDropbox()
end

return Dropbox
