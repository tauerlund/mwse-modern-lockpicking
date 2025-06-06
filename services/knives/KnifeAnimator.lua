local constants = require("tauer.modern-lockpicking.services.knives.enums.constants")

---@class KnifeAnimator
local this = {}

---@private
---@type number
this.iterationTime = 0.005

---@private
---@type number
this.totalDurationInSeconds = 1

---@private
---@type number
this.iterations = math.floor(this.totalDurationInSeconds / this.iterationTime)

---@public
---@param knife niNode
function this.Play(knife)
	this.initializeTransforms(knife)
	timer.start({
		type = timer.real,
		duration = this.iterationTime,
		iterations = this.iterations,
		callback = this.onPlayTimer,
		---@type onPlayTimerData
		data = {
			mesh = knife,
		},
	})
end

function this.initializeTransforms(knife)
	knife.translation = constants.initialTranslation

	local rotation = tes3matrix33.new()
	rotation:fromEulerXYZ(constants.initialRotation.x, constants.initialRotation.y, constants.initialRotation.z)
	knife.rotation = rotation
end

---@private
---@param callback mwseTimerCallbackData
function this.onPlayTimer(callback)
	local data = callback.timer.data --[[@as onPlayTimerData]]
	local knife = data.mesh

	knife.translation = this.getUpdatedTranslation(callback.timer.iterations)
	knife.rotation = this.getUpdatedRotation(callback.timer.iterations)
	knife:update()
end

---@private
---@param iterations number
---@return tes3vector3
function this.getUpdatedTranslation(iterations)
	local translation = tes3vector3.new(
		math.remap(iterations, 0, this.iterations, constants.targetTranslation.x, constants.initialTranslation.x),
		math.remap(iterations, 0, this.iterations, constants.targetTranslation.y, constants.initialTranslation.y),
		math.remap(iterations, 0, this.iterations, constants.targetTranslation.z, constants.initialTranslation.z)
	)
	return translation
end

---@private
---@param iteration number
---@return tes3matrix33
function this.getUpdatedRotation(iteration)
	local rotation = tes3matrix33.new()
	rotation:fromEulerXYZ(
		math.remap(iteration, 0, this.iterations, constants.targetRotation.x, constants.initialRotation.x),
		math.remap(iteration, 0, this.iterations, constants.targetRotation.y, constants.initialRotation.y),
		math.remap(iteration, 0, this.iterations, constants.targetRotation.z, constants.initialRotation.z)
	)

	return rotation
end

return this
