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
    }

    this.eventRegistrar.register(this.eventHandlers)

    return true, nil
end

---@public
function this.uninitialize()
    this.eventRegistrar.unregister(this.eventHandlers)
end

---@private
---@param _ loadEventData
function this.onLoad(_)
    event.trigger(this.enums.events.lockpickingInterrupted)
end

return this
