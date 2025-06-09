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

	local currentPhase = callback.timer.iterations
	local targetPhase = data.totalIterations --[[@as integer]]

	mesh.translation = this.getUpdatedTranslation(currentPhase, targetPhase, data)
	mesh.rotation = this.getUpdatedRotation(currentPhase, targetPhase, data)

	mesh:update()
end

---@private
---@param currentPhase integer
---@param targetPhase integer
---@param data onMeshAnimatorTimerData
---@return tes3vector3
function this.getUpdatedTranslation(currentPhase, targetPhase, data)
	local original = data.originalTranslation
	local target = data.targetTranslation

	local translation = tes3vector3.new(
		math.remap(currentPhase, 0, targetPhase, target.x, original.x),
		math.remap(currentPhase, 0, targetPhase, target.y, original.y),
		math.remap(currentPhase, 0, targetPhase, target.z, original.z)
	)

	return translation
end

---@private
---@param currentPhase integer
---@param targetPhase integer
---@param data onMeshAnimatorTimerData
---@return tes3matrix33
function this.getUpdatedRotation(currentPhase, targetPhase, data)
	local initial = data.originalRotation
	local target = data.targetRotation

	local rotation = tes3matrix33.new()
	rotation:fromEulerXYZ(
		math.remap(currentPhase, 0, targetPhase, target.x, initial.x),
		math.remap(currentPhase, 0, targetPhase, target.y, initial.y),
		math.remap(currentPhase, 0, targetPhase, target.z, initial.z)
	)

	return rotation
end

return this
