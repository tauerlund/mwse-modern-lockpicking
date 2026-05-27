--- SERVICES
local settings = require("tauer.modern-lockpicking.services.mcm.mcmSettings").mcm
---

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
---@type tes3.scanCode
this.currentDirectionKey = nil

---@private
---@type { [tes3.scanCode]: ROTATION_DIRECTION }
this.rotationDirections = nil

---@public
---@return boolean,string|nil
function this.initialize()
	this.applyKeybinds()
	event.register(EVENTS.keyBindsUpdated, this.onKeyBindsUpdated)
	event.register(EVENTS.lockpickingStarted, this.onLockpickingStarted)
	event.register(EVENTS.lockpickingEnd, this.onLockpickingEnd)
	return true, nil
end

---@private
function this.onKeyBindsUpdated()
	this.applyKeybinds()
end

---@private
---@param e lockpickingStartedEventData
function this.onLockpickingStarted(e)
	this.cylinder = e.session.lock.cylinder
	this.enable()
end

---@private
---@param _ lockpickingEndEventData
function this.onLockpickingEnd(_)
	this.disable()
	this.cylinder = nil
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
end

---@private
---@param _ enterFrameEventData
function this.onEnterFrame(_)
	local rotation = this.cylinder.rotation:toEulerXYZ().y

	if rotation <= CONSTANTS.targetRotationLeft or rotation >= CONSTANTS.targetRotationRight then
		event.trigger(EVENTS.cylinderTargetReached)
	end
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
	---@type rotationEventData
	local data = {
		direction = this.rotationDirections[e.keyCode],
	}
	event.trigger(EVENTS.rotationStarted, data)
	this.currentDirectionKey = e.keyCode
end

---@private
---@param e keyUpEventData
function this.onRotationKeyUp(e)
	if this.currentDirectionKey and this.currentDirectionKey ~= e.keyCode then
		return
	end

	---@type rotationEventData
	local data = {
		direction = this.rotationDirections[e.keyCode],
	}
	event.trigger(EVENTS.rotationEnded, data)
	this.currentDirectionKey = nil
end

---@private
function this.applyKeybinds()
	this.rotationDirections = {
		[settings.keyBinds.rotateLockClockwise.keyCode] = DIRECTION.clockwise,
		[settings.keyBinds.rotateLockCounterclockwise.keyCode] = DIRECTION.counterClockwise,
	}
end

return this
