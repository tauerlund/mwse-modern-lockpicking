---@class cylinderAnimator : initializedService
local this = {}

---@private
---@type lockpickingSession|nil
this.session = nil

---@private
---@type lock|nil
this.lock = nil

---@private
---@type cylinder
this.cylinder = nil

---@private
---@type number
this.phase = 0

---@private
this.ending = false

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
---@param e lockpickingStartEventData
function this.onLockpickingStart(e)
	this.session = e.session
	this.lock = e.session.lock
	this.cylinder = e.session.lock.cylinder
	this.lock.cylinderAngle = 0
	this.enable()
end

---@private
---@param _ lockpickingEndEventData
function this.onLockpickingEnd(_)
	this.ending = true
end

---@private
---@param _ lockpickingEndedEventData
function this.onLockpickingEnded(_)
	this.phase = 0
	this.ending = false
	this.session = nil
	this.lock = nil
	this.disable()
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
	local lock = this.lock
	if not lock then
		return
	end

	if this.ending or lock.blocked or (this.session and this.session.paused) then
		return
	end

	local constants = this.enums.constants.cylinder

	if not (lock.rotatingClockwise or lock.rotatingCounterclockwise) then
		if this.phase == 0 then
			return
		end
		this.resetPhase(constants.resetSpeed, e.delta)
	else
		local multiplier = lock.rotatingCounterclockwise and 1 or -1
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
---@param speed number
---@param delta number
function this.resetPhase(speed, delta)
	local step = speed * delta
	if step >= math.abs(this.phase) then
		this.phase = 0
	else
		local multiplier = this.phase <= 0 and 1 or -1
		this.phase = this.phase + (multiplier * step)
	end
end

---@private
function this.rotate()
	local cylinder = this.cylinder

	this.rotationBuffer:toRotationY(this.phase)

	cylinder.rotation = this.rotationBuffer
	cylinder:update()
	this.lock.cylinderAngle = this.phase
end

return this
