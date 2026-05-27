--- SERVICES
local soundFileResolver = require("tauer.modern-lockpicking.services.sounds.soundFileResolver")
---

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
---@type number
this.lockpickRotationTimeCounter = 0

---@private
---@type number
this.cylinderRotationTimeCounter = 0

---@private
---@type boolean
this.isRotatingCylinder = false

---@private
---@type number
this.lockpickRotationTimeCooldown = 0

---@private
---@type number
this.cylinderRotationTimeCooldown = 0

---@public
---@return boolean,string|nil
function this.initialize()
	this.registerEvents()
	return true, nil
end

---@private
---@param _ lockpickingStartEventData
function this.onLockpickingStart(_)
	tes3.playSound({
		reference = tes3.player,
		soundPath = soundFileResolver.resolve(CONSTANTS.templates.lockpickingStart).path,
	})
	this.lastCursorPosition = tes3.getCursorPosition().x

	event.register(tes3.event.enterFrame, this.onEnterFrame)
end

---@private
---@param e lockpickingEndEventData
function this.onLockpickingEnd(e)
	if e.success then
		tes3.playSound({
			reference = tes3.player,
			soundPath = soundFileResolver.resolve(CONSTANTS.templates.unlock).path,
		})
	end

	event.unregister(tes3.event.enterFrame, this.onEnterFrame)
end

---@private
---@param _ pickCycledEventData
function this.onPickChange(_)
	tes3.playSound({
		reference = tes3.player,
		soundPath = soundFileResolver.resolve(CONSTANTS.templates.changeLockpick).path,
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

	if math.abs(cursorPositionDelta) > CONSTANTS.lockpickRotationMaxDelta and this.lockpickRotationTimeCounter >= this.lockpickRotationTimeCooldown then
		local soundFile = soundFileResolver.resolve(CONSTANTS.templates.rotateLockpick)
		tes3.playSound({
			reference = tes3.player,
			soundPath = soundFile.path,
		})
		this.lockpickRotationTimeCooldown = soundFile.duration
		this.lastCursorPosition = currentCursorPosition
		this.lockpickRotationTimeCounter = 0
	end

	this.lockpickRotationTimeCounter = this.lockpickRotationTimeCounter + delta
	this.lastCursorPosition = currentCursorPosition
end

---@private
---@param delta number
function this.playCylinderRotationSound(delta)
	if this.isRotatingCylinder and this.cylinderRotationTimeCounter >= this.cylinderRotationTimeCooldown then
		local soundFile = soundFileResolver.resolve(CONSTANTS.templates.rotateCylinder)
		tes3.playSound({
			reference = tes3.player,
			soundPath = soundFile.path,
		})
		this.cylinderRotationTimeCounter = 0
		this.cylinderRotationTimeCooldown = soundFile.duration
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
