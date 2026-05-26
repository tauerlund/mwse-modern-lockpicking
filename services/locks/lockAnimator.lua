--- SERVICES
local timerManager = require("tauer.modern-lockpicking.services.timers.timerManager")
---

--- ENUMS
local EVENTS = require("tauer.modern-lockpicking.services.events.enums.EVENTS")
local CONSTANTS = require("tauer.modern-lockpicking.services.locks.enums.CONSTANTS")
---

---@class lockAnimator : initializedService
local this = {}

---@public
---@return boolean,string|nil
function this.initialize()
	event.register(EVENTS.lockpickingStart, this.onLockpickingStart)
	return true, nil
end

---@private
---@param lock lock
function this.start(lock)
	timerManager.start({
		durationInSeconds = 0.8,
		callback = this.onStartTimer,
		cancelOn = EVENTS.lockpickingEnded,
		---@type onStartLockAnimationData
		data = {
			mesh = lock.mesh,
			initialTranslation = lock.mesh.translation:copy(),
			targetTranslation = this.getTargetTranslation(lock),
		},
	})
end

---@private
---@param lock lock
---@return tes3vector3
function this.getTargetTranslation(lock)
	local direction = tes3.getCameraVector()
	local forward = direction:normalized() * CONSTANTS.targetDistance

	local translation = lock.mesh.translation + forward

	return translation
end

---@private
---@param callback mwseTimerCallbackData
function this.onStartTimer(callback)
	local data = callback.timer.data --[[@as onStartLockAnimationData]]
	local lock = data.mesh

	local initialTranslation = data.initialTranslation
	local targetTranslation = data.targetTranslation

	local currentPhase = callback.timer.iterations
	local targetPhase = data.totalIterations

	lock.translation = this.getUpdatedTranslation(currentPhase, targetPhase, initialTranslation, targetTranslation)
	lock:update()
end

---@private
---@param e lockpickingStartEventData
function this.onLockpickingStart(e)
	this.start(e.lock)
end

function this.getUpdatedTranslation(currentPhase, targetPhase, initialTranslation, targetTranslation)
	return tes3vector3.new(
		math.remap(currentPhase, 0, targetPhase, targetTranslation.x, initialTranslation.x),
		math.remap(currentPhase, 0, targetPhase, targetTranslation.y, initialTranslation.y),
		math.remap(currentPhase, 0, targetPhase, targetTranslation.z, initialTranslation.z)
	)
end

return this
