--- SERVICES
local TimerHelper = require("tauer.modern-lockpicking.services.timers.TimerHelper")
---

--- ENUMS
local CONSTANTS = require("tauer.modern-lockpicking.services.knives.enums.constants")
---

---@class KnifeAnimator
local this = {}

---@public
---@param knife niNode
function this.Start(knife)
	this.initializeTransforms(knife)

	TimerHelper.Start({
		durationInSeconds = 1,
		callback = this.onStartTimer,
		---@type onStartKnifeAnimationData
		data = {
			knife = knife,
		},
	})
end

function this.initializeTransforms(knife)
	knife.translation = CONSTANTS.initialTranslation

	local rotation = tes3matrix33.new()
	rotation:fromEulerXYZ(CONSTANTS.initialRotation.x, CONSTANTS.initialRotation.y, CONSTANTS.initialRotation.z)

	knife.rotation = rotation
end

---@private
---@param callback mwseTimerCallbackData
function this.onStartTimer(callback)
	local data = callback.timer.data --[[@as onStartKnifeAnimationData]]
	local knife = data.knife

	local currentPhase = callback.timer.iterations
	local targetPhase = data.totalIterations --[[@as integer]]

	knife.translation = this.getUpdatedTranslation(currentPhase, targetPhase)
	knife.rotation = this.getUpdatedRotation(currentPhase, targetPhase)

	knife:update()
end

---@private
---@param currentPhase integer
---@param targetPhase integer
---@return tes3vector3
function this.getUpdatedTranslation(currentPhase, targetPhase)
	local initial = CONSTANTS.initialTranslation
	local target = CONSTANTS.targetTranslation

	local translation = tes3vector3.new(
		math.remap(currentPhase, 0, targetPhase, target.x, initial.x),
		math.remap(currentPhase, 0, targetPhase, target.y, initial.y),
		math.remap(currentPhase, 0, targetPhase, target.z, initial.z)
	)

	return translation
end

---@private
---@param currentPhase integer
---@param targetPhase integer
---@return tes3matrix33
function this.getUpdatedRotation(currentPhase, targetPhase)
	local initial = CONSTANTS.initialRotation
	local target = CONSTANTS.targetRotation

	local rotation = tes3matrix33.new()
	rotation:fromEulerXYZ(
		math.remap(currentPhase, 0, targetPhase, target.x, initial.x),
		math.remap(currentPhase, 0, targetPhase, target.y, initial.y),
		math.remap(currentPhase, 0, targetPhase, target.z, initial.z)
	)

	return rotation
end

return this
