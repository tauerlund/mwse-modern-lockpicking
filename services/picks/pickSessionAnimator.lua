---@class pickSessionAnimator : initializedService
local this = {}

---@private
---@type pickSessionAnimatorState|nil
this.state = nil

---@private
this.rotationBuffer = tes3matrix33.new()

---@private
---@type enums
this.enums = nil

---@private
---@type renderingStrategyController
this.renderingStrategyController = nil

---@private
---@type lockpickingSession|nil
this.session = nil

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
	this.enums = services.enums
	this.renderingStrategyController = services.renderingStrategyController
	this.eventRegistrar = services.eventRegistrar

	local events = services.enums.events

	this.eventHandlers = {
		lifetime = {
			[events.lockpickingStart] = this.onLockpickingStart,
			[events.lockpickingEnd] = this.onLockpickingEnd,
			[events.lockpickingEnded] = this.onLockpickingEnded,
			[events.pickCycled] = this.onPickCycled,
			[events.pickSpawnFinished] = this.onPickSpawnFinished,
			[events.rotationStarted] = this.onRotationStarted,
			[events.rotationEnded] = this.onRotationEnded,
			[events.cylinderBlocked] = this.onCylinderBlocked,
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
---@param e lockpickingStartEventData
function this.onLockpickingStart(e)
	this.session = e.session
	this.state = {
		mesh = e.session.pick.mesh,
		helper = e.session.pick.helper,
		item = e.session.pick.item,
		originalHelperRotation = e.session.pick.helper.rotation:copy(),
		originalPickRotation = nil,
		currentHelperAngle = 0,
		targetHelperAngle = 0,
		blocked = true,
		jigglePhase = 0,
		jiggleOffset = 0,
	}
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
	this.session = nil
	this.disable()
end

---@private
---@param e pickCycledEventData
function this.onPickCycled(e)
	this.state.item = e.pick.item
	this.state.mesh = e.pick.mesh
	this.state.blocked = true
	this.state.jigglePhase = 0
	this.state.jiggleOffset = 0
end

---@private
---@param _ pickSpawnFinishedEventData
function this.onPickSpawnFinished(_)
	if not this.state then
		return
	end
	this.state.blocked = false
	this.state.originalPickRotation = this.state.mesh.rotation:copy()
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
	this.state.jigglePhase = 0
	this.state.jiggleOffset = 0
end

---@private
function this.onCylinderBlocked()
	this.state.blocked = true
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
	if not this.state or this.session.paused then
		return
	end

	local state = this.state --[[@as pickSessionAnimatorState]]

	local session = this.session

	if session and session.pick.damaging then
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

	local itemData = this.session.pick.itemData
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
