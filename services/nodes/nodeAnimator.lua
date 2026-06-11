---@class nodeAnimator : initializedService
local this = {}

---@private
---@type eventRegistrar
this.eventRegistrar = nil

---@private
---@type nodeAnimation[]
this.animations = {}

---@private
---@type eventHandlers
this.eventHandlers = nil

---@private
this.paused = false

---@public
---@param services serviceCollection
---@return boolean,string|nil
function this.initialize(services)
	this.eventRegistrar = services.eventRegistrar

	local events = services.enums.events

	this.eventHandlers = {
		[tes3.event.enterFrame] = this.onEnterFrame,
		[events.optionsMenuOpened] = this.onMenuOpened,
		[events.optionsMenuClosed] = this.onMenuClosed,
	}

	return true, nil
end

---@public
---@param params nodeAnimator.start.params
function this.start(params)
	local keyFramesLength = #params.keyframes
	if keyFramesLength < 2 then
		return
	end

	local firstKeyframe = params.keyframes[1]
	local lastKeyframe = params.keyframes[keyFramesLength]

	this.initializeTransforms(params.node, firstKeyframe.translation, firstKeyframe.rotation)

	---@type nodeAnimation
	local animation = {
		node = params.node,
		keyframes = params.keyframes,
		cancellationEvents = params.cancelOn,
		duration = lastKeyframe.time,
		currentFrame = 1,
		phase = 0,
	}

	this.startAnimation(animation)
end

---@private
---@param mesh niNode
---@param originalTranslation tes3vector3?
---@param originalRotation tes3vector3?
function this.initializeTransforms(mesh, originalTranslation, originalRotation)
	if originalTranslation then
		mesh.translation = originalTranslation --[[@as tes3vector3]]
	end

	if originalRotation then
		local rotation = tes3matrix33.new()
		rotation:fromEulerXYZ(originalRotation.x, originalRotation.y, originalRotation.z)
		mesh.rotation = rotation
	end

	mesh:update()
end

---@private
---@param e enterFrameEventData
function this.onEnterFrame(e)
	if this.paused then
		return
	end

	for index = #this.animations, 1, -1 do
		this.update(index, this.animations[index], e.delta)
	end
end

---@private
---@param index integer
---@param animation nodeAnimation
---@param delta number
function this.update(index, animation, delta)
	animation.phase = animation.phase + delta

	local currentFrame = animation.currentFrame
	local nextFrame = animation.currentFrame + 1

	if animation.keyframes[nextFrame] then
		if animation.phase >= animation.keyframes[nextFrame].time then
			animation.currentFrame = nextFrame
		end
	else
		this.stopAnimation(index, true)
		return
	end

	local currentTransform = animation.keyframes[currentFrame]
	local nextTransform = animation.keyframes[nextFrame]

	local node = animation.node
	local transition = math.clamp(math.remap(animation.phase, currentTransform.time, nextTransform.time, 0, 1), 0, 1)

	if currentTransform.translation and nextTransform.translation then
		node.translation = this.getUpdatedTranslation(currentTransform.translation, nextTransform.translation,
			transition)
	end

	if currentTransform.rotation and nextTransform.rotation then
		node.rotation = this.getUpdatedRotation(currentTransform.rotation, nextTransform.rotation, transition)
	end

	node:update()
end

---@private
---@param animation nodeAnimation
function this.startAnimation(animation)
	table.insert(this.animations, animation)

	if animation.cancellationEvents then
		this.registerCancellationHandlers(animation)
	end

	this.enable()
end

---@private
---@param index integer
---@param snap boolean?
function this.stopAnimation(index, snap)
	local animation = this.animations[index]
	this.unregisterCancellationHandlers(animation)

	if snap then
		local lastKeyframe = animation.keyframes[#animation.keyframes]
		this.initializeTransforms(animation.node, lastKeyframe.translation, lastKeyframe.rotation)
	end

	table.remove(this.animations, index)
	if #this.animations == 0 then
		this.disable()
	end
end

---@private
---@param animation nodeAnimation
function this.registerCancellationHandlers(animation)
	animation.cancellationHandlers = {}

	for _, eventName in ipairs(animation.cancellationEvents) do
		local handler = function ()
			local index = table.find(this.animations, animation)
			if index then
				this.stopAnimation(index)
			end
		end

		animation.cancellationHandlers[eventName] = handler

		event.register(eventName, handler)
	end
end

---@private
---@param animation nodeAnimation
function this.unregisterCancellationHandlers(animation)
	if not animation.cancellationHandlers then
		return
	end
	for eventName, handler in pairs(animation.cancellationHandlers) do
		event.unregister(eventName, handler)
	end
	animation.cancellationHandlers = nil
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

---@private
function this.enable()
	this.eventRegistrar.register(this.eventHandlers)
end

---@private
function this.disable()
	this.eventRegistrar.unregister(this.eventHandlers)
end

---@private
function this.onMenuOpened()
	this.paused = true
end

---@private
function this.onMenuClosed()
	this.paused = false
end

return this
