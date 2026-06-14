---@class playerController : initializedService
local this = {}

---@private
---@type enums
this.enums = nil

---@private
---@type eventRegistrar
this.eventRegistrar = nil

---@private
---@type eventHandlerGroups
this.eventHandlers = {
    lifetime = {},
    session = {}
}

---@private
---@type { [tes3.keybind]: boolean }
this.movementKeybinds = nil

---@public
---@param services serviceCollection
---@return boolean, string|nil
function this.initialize(services)
    this.enums = services.enums
    this.eventRegistrar = services.eventRegistrar

    local events = this.enums.events

    this.eventHandlers = {
        lifetime = {
            [events.lockpickingEnded] = this.onLockpickingEnded,
        },
        session = {
            [tes3.event.keybindTested] = this.onKeybindTested,
            [tes3.event.keyUp] = this.onKeyUp,
        }
    }

    this.movementKeybinds = {
        [tes3.keybind.forward] = true,
        [tes3.keybind.back] = true,
        [tes3.keybind.left] = true,
        [tes3.keybind.right] = true,
    }

    this.eventRegistrar.register(this.eventHandlers.lifetime)

    return true, nil
end

---@public
function this.uninitialize()
    this.eventRegistrar.unregister(this.eventHandlers.lifetime)
end

---@public
---@return playerData
function this.data()
    if not tes3.player then
        return {}
    end

    if not tes3.player.data.modernLockpicking then
        tes3.player.data.modernLockpicking = {}
    end

    return tes3.player.data.modernLockpicking
end

---@private
---@param _ lockpickingEndedEventData
function this.onLockpickingEnded(_)
    if not this.movementKeyDown() then
        return
    end

    this.enable()
end

---@private
---@param e keybindTestedEventData
function this.onKeybindTested(e)
    if this.movementKeybinds[e.keybind] then
        e.result = false
    end
end

---@private
---@param _ keyUpEventData
function this.onKeyUp(_)
    if this.movementKeyDown() then
        return
    end

    this.disable()
end

---@private
function this.enable()
    this.eventRegistrar.register(this.eventHandlers.session)
end

---@private
function this.disable()
    this.eventRegistrar.unregister(this.eventHandlers.session)
end

---@private
---@return boolean
function this.movementKeyDown()
    local inputController = tes3.worldController.inputController
    for keybind in pairs(this.movementKeybinds) do
        local binding = tes3.getInputBinding(keybind)
        if binding and inputController:isKeyDown(binding.code) then
            return true
        end
    end

    return false
end

return this
