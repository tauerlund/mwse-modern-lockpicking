---@class pickAnimator : initializedService
local this = {}

---@private
---@type niNode
this.mesh = nil

---@private
---@type niNode
this.helper = nil

---@private
this.blocked = false

---@private
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
	this.nodeAnimator = services.nodeAnimator
	this.timerManager = services.timerManager
	this.enums = services.enums
	this.eventRegistrar = services.eventRegistrar

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

	this.eventHandlers = {
		lifetime = {
			[events.lockpickingStart] = this.onLockpickingStart,
			[events.lockpickingEnd] = this.onLockpickingEnd,
			[events.lockpickingEnded] = this.onLockpickingEnded,
			[events.pickCycled] = this.onPickCycled,
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
	this.eventRegistrar.register(this.eventHandlers.session)
end

---@private
function this.disable()
	this.eventRegistrar.unregister(this.eventHandlers.session)
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

	-- Lock mesh is in menuCamera space, so world-to-screen projection must use the menu camera.
	local menuCam = tes3.worldController.menuCamera.cameraData.camera
	local screenPoint = menuCam:worldPointToScreenPoint(this.helper.worldTransform.translation)

	if screenPoint and cursor.y > screenPoint.y then
		local relX = cursor.x - screenPoint.x
		local relY = cursor.y - screenPoint.y
		local len = math.sqrt(relX * relX + relY * relY)
		if len > 0 then
			this.targetHelperAngle = -(relX / len) * math.rad(90)
		end
	end

	this.updateAngle(e.delta)

	this.rotateHelper()
	this.rotatePick()
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
