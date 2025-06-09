--- SERVICES
local MeshAnimator = require("tauer.modern-lockpicking.shared.MeshAnimator")
local TimerManager = require("tauer.modern-lockpicking.services.timers.TimerManager")
---

--- ENUMS
local CONSTANTS = require("tauer.modern-lockpicking.services.picks.enums.constants")
local EVENTS = require("tauer.modern-lockpicking.shared.enums.events")
---

---@class PickAnimator
local this = {}

---@private
---@type pick
this.pick = nil

---@private
---@type niNode
this.helper = nil

---@private
---@type boolean
this.blocked = false

---@private
---@type tes3matrix33
this.originalHelperRotation = nil

---@private
---@type tes3matrix33
this.originalPickRotation = nil

---@private
---@type number
this.currentHelperAngle = 0

---@public
---@param pick pick
---@param helper niNode
function this.Start(pick, helper)
	this.pick = pick
	this.helper = helper
	this.originalHelperRotation = helper.rotation:copy()
	this.blocked = true

	MeshAnimator.Start({
		mesh = pick,
		durationInSeconds = CONSTANTS.animation.startAnimationDuration,
		originalRotation = CONSTANTS.rotation.original,
		targetRotation = CONSTANTS.rotation.target,
		originalTranslation = CONSTANTS.translation.original,
		targetTranslation = CONSTANTS.translation.target,
	})

	TimerManager.Start({
		durationInSeconds = CONSTANTS.animation.startAnimationDuration,
		cancelOn = EVENTS.lockpickingEnded,
		finishedCallback = this.onStartTimerFinished,
	})
end

---@private
---@param _ mwseTimerCallbackData
function this.onStartTimerFinished(_)
	this.blocked = false
	this.originalPickRotation = this.pick.rotation:copy()
	this.currentHelperAngle = 0
	this.registerEvents()
end

---@private
---@param e enterFrameEventData
function this.onEnterFrame(e)
	if this.blocked then
		return
	end

	local cursor = tes3.getCursorPosition():normalized()
	local angle = -cursor.x * math.rad(90)

	this.updateAngle(angle, e.delta)

	this.rotateHelper()
	this.rotatePick(angle)
end

---@private
---@param target number
---@param delta number
function this.updateAngle(target, delta)
	local transition = math.min(CONSTANTS.animation.lerpSpeed * delta, 1)
	this.currentHelperAngle = math.lerp(this.currentHelperAngle, target, transition)
end

---@private
function this.rotateHelper()
	local rotation = this.helper.rotation:copy()
	rotation:toRotationY(this.currentHelperAngle)

	this.helper.rotation = rotation
	this.helper:update()
end

---@private
---@param angle number
function this.rotatePick(angle)
	local rotation = this.pick.rotation:copy()
	rotation:toRotationY(angle)

	this.pick.rotation = this.originalPickRotation * rotation
	this.pick:update()
end

---@private
---@param _ lockpickingEndEventData
function this.onLockpickingEnd(_)
	this.blocked = true
end

---@private
---@param _ lockpickingEndedEventData
function this.onLockpickingEnded(_)
	this.unregisterEvents()

	this.helper.rotation = this.originalHelperRotation:copy()
	this.helper:update()

	this.helper = nil
	this.pick = nil
	this.originalHelperRotation = nil
	this.originalPickRotation = nil
	this.currentHelperAngle = 0
end

---@private
function this.registerEvents()
	event.register(tes3.event.enterFrame, this.onEnterFrame)
	event.register(EVENTS.lockpickingEnd, this.onLockpickingEnd, { doOnce = true })
	event.register(EVENTS.lockpickingEnded, this.onLockpickingEnded, { doOnce = true })
end

---@private
function this.unregisterEvents()
	if event.isRegistered(tes3.event.enterFrame, this.onEnterFrame) then
		event.unregister(tes3.event.enterFrame, this.onEnterFrame)
	end
end

return this
