--- ENUMS
local CONSTANTS = require("tauer.modern-lockpicking.services.lockpicking.enums.CONSTANTS")
local EVENTS = require("tauer.modern-lockpicking.services.events.enums.EVENTS")
local DIRECTION = require("tauer.modern-lockpicking.services.lockpicking.enums.ROTATION_DIRECTION")
---

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
---@type { [tes3.scanCode]: ROTATION_DIRECTION }
this.rotationDirections = nil

---@private
---@type boolean
this.paused = false

---@private
---@type settings
this.settings = nil

---@public
---@param services serviceCollection
---@return boolean,string|nil
function this.initialize(services)
	this.settings = services.settings

	this.applyKeybinds()
	event.register(EVENTS.settingsUpdated, this.onSettingsUpdated)
	event.register(EVENTS.lockpickingStarted, this.onLockpickingStarted)
	event.register(EVENTS.lockpickingEnd, this.onLockpickingEnd)
	event.register(EVENTS.sweetSpotUpdated, this.onSweetSpotUpdated)
	event.register(EVENTS.pickCycled, this.onPickCycled)
	event.register(EVENTS.optionsMenuOpened, this.onOptionsMenuOpened)
	event.register(EVENTS.optionsMenuClosed, this.onOptionsMenuClosed)
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

	local rotation = this.cylinder.rotation:toEulerXYZ().y

	if rotation <= CONSTANTS.targetRotationLeft or rotation >= CONSTANTS.targetRotationRight then
		event.trigger(EVENTS.cylinderTargetReached)
		return
	end

	if this.maxAngle == 0 or math.abs(rotation) >= this.maxAngle then
		this.rotating = false
		this.blocked = true
		event.trigger(EVENTS.cylinderBlocked)
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

	return CONSTANTS.targetRotationRight * fraction
end

---@private
---@param e keyDownEventData
function this.onKeyDown(e)
	if this.rotationDirections[e.keyCode] then
		this.onRotationKeyDown(e)
	end
end

---@private
---@param e keyUpEventData
function this.onKeyUp(e)
	if this.rotationDirections[e.keyCode] then
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
		direction = this.rotationDirections[e.keyCode],
	}
	event.trigger(EVENTS.rotationStarted, eventData)
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
		direction = this.rotationDirections[e.keyCode],
	}
	event.trigger(EVENTS.rotationEnded, eventData)
end

---@private
function this.applyKeybinds()
	this.rotationDirections = {
		[this.settings.keyBinds.rotateLockClockwise.keyCode] = DIRECTION.clockwise,
		[this.settings.keyBinds.rotateLockCounterclockwise.keyCode] = DIRECTION.counterClockwise,
	}
end

return this
