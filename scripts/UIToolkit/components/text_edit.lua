---@omw-context player

local ui = require('openmw.ui')
local util = require('openmw.util')
local async = require('openmw.async')
local I = require('openmw.interfaces')

local v2 = util.vector2
local Class = require('scripts.UIToolkit.class')
local Component = require('scripts.UIToolkit.components.component')

local REVERT_TEX = ui.texture { path = 'icons/UIToolkit/revert.dds' }
local PAD = 2
local T = require('scripts.UIToolkit.templates.base')

---@generic T
---@class UIToolkit.TextEdit<T> : UIToolkit.Component
local TextEdit = Class(Component)

local function isEmpty(value)
    return value == nil or value == ''
end

local function toText(value)
    if value == nil then return '' end
    return tostring(value)
end

local function validateText(value) return true, toText(value) end

---@param opts UIToolkit.TextEditOpts
function TextEdit:init(opts)
    local t = I.UIToolkit.getTheme()
    local editTemplate = T.editLine()
    ---@type  fun(text:string|T|nil):boolean,T
    self._validate = opts.validate or validateText
    ---@type T|fun()|string
    self._default = opts.default or ''
    self._value = self:getDefault()
    self._placeholder = opts.placeholder
    self._textSize = opts.textSize or editTemplate.props.textSize
    self._textColorNormal = opts.textColorNormal or t.Colors.DEFAULT_LIGHT
    self._textColorPlaceholder = opts.textColorPlaceholder or t.Colors.DISABLED
    self._onValueChanged = opts.onValueChanged
    local empty = isEmpty(self._value)

    ---@type openmw.ui.Element
    local element
    local w, h = opts.width or 200, self._textSize
    w = w - 2 * PAD

    self._editProps = {
        size = v2(w, h),
        text = empty and self:getPlaceholder() or toText(self._value),
        textColor = self:_textColor(empty),
        textSize = self._textSize,
    }
    if opts.textAlignH then
        self._editProps.textAlignH = opts.textAlignH
    end

    local content = ui.content { {
        name = 'text-edit',
        template = editTemplate,
        props = self._editProps,
        events = {
            textChanged = async:callback(function(text, layout)
                local ok, value = self._validate(text)
                if ok then
                    self._value = value
                end
                layout.props.text = toText(self._value)
                if layout.props.text ~= text then
                    I.UIToolkit.queueUpdate(element)
                end
                if ok and self._onValueChanged then
                    self._onValueChanged()
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
                    layout.props.text = self:getPlaceholder() or ''
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
            anchor = v2(1, 0),
            resource = REVERT_TEX,
            alpha = 0.5,
        }
        local btn = {
            name = 'btn-clear',
            type = ui.TYPE.Image,
            props = self._btnProps,
            userData = { colorable = true, }
        }
        I.UIToolkit.Interactive.updateState(btn, { disabled = true })
        content:add(I.UIToolkit.Interactive.makeInteractive({
            onClick = function()
                self:setValue(self:getDefault())
                if self._onValueChanged then
                    self._onValueChanged()
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
                template = I.UIToolkit.Templates.padding(PAD),
                content = content,
            }
        },
    }

    Component.init(self, element)
end

function TextEdit:isEmpty()
    return toText(self._value) == ''
end

function TextEdit:getDefault()
    if type(self._default) == "function" then
        return self._default()
    end
    return self._default
end

function TextEdit:getPlaceholder()
    if type(self._placeholder) == "function" then
        return self._placeholder()
    end
    return self._placeholder
end

---@return T
function TextEdit:getValue()
    return self._value
end

---@param value T
function TextEdit:setValue(value)
    if self:isDestroyed() then return end
    local ok, v = self._validate(value)
    if not ok then return end
    self._value = v
    local text = toText(self._value)
    local empty = text == ''
    self._editProps.text = empty and self:getPlaceholder() or text
    self._editProps.textColor = self:_textColor(empty)
    I.UIToolkit.queueUpdate(self.element)
end

---@param value string|fun()|nil
function TextEdit:setPlaceholder(value)
    if self:isDestroyed() then return end
    self._placeholder = value
    if self:isEmpty() then
        I.UIToolkit.queueUpdate(self.element)
        self._editProps.text = self:getPlaceholder() or ''
        self._editProps.textColor = self:_textColor(true)
    end
end

---@param width number
function TextEdit:setSize(width)
    if self:isDestroyed() then return end
    local w, h = width or 200, self._textSize
    w = w - 2 * PAD
    self._editProps.size = v2(w, h)
    local deep = false
    if self._btnProps then
        deep = true
        self._btnProps.size = v2(h, h)
        self._btnProps.position = v2(w, 0)
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
