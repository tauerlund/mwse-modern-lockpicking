---@class cylinderAnimator : initializedService
local this = {}

---@private
---@type cylinder
this.cylinder = nil

---@private
---@type number
this.phase = 0

---@private
---@type rotationDirections|nil
this.rotationDirection = nil

---@private
this.blocked = false

---@private
this.constants = {
	rotateSpeed = 1.5,
	resetSpeed = 1.8,
}

---@private
this.rotationBuffer = tes3matrix33.new()

---@private
---@type enums
this.enums = nil

---@public
---@param services serviceCollection
---@return boolean,string|nil
function this.initialize(services)
	this.enums = services.enums

	local events = services.enums.events

	event.register(events.lockpickingStart, this.onLockpickingStart)
	event.register(events.lockpickingEnd, this.onLockpickingEnd)
	event.register(events.lockpickingEnded, this.onLockpickingEnded)
	event.register(events.rotationStarted, this.onRotationStarted)
	event.register(events.rotationEnded, this.onRotationEnded)
	event.register(events.cylinderBlocked, this.onCylinderBlocked)
	event.register(events.optionsMenuOpened, this.onOptionsMenuOpened)
	event.register(events.optionsMenuClosed, this.onOptionsMenuClosed)
	return true, nil
end

---@private
function this.onOptionsMenuOpened()
	this.paused = true
end

---@private
function this.onOptionsMenuClosed()
	this.paused = false
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
	this.blocked = false
end

---@private
function this.onCylinderBlocked()
	this.blocked = true
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
	if this.paused or this.blocked then
		return
	end

	if not this.rotationDirection then
		local rotation = this.cylinder.rotation:toEulerXYZ().y
		if math.isclose(rotation, 0, 0.04) then
			return
		end
		local multiplier = rotation <= 0 and 1 or -1
		this.updatePhase(multiplier, this.constants.resetSpeed, e.delta)
	else
		local multiplier = this.rotationDirection == this.enums.rotationDirections.counterClockwise and 1 or -1
		this.updatePhase(multiplier, this.constants.rotateSpeed, e.delta)
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

	this.rotationBuffer:toRotationY(this.phase)
	cylinder.rotation = this.rotationBuffer
	cylinder:update()
end

return this
