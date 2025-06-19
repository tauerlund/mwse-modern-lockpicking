local SoundFileResolver = require("tauer.modern-lockpicking.services.sounds.SoundFileResolver")

local EVENTS = require("tauer.modern-lockpicking.shared.enums.events")
local CONSTANTS = require("tauer.modern-lockpicking.services.sounds.enums.constants")

---@class SoundController : IInitializedService
local this = {}

---@private
---@type number
this.lastCursorPosition = 0

---@private
---@type number
this.lockpickRotationTimeCounter = 0

---@private
---@type number
this.cylinderRotationTimeCounter = 0

---@private
---@type boolean
this.isRotatingCylinder = false

---@public
function this.Initialize()
	this.registerEvents()
	return true
end

---@private
---@param _ lockpickingStartEventData
function this.onLockpickingStart(_)
	tes3.playSound({
		reference = tes3.player,
		soundPath = SoundFileResolver.Resolve(CONSTANTS.soundTemplates.lockpickingStart),
	})
	this.lastCursorPosition = tes3.getCursorPosition().x

	event.register(tes3.event.enterFrame, this.onEnterFrame)
end

---@private
---@param e lockpickingEndedEventData
function this.onLockpickingEnd(e)
	if e.success then
		tes3.playSound({
			reference = tes3.player,
			soundPath = SoundFileResolver.Resolve(CONSTANTS.soundTemplates.unlock),
		})
	end

	event.unregister(tes3.event.enterFrame, this.onEnterFrame)
end

---@private
---@param _ pickChangeEventData
function this.onPickChange(_)
	tes3.playSound({
		reference = tes3.player,
		soundPath = SoundFileResolver.Resolve(CONSTANTS.soundTemplates.changeLockpick),
	})
end

---@private
---@param e enterFrameEventData
function this.onEnterFrame(e)
	this.playLockpickRotationSound(e.delta)
	this.playCylinderRotationSound(e.delta)
end

---@private
---@param delta number
function this.playLockpickRotationSound(delta)
	local currentCursorPosition = tes3.getCursorPosition().x
	local cursorPositionDelta = currentCursorPosition - this.lastCursorPosition

	if math.abs(cursorPositionDelta) > CONSTANTS.lockpickRotationMaxDelta and this.lockpickRotationTimeCounter >= CONSTANTS.lockpickRotationSoundCountdown then
		this.lastCursorPosition = currentCursorPosition
		tes3.playSound({
			reference = tes3.player,
			soundPath = SoundFileResolver.Resolve(CONSTANTS.soundTemplates.rotateLockpick),
		})
		this.lockpickRotationTimeCounter = 0
	end

	this.lockpickRotationTimeCounter = this.lockpickRotationTimeCounter + delta
	this.lastCursorPosition = currentCursorPosition
end

---@private
---@param delta number
function this.playCylinderRotationSound(delta)
	if this.isRotatingCylinder and this.cylinderRotationTimeCounter >= CONSTANTS.cylinderRotationSoundCountdown then
		tes3.playSound({
			reference = tes3.player,
			soundPath = SoundFileResolver.Resolve(CONSTANTS.soundTemplates.rotateCylinder),
		})
		this.cylinderRotationTimeCounter = 0
	end

	this.cylinderRotationTimeCounter = this.cylinderRotationTimeCounter + delta
end

---@private
---@param _ rotationEventData
function this.onRotationStarted(_)
	this.isRotatingCylinder = true
end

---@private
---@param _ rotationEventData
function this.onRotationEnded(_)
	this.isRotatingCylinder = false
end

---@private
function this.registerEvents()
	event.register(EVENTS.lockpickingStart, this.onLockpickingStart)
	event.register(EVENTS.lockpickingEnd, this.onLockpickingEnd)
	event.register(EVENTS.pickChange, this.onPickChange)
	event.register(EVENTS.rotationStarted, this.onRotationStarted)
	event.register(EVENTS.rotationEnded, this.onRotationEnded)
end

return this
