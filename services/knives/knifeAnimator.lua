--- SERVICES
local timerManager = require("tauer.modern-lockpicking.services.timers.timerManager")
local nodeAnimator = require("tauer.modern-lockpicking.services.nodes.nodeAnimator")
---

--- ENUMS
local EVENTS = require("tauer.modern-lockpicking.services.events.enums.EVENTS")
local DIRECTION = require("tauer.modern-lockpicking.services.lockpicking.enums.ROTATION_DIRECTION")
local CONSTANTS = require("tauer.modern-lockpicking.services.knives.enums.CONSTANTS")
---

---@class knifeAnimator : initializedService
local this = {}

---@private
---@type knife
this.knife = nil

---@private
---@type number
this.phase = 0

---@private
---@type number
this.phaseSpeed = CONSTANTS.animation.phaseSpeed

---@private
---@type tes3matrix33|nil
this.baseRotation = nil

---@private
---@type number
this.targetAngle = 0

---@private
---@type number
this.sourceAngle = 0

---@private
---@type number
this.currentAngle = 0

---@private
---@type boolean
this.blocked = false

---@private
---@type { [ROTATION_DIRECTION]: number }
this.angles = {
	[DIRECTION.clockwise] = CONSTANTS.angles.clockwise,
	[DIRECTION.counterClockwise] = CONSTANTS.angles.counterClockwise,
}

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
	},
}

---@public
---@return boolean,string|nil
function this.initialize()
	event.register(EVENTS.lockpickingStart, this.onLockpickingStart)
	event.register(EVENTS.lockpickingEnd, this.onLockpickingEnd)
	event.register(EVENTS.lockpickingEnded, this.onLockpickingEnded)
	event.register(EVENTS.rotationStarted, this.onRotationStarted)
	event.register(EVENTS.rotationEnded, this.onRotationEnded)
	return true, nil
end

---@private
---@param e lockpickingStartEventData
function this.onLockpickingStart(e)
	this.start(e.session.knife)
	this.enable()
end

---@private
---@param _ lockpickingEndedEventData
function this.onLockpickingEnd(_)
	this.blocked = true
end

---@private
---@param _ lockpickingEndedEventData
function this.onLockpickingEnded(_)
	this.phase = 0
	this.targetAngle = 0
	this.sourceAngle = 0
	this.baseRotation = nil
	this.disable()
end

---@private
---@param e rotationEventData
function this.onRotationStarted(e)
	this.targetAngle = this.angles[e.direction]
	this.sourceAngle = this.currentAngle
	this.phaseSpeed = CONSTANTS.animation.phaseSpeed
	this.phase = 0
end

---@private
---@param _ rotationEventData
function this.onRotationEnded(_)
	this.targetAngle = 0
	this.sourceAngle = this.currentAngle
	this.phaseSpeed = this.getRelativePhaseSpeed()
	this.phase = 0
end

---@private
function this.enable()
	if not event.isRegistered(tes3.event.enterFrame, this.onEnterFrame) then
		event.register(tes3.event.enterFrame, this.onEnterFrame)
	end
end

---@private
function this.disable()
	if event.isRegistered(tes3.event.enterFrame, this.onEnterFrame) then
		event.unregister(tes3.event.enterFrame, this.onEnterFrame)
	end
end

---@private
---@param e enterFrameEventData
function this.onEnterFrame(e)
	if this.blocked then
		return
	end

	this.updatePhase(e.delta)
	this.rotate()
end

---@private
---@param knife niNode
function this.start(knife)
	this.knife = knife
	this.blocked = true

	nodeAnimator.start({
		node = knife,
		keyframes = this.startAnimationKeyFrames,
		cancelOn = EVENTS.lockpickingEnded,
	})

	timerManager.start({
		durationInSeconds = CONSTANTS.animation.startAnimationDuration,
		finishedCallback = this.onStartTimerFinished,
		cancelOn = EVENTS.lockpickingEnded,
	})
end

---@private
function this.onStartTimerFinished()
	this.baseRotation = this.knife.rotation:copy()
	this.blocked = false
end

---@private
function this.rotate()
	this.currentAngle = math.lerp(this.sourceAngle, this.targetAngle, this.phase)

	local rotation = tes3matrix33.new()
	rotation:toRotationY(this.currentAngle)

	this.knife.rotation = this.baseRotation * rotation
	this.knife:update()
end

---@private
---@param delta number
function this.updatePhase(delta)
	this.phase = math.min(this.phase + this.phaseSpeed * delta, 1)
end

---@private
function this.getRelativePhaseSpeed()
	if this.phase == 0 then
		return CONSTANTS.animation.phaseSpeed
	end
	return CONSTANTS.animation.phaseSpeed / this.phase
end

return this
