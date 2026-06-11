---@class cylinderController : initializedService
local this = {}

---@private
---@type lock|nil
this.lock = nil

---@private
---@type cylinder
this.cylinder = nil

---@private
---@type niNode
this.pickHelper = nil

---@private
---@type number
this.sweetSpotCenter = nil

---@private
---@type number
this.sweetSpotRadius = nil

---@private
---@type number
this.gradientWidth = nil

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
---@type boolean
this.paused = false

---@private
---@type settings
this.settings = nil

---@private
---@type enums
this.enums = nil

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

	local events = services.enums.events

	this.eventHandlers = {
		lifetime = {
			[events.settingsUpdated] = this.onSettingsUpdated,
			[events.lockpickingStarted] = this.onLockpickingStarted,
			[events.lockpickingEnd] = this.onLockpickingEnd,
			[events.sweetSpotUpdated] = this.onSweetSpotUpdated,
			[events.pickCycled] = this.onPickCycled,
			[events.optionsMenuOpened] = this.onOptionsMenuOpened,
			[events.optionsMenuClosed] = this.onOptionsMenuClosed,
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
function this.onOptionsMenuOpened()
	this.paused = true
end

---@private
function this.onOptionsMenuClosed()
	this.paused = false
end

---@private
function this.onSettingsUpdated()
	this.applyKeybinds()
end

---@private
---@param e lockpickingStartedEventData
function this.onLockpickingStarted(e)
	this.lock = e.session.lock
	this.cylinder = e.session.lock.cylinder
	this.pickHelper = e.session.pick.helper
	this.enable()
end

---@private
---@param e sweetSpotUpdatedEventData
function this.onSweetSpotUpdated(e)
	this.sweetSpotCenter = e.center
	this.sweetSpotRadius = e.radius
	this.gradientWidth = e.gradientWidth
end

---@private
---@param e pickCycledEventData
function this.onPickCycled(e)
	this.pickHelper = e.pick.helper
end

---@private
---@param _ lockpickingEndEventData
function this.onLockpickingEnd(_)
	this.disable()
	this.lock = nil
	this.cylinder = nil
	this.pickHelper = nil
	this.sweetSpotCenter = nil
	this.sweetSpotRadius = nil
	this.gradientWidth = nil
end

---@private
function this.enable()
	this.eventRegistrar.register(this.eventHandlers.session)
end

---@private
function this.disable()
	this.eventRegistrar.unregister(this.eventHandlers.session)

	this.currentDirectionKey = nil
	if this.lock then
		this.lock.rotatingCounterclockwise = false
		this.lock.rotatingClockwise = false
		this.lock.blocked = false
	end
	this.maxAngle = 0
end

---@private
---@param _ enterFrameEventData
function this.onEnterFrame(_)
	if this.paused or this.lock.blocked or not (this.lock.rotatingCounterclockwise or this.lock.rotatingClockwise) then
		return
	end

	local constants = this.enums.constants.cylinder
	local events = this.enums.events

	local rotation = this.lock.cylinderAngle

	if rotation <= constants.targetRotationLeft or rotation >= constants.targetRotationRight then
		event.trigger(events.cylinderTargetReached)
		return
	end

	if this.maxAngle == 0 or math.abs(rotation) >= this.maxAngle then
		this.lock.rotatingCounterclockwise = false
		this.lock.rotatingClockwise = false
		this.lock.blocked = true
		event.trigger(events.cylinderBlocked)
	end
end

---@private
---@return number
function this.computeMaxAngle()
	if not this.pickHelper or not this.sweetSpotCenter or not this.sweetSpotRadius then
		return 0
	end

	local pickAngle = this.pickHelper.rotation:toEulerXYZ().y
	local distance = math.abs(pickAngle - this.sweetSpotCenter)
	if distance <= this.sweetSpotRadius then
		return math.huge
	end

	if not this.gradientWidth or this.gradientWidth == 0 then
		return 0
	end

	local overshoot = distance - this.sweetSpotRadius
	local fraction = math.max(0, 1 - overshoot / this.gradientWidth)

	return this.enums.constants.cylinder.targetRotationRight * fraction
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
	if this.lock.rotatingCounterclockwise or this.lock.rotatingClockwise or this.lock.blocked then
		return
	end

	this.currentDirectionKey = e.keyCode
	this.maxAngle = this.computeMaxAngle()

	local direction = this.rotationKeyCodeToRotationDirectionMap[e.keyCode]
	this.lock.rotatingCounterclockwise = direction == this.enums.rotationDirections.counterClockwise
	this.lock.rotatingClockwise = direction == this.enums.rotationDirections.clockwise

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

	this.lock.blocked = false
	this.lock.rotatingCounterclockwise = false
	this.lock.rotatingClockwise = false
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
