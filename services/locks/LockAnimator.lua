--- SERVICES
local TimerManager = require("tauer.modern-lockpicking.services.timers.TimerManager")
---

--- ENUMS
local CONSTANTS = require("tauer.modern-lockpicking.services.locks.enums.constants")
---

---@class LockAnimator
local this = {}

---@public
---@param lock lock
function this.Start(lock)
	TimerManager.Start({
		durationInSeconds = 0.8,
		callback = this.onStartTimer,
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

	return lock.mesh.translation + forward
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

function this.getUpdatedTranslation(currentPhase, targetPhase, initialTranslation, targetTranslation)
	return tes3vector3.new(
		math.remap(currentPhase, 0, targetPhase, targetTranslation.x, initialTranslation.x),
		math.remap(currentPhase, 0, targetPhase, targetTranslation.y, initialTranslation.y),
		math.remap(currentPhase, 0, targetPhase, targetTranslation.z, initialTranslation.z)
	)
end

return this
