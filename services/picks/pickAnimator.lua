--- SERVICES
local nodeAnimator = require("tauer.modern-lockpicking.services.nodes.nodeAnimator")
local timerManager = require("tauer.modern-lockpicking.services.timers.timerManager")
---

--- ENUMS
local CONSTANTS = require("tauer.modern-lockpicking.services.picks.enums.CONSTANTS")
local EVENTS = require("tauer.modern-lockpicking.services.events.enums.EVENTS")
---

---@class pickAnimator : initializedService
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
---@type nodeAnimatorKeyframe[]
this.startAnimationKeyFrames = {
	{
		time = 0,
		translation = CONSTANTS.translation.original,
		rotation = CONSTANTS.rotation.original,
	},
	{
		time = CONSTANTS.animation.startAnimationDuration,
		translation = CONSTANTS.translation.target,
		rotation = CONSTANTS.rotation.target,
	}
}

---@private
---@type nodeAnimatorKeyframe[]
this.cycleAnimationKeyFrames = {
	{
		time = 0,
		translation = CONSTANTS.translation.original,
		rotation = CONSTANTS.rotation.original,
	},
	{
		time = CONSTANTS.animation.cycleAnimationDuration,
		translation = CONSTANTS.translation.target,
		rotation = CONSTANTS.rotation.target,
	}
}

---@public
---@return boolean,string|nil
function this.initialize()
	event.register(EVENTS.lockpickingStart, this.onLockpickingStart)
	return true, nil
end

---@private
---@param pick pick
---@param keyframes nodeAnimatorKeyframe[]
function this.start(pick, keyframes)
	this.mesh = pick.mesh
	this.blocked = true

	nodeAnimator.start({
		node = pick.mesh,
		keyframes = keyframes,
		cancelOn = { EVENTS.lockpickingEnded, EVENTS.pickCycled },
	})

	timerManager.start({
		durationInSeconds = keyframes[#keyframes].time,
		cancelOn = { EVENTS.lockpickingEnded, EVENTS.pickCycled },
		finishedCallback = this.onStartTimerFinished,
	})
end

---@private
---@param _ mwseTimerCallbackData
function this.onStartTimerFinished(_)
	this.blocked = false
	this.originalPickRotation = this.mesh.rotation:copy()
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
	this.helper = e.session.pick.helper
	this.originalHelperRotation = e.session.pick.helper.rotation:copy()

	this.start(e.session.pick, this.startAnimationKeyFrames)
	this.registerEvents()
end

---@private
---@param e pickSelectedEventData
function this.onPickSelected(e)
	this.start(e.pick, this.cycleAnimationKeyFrames)
end

---@private
---@param _ lockpickingEndEventData
function this.onLockpickingEnd(_)
	this.blocked = true
end

---@private
---@param _ lockpickingEndedEventData
function this.onLockpickingEnded(_)
	this.resetHelper()
	this.resetFields()
	this.unregisterEvents()
end

function this.resetHelper()
	this.helper.rotation = this.originalHelperRotation:copy()
	this.helper:update()
end

---@private
function this.resetFields()
	this.mesh = nil
	this.helper = nil
	this.blocked = false
	this.originalHelperRotation = nil
	this.originalPickRotation = nil
	this.currentHelperAngle = 0
	this.targetHelperAngle = 0
end

---@private
function this.registerEvents()
	event.register(tes3.event.enterFrame, this.onEnterFrame)
	event.register(EVENTS.pickSelected, this.onPickSelected)
	event.register(EVENTS.lockpickingEnd, this.onLockpickingEnd)
	event.register(EVENTS.lockpickingEnded, this.onLockpickingEnded)
end

---@private
function this.unregisterEvents()
	if event.isRegistered(tes3.event.enterFrame, this.onEnterFrame) then
		event.unregister(tes3.event.enterFrame, this.onEnterFrame)
	end
	if event.isRegistered(EVENTS.pickSelected, this.onPickSelected) then
		event.unregister(EVENTS.pickSelected, this.onPickSelected)
	end
	if event.isRegistered(EVENTS.lockpickingEnd, this.onLockpickingEnd) then
		event.unregister(EVENTS.lockpickingEnd, this.onLockpickingEnd)
	end
	if event.isRegistered(EVENTS.lockpickingEnded, this.onLockpickingEnded) then
		event.unregister(EVENTS.lockpickingEnded, this.onLockpickingEnded)
	end
end

return this
