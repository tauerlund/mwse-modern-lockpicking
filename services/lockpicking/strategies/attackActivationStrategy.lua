--- ENUMS
local EVENTS = require("tauer.modern-lockpicking.services.events.enums.EVENTS")
local ACTIVATION_STRATEGY_NAMES = require(
    "tauer.modern-lockpicking.services.lockpicking.strategies.enums.ACTIVATION_STRATEGY_NAMES")
---

---@class attackActivationStrategy : activationStrategy
local this = {}

---@public
---@type string
this.name = ACTIVATION_STRATEGY_NAMES.attack

---@public
function this.enable()
    if not event.isRegistered(tes3.event.lockPick, this.onLockPick) then
        event.register(tes3.event.lockPick, this.onLockPick)
    end
end

---@public
function this.disable()
    if event.isRegistered(tes3.event.lockPick, this.onLockPick) then
        event.unregister(tes3.event.lockPick, this.onLockPick)
    end
end

---@private
---@param e lockPickEventData
function this.onLockPick(e)
    if not e.lockPresent then
        return
    end

    e.block = true

    ---@type lockpickingActivatedEventData
    local eventData = {
        activator = e.reference --[[@as tes3containerInstance|tes3door]]
    }
    event.trigger(EVENTS.lockpickingActivated, eventData)
end

return this
