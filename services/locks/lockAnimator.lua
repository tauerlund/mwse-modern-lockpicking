--- ENUMS
local EVENTS = require("tauer.modern-lockpicking.services.events.enums.EVENTS")
local CONSTANTS = require("tauer.modern-lockpicking.services.locks.enums.constants")
---

---@class lockAnimator : initializedService
local this = {}

---@private
---@type timerManager
this.timerManager = nil

---@private
---@type lock|nil
this.lock = nil

---@private
---@type tes3matrix33|nil
this.initialRotation = nil

---@private
---@type number
this.currentRotX = 0

---@private
---@type number
this.currentRotY = 0

---@private
---@type number
this.startCursorX = 0

---@private
---@type number
this.startCursorY = 0

---@private
---@type boolean
this.paused = false

---@private
this.mouseConstants = {
	amplitude = 0.15,
	lerpSpeed = 5,
}

---@private
---@type tes3matrix33
this.rotationBufferX = tes3matrix33.new()

---@private
---@type tes3matrix33
this.rotationBufferY = tes3matrix33.new()

---@public
---@param services serviceCollection
---@return boolean,string|nil
function this.initialize(services)
	this.timerManager = services.timerManager

	event.register(EVENTS.lockpickingStart, this.onLockpickingStart)
	event.register(EVENTS.lockpickingStarted, this.onLockpickingStarted)
	event.register(EVENTS.lockpickingEnded, this.onLockpickingEnded)
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
---@param e lockpickingStartEventData
function this.onLockpickingStart(e)
	local lock = e.session.lock

	this.timerManager.start({
		durationInSeconds = 0.8,
		callback = this.onStartTimer,
		cancelOn = EVENTS.lockpickingEnded,
		---@type onStartLockAnimationData
		data = {
			mesh = lock.mesh,
			initialTranslation = lock.mesh.translation:copy(),
			targetTranslation = this.getTargetTranslation(lock),
		},
	})
end

---@private
---@param e lockpickingStartedEventData
function this.onLockpickingStarted(e)
	this.lock = e.session.lock
	this.initialRotation = e.session.lock.mesh.rotation:copy()
	this.currentRotX = 0
	this.currentRotY = 0
	local cursor = tes3.getCursorPosition()
	this.startCursorX = cursor.x
	this.startCursorY = cursor.y
	this.enable()
end

---@private
---@param _ lockpickingEndedEventData
function this.onLockpickingEnded(_)
	this.lock = nil
	this.initialRotation = nil
	this.currentRotX = 0
	this.currentRotY = 0
	this.disable()
end

---@private
function this.enable()
	if not event.isRegistered(tes3.event.enterFrame, this.onEnterFrame) then
		event.register(tes3.event.enterFrame, this.onEnterFrame)
	end
end

---@private
function this.disable()
	if event.isRegistered(tes3.event.enterFrame, this.onEnterFrame) then
		event.unregister(tes3.event.enterFrame, this.onEnterFrame)
	end
end

---@private
---@param e enterFrameEventData
function this.onEnterFrame(e)
	if this.paused or not this.lock then
		return
	end

	local constants = this.mouseConstants

	local cursor = tes3.getCursorPosition()
	local viewportWidth, viewportHeight = tes3.getViewportSize()

	local currentRotX = this.currentRotX
	local currentRotY = this.currentRotY

	local targetRotX = ((this.startCursorY - cursor.y) / viewportHeight) * constants.amplitude
	local targetRotY = ((cursor.x - this.startCursorX) / viewportWidth) * constants.amplitude

	local t = math.min(1, constants.lerpSpeed * e.delta)
	this.currentRotX = currentRotX + (targetRotX - currentRotX) * t
	this.currentRotY = currentRotY + (targetRotY - currentRotY) * t

	this.rotationBufferX:toRotationX(this.currentRotX)
	this.rotationBufferY:toRotationY(this.currentRotY)

	this.lock.mesh.rotation = this.rotationBufferX * this.rotationBufferY * this.initialRotation
	this.lock.mesh:update()
end

---@private
---@param lock lock
---@return tes3vector3
function this.getTargetTranslation(lock)
	local direction = tes3.getCameraVector()
	local forward = direction:normalized() * CONSTANTS.targetDistance

	local translation = lock.mesh.translation + forward

	return translation
end

---@private
---@param callback mwseTimerCallbackData
function this.onStartTimer(callback)
	local data = callback.timer.data --[[@as onStartLockAnimationData]]
	local lock = data.mesh

	local initialTranslation = data.initialTranslation
	local targetTranslation = data.targetTranslation

	local currentPhase = callback.timer.iterations
	local targetPhase = data.totalIterations

	lock.translation = this.getUpdatedTranslation(currentPhase, targetPhase, initialTranslation, targetTranslation)
	lock:update()
end

function this.getUpdatedTranslation(currentPhase, targetPhase, initialTranslation, targetTranslation)
	return tes3vector3.new(
		math.remap(currentPhase, 0, targetPhase, targetTranslation.x, initialTranslation.x),
		math.remap(currentPhase, 0, targetPhase, targetTranslation.y, initialTranslation.y),
		math.remap(currentPhase, 0, targetPhase, targetTranslation.z, initialTranslation.z)
	)
end

return this
