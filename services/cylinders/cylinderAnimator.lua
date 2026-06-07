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
this.rotationBuffer = tes3matrix33.new()

---@private
---@type enums
this.enums = nil

---@private
---@type eventRegistrar
this.eventRegistrar = nil

---@private
---@type eventHandlerGroups
this.eventHandlers = {
	lifetime = {},
	session = {}
}

---@public
---@param services serviceCollection
---@return boolean,string|nil
function this.initialize(services)
	this.eventRegistrar = services.eventRegistrar
	this.enums = services.enums

	local events = services.enums.events

	this.eventHandlers = {
		lifetime = {
			[events.lockpickingStart] = this.onLockpickingStart,
			[events.lockpickingEnd] = this.onLockpickingEnd,
			[events.lockpickingEnded] = this.onLockpickingEnded,
			[events.rotationStarted] = this.onRotationStarted,
			[events.rotationEnded] = this.onRotationEnded,
			[events.cylinderBlocked] = this.onCylinderBlocked,
			[events.optionsMenuOpened] = this.onOptionsMenuOpened,
			[events.optionsMenuClosed] = this.onOptionsMenuClosed,
		},
		session = {
			[tes3.event.enterFrame] = this.onEnterFrame
		}
	}

	this.eventRegistrar.register(this.eventHandlers.lifetime)

	return true, nil
end

---@public
function this.uninitialize()
	this.eventRegistrar.unregister(this.eventHandlers.lifetime)
	this.enums = nil
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
	this.eventRegistrar.register(this.eventHandlers.session)
end

---@private
function this.disable()
	this.eventRegistrar.unregister(this.eventHandlers.session)
end

---@private
---@param e enterFrameEventData
function this.onEnterFrame(e)
	if this.paused or this.blocked then
		return
	end

	local constants = this.enums.constants.cylinder

	if not this.rotationDirection then
		local rotation = this.cylinder.rotation:toEulerXYZ().y
		if math.isclose(rotation, 0, 0.04) then
			return
		end
		local multiplier = rotation <= 0 and 1 or -1
		this.updatePhase(multiplier, constants.resetSpeed, e.delta)
	else
		local multiplier = this.rotationDirection == this.enums.rotationDirections.counterClockwise and 1 or -1
		this.updatePhase(multiplier, constants.rotateSpeed, e.delta)
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
