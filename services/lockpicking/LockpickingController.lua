--- SERVICES
local LockSpawner = require("tauer.modern-lockpicking.services.locks.LockSpawner")
local LockAnimator = require("tauer.modern-lockpicking.services.locks.LockAnimator")
local KnifeSpawner = require("tauer.modern-lockpicking.services.knives.KnifeSpawner")
local KnifeAnimator = require("tauer.modern-lockpicking.services.knives.KnifeAnimator")
local CylinderAnimator = require("tauer.modern-lockpicking.services.cylinders.CylinderAnimator")
local TimerManager = require("tauer.modern-lockpicking.services.timers.TimerManager")
local InventoryManager = require("tauer.modern-lockpicking.services.inventory.InventoryManager")
local Translations = require("tauer.modern-lockpicking.shared.Translations")
local PickSpawner = require("tauer.modern-lockpicking.services.picks.PickSpawner")
local PickAnimator = require("tauer.modern-lockpicking.services.picks.PickAnimator")
---

--- ENUMS
local CONSTANTS = require("tauer.modern-lockpicking.services.lockpicking.enums.constants")
local EVENTS = require("tauer.modern-lockpicking.shared.enums.events")
local DIRECTION = require("tauer.modern-lockpicking.shared.enums.rotationDirection")
---

---@class LockpickingController
local this = {}

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
---@type { [tes3.scanCode]: DIRECTION }
this.directions = {
	[tes3.scanCode.d] = DIRECTION.clockwise,
	[tes3.scanCode.a] = DIRECTION.counterClockwise,
}

---@public
---@param container tes3containerInstance
---@return boolean
function this.Start(container)
	local picks = InventoryManager.GetLockpicks()
	if not picks then
		tes3.messageBox(Translations.Get("messageBox.noLockpicks"))
		return false
	end

	local lock = LockSpawner.Spawn(container)
	local knife = KnifeSpawner.Spawn(lock)
	local pick = PickSpawner.Spawn(lock, picks)

	require("tauer.modern-lockpicking.DebuggingAnimator").Start(pick)

	LockAnimator.Start(lock)
	KnifeAnimator.Start(knife)
	CylinderAnimator.Start(lock.cylinder)
	PickAnimator.Start(pick)

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
	this.stop(false)
end

---@private
---@param e keyDownEventData
function this.onKeyDown(e)
	if this.directions[e.keyCode] then
		this.onDirectionKeyDown(e)
		return
	end
end

---@private
---@param e keyUpEventData
function this.onKeyUp(e)
	if this.directions[e.keyCode] then
		this.onDirectionKeyUp(e)
		return
	end
end

---@private
---@param e keyDownEventData
function this.onDirectionKeyDown(e)
	---@type rotationEventData
	local data = {
		direction = this.directions[e.keyCode],
	}
	event.trigger(EVENTS.rotationStarted, data)
	this.currentDirectionKey = e.keyCode
end

---@private
---@param e keyUpEventData
function this.onDirectionKeyUp(e)
	if this.directionKeyIsBlocked(e.keyCode) then
		return
	end

	---@type rotationEventData
	local data = {
		direction = this.directions[e.keyCode],
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
		this.unlock()
	end
end

---@private
function this.unlock()
	tes3.unlock({
		reference = this.lock.container --[[@as tes3reference]],
	})

	---@type lockpickingEndEventData
	local data = {
		lock = this.lock,
		knife = this.knife,
		pick = this.pick,
		success = true,
	}
	event.trigger(EVENTS.lockpickingEnd, data)

	TimerManager.Start({
		durationInSeconds = 1,
		finishedCallback = this.onEndTimerFinished,
		data = data --[[@as timerData]],
	})
end

---@private
---@param data timerData
function this.onEndTimerFinished(data)
	---@cast data +lockpickingEndedEventData, -timerData
	this.stop(data.success)
end

---@private
---@param success boolean
function this.stop(success)
	---@type lockpickingEndedEventData
	local data = {
		lock = this.lock,
		knife = this.knife,
		pick = this.pick,
		success = success,
	}
	event.trigger(EVENTS.lockpickingEnded, data)

	this.unregisterEvents()
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
