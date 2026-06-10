---@class lockpickingCircuitBreaker : initializedService
local this = {}

---@private
---@type mwseLogger
this.logger = mwse.Logger.new()

---@private
---@type eventHandlers
this.eventHandlers = nil

---@private
---@type enums
this.enums = nil

---@private
---@type eventRegistrar
this.eventRegistrar = nil

---@public
---@param services serviceCollection
---@return boolean,string|nil
function this.initialize(services)
    this.enums = services.enums
    this.eventRegistrar = services.eventRegistrar

    this.eventHandlers = {
        [tes3.event.load] = this.onLoad,
        [tes3.event.cellChanged] = this.onCellChanged,
        [tes3.event.save] = this.onSave
    }

    this.eventRegistrar.register(this.eventHandlers)

    return true, nil
end

---@public
function this.uninitialize()
    this.eventRegistrar.unregister(this.eventHandlers)
end

---@private
---@param _ saveEventData
function this.onSave(_)
    this.triggerInterruptionEvent("the game was saved")
end

---@private
---@param _ cellChangedEventData
function this.onCellChanged(_)
    this.triggerInterruptionEvent("the player changed cells")
end

---@private
---@param _ loadEventData
function this.onLoad(_)
    this.triggerInterruptionEvent("a save game was loaded")
end

---@private
---@param reason string
function this.triggerInterruptionEvent(reason)
    ---@type lockpickingInterruptedEventData
    local eventData = {
        reason = reason
    }
    event.trigger(this.enums.events.lockpickingInterrupted, eventData)
end

return this
