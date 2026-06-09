---@class soundController : initializedService
local this = {}

---@private
---@type number
this.lastCursorPosition = 0

---@private
---@type boolean
this.rotatingCylinder = false

---@private
---@type boolean
this.jiggling = false

---@private
---@type soundCooldownState
this.lockpickRotationState = { counter = 0, cooldown = 0 }

---@private
---@type soundCooldownState
this.cylinderRotationState = { counter = 0, cooldown = 0 }

---@private
---@type soundCooldownState
this.jiggleState = { counter = 0, cooldown = 0 }

---@private
---@type boolean
this.paused = false

---@private
---@type soundFileResolver
this.soundFileResolver = nil

---@private
---@type enums
this.enums = nil

---@private
---@type renderingStrategyController
this.renderingStrategyController = nil

---@private
---@type niNode|nil
this.pickHelper = nil

---@private
---@type integer
this.debounceInFrames = 3

---@private
---@type integer
this.frameCounter = 0

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
	this.soundFileResolver = services.soundFileResolver
	this.enums = services.enums
	this.eventRegistrar = services.eventRegistrar
	this.renderingStrategyController = services.renderingStrategyController

	local events = services.enums.events

	this.eventHandlers = {
		lifetime = {
			[events.lockpickingStart] = this.onLockpickingStart,
			[events.lockpickingStarted] = this.onLockpickingStarted,
			[events.lockpickingEnd] = this.onLockpickingEnd,
			[events.lockpickingEnded] = this.onLockpickingEnded,
			[events.pickCycled] = this.onPickCycled,
			[events.rotationStarted] = this.onRotationStarted,
			[events.rotationEnded] = this.onRotationEnded,
			[events.cylinderBlocked] = this.onCylinderBlocked,
			[events.pickBroken] = this.onPickBroken,
			[events.optionsMenuOpened] = this.onOptionsMenuOpened,
			[events.optionsMenuClosed] = this.onOptionsMenuClosed,
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
function this.onOptionsMenuOpened()
	this.paused = true
end

---@private
function this.onOptionsMenuClosed()
	this.paused = false
end

---@private
---@param _ lockpickingStartEventData
function this.onLockpickingStart(_)
	local constants = this.enums.constants.sounds
	tes3.playSound({
		reference = tes3.player,
		soundPath = this.soundFileResolver.resolve(constants.templates.lockpickingStart).path,
	})
	this.lastCursorPosition = tes3.getCursorPosition().x
	this.enable()
end

---@private
---@param e lockpickingStartedEventData
function this.onLockpickingStarted(e)
	this.pickHelper = e.session.pick.helper
end

---@private
---@param e lockpickingEndEventData
function this.onLockpickingEnd(e)
	local constants = this.enums.constants.sounds
	if e.success then
		tes3.playSound({
			reference = tes3.player,
			soundPath = this.soundFileResolver.resolve(constants.templates.unlock).path,
		})
	end

	this.pickHelper = nil
	this.rotatingCylinder = false
	this.jiggling = false
	this.disable()
end

---@private
---@param _ lockpickingEndedEventData
function this.onLockpickingEnded(_)
	this.pickHelper = nil
	this.rotatingCylinder = false
	this.jiggling = false
	this.disable()
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
---@param e pickCycledEventData
function this.onPickCycled(e)
	this.pickHelper = e.pick.helper
	tes3.playSound({
		reference = tes3.player,
		soundPath = this.soundFileResolver.resolve(this.enums.constants.sounds.templates.changeLockpick).path,
	})
end

---@private
function this.onPickBroken()
	tes3.playSound({
		reference = tes3.player,
		soundPath = this.soundFileResolver.resolve(this.enums.constants.sounds.templates.breakLockpick).path,
	})
end

---@private
---@param e enterFrameEventData
function this.onEnterFrame(e)
	if this.paused then
		return
	end

	this.frameCounter = (this.frameCounter + 1) % this.debounceInFrames
	if this.frameCounter ~= 0 then
		return
	end

	this.playLockpickRotationSound(e.delta)
	this.playCylinderRotationSound(e.delta)
	this.playJiggleSound(e.delta)
end

---@private
---@return boolean
function this.isInRotationZone()
	if not this.pickHelper then
		return false
	end
	local cursor = tes3.getCursorPosition()
	local screenPoint = this.renderingStrategyController
		.getNiCamera()
		:worldPointToScreenPoint(this.pickHelper.worldTransform.translation)
	return screenPoint ~= nil and cursor.y > screenPoint.y
end

---@private
---@param delta number
function this.playLockpickRotationSound(delta)
	local constants = this.enums.constants.sounds
	local currentCursorPosition = tes3.getCursorPosition().x
	local moved = math.abs(currentCursorPosition - this.lastCursorPosition) > constants.lockpickRotationMaxDelta
	this.playOnCooldown({
		state = this.lockpickRotationState,
		template = constants.templates.rotateLockpick,
		delta = delta,
		condition = not this.rotatingCylinder and moved and this.isInRotationZone(),
	})
	this.lastCursorPosition = currentCursorPosition
end

---@private
---@param delta number
function this.playCylinderRotationSound(delta)
	this.playOnCooldown({
		state = this.cylinderRotationState,
		template = this.enums.constants.sounds.templates.rotateCylinder,
		delta = delta,
		condition = this.rotatingCylinder,
	})
end

---@private
---@param delta number
function this.playJiggleSound(delta)
	this.playOnCooldown({
		state = this.jiggleState,
		template = this.enums.constants.sounds.templates.jiggleLockpick,
		delta = delta,
		condition = this.jiggling,
	})
end

---@private
---@param e soundController.playOnCooldown.params
function this.playOnCooldown(e)
	if e.condition and e.state.counter >= e.state.cooldown then
		local soundFile = this.soundFileResolver.resolve(e.template)
		tes3.playSound({ reference = tes3.player, soundPath = soundFile.path })
		e.state.counter = 0
		e.state.cooldown = soundFile.duration
	end
	e.state.counter = e.state.counter + (e.delta * this.debounceInFrames)
end

---@private
---@param _ rotationEventData
function this.onRotationStarted(_)
	this.rotatingCylinder = true
end

---@private
---@param _ rotationEventData
function this.onRotationEnded(_)
	this.rotatingCylinder = false
	this.jiggling = false
end

---@private
function this.onCylinderBlocked()
	this.rotatingCylinder = false
	this.jiggling = true
	this.jiggleState.counter = 0
	this.jiggleState.cooldown = 0
end

return this
