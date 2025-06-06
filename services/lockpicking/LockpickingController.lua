local LockSpawner = require("tauer.modern-lockpicking.services.locks.LockSpawner")
local LockAnimator = require("tauer.modern-lockpicking.services.locks.LockAnimator")
local KnifeSpawner = require("tauer.modern-lockpicking.services.knives.KnifeSpawner")
local KnifeAnimator = require("tauer.modern-lockpicking.services.knives.KnifeAnimator")

local events = require("tauer.modern-lockpicking.shared.enums.event")

---@class LockpickingController
local this = {}

---@private
---@type lock
this.lock = nil

---@private
---@type number
this.maxRotationLeft = -1.56

---@private
---@type number
this.maxRotationRight = 1.56

---@public
---@param container tes3containerInstance
function this.Start(container)
	this.lock = LockSpawner.Spawn(container)

	KnifeSpawner.Spawn(this.lock)

	KnifeAnimator.Play(this.lock.knife)
	LockAnimator.Play(this.lock)

	this.registerEvents()
end

---@public
function this.Stop()
	this.unregisterEvents()

	---@type lockpickingEndedEventData
	local data = {
		lock = this.lock,
		success = false,
	}
	event.trigger(events.lockpickingEnded, data)
end

function this.registerEvents()
	event.register(tes3.event.keyDown, this.onKeyDown)
	event.register(tes3.event.keyUp, this.onKeyUp)
	event.register(tes3.event.enterFrame, this.onEnterFrame)
end

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

---@private
---@param e keyDownEventData
function this.onKeyDown(e)
	if e.keyCode == tes3.scanCode.a then
		this.lock.rotatingLeft = true
	elseif e.keyCode == tes3.scanCode.d then
		this.lock.rotatingRight = true
	end
end

---@private
---@param e keyUpEventData
function this.onKeyUp(e)
	if e.keyCode == tes3.scanCode.a then
		this.lock.rotatingLeft = false
	elseif e.keyCode == tes3.scanCode.d then
		this.lock.rotatingRight = false
	end
end

---@private
---@param _ enterFrameEventData
function this.onEnterFrame(_)
	local rotation = this.lock.cylinder.rotation:toEulerXYZ().y

	if rotation <= this.maxRotationLeft or rotation >= this.maxRotationRight then
		this.unlock()
	end
end

---@private
function this.unlock()
	tes3.unlock({
		reference = this.lock.container --[[@as tes3reference]],
	})
	---@type lockpickingEndedEventData
	local data = {
		lock = this.lock,
		success = true,
	}
	event.trigger(events.lockpickingEnded, data)
end

return this
