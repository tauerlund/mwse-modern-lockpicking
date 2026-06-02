---@class cylinderController : initializedService
local this = {}

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
---@type boolean
this.rotating = false

---@private
---@type boolean
this.blocked = false

---@private
---@type number
this.maxAngle = 0

---@private
---@type tes3.scanCode
this.currentDirectionKey = nil

---@private
---@type { [tes3.scanCode]: rotationDirections }
this.rotationKeyCodeToRotatioDirectionMap = nil

---@private
---@type boolean
this.paused = false

---@private
---@type settings
this.settings = nil

---@private
---@type enums
this.enums = nil

---@public
---@param services serviceCollection
---@return boolean,string|nil
function this.initialize(services)
	this.settings = services.settings
	this.enums = services.enums
	this.applyKeybinds()

	local events = this.enums.events

	event.register(events.settingsUpdated, this.onSettingsUpdated)
	event.register(events.lockpickingStarted, this.onLockpickingStarted)
	event.register(events.lockpickingEnd, this.onLockpickingEnd)
	event.register(events.sweetSpotUpdated, this.onSweetSpotUpdated)
	event.register(events.pickCycled, this.onPickCycled)
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
function this.onSettingsUpdated()
	this.applyKeybinds()
end

---@private
---@param e lockpickingStartedEventData
function this.onLockpickingStarted(e)
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
	this.cylinder = nil
	this.pickHelper = nil
	this.sweetSpotCenter = nil
	this.sweetSpotRadius = nil
	this.gradientWidth = nil
end

---@private
function this.enable()
	if not event.isRegistered(tes3.event.enterFrame, this.onEnterFrame) then
		event.register(tes3.event.enterFrame, this.onEnterFrame)
	end
	if not event.isRegistered(tes3.event.keyDown, this.onKeyDown) then
		event.register(tes3.event.keyDown, this.onKeyDown)
	end
	if not event.isRegistered(tes3.event.keyUp, this.onKeyUp) then
		event.register(tes3.event.keyUp, this.onKeyUp)
	end
end

---@private
function this.disable()
	if event.isRegistered(tes3.event.enterFrame, this.onEnterFrame) then
		event.unregister(tes3.event.enterFrame, this.onEnterFrame)
	end
	if event.isRegistered(tes3.event.keyDown, this.onKeyDown) then
		event.unregister(tes3.event.keyDown, this.onKeyDown)
	end
	if event.isRegistered(tes3.event.keyUp, this.onKeyUp) then
		event.unregister(tes3.event.keyUp, this.onKeyUp)
	end
	this.currentDirectionKey = nil
	this.rotating = false
	this.blocked = false
	this.maxAngle = 0
end

---@private
---@param _ enterFrameEventData
function this.onEnterFrame(_)
	if this.paused or this.blocked or not this.rotating then
		return
	end

	local constants = this.enums.constants.cylinder
	local events = this.enums.events

	local rotation = this.cylinder.rotation:toEulerXYZ().y

	if rotation <= constants.targetRotationLeft or rotation >= constants.targetRotationRight then
		event.trigger(events.cylinderTargetReached)
		return
	end

	if this.maxAngle == 0 or math.abs(rotation) >= this.maxAngle then
		this.rotating = false
		this.blocked = true
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
	if this.rotationKeyCodeToRotatioDirectionMap[e.keyCode] then
		this.onRotationKeyDown(e)
	end
end

---@private
---@param e keyUpEventData
function this.onKeyUp(e)
	if this.rotationKeyCodeToRotatioDirectionMap[e.keyCode] then
		this.onRotationKeyUp(e)
	end
end

---@private
---@param e keyDownEventData
function this.onRotationKeyDown(e)
	if this.rotating or this.blocked then
		return
	end

	this.currentDirectionKey = e.keyCode
	this.maxAngle = this.computeMaxAngle()
	this.rotating = true

	---@type rotationEventData
	local eventData = {
		direction = this.rotationKeyCodeToRotatioDirectionMap[e.keyCode],
	}
	event.trigger(this.enums.events.rotationStarted, eventData)
end

---@private
---@param e keyUpEventData
function this.onRotationKeyUp(e)
	if this.currentDirectionKey and this.currentDirectionKey ~= e.keyCode then
		return
	end

	this.blocked = false
	this.rotating = false
	this.currentDirectionKey = nil

	---@type rotationEventData
	local eventData = {
		direction = this.rotationKeyCodeToRotatioDirectionMap[e.keyCode],
	}
	event.trigger(this.enums.events.rotationEnded, eventData)
end

---@private
function this.applyKeybinds()
	local keyBinds = this.settings.keyBinds
	local rotationDirections = this.enums.rotationDirections

	this.rotationKeyCodeToRotatioDirectionMap = {
		[keyBinds.rotateLockClockwise.keyCode] = rotationDirections.clockwise,
		[keyBinds.rotateLockCounterclockwise.keyCode] = rotationDirections.counterClockwise,
	}
end

return this
