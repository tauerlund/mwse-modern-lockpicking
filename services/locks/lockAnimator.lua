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
	this.nodeAnimator = services.nodeAnimator
	this.timerManager = services.timerManager
	this.enums = services.enums

	local events = services.enums.events

	event.register(events.lockpickingStart, this.onLockpickingStart)
	event.register(events.lockpickingStarted, this.onLockpickingStarted)
	event.register(events.lockpickingEnded, this.onLockpickingEnded)
	event.register(events.optionsMenuOpened, this.onOptionsMenuOpened)
	event.register(events.optionsMenuClosed, this.onOptionsMenuClosed)

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

	this.nodeAnimator.start({
		node = lock.mesh,
		keyframes = {
			{
				time = 0,
				translation = lock.mesh.translation:copy(),
			},
			{
				time = 0.8,
				translation = this.getTargetTranslation(lock),
			}
		},
		cancelOn = { this.enums.events.lockpickingEnded }
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

	local targetRotX = ((cursor.y - this.startCursorY) / viewportHeight) * constants.amplitude
	local targetRotY = ((this.startCursorX - cursor.x) / viewportWidth) * constants.amplitude

	local t = math.min(1, constants.lerpSpeed * e.delta)
	this.currentRotX = currentRotX + (targetRotX - currentRotX) * t
	this.currentRotY = currentRotY + (targetRotY - currentRotY) * t

	-- X=right, Y=depth, Z=up in menuCamera space.
	-- Pitch (vertical mouse)   → rotate around X
	-- Yaw   (horizontal mouse) → rotate around Z
	this.rotationBufferX:toRotationX(this.currentRotX)
	this.rotationBufferY:toRotationZ(this.currentRotY)

	-- menuCamRot is identity (cameraRoot has no world rotation), so no change-of-basis needed.
	this.lock.mesh.rotation = this.rotationBufferX * this.rotationBufferY * this.initialRotation
	this.lock.mesh:update()
end

---@private
---@param lock lock
---@return tes3vector3
function this.getTargetTranslation(lock)
	return tes3vector3.new(0, this.enums.constants.locks.targetDistance, 0)
end

return this
