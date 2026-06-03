---@class knifeAnimator : initializedService
local this = {}

---@private
---@type timerManager
this.timerManager = nil

---@private
---@type nodeAnimator
this.nodeAnimator = nil

---@private
---@type enums
this.enums = nil

---@private
---@type knife
this.knife = nil

---@private
---@type number
this.phase = 0

---@private
---@type number
this.phaseSpeed = 0

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
---@type { [rotationDirections]: number }
this.angles = nil

---@private
---@type tes3matrix33
this.rotationBuffer = tes3matrix33.new()

---@private
---@type nodeAnimatonKeyframe[]
this.startAnimationKeyFrames = nil

---@public
---@param services serviceCollection
---@return boolean,string|nil
function this.initialize(services)
	this.timerManager = services.timerManager
	this.nodeAnimator = services.nodeAnimator
	this.enums = services.enums

	local events = services.enums.events
	local constants = services.enums.constants.knives

	this.phaseSpeed = constants.animation.phaseSpeed
	this.angles = {
		[this.enums.rotationDirections.clockwise] = constants.angles.clockwise,
		[this.enums.rotationDirections.counterClockwise] = constants.angles.counterClockwise,
	}
	this.startAnimationKeyFrames = {
		{
			time = 0,
			translation = constants.translation.original,
			rotation = constants.rotation.original,
		},
		{
			time = constants.animation.startAnimationDuration,
			translation = constants.translation.target,
			rotation = constants.rotation.target,
		},
	}

	event.register(events.lockpickingStart, this.onLockpickingStart)
	event.register(events.lockpickingEnd, this.onLockpickingEnd)
	event.register(events.lockpickingEnded, this.onLockpickingEnded)
	event.register(events.rotationStarted, this.onRotationStarted)
	event.register(events.rotationEnded, this.onRotationEnded)
	event.register(events.cylinderBlocked, this.onCylinderBlocked)
	event.register(events.optionsMenuOpened, this.onOptionsMenuOpened)
	event.register(events.optionsMenuClosed, this.onOptionsMenuClosed)
	return true, nil
end

---@private
function this.onOptionsMenuOpened()
	this.paused = true
end

---@private
function this.onOptionsMenuClosed()
	this.paused = false
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
	this.phaseSpeed = this.enums.constants.knives.animation.phaseSpeed
	this.phase = 0
end

---@private
---@param _ rotationEventData
function this.onRotationEnded(_)
	this.blocked = false
	this.targetAngle = 0
	this.sourceAngle = this.currentAngle
	this.phaseSpeed = this.getRelativePhaseSpeed()
	this.phase = 0
end

---@private
function this.onCylinderBlocked()
	this.blocked = true
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
	if this.paused or this.blocked then
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

	this.nodeAnimator.start({
		node = knife,
		keyframes = this.startAnimationKeyFrames,
		cancelOn = { this.enums.events.lockpickingEnded },
	})

	this.timerManager.start({
		durationInSeconds = this.enums.constants.knives.animation.startAnimationDuration,
		callback = this.onStartTimerFinished,
		cancelOn = { this.enums.events.lockpickingEnded },
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

	this.rotationBuffer:toRotationY(this.currentAngle)

	this.knife.rotation = this.baseRotation * this.rotationBuffer
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
		return this.enums.constants.knives.animation.phaseSpeed
	end
	return this.enums.constants.knives.animation.phaseSpeed / this.phase
end

return this
