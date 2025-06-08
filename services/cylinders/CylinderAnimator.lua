--- ENUMS
local EVENTS = require("tauer.modern-lockpicking.shared.enums.events")
local DIRECTION = require("tauer.modern-lockpicking.shared.enums.rotationDirection")
local CONSTANTS = require("tauer.modern-lockpicking.services.cylinders.enums.constants")
---

---@class CylinderAnimator
local this = {}

---@private
---@type cylinder
this.cylinder = nil

---@private
---@type number
this.phase = 0

---@private
---@type DIRECTION|nil
this.rotationDirection = nil

---@public
---@param cylinder cylinder
function this.Start(cylinder)
	this.cylinder = cylinder
	this.registerEvents()
end

---@private
---@param e enterFrameEventData
function this.onEnterFrame(e)
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

	this.rotateCylinder()
end

---@private
---@param multiplier number
---@param speed number
---@param delta number
function this.updatePhase(multiplier, speed, delta)
	this.phase = this.phase + (multiplier * speed * delta)
end

---@private
function this.rotateCylinder()
	local cylinder = this.cylinder

	local rotation = cylinder.rotation:copy()
	rotation:toRotationY(this.phase)

	cylinder.rotation = rotation
	cylinder:update()
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
---@param _ lockpickingEndedEventData
function this.onLockpickingEnded(_)
	this.phase = 0
	this.rotationDirection = nil
	this.unregisterEvents()
end

---@private
function this.registerEvents()
	event.register(tes3.event.enterFrame, this.onEnterFrame)
	event.register(EVENTS.rotationStarted, this.onRotationStarted)
	event.register(EVENTS.rotationEnded, this.onRotationEnded)
	event.register(EVENTS.lockpickingEnded, this.onLockpickingEnded, { doOnce = true })
end

---@private
function this.unregisterEvents()
	if event.isRegistered(tes3.event.enterFrame, this.onEnterFrame) then
		event.unregister(tes3.event.enterFrame, this.onEnterFrame)
	end
	if event.isRegistered(EVENTS.rotationStarted, this.onRotationStarted) then
		event.unregister(EVENTS.rotationStarted, this.onRotationStarted)
	end
	if event.isRegistered(EVENTS.rotationEnded, this.onRotationEnded) then
		event.unregister(EVENTS.rotationEnded, this.onRotationEnded)
	end
end

return this
