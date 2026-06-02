---@class attackActivationStrategy : activationStrategy
local this = {}

---@public
---@type string
this.name = nil

---@private
---@type enums
this.enums = nil

---@private
---@type timerManager
this.timerManager = nil

---@public
---@param services serviceCollection
function this.initialize(services)
    this.name = services.enums.activationStrategyNames.attack
    this.enums = services.enums
    this.timerManager = services.timerManager
end

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

    this.timerManager.start({
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
    event.trigger(this.enums.events.lockpickingActivated, eventData)
end

return this
