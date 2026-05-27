--- SERVICES
local pickSelector = require("tauer.modern-lockpicking.services.picks.pickSelector")
local lockSpawner = require("tauer.modern-lockpicking.services.locks.lockSpawner")
local knifeSpawner = require("tauer.modern-lockpicking.services.knives.knifeSpawner")
local pickSpawner = require("tauer.modern-lockpicking.services.picks.pickSpawner")
local timerManager = require("tauer.modern-lockpicking.services.timers.timerManager")
local inventoryManager = require("tauer.modern-lockpicking.services.inventory.inventoryManager")
local translations = require("tauer.modern-lockpicking.services.translations.translations")
---

--- ENUMS
local CONSTANTS = require("tauer.modern-lockpicking.services.lockpicking.enums.CONSTANTS")
local EVENTS = require("tauer.modern-lockpicking.services.events.enums.EVENTS")
local TRANSLATION_KEY = require("tauer.modern-lockpicking.services.translations.enums.TRANSLATION_KEY")
---

---@class lockpickingController : initializedService
local this = {}

---@private
---@type lockpickingSession|nil
this.session = nil

---@public
---@return boolean,string|nil
function this.initialize()
	this.registerEvents()
	return true, nil
end

---@private
---@param e lockpickingActivatedEventData
function this.onLockPickingActivated(e)
	this.session = this.createSession(e.activator)
	if not this.session then
		return
	end

	---@type lockpickingStartEventData
	local eventData = {
		session = this.session,
	}
	event.trigger(EVENTS.lockpickingStart, eventData)

	timerManager.start({
		durationInSeconds = 1.3,
		finishedCallback = this.onLockpickingReady,
		cancelOn = EVENTS.lockpickingEnded,
	})
end

---@private
---@param activator tes3containerInstance|tes3door
---@return lockpickingSession|nil
function this.createSession(activator)
	local picks = inventoryManager.getLockpicks()
	if not picks then
		tes3.messageBox(translations.get(TRANSLATION_KEY.messageBoxNoLockpicks))
		return nil
	end

	local lock = lockSpawner.spawn(activator)
	local knife = knifeSpawner.spawn(lock)

	local session = {
		activator = activator,
		picks = picks,
		lock = lock,
		knife = knife,
	}

	session.pick = this.selectPick({
		session = session
	})

	return session
end

---@private
function this.onLockpickingReady()
	this.enable()

	---@type lockpickingStartedEventData
	local eventData = {
		session = this.session,
	}
	event.trigger(EVENTS.lockpickingStarted, eventData)
end

---@private
---@param e pickCycleRequestedEventData
function this.onPickCycleRequested(e)
	this.session.pick = this.selectPick({
		direction = e.direction
	})
end

---@private
function this.onExitRequested()
	this.finish({ success = false })
end

---@private
---@param _ enterFrameEventData
function this.onEnterFrame(_)
	local rotation = this.session.lock.cylinder.rotation:toEulerXYZ().y

	if rotation <= CONSTANTS.targetRotationLeft or rotation >= CONSTANTS.targetRotationRight then
		this.finish({ success = true })
		return
	end
end

---@private
---@param params lockpickingController.selectPick.params
---@return pick|nil
function this.selectPick(params)
	local session = params.session or this.session
	if not session then
		return nil
	end

	if session.pick then
		---@type pickCycledEventData
		local pickChangedEventData = {
			pick = this.session.pick,
		}
		event.trigger(EVENTS.pickCycled, pickChangedEventData)
	end

	local item = pickSelector.select(session.picks, params.direction)
	local pick = pickSpawner.spawn(session.lock, item)

	---@type pickSelectedEventData
	local pickSelectedEventData = {
		pick = pick,
	}
	event.trigger(EVENTS.pickSelected, pickSelectedEventData)

	return pick
end

---@private
---@param parameters stopLockpickingParameters
function this.finish(parameters)
	---@type lockpickingEndEventData
	local data = {
		session = this.session,
		success = parameters.success,
	}
	event.trigger(EVENTS.lockpickingEnd, data)

	timerManager.start({
		durationInSeconds = 1,
		finishedCallback = this.onEndTimerFinished,
		data = data --[[@as timerData]],
	})

	this.disable()
end

---@private
---@param data timerData
function this.onEndTimerFinished(data)
	---@cast data +lockpickingEndedEventData, -timerData
	this.stop({ success = data.success })
end

---@private
---@param parameters stopLockpickingParameters
function this.stop(parameters)
	---@type lockpickingEndedEventData
	local data = {
		session = this.session,
		success = parameters.success,
	}
	event.trigger(EVENTS.lockpickingEnded, data)

	local activator = this.session and this.session.activator

	if parameters.success then
		tes3.unlock({
			reference = activator --[[@as tes3reference]],
		})
		timer.delayOneFrame(function ()
			tes3.player:activate(activator --[[@as tes3reference]])
		end)
	end

	this.disable()
	this.resetFields()
end

function this.resetFields()
	this.session = nil
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
function this.registerEvents()
	event.register(EVENTS.lockpickingActivated, this.onLockPickingActivated)
	event.register(EVENTS.pickCycleRequested, this.onPickCycleRequested)
	event.register(EVENTS.exitRequested, this.onExitRequested)
end

return this
