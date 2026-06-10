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

---@private
---@type eventRegistrar
this.eventRegistrar = nil

---@private
---@type eventHandlers
this.eventHandlers = nil

---@public
---@param services serviceCollection
function this.initialize(services)
    this.name = services.enums.activationStrategyNames.attack
    this.enums = services.enums
    this.timerManager = services.timerManager
    this.eventRegistrar = services.eventRegistrar

    this.eventHandlers = {
        [tes3.event.lockPick] = this.onLockPick,
    }
end

---@public
function this.enable()
    this.eventRegistrar.register(this.eventHandlers)
end

---@public
function this.disable()
    this.eventRegistrar.unregister(this.eventHandlers)
end

---@private
---@param e lockPickEventData
function this.onLockPick(e)
    if not e.lockPresent then
        return
    end

    if e.chance <= 0 then
        return
    end

    e.block = true

    local events = this.enums.events

    this.timerManager.start({
        callback = this.onStartTimerFinished,
        durationInSeconds = 0.5,
        ---@class attackActivationStrategy.startTimer.data
        data = {
            activator = e.reference
        },
        cancelOn = { events.lockpickingEnded, events.lockpickingInterrupted },
        pauseOn = { events.optionsMenuOpened },
        resumeOn = { events.optionsMenuClosed },
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
