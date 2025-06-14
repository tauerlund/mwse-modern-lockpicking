--- SERVICES
local LockSpawner = require("tauer.modern-lockpicking.services.locks.LockSpawner")
local KnifeSpawner = require("tauer.modern-lockpicking.services.knives.KnifeSpawner")
local PickSpawner = require("tauer.modern-lockpicking.services.picks.PickSpawner")
local TimerManager = require("tauer.modern-lockpicking.services.timers.TimerManager")
local Settings = require("tauer.modern-lockpicking.shared.Settings").Mcm
---

--- ENUMS
local CONSTANTS = require("tauer.modern-lockpicking.services.lockpicking.enums.constants")
local EVENTS = require("tauer.modern-lockpicking.shared.enums.events")
local DIRECTION = require("tauer.modern-lockpicking.shared.enums.rotationDirection")
local CYCLE = require("tauer.modern-lockpicking.shared.enums.cycleDirection")
local OBJECT_NAMES = require("tauer.modern-lockpicking.shared.enums.objectNames")
---

---@class LockpickingController : IInitializedService
local this = {}

---@private
---@type tes3containerInstance|tes3door
this.activator = nil

---@private
---@type tes3itemStack[]
this.picks = nil

---@private
---@type lock
this.lock = nil

---@private
---@type knife
this.knife = nil

---@private
---@type pick
this.pick = nil

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
---@return boolean
function this.Initialize()
	event.register(EVENTS.keyBindsUpdated, this.onKeyBindsUpdated)
	this.rotationDirections = this.getRotationDirections()
	this.pickCycleDirections = this.getPickCycleDirections()
	return true
end

---@public
---@param activator tes3containerInstance|tes3door
---@param picks tes3itemStack[]
---@return boolean
function this.Start(activator, picks)
	local lock = LockSpawner.Spawn(activator)
	local knife = KnifeSpawner.Spawn(lock)
	local pick = PickSpawner.Spawn(lock, picks)
	local pickHelper = lock.mesh:getObjectByName(OBJECT_NAMES.pickHelper) --[[@as niNode]]

	---@type lockpickingStartEventData
	local data = {
		lock = lock,
		knife = knife,
		pick = pick,
		pickHelper = pickHelper,
		picks = picks,
		activator = activator,
	}
	event.trigger(EVENTS.lockpickingStart, data)

	this.activator = activator
	this.picks = picks
	this.lock = lock
	this.knife = knife
	this.pick = pick

	TimerManager.Start({
		durationInSeconds = 1.3,
		finishedCallback = this.registerEvents,
		cancelOn = EVENTS.lockpickingEnded,
	})

	return true
end

---@public
function this.Stop()
	this.stop({ success = false })
end

---@private
---@param e keyDownEventData
function this.onKeyDown(e)
	if this.rotationDirections[e.keyCode] then
		this.onDirectionKeyDown(e)
		return
	end
	if this.pickCycleDirections[e.keyCode] then
		this.onPickSelectionKeyDown(e)
		return
	end
end

---@private
---@param e keyUpEventData
function this.onKeyUp(e)
	if this.rotationDirections[e.keyCode] then
		this.onDirectionKeyUp(e)
		return
	end
	if e.keyCode == Settings.keyBinds.exit.keyCode then
		this.finish({ success = false })
		return
	end
end

---@private
---@param e keyDownEventData
function this.onDirectionKeyDown(e)
	---@type rotationEventData
	local data = {
		direction = this.rotationDirections[e.keyCode],
	}
	event.trigger(EVENTS.rotationStarted, data)
	this.currentDirectionKey = e.keyCode
end

---@private
---@param e keyDownEventData
function this.onPickSelectionKeyDown(e)
	---@type pickCycledEventData
	local data = {
		direction = this.pickCycleDirections[e.keyCode],
	}
	event.trigger(EVENTS.pickCycled, data)
end

---@private
---@param e keyUpEventData
function this.onDirectionKeyUp(e)
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
---@param _ enterFrameEventData
function this.onEnterFrame(_)
	local rotation = this.lock.cylinder.rotation:toEulerXYZ().y

	if rotation <= CONSTANTS.targetRotationLeft or rotation >= CONSTANTS.targetRotationRight then
		this.finish({ success = true })
		return
	end
end

---@private
---@param parameters stopLockpickingParameters
function this.finish(parameters)
	---@type lockpickingEndEventData
	local data = {
		lock = this.lock,
		knife = this.knife,
		pick = this.pick,
		activator = this.activator,
		success = parameters.success,
	}
	event.trigger(EVENTS.lockpickingEnd, data)

	TimerManager.Start({
		durationInSeconds = 1,
		finishedCallback = this.onEndTimerFinished,
		data = data --[[@as timerData]],
	})

	this.unregisterEvents()
end

---@private
---@param data timerData
function this.onEndTimerFinished(data)
	---@cast data +lockpickingEndedEventData, -timerData
	this.stop({ success = data.success })
end

---@private
---@param parameters stopLockpickingParameters
function this.stop(parameters)
	---@type lockpickingEndedEventData
	local data = {
		lock = this.lock,
		knife = this.knife,
		pick = this.pick,
		activator = this.activator,
		success = parameters.success,
	}
	event.trigger(EVENTS.lockpickingEnded, data)

	this.unregisterEvents()
end

---@private
function this.onKeyBindsUpdated()
	this.rotationDirections = this.getRotationDirections()
	this.pickCycleDirections = this.getPickCycleDirections()
end

---@private
---@return { [tes3.scanCode]: ROTATION_DIRECTION }
function this.getRotationDirections()
	return {
		[Settings.keyBinds.rotateLockClockwise.keyCode] = DIRECTION.clockwise,
		[Settings.keyBinds.rotateLockCounterclockwise.keyCode] = DIRECTION.counterClockwise,
	}
end

---@private
---@return { [tes3.scanCode]: CYCLE_DIRECTION }
function this.getPickCycleDirections()
	return {
		[Settings.keyBinds.cycleNextPick.keyCode] = CYCLE.next,
		[Settings.keyBinds.cyclePreviousPick.keyCode] = CYCLE.previous,
	}
end

---@private
function this.registerEvents()
	event.register(tes3.event.keyDown, this.onKeyDown)
	event.register(tes3.event.keyUp, this.onKeyUp)
	event.register(tes3.event.enterFrame, this.onEnterFrame)
end

---@private
function this.unregisterEvents()
	if event.isRegistered(tes3.event.keyDown, this.onKeyDown) then
		event.unregister(tes3.event.keyDown, this.onKeyDown)
	end
	if event.isRegistered(tes3.event.keyUp, this.onKeyUp) then
		event.unregister(tes3.event.keyUp, this.onKeyUp)
	end
	if event.isRegistered(tes3.event.enterFrame, this.onEnterFrame) then
		event.unregister(tes3.event.enterFrame, this.onEnterFrame)
	end
end

return this
