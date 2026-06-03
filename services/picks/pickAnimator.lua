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
---@type boolean
this.jiggling = false

---@private
---@type number
this.jigglePhase = 0

---@private
---@type number
this.jiggleOffset = 0

---@private
---@type tes3itemStack
this.item = nil

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
---@type nodeAnimatonKeyframe[]
this.startAnimationKeyFrames = nil

---@private
---@type nodeAnimatonKeyframe[]
this.cycleAnimationKeyFrames = nil

---@private
---@type tes3matrix33
this.rotationBuffer = tes3matrix33.new()

---@private
---@type nodeAnimator
this.nodeAnimator = nil

---@private
---@type timerManager
this.timerManager = nil

---@private
---@type enums
this.enums = nil

---@public
---@param services serviceCollection
---@return boolean,string|nil
function this.initialize(services)
	this.nodeAnimator = services.nodeAnimator
	this.timerManager = services.timerManager
	this.enums = services.enums

	local events = services.enums.events
	local constants = services.enums.constants.picks

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
		}
	}
	this.cycleAnimationKeyFrames = {
		{
			time = 0,
			translation = constants.translation.original,
			rotation = constants.rotation.original,
		},
		{
			time = constants.animation.cycleAnimationDuration,
			translation = constants.translation.target,
			rotation = constants.rotation.target,
		}
	}

	event.register(events.lockpickingStart, this.onLockpickingStart)
	event.register(events.lockpickingEnd, this.onLockpickingEnd)
	event.register(events.lockpickingEnded, this.onLockpickingEnded)
	event.register(events.pickCycled, this.onPickCycled)
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
	this.helper = e.session.pick.helper
	this.originalHelperRotation = e.session.pick.helper.rotation:copy()
	this.item = e.session.pick.item

	this.start(e.session.pick, this.startAnimationKeyFrames)
	this.enable()
end

---@private
---@param _ lockpickingEndEventData
function this.onLockpickingEnd(_)
	this.blocked = true
end

---@private
---@param _ lockpickingEndedEventData
function this.onLockpickingEnded(_)
	this.resetFields()
	this.disable()
end

---@private
---@param e pickCycledEventData
function this.onPickCycled(e)
	this.item = e.pick.item
	this.start(e.pick, this.cycleAnimationKeyFrames)
end

---@private
---@param _ rotationEventData
function this.onRotationStarted(_)
	this.blocked = true
end

---@private
---@param _ rotationEventData
function this.onRotationEnded(_)
	this.blocked = false
	this.jiggling = false
	this.jigglePhase = 0
	this.jiggleOffset = 0
end

---@private
function this.onCylinderBlocked()
	this.blocked = true
	this.jiggling = true
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
function this.resetFields()
	this.helper.rotation = this.originalHelperRotation:copy()
	this.helper:update()
	this.helper = nil

	this.mesh = nil
	this.item = nil
	this.blocked = false
	this.jiggling = false
	this.jigglePhase = 0
	this.jiggleOffset = 0
	this.originalHelperRotation = nil
	this.originalPickRotation = nil
	this.currentHelperAngle = 0
	this.targetHelperAngle = 0
end

---@private
---@param pick pick
---@param keyframes nodeAnimatonKeyframe[]
function this.start(pick, keyframes)
	this.mesh = pick.mesh
	this.blocked = true

	this.nodeAnimator.start({
		node = pick.mesh,
		keyframes = keyframes,
		cancelOn = { this.enums.events.lockpickingEnded, this.enums.events.pickCycled },
	})

	this.timerManager.start({
		durationInSeconds = keyframes[#keyframes].time,
		cancelOn = { this.enums.events.lockpickingEnded, this.enums.events.pickCycled },
		callback = this.onStartTimerFinished,
	})
end

---@private
---@param _ mwseTimerCallbackData
function this.onStartTimerFinished(_)
	this.blocked = false
	this.originalPickRotation = this.mesh.rotation:copy()
end

---@private
---@param e enterFrameEventData
function this.onEnterFrame(e)
	if this.paused then
		return
	end

	if this.jiggling then
		this.updateJiggle(e.delta)
		return
	end

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
	local transition = math.min(this.enums.constants.picks.animation.lerpSpeed * delta, 1)
	this.currentHelperAngle = math.lerp(this.currentHelperAngle, this.targetHelperAngle, transition)
end

---@private
---@return number
function this.computeJiggleAmplitude()
	local constants = this.enums.constants.picks
	local base = constants.animation.jiggleAmplitude
	if not this.item then
		return base
	end

	local itemData = this.item.variables and this.item.variables[1]
	if itemData then
		for _, variable in ipairs(this.item.variables) do
			if variable.condition < itemData.condition then
				itemData = variable
			end
		end
	end

	local conditionRatio = itemData and math.max(0, itemData.condition / this.item.object.maxCondition) or 1
	return base * (1 + constants.animation.jiggleDamageFactor * (1 - conditionRatio))
end

---@private
function this.updateJiggle(delta)
	local constants = this.enums.constants.picks
	this.jigglePhase = this.jigglePhase + constants.animation.jiggleSpeed * delta
	local wave = math.sin(this.jigglePhase) + math.sin(this.jigglePhase * 1.7 + 1.3) * constants.animation.jiggleNoise
	this.jiggleOffset = wave * this.computeJiggleAmplitude()
	this.rotateHelper()
	this.rotatePick()
end

---@private
function this.rotateHelper()
	this.rotationBuffer:toRotationY(this.currentHelperAngle + this.jiggleOffset)
	this.helper.rotation = this.rotationBuffer
	this.helper:update()
end

---@private
function this.rotatePick()
	this.rotationBuffer:toRotationY(this.currentHelperAngle + this.jiggleOffset)

	this.mesh.rotation = this.originalPickRotation * this.rotationBuffer
	this.mesh:update()
end

return this
