--- SERVICES
local LockSpawner = require("tauer.modern-lockpicking.services.locks.LockSpawner")
local LockAnimator = require("tauer.modern-lockpicking.services.locks.LockAnimator")
local KnifeSpawner = require("tauer.modern-lockpicking.services.knives.KnifeSpawner")
local KnifeAnimator = require("tauer.modern-lockpicking.services.knives.KnifeAnimator")
local CylinderAnimator = require("tauer.modern-lockpicking.services.cylinders.CylinderAnimator")
local TimerManager = require("tauer.modern-lockpicking.services.timers.TimerManager")
---

--- ENUMS
local CONSTANTS = require("tauer.modern-lockpicking.services.lockpicking.enums.constants")
local EVENTS = require("tauer.modern-lockpicking.shared.enums.events")
local DIRECTION = require("tauer.modern-lockpicking.shared.enums.rotationDirection")
---

---@class LockpickingController
local this = {}

---@private
---@type lock
this.lock = nil

---@private
---@type { [tes3.scanCode]: DIRECTION }
this.directions = {
	[tes3.scanCode.d] = DIRECTION.clockwise,
	[tes3.scanCode.a] = DIRECTION.counterClockwise,
}

---@public
---@param container tes3containerInstance
function this.Start(container)
	this.lock = LockSpawner.Spawn(container)

	KnifeSpawner.Spawn(this.lock)

	LockAnimator.Start(this.lock)
	KnifeAnimator.Start(this.lock.knife)
	CylinderAnimator.Start(this.lock.cylinder)

	TimerManager.Start({
		durationInSeconds = 1,
		finishedCallback = this.registerEvents,
	})
end

---@public
function this.Stop()
	this.stop(false)
end

---@private
---@param e keyDownEventData
function this.onKeyDown(e)
	---@type rotationStartedEventData
	local data = {
		direction = this.directions[e.keyCode],
	}
	event.trigger(EVENTS.rotationStarted, data)
end

---@private
---@param _ keyUpEventData
function this.onKeyUp(_)
	event.trigger(EVENTS.rotationEnded)
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
	this.stop(true)
end

---@private
---@param success boolean
function this.stop(success)
	this.unregisterEvents()

	---@type lockpickingEndedEventData
	local data = {
		lock = this.lock,
		success = success,
	}
	event.trigger(EVENTS.lockpickingEnded, data)
end

function this.registerEvents()
	event.register(tes3.event.keyDown, this.onKeyDown, { filter = tes3.scanCode.a })
	event.register(tes3.event.keyDown, this.onKeyDown, { filter = tes3.scanCode.d })
	event.register(tes3.event.keyUp, this.onKeyUp, { filter = tes3.scanCode.a })
	event.register(tes3.event.keyUp, this.onKeyUp, { filter = tes3.scanCode.d })
	event.register(tes3.event.enterFrame, this.onEnterFrame)
end

function this.unregisterEvents()
	if event.isRegistered(tes3.event.keyDown, this.onKeyDown, { filter = tes3.scanCode.a }) then
		event.unregister(tes3.event.keyDown, this.onKeyDown, { filter = tes3.scanCode.a })
	end
	if event.isRegistered(tes3.event.keyDown, this.onKeyDown, { filter = tes3.scanCode.d }) then
		event.unregister(tes3.event.keyDown, this.onKeyDown, { filter = tes3.scanCode.d })
	end
	if event.isRegistered(tes3.event.keyUp, this.onKeyUp, { filter = tes3.scanCode.a }) then
		event.unregister(tes3.event.keyUp, this.onKeyUp, { filter = tes3.scanCode.a })
	end
	if event.isRegistered(tes3.event.keyUp, this.onKeyUp, { filter = tes3.scanCode.d }) then
		event.unregister(tes3.event.keyUp, this.onKeyUp, { filter = tes3.scanCode.d })
	end
	if event.isRegistered(tes3.event.enterFrame, this.onEnterFrame) then
		event.unregister(tes3.event.enterFrame, this.onEnterFrame)
	end
end

return this
