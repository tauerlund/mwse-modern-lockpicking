---@class cylinderController : initializedService
local this = {}

---@private
---@type lockpickingSession|nil
this.session = nil

---@private
---@type number
this.maxAngle = 0

---@private
---@type tes3.scanCode
this.currentDirectionKey = nil

---@private
---@type { [tes3.scanCode]: rotationDirections }
this.rotationKeyCodeToRotationDirectionMap = nil

---@private
---@type settings
this.settings = nil

---@private
---@type enums
this.enums = nil

---@private
---@type formulas
this.formulas = nil

---@private
---@type eventHandlerGroups
this.eventHandlers = {
	lifetime = {},
	session = {}
}

---@private
---@type eventRegistrar
this.eventRegistrar = nil

---@public
---@param services serviceCollection
---@return boolean,string|nil
function this.initialize(services)
	this.eventRegistrar = services.eventRegistrar
	this.settings = services.settings
	this.enums = services.enums
	this.formulas = services.formulas

	local events = services.enums.events

	this.eventHandlers = {
		lifetime = {
			[events.settingsUpdated] = this.onSettingsUpdated,
			[events.lockpickingStarted] = this.onLockpickingStarted,
			[events.lockpickingEnd] = this.onLockpickingEnd,
		},
		session = {
			[tes3.event.enterFrame] = this.onEnterFrame,
			[tes3.event.keyDown] = this.onKeyDown,
			[tes3.event.keyUp] = this.onKeyUp
		}
	}

	this.eventRegistrar.register(this.eventHandlers.lifetime)

	this.applyKeybinds()

	return true, nil
end

---@public
function this.uninitialize()
	this.eventRegistrar.unregister(this.eventHandlers.lifetime)
end

---@private
function this.onSettingsUpdated()
	this.applyKeybinds()
end

---@private
---@param e lockpickingStartedEventData
function this.onLockpickingStarted(e)
	this.session = e.session
	this.enable()
end

---@private
---@param _ lockpickingEndEventData
function this.onLockpickingEnd(_)
	this.disable()
	this.session = nil
end

---@private
function this.enable()
	this.eventRegistrar.register(this.eventHandlers.session)
end

---@private
function this.disable()
	this.eventRegistrar.unregister(this.eventHandlers.session)

	this.currentDirectionKey = nil
	if this.session then
		this.session.lock.rotatingCounterclockwise = false
		this.session.lock.rotatingClockwise = false
		this.session.lock.blocked = false
	end
	this.maxAngle = 0
end

---@private
---@param _ enterFrameEventData
function this.onEnterFrame(_)
	local lock = this.session.lock
	if this.session.paused or lock.blocked or not (lock.rotatingCounterclockwise or lock.rotatingClockwise) then
		return
	end

	if this.session.pick.animating then
		return
	end

	local constants = this.enums.constants.cylinder
	local events = this.enums.events

	local rotation = lock.cylinderAngle

	if rotation <= constants.targetRotationLeft or rotation >= constants.targetRotationRight then
		event.trigger(events.cylinderTargetReached)
		return
	end

	if this.maxAngle == 0 or math.abs(rotation) >= this.maxAngle then
		lock.rotatingCounterclockwise = false
		lock.rotatingClockwise = false
		lock.blocked = true
		event.trigger(events.cylinderBlocked)
	end
end

---@private
---@return number
function this.computeMaxAngle()
	local pick = this.session and this.session.pick
	local sweetSpot = this.session and this.session.sweetSpot
	if not pick or not sweetSpot then
		return 0
	end

	local pickAngle = pick.helper.rotation:toEulerXYZ().y
	return this.formulas.computeMaxAngle(pickAngle, sweetSpot, this.enums.constants.cylinder.targetRotationRight)
end

---@private
---@param e keyDownEventData
function this.onKeyDown(e)
	if this.rotationKeyCodeToRotationDirectionMap[e.keyCode] then
		this.onRotationKeyDown(e)
	end
end

---@private
---@param e keyUpEventData
function this.onKeyUp(e)
	if this.rotationKeyCodeToRotationDirectionMap[e.keyCode] then
		this.onRotationKeyUp(e)
	end
end

---@private
---@param e keyDownEventData
function this.onRotationKeyDown(e)
	local lock = this.session.lock
	if lock.rotatingCounterclockwise or lock.rotatingClockwise or lock.blocked then
		return
	end

	if this.session.pick.animating then
		return
	end

	this.currentDirectionKey = e.keyCode
	this.maxAngle = this.computeMaxAngle()

	local direction = this.rotationKeyCodeToRotationDirectionMap[e.keyCode]
	lock.rotatingCounterclockwise = direction == this.enums.rotationDirections.counterClockwise
	lock.rotatingClockwise = direction == this.enums.rotationDirections.clockwise

	---@type rotationEventData
	local eventData = { direction = direction }
	event.trigger(this.enums.events.rotationStarted, eventData)
end

---@private
---@param e keyUpEventData
function this.onRotationKeyUp(e)
	if this.currentDirectionKey and this.currentDirectionKey ~= e.keyCode then
		return
	end

	local lock = this.session.lock
	lock.blocked = false
	lock.rotatingCounterclockwise = false
	lock.rotatingClockwise = false
	this.currentDirectionKey = nil

	---@type rotationEventData
	local eventData = {
		direction = this.rotationKeyCodeToRotationDirectionMap[e.keyCode],
	}
	event.trigger(this.enums.events.rotationEnded, eventData)
end

---@private
function this.applyKeybinds()
	local keyBinds = this.settings.keyBinds
	local rotationDirections = this.enums.rotationDirections

	this.rotationKeyCodeToRotationDirectionMap = {
		[keyBinds.rotateLockClockwise.keyCode] = rotationDirections.clockwise,
		[keyBinds.rotateLockCounterclockwise.keyCode] = rotationDirections.counterClockwise,
	}
end

return this
