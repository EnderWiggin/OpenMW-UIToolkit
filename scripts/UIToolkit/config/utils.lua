---@omw-context none

local D      = require 'scripts.UIToolkit.config.defaults'
local Device = D.Device


local M = {}

---@param device number
---@param code number
---@param bind UIToolkit.SettingRenderer.CustomBind[]
---@return boolean
function M.inputMatches(device, code, bind)
    local t = type(bind)
    if t ~= 'table' and t ~= 'userdata' then return false end
    for i = 1, #bind do
        local tmp = bind[i]
        if tmp.device == device and tmp.code == code then return true end
    end
    return false
end

---@param key number
---@param bind UIToolkit.SettingRenderer.CustomBind[]
function M.keyboardMatches(key, bind)
    return M.inputMatches(Device.Keyboard, key, bind)
end

---@param button number
---@param bind UIToolkit.SettingRenderer.CustomBind[]
function M.controllerMatches(button, bind)
    return M.inputMatches(Device.Controller, button, bind)
end

---@param device number
---@param code number
---@param binds table<string, UIToolkit.SettingRenderer.CustomBind[]>
---@return string|nil
function M.findMatching(device, code, binds)
    local t = type(binds)
    if t ~= 'table' and t ~= 'userdata' then return nil end

    for k, v in pairs(binds) do
        if M.inputMatches(device, code, v) then return k end
    end
    return nil
end

---@param key number
---@param binds table<string, UIToolkit.SettingRenderer.CustomBind[]>
---@return string|nil
function M.findMatchingKeyboard(key, binds)
    return M.findMatching(Device.Keyboard, key, binds)
end

---@param button number
---@param binds table<string, UIToolkit.SettingRenderer.CustomBind[]>
---@return string|nil
function M.findMatchingController(button, binds)
    return M.findMatching(Device.Controller, button, binds)
end

---@param bind UIToolkit.SettingRenderer.CustomBind[]
---@return UIToolkit.Controller.Input[]
function M.getControllerInputs(bind)
    ---@type UIToolkit.Controller.Input[]
    local inputs = {}
    if not bind then return inputs end
    for i = 1, #bind do
        local tmp = bind[i]
        if tmp.device == Device.Controller and tmp.code then
            inputs[#inputs + 1] = { id = tmp.code }
        end
    end
    return inputs
end

return M
