--- ENUMS
local EVENTS = require("tauer.modern-lockpicking.services.events.enums.EVENTS")
local CONSTANTS = require("tauer.modern-lockpicking.services.sounds.enums.CONSTANTS")
---

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
---@type integer
this.debounceInFrames = 3

---@private
---@type integer
this.frameCounter = 0

---@public
---@param services serviceCollection
---@return boolean,string|nil
function this.initialize(services)
	this.soundFileResolver = services.soundFileResolver

	event.register(EVENTS.lockpickingStart, this.onLockpickingStart)
	event.register(EVENTS.lockpickingEnd, this.onLockpickingEnd)
	event.register(EVENTS.pickCycled, this.onPickCycled)
	event.register(EVENTS.rotationStarted, this.onRotationStarted)
	event.register(EVENTS.rotationEnded, this.onRotationEnded)
	event.register(EVENTS.cylinderBlocked, this.onCylinderBlocked)
	event.register(EVENTS.pickBroken, this.onPickBroken)
	event.register(EVENTS.optionsMenuOpened, this.onOptionsMenuOpened)
	event.register(EVENTS.optionsMenuClosed, this.onOptionsMenuClosed)
	return true, nil
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
	tes3.playSound({
		reference = tes3.player,
		soundPath = this.soundFileResolver.resolve(CONSTANTS.templates.lockpickingStart).path,
	})
	this.lastCursorPosition = tes3.getCursorPosition().x

	if not event.isRegistered(tes3.event.enterFrame, this.onEnterFrame) then
		event.register(tes3.event.enterFrame, this.onEnterFrame)
	end
end

---@private
---@param e lockpickingEndEventData
function this.onLockpickingEnd(e)
	if e.success then
		tes3.playSound({
			reference = tes3.player,
			soundPath = this.soundFileResolver.resolve(CONSTANTS.templates.unlock).path,
		})
	end

	if event.isRegistered(tes3.event.enterFrame, this.onEnterFrame) then
		event.unregister(tes3.event.enterFrame, this.onEnterFrame)
	end
end

---@private
---@param _ pickCycledEventData
function this.onPickCycled(_)
	tes3.playSound({
		reference = tes3.player,
		soundPath = this.soundFileResolver.resolve(CONSTANTS.templates.changeLockpick).path,
	})
end

---@private
function this.onPickBroken()
	tes3.playSound({
		reference = tes3.player,
		soundPath = this.soundFileResolver.resolve(CONSTANTS.templates.breakLockpick).path,
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
---@param delta number
function this.playLockpickRotationSound(delta)
	local currentCursorPosition = tes3.getCursorPosition().x
	local moved = math.abs(currentCursorPosition - this.lastCursorPosition) > CONSTANTS.lockpickRotationMaxDelta
	this.playOnCooldown({
		state = this.lockpickRotationState,
		template = CONSTANTS.templates.rotateLockpick,
		delta = delta,
		condition = not this.rotatingCylinder and moved,
	})
	this.lastCursorPosition = currentCursorPosition
end

---@private
---@param delta number
function this.playCylinderRotationSound(delta)
	this.playOnCooldown({
		state = this.cylinderRotationState,
		template = CONSTANTS.templates.rotateCylinder,
		delta = delta,
		condition = this.rotatingCylinder,
	})
end

---@private
---@param delta number
function this.playJiggleSound(delta)
	this.playOnCooldown({
		state = this.jiggleState,
		template = CONSTANTS.templates.jiggleLockpick,
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
