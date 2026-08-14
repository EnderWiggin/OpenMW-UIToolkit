---@omw-context player

local ui = require('openmw.ui')
local util = require('openmw.util')
local async = require('openmw.async')
local I = require('openmw.interfaces')

local v2 = util.vector2
local Class = require('scripts.UIToolkit.class')
local Component = require('scripts.UIToolkit.components.component')

local REVERT_TEX = ui.texture { path = 'icons/UIToolkit/revert.dds' }
local T = {
    Base = require('scripts.UIToolkit.templates.base'),
    Interactive = require('scripts.UIToolkit.templates.interactive'),
}

---@class UIToolkit.TextEdit : UIToolkit.Component
local TextEdit = Class(Component)

---@param opts UIToolkit.TextEditOpts
function TextEdit:init(opts)
    local t = I.UIToolkit.getTheme()
    local editTemplate = T.Base.textEditLine
    self._text = opts.text or ''
    self._placeholder = opts.placeholder
    self._textSize = opts.textSize or editTemplate.props.textSize
    self._textColorNormal = opts.textColorNormal or t.Colors.DEFAULT_LIGHT
    self._textColorPlaceholder = opts.textColorPlaceholder or t.Colors.DISABLED
    self._onTextChanged = opts.onTextChanged
    local isEmpty = self._text == ''

    ---@type openmw.ui.Element
    local element
    local w, h = opts.width or 200, self._textSize

    self._editProps = {
        size = v2(w, h),
        text = isEmpty and self._placeholder or self._text,
        textColor = self:_textColor(isEmpty),
        textSize = self._textSize,
    }

    local content = ui.content { {
        name = 'text-edit',
        template = editTemplate,
        props = self._editProps,
        events = {
            textChanged = async:callback(function(text, layout)
                self._text = text
                layout.props.text = text
                if self._onTextChanged then
                    self._onTextChanged(text)
                end
            end),
            focusGain = async:callback(function(_, layout)
                if self:isEmpty() then
                    layout.props.text = ''
                    layout.props.textColor = self:_textColor(false)
                    I.UIToolkit.queueUpdate(element)
                end
            end),
            focusLoss = async:callback(function(_, layout)
                if self:isEmpty() then
                    layout.props.text = self._placeholder or ''
                    layout.props.textColor = self:_textColor(true)
                    I.UIToolkit.queueUpdate(element)
                end
            end),
        }
    } }

    if opts.showClearButton then
        self._btnProps = {
            size = v2(h, h),
            position = v2(w, 0),
            resource = REVERT_TEX,
        }
        local btn = {
            name = 'btn-clear',
            type = ui.TYPE.Image,
            props = self._btnProps,
            userData = { colorable = true, }
        }
        I.UIToolkit.updateInteractiveState(btn, { disabled = true })
        content:add(T.Interactive.interactive({
            onClick = function()
                self:setText('')
                if self._onTextChanged then
                    self._onTextChanged('')
                end
            end
        }, btn))
    end

    element = ui.create {
        name = 'edit-box',
        template = I.MWUI.templates.box,
        props = {},
        content = ui.content {
            {
                name = 'padding',
                template = I.MWUI.templates.padding,
                content = content,
            }
        },
    }

    Component.init(self, element)
end

function TextEdit:isEmpty()
    return self._text == nil or self._text == ''
end

---@return string
function TextEdit:getText()
    return self._text or ''
end

---@param value string
function TextEdit:setText(value)
    if self:isDestroyed() then return end
    self._text = value or ''
    local isEmpty = self._text == ''
    self._editProps.text = isEmpty and self._placeholder or value
    self._editProps.textColor = self:_textColor(isEmpty)
    I.UIToolkit.queueUpdate(self.element)
end

---@param value string?
function TextEdit:setPlaceholder(value)
    if self:isDestroyed() then return end
    self._placeholder = value
    if self:isEmpty() then
        I.UIToolkit.queueUpdate(self.element)
        self._editProps.text = self._placeholder
        self._editProps.textColor = self:_textColor(true)
    end
end

---@param width number
function TextEdit:setSize(width)
    if self:isDestroyed() then return end
    local w, h = width or 200, self._textSize
    self._editProps.size = v2(w, h)
    local deep = false
    if self._btnProps then
        deep = true
        self._btnProps.size = v2(h, h)
        self._btnProps.position = v2(w - h, 0)
    end
    I.UIToolkit.queueUpdate(self.element, deep)
end

---@private
---@param empty boolean
function TextEdit:_textColor(empty)
    if empty then
        return self._textColorPlaceholder
    end
    return self._textColorNormal
end

return TextEdit
