--- SERVICES
local settings = require("tauer.modern-lockpicking.services.mcm.mcmSettings").mcm
---

--- ENUMS
local EVENTS = require("tauer.modern-lockpicking.services.events.enums.EVENTS")
local DIRECTION = require("tauer.modern-lockpicking.services.lockpicking.enums.ROTATION_DIRECTION")
local CYCLE = require("tauer.modern-lockpicking.services.lockpicking.enums.CYCLE_DIRECTION")
---

---@class lockpickingInputHandler : initializedService
local this = {}

---@private
---@type tes3.scanCode
this.currentDirectionKey = nil

---@private
---@type { [tes3.scanCode]: ROTATION_DIRECTION }
this.rotationDirections = nil

---@private
---@type { [tes3.scanCode]: CYCLE_DIRECTION }
this.pickCycleDirections = nil

---@public
---@return boolean, string|nil
function this.initialize()
	this.applyKeybinds()
	event.register(EVENTS.keyBindsUpdated, this.onKeyBindsUpdated)
	event.register(EVENTS.lockpickingStarted, this.onLockpickingStarted)
	event.register(EVENTS.lockpickingEnd, this.onLockpickingEnd)
	event.register(EVENTS.lockpickingEnded, this.onLockpickingEnded)
	return true, nil
end

---@private
function this.onKeyBindsUpdated()
	this.applyKeybinds()
end

---@private
---@param _ lockpickingStartedEventData
function this.onLockpickingStarted(_)
	this.enable()
end

---@private
---@param _ lockpickingEndEventData
function this.onLockpickingEnd(_)
	this.disable()
end

---@private
---@param _ lockpickingEndedEventData
function this.onLockpickingEnded(_)
	this.disable()
end

---@private
function this.enable()
	if not event.isRegistered(tes3.event.keyDown, this.onKeyDown) then
		event.register(tes3.event.keyDown, this.onKeyDown)
	end
	if not event.isRegistered(tes3.event.keyUp, this.onKeyUp) then
		event.register(tes3.event.keyUp, this.onKeyUp)
	end
end

---@private
function this.disable()
	if event.isRegistered(tes3.event.keyDown, this.onKeyDown) then
		event.unregister(tes3.event.keyDown, this.onKeyDown)
	end
	if event.isRegistered(tes3.event.keyUp, this.onKeyUp) then
		event.unregister(tes3.event.keyUp, this.onKeyUp)
	end
	this.currentDirectionKey = nil
end

---@private
---@param e keyDownEventData
function this.onKeyDown(e)
	if this.rotationDirections[e.keyCode] then
		this.onRotationDirectionKeyDown(e)
		return
	end
	if this.pickCycleDirections[e.keyCode] then
		this.onPickCycleKeyDown(e)
		return
	end
end

---@private
---@param e keyUpEventData
function this.onKeyUp(e)
	if this.rotationDirections[e.keyCode] then
		this.onRotationDirectionKeyUp(e)
		return
	end
	if e.keyCode == settings.keyBinds.exit.keyCode then
		event.trigger(EVENTS.exitRequested)
		return
	end
end

---@private
---@param e keyDownEventData
function this.onRotationDirectionKeyDown(e)
	---@type rotationEventData
	local data = {
		direction = this.rotationDirections[e.keyCode],
	}
	event.trigger(EVENTS.rotationStarted, data)
	this.currentDirectionKey = e.keyCode
end

---@private
---@param e keyDownEventData
function this.onPickCycleKeyDown(e)
	---@type pickCycleRequestedEventData
	local data = {
		direction = this.pickCycleDirections[e.keyCode],
	}
	event.trigger(EVENTS.pickCycleRequested, data)
end

---@private
---@param e keyUpEventData
function this.onRotationDirectionKeyUp(e)
	if this.directionKeyIsBlocked(e.keyCode) then
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
---@param keyCode tes3.scanCode
---@return boolean
function this.directionKeyIsBlocked(keyCode)
	return this.currentDirectionKey and this.currentDirectionKey ~= keyCode
end

---@private
function this.applyKeybinds()
	this.rotationDirections = {
		[settings.keyBinds.rotateLockClockwise.keyCode] = DIRECTION.clockwise,
		[settings.keyBinds.rotateLockCounterclockwise.keyCode] = DIRECTION.counterClockwise,
	}
	this.pickCycleDirections = {
		[settings.keyBinds.cycleNextPick.keyCode] = CYCLE.next,
		[settings.keyBinds.cyclePreviousPick.keyCode] = CYCLE.previous,
	}
end

return this
