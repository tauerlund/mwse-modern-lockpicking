--- SERVICES
local MeshAnimator = require("tauer.modern-lockpicking.shared.MeshAnimator")
local TimerManager = require("tauer.modern-lockpicking.services.timers.TimerManager")
---

--- ENUMS
local CONSTANTS = require("tauer.modern-lockpicking.services.picks.enums.constants")
local EVENTS = require("tauer.modern-lockpicking.shared.enums.events")
---

---@class PickAnimator : IInitializedService
local this = {}

---@private
---@type niNode
this.mesh = nil

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

---@private
---@type number
this.targetHelperAngle = 0

---@private
---@type number
this.animationDuration = CONSTANTS.animation.startAnimationDuration

---@public
---@return boolean
function this.Initialize()
	event.register(EVENTS.pickSelected, this.onPickSelected)
	return true
end

---@private
---@param pick pick
function this.start(pick)
	this.mesh = pick.mesh
	this.helper = pick.helper
	this.originalHelperRotation = pick.helper.rotation:copy()
	this.blocked = true

	MeshAnimator.Start({
		mesh = pick.mesh,
		durationInSeconds = this.animationDuration,
		originalRotation = CONSTANTS.rotation.original,
		targetRotation = CONSTANTS.rotation.target,
		originalTranslation = CONSTANTS.translation.original,
		targetTranslation = CONSTANTS.translation.target,
		cancelOn = { EVENTS.lockpickingEnded, EVENTS.pickChange },
	})

	TimerManager.Start({
		durationInSeconds = this.animationDuration,
		cancelOn = { EVENTS.lockpickingEnded, EVENTS.pickChange },
		finishedCallback = this.onStartTimerFinished,
	})
end

---@private
---@param _ mwseTimerCallbackData
function this.onStartTimerFinished(_)
	this.blocked = false
	this.originalPickRotation = this.mesh.rotation:copy()
	this.currentHelperAngle = 0
	this.targetHelperAngle = 0
	this.registerEvents()
end

---@private
---@type number
this.targetHelperAngle = 0

---@private
---@param e enterFrameEventData
function this.onEnterFrame(e)
	if this.blocked then
		return
	end

	local cursor = tes3.getCursorPosition()

	if this.cursorIsAboveHelper(cursor) then
		cursor:normalize()
		this.targetHelperAngle = -cursor.x * math.rad(90)
	end

	this.updateAngle(e.delta)

	this.rotateHelper()
	this.rotatePick()
end

---@private
---@param cursor tes3vector2
---@return boolean
function this.cursorIsAboveHelper(cursor)
	local screenPoint = tes3.getCamera():worldPointToScreenPoint(this.helper.worldTransform.translation)
	if not screenPoint then
		return false
	end

	return cursor.y > screenPoint.y
end

---@private
---@param delta number
function this.updateAngle(delta)
	local transition = math.min(CONSTANTS.animation.lerpSpeed * delta, 1)
	this.currentHelperAngle = math.lerp(this.currentHelperAngle, this.targetHelperAngle, transition)
end

---@private
function this.rotateHelper()
	local rotation = this.helper.rotation:copy()
	rotation:toRotationY(this.currentHelperAngle)

	this.helper.rotation = rotation
	this.helper:update()
end

---@private
function this.rotatePick()
	local rotation = this.mesh.rotation:copy()
	rotation:toRotationY(this.currentHelperAngle)

	this.mesh.rotation = this.originalPickRotation * rotation
	this.mesh:update()
end

---@private
---@param e lockpickingStartEventData
function this.onLockpickingStart(e)
	this.start(e.pick)
end

---@private
---@param _ pickChangeEventData
function this.onPickChange(_)
	this.stop()
	this.animationDuration = CONSTANTS.animation.changeAnimationDuration
end

---@private
---@param e pickSelectedEventData
function this.onPickSelected(e)
	this.start(e.pick)
end

---@private
---@param _ lockpickingEndEventData
function this.onLockpickingEnd(_)
	this.blocked = true
end

---@private
---@param _ lockpickingEndedEventData
function this.onLockpickingEnded(_)
	this.stop()
	this.animationDuration = CONSTANTS.animation.startAnimationDuration
end

---@private
function this.stop()
	this.unregisterEvents()

	this.helper.rotation = this.originalHelperRotation:copy()
	this.helper:update()
end

---@private
function this.registerEvents()
	event.register(tes3.event.enterFrame, this.onEnterFrame)
	event.register(EVENTS.lockpickingEnd, this.onLockpickingEnd, { doOnce = true })
	event.register(EVENTS.lockpickingEnded, this.onLockpickingEnded, { doOnce = true })
	event.register(EVENTS.pickChange, this.onPickChange, { doOnce = true })
	event.register(EVENTS.pickSelected, this.onPickSelected, { doOnce = true })
end

---@private
function this.unregisterEvents()
	if event.isRegistered(tes3.event.enterFrame, this.onEnterFrame) then
		event.unregister(tes3.event.enterFrame, this.onEnterFrame)
	end
	if event.isRegistered(EVENTS.pickSelected, this.onPickSelected) then
		event.unregister(EVENTS.pickSelected, this.onPickSelected)
	end
end

return this
