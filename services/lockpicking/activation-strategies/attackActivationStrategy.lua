local timerManager = require("tauer.modern-lockpicking.services.timers.timerManager")

--- ENUMS
local EVENTS = require("tauer.modern-lockpicking.services.events.enums.EVENTS")
local ACTIVATION_STRATEGY_NAMES = require(
    "tauer.modern-lockpicking.services.lockpicking.activation-strategies.enums.ACTIVATION_STRATEGY_NAMES")
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

    timerManager.start({
        finishedCallback = this.onStartTimerFinished,
        durationInSeconds = 0.5,
        ---@class attackActivationStrategy.startTimer.data
        data = {
            activator = e.reference
        }
    })
end

---@private
---@param data attackActivationStrategy.startTimer.data
function this.onStartTimerFinished(data)
    ---@type lockpickingActivatedEventData
    local eventData = {
        activator = data.activator
    }
    event.trigger(EVENTS.lockpickingActivated, eventData)
end

return this
