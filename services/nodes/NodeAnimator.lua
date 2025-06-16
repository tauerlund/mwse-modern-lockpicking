--- SERVICES
local TimerManager = require("tauer.modern-lockpicking.services.timers.TimerManager")
---

---@class NodeAnimator
local this = {}

---@public
---@param parameters meshAnimatorStartParameters
function this.Start(parameters)
	local keyFramesLength = #parameters.keyframes
	if keyFramesLength < 2 then
		return
	end

	local firstKeyframe = parameters.keyframes[1]
	local lastKeyframe = parameters.keyframes[keyFramesLength]

	this.initializeTransforms(parameters.node, firstKeyframe.translation, firstKeyframe.rotation)
	TimerManager.Start({
		durationInSeconds = lastKeyframe.time,
		callback = this.onStartTimer,
		cancelOn = parameters.cancelOn or nil,
		---@type onMeshAnimatorTimerData
		data = {
			node = parameters.node,
			keyframes = parameters.keyframes,
			currentFrame = 1,
			currentPhase = 0,
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
	data.currentPhase = data.currentPhase + callback.timer.duration

	local currentFrame = data.currentFrame
	local nextFrame = data.currentFrame + 1

	if data.keyframes[nextFrame] then
		if data.currentPhase >= data.keyframes[nextFrame].time then
			data.currentFrame = nextFrame
		end
	else
		return
	end

	local currentTransform = data.keyframes[currentFrame]
	local nextTransform = data.keyframes[nextFrame]

	local node = data.node
	local transition = math.remap(data.currentPhase, currentTransform.time, nextTransform.time, 0, 1)

	node.translation = this.getUpdatedTranslation(currentTransform.translation, nextTransform.translation,
		transition)
	node.rotation = this.getUpdatedRotation(currentTransform.rotation, nextTransform.rotation, transition)

	node:update()
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
