--- SERVICES
local TimerManager = require("tauer.modern-lockpicking.services.timers.TimerManager")
---

---@class MeshAnimator
local this = {}

---@public
---@param parameters meshAnimatorStartParameters
function this.Start(parameters)
	this.initializeTransforms(parameters.mesh, parameters.originalTranslation, parameters.originalRotation)
	TimerManager.Start({
		durationInSeconds = parameters.durationInSeconds,
		callback = this.onStartTimer,
		cancelOn = parameters.cancelOn or nil,
		---@type onMeshAnimatorTimerData
		data = {
			mesh = parameters.mesh,
			originalRotation = parameters.originalRotation,
			targetRotation = parameters.targetRotation,
			originalTranslation = parameters.originalTranslation,
			targetTranslation = parameters.targetTranslation,
		},
	})
end

function this.initializeTransforms(mesh, originalTranslation, originalRotation)
	mesh.translation = originalTranslation

	local rotation = tes3matrix33.new()
	rotation:fromEulerXYZ(originalRotation.x, originalRotation.y, originalRotation.z)

	mesh.rotation = rotation
	mesh:update()
end

---@private
---@param callback mwseTimerCallbackData
function this.onStartTimer(callback)
	local data = callback.timer.data --[[@as onMeshAnimatorTimerData]]
	local mesh = data.mesh

	local total = data.totalIterations --[[@as integer]]
	local iteration = (total - callback.timer.iterations)

	local transition = math.remap(iteration, 0, total, 0, 1)

	mesh.translation = this.getUpdatedTranslation(data.originalTranslation, data.targetTranslation, transition)
	mesh.rotation = this.getUpdatedRotation(data.originalRotation, data.targetRotation, transition)

	mesh:update()
end

---@private
---@param original tes3vector3
---@param target tes3vector3
---@param transition number
---@return tes3vector3
function this.getUpdatedTranslation(original, target, transition)
	return original:lerp(target, transition)
end

---@private
---@param original tes3vector3
---@param target tes3vector3
---@param transition number
---@return tes3matrix33
function this.getUpdatedRotation(original, target, transition)
	local euler = original:lerp(target, transition)

	local rotation = tes3matrix33.new()
	rotation:fromEulerXYZ(euler.x, euler.y, euler.z)

	return rotation
end

return this
