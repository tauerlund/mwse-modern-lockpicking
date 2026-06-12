---@class eventLogger : initializedService
local this = {}

---@private
this.logger = mwse.Logger.new()

---@private
---@type enums
this.enums = nil

---@private
---@type eventRegistrar
this.eventRegistrar = nil

---@private
---@type eventHandlers
this.eventHandlers = nil

---@public
---@param services serviceCollection
---@return boolean, string|nil
function this.initialize(services)
    this.enums = services.enums
    this.eventRegistrar = services.eventRegistrar

    local events = services.enums.events

    this.eventHandlers = {
        [events.lockpickingStart] = this.onLockpickingStart,
        [events.lockpickingStarted] = this.onLockpickingStarted,
        [events.lockpickingEnd] = this.onLockpickingEnd,
        [events.lockpickingEnded] = this.onLockpickingEnded,
        [events.rotationStarted] = this.onRotationStarted,
        [events.rotationEnded] = this.onRotationEnded,
        [events.cylinderBlocked] = this.onCylinderBlocked,
        [events.pickCycled] = this.onPickCycled,
        [events.pickBroken] = this.onPickBroken,
    }

    this.eventRegistrar.register(this.eventHandlers)
    return true, nil
end

---@public
function this.uninitialize()
    this.eventRegistrar.unregister(this.eventHandlers)
end

---@private
---@param _ lockpickingStartEventData
function this.onLockpickingStart(_)
    this.logger:debug("Lockpicking starting")
end

---@private
---@param _ lockpickingStartedEventData
function this.onLockpickingStarted(_)
    this.logger:debug("Lockpicking started")
end

---@private
---@param _ lockpickingEndEventData
function this.onLockpickingEnd(_)
    this.logger:debug("Lockpicking ending")
end

---@private
---@param _ lockpickingEndedEventData
function this.onLockpickingEnded(_)
    this.logger:debug("Lockpicking ended")
end

---@private
---@param e rotationEventData
function this.onRotationStarted(e)
    local direction = e.direction == this.enums.rotationDirections.clockwise and "clockwise" or "counter-clockwise"
    this.logger:debug("Rotation %s started", direction)
end

---@private
---@param _ rotationEventData
function this.onRotationEnded(_)
    this.logger:debug("Rotation ended")
end

---@private
function this.onCylinderBlocked()
    this.logger:debug("Cylinder blocked")
end

---@private
---@param e pickCycledEventData
function this.onPickCycled(e)
    local previous = e.previousPick.item.object
    local next = e.pick.item.object

    local from = previous and previous:isValid() and previous.name or "?"
    local to = next and next:isValid() and next.name or "?"

    this.logger:debug("Cycled from %s to %s", from, to)
end

---@private
---@param e pickBrokenEventData
function this.onPickBroken(e)
    this.logger:debug("%s broke", e.item.name)
end

return this
