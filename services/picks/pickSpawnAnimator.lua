---@class pickSpawnAnimator : initializedService
local this = {}

---@private
---@type pick|nil
this.currentPick = nil

---@private
---@type pickOverrideResolver
this.pickOverrideResolver = nil

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
}

---@public
---@param services serviceCollection
---@return boolean,string|nil
function this.initialize(services)
	this.nodeAnimator = services.nodeAnimator
	this.timerManager = services.timerManager
	this.enums = services.enums
	this.eventRegistrar = services.eventRegistrar
	this.pickOverrideResolver = services.pickOverrideResolver

	local events = services.enums.events

	this.eventHandlers = {
		lifetime = {
			[events.lockpickingStart] = this.onLockpickingStart,
			[events.pickCycled] = this.onPickCycled,
			[events.lockpickingEnded] = this.onLockpickingEnded,
		},
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
	local constants = this.enums.constants.picks
	local keyframes = this.buildKeyframes(e.session.pick, constants.animation.startAnimationDuration)
	this.startAnimation(e.session.pick, keyframes)
end

---@private
---@param e pickCycledEventData
function this.onPickCycled(e)
	local constants = this.enums.constants.picks
	local keyframes = this.buildKeyframes(e.pick, constants.animation.cycleAnimationDuration)
	this.startAnimation(e.pick, keyframes)
end

---@private
---@param pick pick
---@param duration number
---@return nodeAnimatonKeyframe[]
function this.buildKeyframes(pick, duration)
	local override = this.pickOverrideResolver.resolve(pick.item.object.mesh)
	local constants = this.enums.constants.picks

	local depthRotation = tes3matrix33.new()
	depthRotation:fromEulerXYZ(
		override.rotationTarget.x,
		override.rotationTarget.y,
		override.rotationTarget.z
	)
	local depthVec = depthRotation * tes3vector3.new(0, override.depthOffset, 0)

	return {
		{
			time = 0,
			translation = constants.translation.original + depthVec,
			rotation = constants.rotation.original,
		},
		{
			time = duration,
			translation = override.translationTarget + depthVec,
			rotation = override.rotationTarget,
		},
	}
end

---@private
function this.onLockpickingEnded(_)
	this.currentPick = nil
end

---@private
---@param pick pick
---@param keyframes nodeAnimatonKeyframe[]
function this.startAnimation(pick, keyframes)
	this.currentPick = pick
	pick.animating = true

	local events = this.enums.events

	this.nodeAnimator.start({
		node = pick.mesh,
		keyframes = keyframes,
		cancelOn = { events.lockpickingEnded, events.pickCycled },
	})

	this.timerManager.start({
		durationInSeconds = keyframes[#keyframes].time,
		cancelOn = { events.lockpickingEnded, events.pickCycled },
		pauseOn = { events.optionsMenuOpened },
		resumeOn = { events.optionsMenuClosed },
		callback = this.onTimerFinished,
	})
end

---@private
---@param _ mwseTimerCallbackData
function this.onTimerFinished(_)
	if this.currentPick then
		this.currentPick.animating = false
		event.trigger(this.enums.events.pickSpawnFinished, { pick = this.currentPick })
	end
	this.currentPick = nil
end

return this
