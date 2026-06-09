---@class pickSessionAnimator : initializedService
local this = {}

---@private
---@type pickSessionAnimatorState|nil
this.state = nil

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
---@type renderingStrategyController
this.renderingStrategyController = nil

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
	this.renderingStrategyController = services.renderingStrategyController
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
	this.state = {
		mesh = e.session.pick.mesh,
		helper = e.session.pick.helper,
		item = e.session.pick.item,
		originalHelperRotation = e.session.pick.helper.rotation:copy(),
		originalPickRotation = nil,
		currentHelperAngle = 0,
		targetHelperAngle = 0,
		blocked = true,
		jiggling = false,
		jigglePhase = 0,
		jiggleOffset = 0,
	}
	this.start(e.session.pick, this.startAnimationKeyFrames)
	this.enable()
end

---@private
---@param _ lockpickingEndEventData
function this.onLockpickingEnd(_)
	this.state.blocked = true
end

---@private
---@param _ lockpickingEndedEventData
function this.onLockpickingEnded(_)
	if this.state then
		this.state.helper.rotation = this.state.originalHelperRotation:copy()
		this.state.helper:update()
		this.state = nil
	end
	this.disable()
end

---@private
---@param e pickCycledEventData
function this.onPickCycled(e)
	this.state.item = e.pick.item
	this.start(e.pick, this.cycleAnimationKeyFrames)
end

---@private
---@param _ rotationEventData
function this.onRotationStarted(_)
	this.state.blocked = true
end

---@private
---@param _ rotationEventData
function this.onRotationEnded(_)
	this.state.blocked = false
	this.state.jiggling = false
	this.state.jigglePhase = 0
	this.state.jiggleOffset = 0
end

---@private
function this.onCylinderBlocked()
	this.state.blocked = true
	this.state.jiggling = true
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
---@param pick pick
---@param keyframes nodeAnimatonKeyframe[]
function this.start(pick, keyframes)
	this.state.mesh = pick.mesh
	this.state.blocked = true

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
	this.state.blocked = false
	this.state.originalPickRotation = this.state.mesh.rotation:copy()
end

---@private
---@param e enterFrameEventData
function this.onEnterFrame(e)
	if this.paused or not this.state then
		return
	end

	local state = this.state
	if not state then
		return
	end

	if state.jiggling then
		this.updateJiggle(e.delta)
		return
	end

	if state.blocked then
		return
	end

	local cursor = tes3.getCursorPosition()

	local screenPoint = this.renderingStrategyController
		.getNiCamera()
		:worldPointToScreenPoint(state.helper.worldTransform.translation)

	if not screenPoint then
		return
	end

	if cursor.y > screenPoint.y then
		local relX = cursor.x - screenPoint.x
		local relY = cursor.y - screenPoint.y
		local len = math.sqrt(relX * relX + relY * relY)
		if len > 0 then
			state.targetHelperAngle = -(relX / len) * math.rad(90)
		end
	end

	this.updateAngle(e.delta)
	this.rotateHelper()
	this.rotatePick()
end

---@private
---@param delta number
function this.updateAngle(delta)
	local state = this.state --[[@as pickSessionAnimatorState]]
	local transition = math.min(this.enums.constants.picks.animation.lerpSpeed * delta, 1)
	state.currentHelperAngle = math.lerp(state.currentHelperAngle, state.targetHelperAngle, transition)
end

---@private
---@return number
function this.computeJiggleAmplitude()
	local state = this.state --[[@as pickSessionAnimatorState]]
	local constants = this.enums.constants.picks
	local base = constants.animation.jiggleAmplitude

	if not state.item then
		return base
	end

	local itemData = state.item.variables and state.item.variables[1]
	if itemData then
		for _, variable in ipairs(state.item.variables) do
			if variable.condition < itemData.condition then
				itemData = variable
			end
		end
	end

	local conditionRatio = itemData and math.max(0, itemData.condition / state.item.object.maxCondition) or 1
	return base * (1 + constants.animation.jiggleDamageFactor * (1 - conditionRatio))
end

---@private
---@param delta number
function this.updateJiggle(delta)
	local state = this.state --[[@as pickSessionAnimatorState]]

	local constants = this.enums.constants.picks
	state.jigglePhase = state.jigglePhase + constants.animation.jiggleSpeed * delta

	local wave = math.sin(state.jigglePhase) + math.sin(state.jigglePhase * 1.7 + 1.3) * constants.animation.jiggleNoise
	state.jiggleOffset = wave * this.computeJiggleAmplitude()

	this.rotateHelper()
	this.rotatePick()
end

---@private
function this.rotateHelper()
	local state = this.state --[[@as pickSessionAnimatorState]]

	this.rotationBuffer:toRotationY(state.currentHelperAngle + state.jiggleOffset)

	state.helper.rotation = this.rotationBuffer
	state.helper:update()
end

---@private
function this.rotatePick()
	local state = this.state --[[@as pickSessionAnimatorState]]

	this.rotationBuffer:toRotationY(state.currentHelperAngle + state.jiggleOffset)

	state.mesh.rotation = state.originalPickRotation * this.rotationBuffer
	state.mesh:update()
end

return this
