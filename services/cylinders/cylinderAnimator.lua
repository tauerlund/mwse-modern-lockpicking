--- ENUMS
local EVENTS = require("tauer.modern-lockpicking.services.events.enums.EVENTS")
local DIRECTION = require("tauer.modern-lockpicking.services.lockpicking.enums.ROTATION_DIRECTION")
local CONSTANTS = require("tauer.modern-lockpicking.services.cylinders.enums.CONSTANTS")
---

---@class cylinderAnimator : initializedService
local this = {}

---@private
---@type cylinder
this.cylinder = nil

---@private
---@type number
this.phase = 0

---@private
---@type ROTATION_DIRECTION|nil
this.rotationDirection = nil

---@private
---@type boolean
this.blocked = false

---@public
---@return boolean,string|nil
function this.initialize()
	event.register(EVENTS.lockpickingStart, this.onLockpickingStart)
	event.register(EVENTS.lockpickingEnd, this.onLockpickingEnd)
	event.register(EVENTS.lockpickingEnded, this.onLockpickingEnded)
	event.register(EVENTS.rotationStarted, this.onRotationStarted)
	event.register(EVENTS.rotationEnded, this.onRotationEnded)
	return true, nil
end

---@private
---@param e lockpickingStartEventData
function this.onLockpickingStart(e)
	this.cylinder = e.session.lock.cylinder
	this.enable()
end

---@private
---@param _ lockpickingEndEventData
function this.onLockpickingEnd(_)
	this.blocked = true
end

---@private
---@param _ lockpickingEndedEventData
function this.onLockpickingEnded(_)
	this.phase = 0
	this.blocked = false
	this.rotationDirection = nil
	this.disable()
end

---@private
---@param e rotationEventData
function this.onRotationStarted(e)
	this.rotationDirection = e.direction
end

---@private
function this.onRotationEnded()
	this.rotationDirection = nil
end

---@private
function this.enable()
	if not event.isRegistered(tes3.event.enterFrame, this.onEnterFrame) then
		event.register(tes3.event.enterFrame, this.onEnterFrame)
	end
end

---@private
function this.disable()
	if event.isRegistered(tes3.event.enterFrame, this.onEnterFrame) then
		event.unregister(tes3.event.enterFrame, this.onEnterFrame)
	end
end

---@private
---@param e enterFrameEventData
function this.onEnterFrame(e)
	if this.blocked then
		return
	end

	if not this.rotationDirection then
		local rotation = this.cylinder.rotation:toEulerXYZ().y
		if math.isclose(rotation, 0, 0.04) then
			return
		end
		local multiplier = rotation <= 0 and 1 or -1
		this.updatePhase(multiplier, CONSTANTS.resetSpeed, e.delta)
	else
		local multiplier = this.rotationDirection == DIRECTION.counterClockwise and 1 or -1
		this.updatePhase(multiplier, CONSTANTS.rotateSpeed, e.delta)
	end

	this.rotate()
end

---@private
---@param multiplier number
---@param speed number
---@param delta number
function this.updatePhase(multiplier, speed, delta)
	this.phase = this.phase + (multiplier * speed * delta)
end

---@private
function this.rotate()
	local cylinder = this.cylinder

	local rotation = cylinder.rotation:copy()
	rotation:toRotationY(this.phase)

	cylinder.rotation = rotation
	cylinder:update()
end

return this
