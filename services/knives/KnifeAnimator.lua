--- SERVICES
local TimerManager = require("tauer.modern-lockpicking.services.timers.TimerManager")
local NodeAnimator = require("tauer.modern-lockpicking.services.nodes.NodeAnimator")
---

--- ENUMS
local EVENTS = require("tauer.modern-lockpicking.shared.enums.events")
local DIRECTION = require("tauer.modern-lockpicking.shared.enums.rotationDirection")
local CONSTANTS = require("tauer.modern-lockpicking.services.knives.enums.constants")
---

---@class KnifeAnimator : IInitializedService
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
---@return boolean
function this.Initialize()
	event.register(EVENTS.lockpickingStart, this.onLockpickingStart)
	return true
end

---@private
---@param knife niNode
function this.start(knife)
	this.knife = knife
	this.blocked = true

	NodeAnimator.Start({
		node = knife,
		keyframes = this.startAnimationKeyFrames,
		cancelOn = EVENTS.lockpickingEnded,
	})

	TimerManager.Start({
		durationInSeconds = CONSTANTS.animation.startAnimationDuration,
		finishedCallback = this.onStartTimerFinished,
		cancelOn = EVENTS.lockpickingEnded,
	})

	this.registerEvents()
end

---@private
function this.onStartTimerFinished()
	this.baseRotation = this.knife.rotation:copy()
	this.blocked = false
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
---@param e lockpickingStartEventData
function this.onLockpickingStart(e)
	this.start(e.knife)
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

	this.unregisterEvents()
end

---@private
function this.getRelativePhaseSpeed()
	if this.phase == 0 then
		return CONSTANTS.animation.phaseSpeed
	end
	return CONSTANTS.animation.phaseSpeed / this.phase
end

---@private
function this.registerEvents()
	event.register(tes3.event.enterFrame, this.onEnterFrame)
	event.register(EVENTS.lockpickingEnd, this.onLockpickingEnd, { doOnce = true })
	event.register(EVENTS.lockpickingEnded, this.onLockpickingEnded, { doOnce = true })
	event.register(EVENTS.rotationStarted, this.onRotationStarted)
	event.register(EVENTS.rotationEnded, this.onRotationEnded)
end

---@private
function this.unregisterEvents()
	if event.isRegistered(tes3.event.enterFrame, this.onEnterFrame) then
		event.unregister(tes3.event.enterFrame, this.onEnterFrame)
	end
	if event.isRegistered(EVENTS.rotationStarted, this.onRotationStarted) then
		event.unregister(EVENTS.rotationStarted, this.onRotationStarted)
	end
	if event.isRegistered(EVENTS.rotationEnded, this.onRotationEnded) then
		event.unregister(EVENTS.rotationEnded, this.onRotationEnded)
	end
end

return this
