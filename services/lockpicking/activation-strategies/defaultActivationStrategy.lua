--- ENUMS
local EVENTS = require("tauer.modern-lockpicking.services.events.enums.EVENTS")
local ACTIVATION_STRATEGY_NAMES = require(
    "tauer.modern-lockpicking.services.lockpicking.activation-strategies.enums.ACTIVATION_STRATEGY_NAMES")
---

---@class defaultActivationStrategy : activationStrategy
local this = {}

---@public
---@type string
this.name = ACTIVATION_STRATEGY_NAMES.default

---@public
function this.enable()
    if not event.isRegistered(tes3.event.activate, this.onActivate) then
        event.register(tes3.event.activate, this.onActivate)
    end
end

---@public
function this.disable()
    if event.isRegistered(tes3.event.activate, this.onActivate) then
        event.unregister(tes3.event.activate, this.onActivate)
    end
end

---@private
---@param e activateEventData
function this.onActivate(e)
    if e.activator ~= tes3.player then
        return
    end

    local activator = this.validateActivator(e.target)
    if not activator then
        return
    end

    if not this.isLocked(activator) then
        return
    end

    ---@type lockpickingActivatedEventData
    local eventData = {
        activator = activator
    }
    event.trigger(EVENTS.lockpickingActivated, eventData)
end

---@private
---@param target tes3reference
---@return tes3reference|nil
function this.validateActivator(target)
    local type = target.object.objectType
    if type == tes3.objectType.container or type == tes3.objectType.door then
        return target
    end
    return nil
end

---@private
---@param activator tes3reference
---@return boolean
function this.isLocked(activator)
    return tes3.getLocked({
        reference = activator,
    })
end

return this
