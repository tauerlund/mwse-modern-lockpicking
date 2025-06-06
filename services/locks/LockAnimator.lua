local events = require("tauer.modern-lockpicking.shared.enums.event")

---@class LockAnimator
local this = {}

---@private
---@type lock
this.lock = nil

---@private
---@type number
this.phase = 0

---@private
---@type number
this.rotateSpeed = 1.5

---@private
---@type number
this.resetSpeed = 1.8

---@public
---@param lock lock
function this.Play(lock)
	this.lock = lock

	timer.start({
		type = timer.real,
		duration = 0.005,
		iterations = 80,
		callback = this.onPlayTimer,
		---@type onPlayTimerData
		data = {
			translation = tes3.getCameraPosition():copy(),
			direction = tes3.getCameraVector():copy(),
			targetDistance = 75,
			mesh = lock.mesh,
		},
	})

	this.registerEvents()
end

---@private
---@param callback mwseTimerCallbackData
function this.onPlayTimer(callback)
	local data = callback.timer.data --[[@as onPlayTimerData]]

	local distance = data.targetDistance - callback.timer.iterations
	local forward = data.direction:normalized() * distance

	local mesh = this.lock.mesh

	mesh.translation = data.translation + forward
	mesh:update()
end

function this.registerEvents()
	event.register(tes3.event.enterFrame, this.onEnterFrame)
	event.register(events.lockpickingEnded, this.onLockpickingEnded, { doOnce = true })
end

function this.unregisterEvents()
	if event.isRegistered(tes3.event.enterFrame, this.onEnterFrame) then
		event.unregister(tes3.event.enterFrame, this.onEnterFrame)
	end
end

---@private
---@param e enterFrameEventData
function this.onEnterFrame(e)
	local lock = this.lock

	if lock.blocked then
		return
	end

	local cylinder = lock.cylinder

	if not lock.rotatingLeft and not lock.rotatingRight then
		local rotation = cylinder.rotation:toEulerXYZ().y
		if math.isclose(rotation, 0, 0.04) then
			return
		end
		local multiplier = rotation <= 0 and 1 or -1
		this.updatePhase(multiplier, this.resetSpeed, e.delta)
	else
		local multiplier = lock.rotatingLeft and 1 or -1
		this.updatePhase(multiplier, this.rotateSpeed, e.delta)
	end

	this.rotateCylinder(this.phase)
end

---@private
---@param multiplier number
---@param speed number
---@param delta number
function this.updatePhase(multiplier, speed, delta)
	this.phase = this.phase + (multiplier * speed * delta)
end

---@private
---@param value number
function this.rotateCylinder(value)
	local cylinder = this.lock.cylinder

	local rotation = cylinder.rotation:copy()
	rotation:toRotationY(value)

	cylinder.rotation = rotation
	cylinder:update()
end

---@private
---@param _ lockpickingEndedEventData
function this.onLockpickingEnded(_)
	this.lock = nil
	this.phase = 0
	this.unregisterEvents()
end

return this
