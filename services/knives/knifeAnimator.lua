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
---@type boolean
this.paused = false

---@private
---@type { [rotationDirections]: number }
this.angles = nil

---@private
this.rotationBuffer = tes3matrix33.new()

---@private
this.rotationBufferTiltX = tes3matrix33.new()

---@private
this.rotationBufferTiltZ = tes3matrix33.new()

---@private
this.mouseConstants = {
	amplitude = 0.05,
	lerpSpeed = 2,
}

---@private
---@type number
this.startCursorX = 0

---@private
---@type number
this.startCursorY = 0

---@private
---@type number
this.currentTiltX = 0

---@private
---@type number
this.currentTiltZ = 0

---@private
---@type nodeAnimatonKeyframe[]
this.startAnimationKeyFrames = nil

---@private
---@type eventRegistrar
this.eventRegistrar = nil

---@private
---@type eventHandlerGroups
this.eventHandlers = {
	lifetime = {},
	session = {}
}

---@public
---@param services serviceCollection
---@return boolean,string|nil
function this.initialize(services)
	this.timerManager = services.timerManager
	this.nodeAnimator = services.nodeAnimator
	this.enums = services.enums
	this.eventRegistrar = services.eventRegistrar

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

	this.eventHandlers = {
		lifetime = {
			[events.lockpickingStart] = this.onLockpickingStart,
			[events.lockpickingEnd] = this.onLockpickingEnd,
			[events.lockpickingEnded] = this.onLockpickingEnded,
			[events.rotationStarted] = this.onRotationStarted,
			[events.rotationEnded] = this.onRotationEnded,
			[events.cylinderBlocked] = this.onCylinderBlocked,
			[events.optionsMenuOpened] = this.onOptionsMenuOpened,
			[events.optionsMenuClosed] = this.onOptionsMenuClosed,
		},
		session = {
			[tes3.event.enterFrame] = this.onEnterFrame,
		}
	}

	this.eventRegistrar.register(this.eventHandlers.lifetime)
	return true, nil
end

---@public
function this.uninitialize()
	this.eventRegistrar.unregister(this.eventHandlers.lifetime)
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
	this.currentTiltX = 0
	this.currentTiltZ = 0
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
	this.eventRegistrar.register(this.eventHandlers.session)
end

---@private
function this.disable()
	this.eventRegistrar.unregister(this.eventHandlers.session)
end

---@private
---@param e enterFrameEventData
function this.onEnterFrame(e)
	if this.paused or this.blocked then
		return
	end

	this.updatePhase(e.delta)
	this.updateTilt(e.delta)
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
	local cursor = tes3.getCursorPosition()
	this.startCursorX = cursor.x
	this.startCursorY = cursor.y
	this.blocked = false
end

---@private
function this.updateTilt(delta)
	local cursor = tes3.getCursorPosition()
	local viewportWidth, viewportHeight = tes3.getViewportSize()
	local constants = this.mouseConstants

	local targetTiltX = ((cursor.y - this.startCursorY) / viewportHeight) * constants.amplitude
	local targetTiltZ = ((this.startCursorX - cursor.x) / viewportWidth) * constants.amplitude

	local t = math.min(1, constants.lerpSpeed * delta)
	this.currentTiltX = this.currentTiltX + (targetTiltX - this.currentTiltX) * t
	this.currentTiltZ = this.currentTiltZ + (targetTiltZ - this.currentTiltZ) * t
end

---@private
function this.rotate()
	this.currentAngle = math.lerp(this.sourceAngle, this.targetAngle, this.phase)

	this.rotationBuffer:toRotationY(this.currentAngle)
	this.rotationBufferTiltX:toRotationX(this.currentTiltX)
	this.rotationBufferTiltZ:toRotationZ(this.currentTiltZ)

	this.knife.rotation = this.rotationBufferTiltX * this.rotationBufferTiltZ * this.baseRotation * this.rotationBuffer
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
