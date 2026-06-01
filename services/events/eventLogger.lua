local logger = mwse.Logger.new()

--- ENUMS
local EVENTS = require("tauer.modern-lockpicking.services.events.enums.EVENTS")
local DIRECTION = require("tauer.modern-lockpicking.services.lockpicking.enums.ROTATION_DIRECTION")
---

---@class eventLogger : initializedService
local this = {}

---@public
---@return boolean, string|nil
function this.initialize()
    event.register(EVENTS.lockpickingStart, this.onLockpickingStart)
    event.register(EVENTS.lockpickingStarted, this.onLockpickingStarted)
    event.register(EVENTS.lockpickingEnd, this.onLockpickingEnd)
    event.register(EVENTS.lockpickingEnded, this.onLockpickingEnded)
    event.register(EVENTS.rotationStarted, this.onRotationStarted)
    event.register(EVENTS.rotationEnded, this.onRotationEnded)
    event.register(EVENTS.cylinderBlocked, this.onCylinderBlocked)
    event.register(EVENTS.pickCycled, this.onPickCycled)
    event.register(EVENTS.pickBroken, this.onPickBroken)
    return true, nil
end

---@private
---@param _ lockpickingStartEventData
function this.onLockpickingStart(_)
    logger:debug("Lockpicking starting")
end

---@private
---@param _ lockpickingStartedEventData
function this.onLockpickingStarted(_)
    logger:debug("Lockpicking started")
end

---@private
---@param _ lockpickingEndEventData
function this.onLockpickingEnd(_)
    logger:debug("Lockpicking ending")
end

---@private
---@param _ lockpickingEndedEventData
function this.onLockpickingEnded(_)
    logger:debug("Lockpicking ended")
end

---@private
---@param e rotationEventData
function this.onRotationStarted(e)
    logger:debug("Rotation %s started", e.direction == DIRECTION.clockwise and "clockwise" or "counter-clockwise")
end

---@private
---@param _ rotationEventData
function this.onRotationEnded(_)
    logger:debug("Rotation ended")
end

---@private
function this.onCylinderBlocked()
    logger:debug("Cylinder blocked")
end

---@private
---@param e pickCycledEventData
function this.onPickCycled(e)
    logger:debug("Cycled from %s to %s", e.previousPick.item.object.name, e.pick.item.object.name)
end

---@private
---@param e pickBrokenEventData
function this.onPickBroken(e)
    logger:debug("%s broke", e.pick.item.object.name)
end

return this
