---@class KnifeAnimator
local this = {}

---@private
---@type number
this.initialDistance = -60

---@private
---@type number
this.targetDistance = -16

---@private
---@type tes3vector3
this.initialRotation = tes3vector3.new(-0.68, -0.52, 0.60)

---@private
---@type tes3vector3
this.targetRotation = tes3vector3.new(-1.07, -1.23, 1.04)

---@private
---@type number
this.iterationTime = 0.005

---@private
---@type number
this.totalDurationInSeconds = 0.75

---@private
---@type number
this.iterations = math.floor(this.totalDurationInSeconds / this.iterationTime)

---@public
---@param knife niNode
function this.Play(knife)
	timer.start({
		type = timer.real,
		duration = this.iterationTime,
		iterations = this.iterations,
		callback = this.onPlayTimer,
		---@type onPlayTimerData
		data = {
			translation = knife.translation:copy(),
			direction = knife.rotation:getForwardVector():copy(),
			targetDistance = this.targetDistance,
			mesh = knife,
		},
	})
end

---@private
---@param callback mwseTimerCallbackData
function this.onPlayTimer(callback)
	local data = callback.timer.data --[[@as onPlayTimerData]]
	local knife = data.mesh

	knife.translation = this.getUpdatedTranslation(data.direction, data.translation, callback.timer.iterations)
	knife.rotation = this.getUpdatedRotation(callback.timer.iterations)
	knife:update()
end

---@private
---@param direction tes3vector3
---@param position tes3vector3
---@param iterations number
---@return tes3vector3
function this.getUpdatedTranslation(direction, position, iterations)
	local distance = this.getUpdatedDistance(iterations)
	local forward = direction:normalized() * distance

	return position + forward
end

---@private
---@param iteration number
---@return tes3matrix33
function this.getUpdatedRotation(iteration)
	local rotation = tes3matrix33.new()
	rotation:fromEulerXYZ(
		math.remap(iteration, 0, this.iterations, this.targetRotation.x, this.initialRotation.x),
		math.remap(iteration, 0, this.iterations, this.targetRotation.y, this.initialRotation.y),
		math.remap(iteration, 0, this.iterations, this.targetRotation.z, this.initialRotation.z)
	)

	return rotation
end

---@private
---@param iteration number
---@return number
function this.getUpdatedDistance(iteration)
	return math.remap(iteration, 0, this.iterations, this.targetDistance, this.initialDistance)
end

return this
