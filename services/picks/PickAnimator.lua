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
---@type boolean
this.paused = false

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
this.noiseStrength = CONSTANTS.noise.min

---@private
this.noisePhaseX = 0

---@private
this.noisePhaseY = 0

---@private
this.noisePhaseZ = 0

---@public
---@param pick pick
---@param helper niNode
function this.Start(pick, helper)
	this.pick = pick
	this.helper = helper
	this.originalHelperRotation = helper.rotation:copy()
	this.paused = true

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
	this.paused = false
	this.originalPickRotation = this.pick.rotation:copy()
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
	if this.paused then
		return
	end

	local cursor = tes3.getCursorPosition()

	if this.cursorIsAboveHelper(cursor) then
		cursor:normalize()
		this.targetHelperAngle = -cursor.x * math.rad(90)
	end

	this.updateAngle(e.delta)

	this.rotateHelper()
	this.rotatePick(e.delta)
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
function this.rotatePick(delta)
	local noiseX, noiseZ = 0, 0

	if this.blocked then
		noiseX, noiseZ = this.getSmoothNoise(delta)
	end

	local rotation = tes3matrix33.new()
	rotation:fromEulerXYZ(noiseX, this.currentHelperAngle, noiseZ)

	this.pick.rotation = this.originalPickRotation * rotation
	this.pick:update()

	this.noiseStrength = math.min(this.noiseStrength + CONSTANTS.noise.increase * delta, CONSTANTS.noise.max)
end

---@private
---@param delta number
---@return number, number
function this.getSmoothNoise(delta)
	local speedX, speedZ = math.random(20, 40), math.random(20, 40)
	this.noisePhaseX = (this.noisePhaseX or 0) + delta * speedX
	this.noisePhaseZ = (this.noisePhaseZ or 0) + delta * speedZ

	local x = math.sin(this.noisePhaseX) * this.noiseStrength
	local z = math.sin(this.noisePhaseZ) * this.noiseStrength
	return x, z
end

function this.onLockpickingBlocked()
	this.blocked = true
end

---@private
---@param _ lockpickingEndEventData
function this.onLockpickingEnd(_)
	this.paused = true
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
	this.targetHelperAngle = 0
	this.blocked = false
	this.noiseStrength = CONSTANTS.noise.min
end

---@private
function this.registerEvents()
	event.register(tes3.event.enterFrame, this.onEnterFrame)
	event.register(EVENTS.lockpickingBlocked, this.onLockpickingBlocked)
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
