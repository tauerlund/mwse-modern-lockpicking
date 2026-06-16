---@class pickSpawnAnimator : initializedService
local this = {}

---@private
---@type pick|nil
this.currentPick = nil

---@private
---@type nodeAnimatonKeyframe[]
this.startAnimationKeyFrames = nil

---@private
---@type nodeAnimatonKeyframe[]
this.cycleAnimationKeyFrames = nil

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
	this.startAnimation(e.session.pick, this.startAnimationKeyFrames)
end

---@private
---@param e pickCycledEventData
function this.onPickCycled(e)
	this.startAnimation(e.pick, this.cycleAnimationKeyFrames)
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
