---@class eventLogger : initializedService
local this = {}

---@private
---@type mwseLogger
this.logger = mwse.Logger.new()

---@private
---@type enums
this.enums = nil

---@public
---@param services serviceCollection
---@return boolean, string|nil
function this.initialize(services)
    this.enums = services.enums

    local events = services.enums.events

    event.register(events.lockpickingStart, this.onLockpickingStart)
    event.register(events.lockpickingStarted, this.onLockpickingStarted)
    event.register(events.lockpickingEnd, this.onLockpickingEnd)
    event.register(events.lockpickingEnded, this.onLockpickingEnded)
    event.register(events.rotationStarted, this.onRotationStarted)
    event.register(events.rotationEnded, this.onRotationEnded)
    event.register(events.cylinderBlocked, this.onCylinderBlocked)
    event.register(events.pickCycled, this.onPickCycled)
    event.register(events.pickBroken, this.onPickBroken)
    return true, nil
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
    this.logger:debug("Cycled from %s to %s", e.previousPick.item.object.name, e.pick.item.object.name)
end

---@private
---@param e pickBrokenEventData
function this.onPickBroken(e)
    this.logger:debug("%s broke", e.pick.item.object.name)
end

return this
