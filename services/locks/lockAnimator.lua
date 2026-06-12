---@class lockAnimator : initializedService
local this = {}

---@private
---@type timerManager
this.timerManager = nil

---@private
---@type nodeAnimator
this.nodeAnimator = nil

---@private
---@type enums
this.enums = nil

---@private
---@type renderingStrategyController
this.renderingStrategyController = nil

---@private
---@type lockpickingSession|nil
this.session = nil

---@private
---@type lock|nil
this.lock = nil

---@private
---@type tes3matrix33|nil
this.initialRotation = nil

---@private
---@type number
this.currentPitch = 0

---@private
---@type number
this.currentYaw = 0

---@private
---@type number
this.startCursorX = 0

---@private
---@type number
this.startCursorY = 0

---@private
this.mouseConstants = {
	amplitude = 0.15,
	lerpSpeed = 5,
}

-- In menu camera space, pitch is a rotation around X and yaw around Z.
---@private
this.rotationBufferPitch = tes3matrix33.new()

---@private
this.rotationBufferYaw = tes3matrix33.new()

---@private
---@type eventRegistrar
this.eventRegistrar = nil

---@private
---@type eventHandlerGroups
this.eventHandlers = {
	lifetime = {},
	session = {}
}

---@public
---@param services serviceCollection
---@return boolean,string|nil
function this.initialize(services)
	this.nodeAnimator = services.nodeAnimator
	this.timerManager = services.timerManager
	this.enums = services.enums
	this.renderingStrategyController = services.renderingStrategyController
	this.eventRegistrar = services.eventRegistrar

	local events = services.enums.events

	this.eventHandlers = {
		lifetime = {
			[events.lockpickingStart] = this.onLockpickingStart,
			[events.lockpickingStarted] = this.onLockpickingStarted,
			[events.lockpickingEnded] = this.onLockpickingEnded,
			[events.renderingStrategyChanged] = this.onRenderingStrategyChanged,
			[events.settingsUpdated] = this.onSettingsUpdated,
		},
		session = {
			[tes3.event.enterFrame] = this.onEnterFrame,
		}
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
	local lock = e.session.lock

	this.nodeAnimator.start({
		node = lock.mesh,
		keyframes = {
			{
				time = 0,
				translation = lock.mesh.translation:copy(),
			},
			{
				time = 0.8,
				translation = this.getTargetTranslation(),
			}
		},
		cancelOn = { this.enums.events.lockpickingEnded }
	})
end

---@private
---@param e lockpickingStartedEventData
function this.onLockpickingStarted(e)
	this.session = e.session
	this.lock = e.session.lock
	this.initialRotation = e.session.lock.mesh.rotation:copy()
	this.currentPitch = 0
	this.currentYaw = 0

	local cursor = tes3.getCursorPosition()
	this.startCursorX = cursor.x
	this.startCursorY = cursor.y

	this.enable()
end

---@private
---@param _ lockpickingEndedEventData
function this.onLockpickingEnded(_)
	this.session = nil
	this.lock = nil
	this.initialRotation = nil
	this.currentPitch = 0
	this.currentYaw = 0

	this.disable()
end

---@private
function this.onRenderingStrategyChanged()
	this.applyTargetTranslation()
end

---@private
function this.onSettingsUpdated()
	this.applyTargetTranslation()
end

---@private
function this.applyTargetTranslation()
	if not this.lock then
		return
	end
	this.lock.mesh.translation = this.getTargetTranslation()
	this.lock.mesh:update()
end

---@private
function this.enable()
	this.eventRegistrar.register(this.eventHandlers.session)
end

---@private
function this.disable()
	this.eventRegistrar.unregister(this.eventHandlers.session)
end

---@private
---@param e enterFrameEventData
function this.onEnterFrame(e)
	if not this.lock or (this.session and this.session.paused) then
		return
	end

	local constants = this.mouseConstants

	local cursor = tes3.getCursorPosition()
	local viewportWidth, viewportHeight = tes3.getViewportSize()

	local currentPitch = this.currentPitch
	local currentYaw = this.currentYaw

	local targetPitch = ((cursor.y - this.startCursorY) / viewportHeight) * constants.amplitude
	local targetYaw = ((this.startCursorX - cursor.x) / viewportWidth) * constants.amplitude

	local t = math.min(1, constants.lerpSpeed * e.delta)
	this.currentPitch = math.lerp(currentPitch, targetPitch, t)
	this.currentYaw = math.lerp(currentYaw, targetYaw, t)

	this.rotationBufferPitch:toRotationX(this.currentPitch)
	this.rotationBufferYaw:toRotationZ(this.currentYaw)

	this.lock.mesh.rotation = this.rotationBufferPitch * this.rotationBufferYaw * this.initialRotation
	this.lock.mesh:update()
end

---@private
---@return tes3vector3
function this.getTargetTranslation()
	return tes3vector3.new(0, this.renderingStrategyController.getTargetDistance(), -2.5)
end

return this
