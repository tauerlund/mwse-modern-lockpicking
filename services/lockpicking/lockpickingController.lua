--- SERVICES
local settings = require("tauer.modern-lockpicking.services.mcm.mcmSettings").mcm
local lockSpawner = require("tauer.modern-lockpicking.services.locks.lockSpawner")
local knifeSpawner = require("tauer.modern-lockpicking.services.knives.knifeSpawner")
local pickSelector = require("tauer.modern-lockpicking.services.picks.pickSelector")
local pickSpawner = require("tauer.modern-lockpicking.services.picks.pickSpawner")
local timerManager = require("tauer.modern-lockpicking.services.timers.timerManager")
local inventoryController = require("tauer.modern-lockpicking.services.inventory.inventoryController")
local translations = require("tauer.modern-lockpicking.services.translations.translations")
---

--- ENUMS
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
	event.register(EVENTS.lockpickingActivated, this.onLockPickingActivated)
	event.register(EVENTS.cylinderTargetReached, this.onCylinderTargetReached)
	event.register(EVENTS.pickCycled, this.onPickCycled)
	event.register(EVENTS.pickBroken, this.onPickBroken)
	event.register(EVENTS.lockpickingEnd, this.onLockpickingEnd)
	event.register(EVENTS.settingsUpdated, this.onSettingsUpdated)
	return true, nil
end

---@private
function this.onSettingsUpdated()
	if this.session then
		this.triggerSweetSpotUpdated()
	end
end

---@private
---@param _ pickBrokenEventData
function this.onPickBroken(_)
	local picks = inventoryController.getLockpicks()
	if not picks then
		return
	end

	this.session.picks = picks
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
		finishedCallback = this.onStartTimerFinished,
		cancelOn = EVENTS.lockpickingEnded,
	})
end

---@private
---@param activator tes3reference
---@return lockpickingSession|nil
function this.createSession(activator)
	local picks = inventoryController.getLockpicks()
	if not picks then
		tes3.messageBox(translations.get(TRANSLATION_KEY.messageBoxNoLockpicks))
		return nil
	end

	local lock = lockSpawner.spawn(activator)
	local knife = knifeSpawner.spawn(lock)
	local item = pickSelector.select(picks, nil)
	local pick = pickSpawner.spawn(lock, item)

	return {
		activator = activator,
		picks = picks,
		lock = lock,
		knife = knife,
		pick = pick,
		sweetSpotCenter = math.random() * math.pi - (math.pi / 2),
	}
end

---@private
---@return number
function this.computeSweetSpotRadius()
	local difficulty = settings.difficulty
	local security = tes3.mobilePlayer:getSkillValue(tes3.skill.security)
	local lockLevel = this.session.activator.lockNode and this.session.activator.lockNode.level or 1
	local quality = this.session.pick.item.object.quality
	local radius = math.pi * quality * difficulty.qualityFactor * security * difficulty.securityFactor /
		(math.max(1, lockLevel) * difficulty.lockLevelFactor)
	return math.min(radius, math.rad(difficulty.maxSweetSpotRadius))
end

---@private
function this.triggerSweetSpotUpdated()
	local radius = this.computeSweetSpotRadius()
	---@type sweetSpotUpdatedEventData
	local eventData = {
		center = this.session.sweetSpotCenter,
		radius = radius,
		gradientWidth = radius * settings.difficulty.gradientFactor,
	}
	event.trigger(EVENTS.sweetSpotUpdated, eventData)
end

---@private
function this.onStartTimerFinished()
	---@type lockpickingStartedEventData
	local eventData = {
		session = this.session,
	}
	event.trigger(EVENTS.lockpickingStarted, eventData)
	this.enableInput()
	this.triggerSweetSpotUpdated()
end

---@private
function this.onCylinderTargetReached()
	---@type lockpickingEndEventData
	local data = {
		session = this.session,
		success = true,
	}
	event.trigger(EVENTS.lockpickingEnd, data)
end

---@private
---@param e pickCycledEventData
function this.onPickCycled(e)
	this.session.pick = e.pick
	this.triggerSweetSpotUpdated()
end

---@private
---@param e keyUpEventData
function this.onKeyUp(e)
	if e.keyCode == settings.keyBinds.exit.keyCode then
		---@type lockpickingEndEventData
		local data = {
			session = this.session,
			success = false,
		}
		event.trigger(EVENTS.lockpickingEnd, data)
	end
end

---@private
---@param e lockpickingEndEventData
function this.onLockpickingEnd(e)
	this.disableInput()
	timerManager.start({
		durationInSeconds = 1,
		finishedCallback = this.onEndTimerFinished,
		data = e --[[@as timerData]],
	})
end

---@private
---@param data timerData
function this.onEndTimerFinished(data)
	---@cast data +lockpickingEndEventData, -timerData
	---@type lockpickingEndedEventData
	local eventData = {
		session = this.session,
		success = data.success,
	}
	event.trigger(EVENTS.lockpickingEnded, eventData)
	this.session = nil
end

---@private
function this.enableInput()
	if not event.isRegistered(tes3.event.keyUp, this.onKeyUp) then
		event.register(tes3.event.keyUp, this.onKeyUp)
	end
end

---@private
function this.disableInput()
	if event.isRegistered(tes3.event.keyUp, this.onKeyUp) then
		event.unregister(tes3.event.keyUp, this.onKeyUp)
	end
end

return this
