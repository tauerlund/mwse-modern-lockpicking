--- SERVICES
local TimerManager = require("tauer.modern-lockpicking.services.timers.TimerManager")
---

--- ENUMS
local EVENTS = require("tauer.modern-lockpicking.shared.enums.events")
local DIRECTION = require("tauer.modern-lockpicking.shared.enums.rotationDirection")
local CONSTANTS = require("tauer.modern-lockpicking.services.knives.enums.constants")
---

---@class KnifeAnimator
local this = {}

---@private
---@type knife
this.knife = nil

---@private
---@type number
this.phase = 0

---@private
---@type number
this.phaseSpeed = CONSTANTS.phase.speed

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
---@type { [DIRECTION]: number }
this.angles = {
	[DIRECTION.clockwise] = CONSTANTS.angles.clockwise,
	[DIRECTION.counterClockwise] = CONSTANTS.angles.counterClockwise,
}

---@public
---@param knife niNode
function this.Start(knife)
	this.knife = knife
	this.initializeTransforms()

	TimerManager.Start({
		durationInSeconds = 1,
		callback = this.onStartTimer,
		finishedCallback = this.onStartTimerFinished,
		---@type onStartKnifeAnimationData
		data = {
			knife = knife,
		},
	})
	this.registerEvents()
end

function this.initializeTransforms()
	this.knife.translation = CONSTANTS.translation.initial

	local rotation = tes3matrix33.new()
	rotation:fromEulerXYZ(CONSTANTS.rotation.initial.x, CONSTANTS.rotation.initial.y, CONSTANTS.rotation.initial.z)

	this.knife.rotation = rotation
end

---@private
---@param callback mwseTimerCallbackData
function this.onStartTimer(callback)
	local data = callback.timer.data --[[@as onStartKnifeAnimationData]]
	local knife = data.knife

	local currentPhase = callback.timer.iterations
	local targetPhase = data.totalIterations --[[@as integer]]

	knife.translation = this.getUpdatedTranslation(currentPhase, targetPhase)
	knife.rotation = this.getUpdatedRotation(currentPhase, targetPhase)

	knife:update()
end

---@private
function this.onStartTimerFinished()
	this.baseRotation = this.knife.rotation:copy()
end

---@private
---@param currentPhase integer
---@param targetPhase integer
---@return tes3vector3
function this.getUpdatedTranslation(currentPhase, targetPhase)
	local initial = CONSTANTS.translation.initial
	local target = CONSTANTS.translation.target

	local translation = tes3vector3.new(
		math.remap(currentPhase, 0, targetPhase, target.x, initial.x),
		math.remap(currentPhase, 0, targetPhase, target.y, initial.y),
		math.remap(currentPhase, 0, targetPhase, target.z, initial.z)
	)

	return translation
end

---@private
---@param currentPhase integer
---@param targetPhase integer
---@return tes3matrix33
function this.getUpdatedRotation(currentPhase, targetPhase)
	local initial = CONSTANTS.rotation.initial
	local target = CONSTANTS.rotation.target

	local rotation = tes3matrix33.new()
	rotation:fromEulerXYZ(
		math.remap(currentPhase, 0, targetPhase, target.x, initial.x),
		math.remap(currentPhase, 0, targetPhase, target.y, initial.y),
		math.remap(currentPhase, 0, targetPhase, target.z, initial.z)
	)

	return rotation
end

---@private
---@param e enterFrameEventData
function this.onEnterFrame(e)
	if not this.baseRotation then
		return
	end

	this.rotate()
	this.increasePhase(e.delta)
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
function this.increasePhase(delta)
	this.phase = math.min(this.phase + this.phaseSpeed * delta, 1)
end

---@private
---@param e rotationEventData
function this.onRotationStarted(e)
	this.targetAngle = this.angles[e.direction]
	this.sourceAngle = this.currentAngle
	this.phaseSpeed = CONSTANTS.phase.speed
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
		return CONSTANTS.phase.speed
	end
	return CONSTANTS.phase.speed / this.phase
end

---@private
function this.registerEvents()
	event.register(tes3.event.enterFrame, this.onEnterFrame)
	event.register(EVENTS.rotationStarted, this.onRotationStarted)
	event.register(EVENTS.rotationEnded, this.onRotationEnded)
	event.register(EVENTS.lockpickingEnded, this.onLockpickingEnded, { doOnce = true })
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
