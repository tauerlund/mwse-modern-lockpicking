---@class lockpickingController : initializedService
local this = {}

---@private
---@type settings
this.settings = nil

---@private
---@type lockSpawner
this.lockSpawner = nil

---@private
---@type knifeSpawner
this.knifeSpawner = nil

---@private
---@type pickSelector
this.pickSelector = nil

---@private
---@type pickSpawner
this.pickSpawner = nil

---@private
---@type timerManager
this.timerManager = nil

---@private
---@type inventoryController
this.inventoryController = nil

---@private
---@type translations
this.translations = nil

---@private
---@type skillController
this.skillController = nil

---@private
---@type enums
this.enums = nil

---@private
---@type lockpickingSession|nil
this.session = nil

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
	this.settings = services.settings
	this.lockSpawner = services.lockSpawner
	this.knifeSpawner = services.knifeSpawner
	this.pickSelector = services.pickSelector
	this.pickSpawner = services.pickSpawner
	this.timerManager = services.timerManager
	this.inventoryController = services.inventoryController
	this.translations = services.translations
	this.skillController = services.skillController
	this.enums = services.enums
	this.eventRegistrar = services.eventRegistrar

	local events = services.enums.events

	this.eventHandlers = {
		lifetime = {
			[events.lockpickingActivated] = this.onLockPickingActivated,
			[events.cylinderTargetReached] = this.onCylinderTargetReached,
			[events.pickCycled] = this.onPickCycled,
			[events.pickBroken] = this.onPickBroken,
			[events.lockpickingEnd] = this.onLockpickingEnd,
			[events.settingsUpdated] = this.onSettingsUpdated,
			[events.optionsMenuOpened] = this.onOptionsMenuOpened,
			[events.optionsMenuClosed] = this.onOptionsMenuClosed,
		},
		session = {
			[tes3.event.keyUp] = this.onKeyUp,
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
function this.onSettingsUpdated()
	if this.session then
		this.triggerSweetSpotUpdated()
	end
end

---@private
---@param _ pickBrokenEventData
function this.onPickBroken(_)
	local picks = this.inventoryController.getLockpicks()
	if not picks then
		this.endLockpicking(false)
		tes3.messageBox(this.translations.get(this.enums.translationKeys.messageBoxOutOfLockpicks))
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
	event.trigger(this.enums.events.lockpickingStart, eventData)

	this.timerManager.start({
		durationInSeconds = 1.3,
		callback = this.onStartTimerFinished,
		cancelOn = { this.enums.events.lockpickingEnded },
	})
end

---@private
---@param activator tes3reference
---@return lockpickingSession|nil
function this.createSession(activator)
	local picks = this.inventoryController.getLockpicks()
	if not picks then
		tes3.messageBox(this.translations.get(this.enums.translationKeys.messageBoxNoLockpicks))
		return nil
	end

	local lock = this.lockSpawner.spawn(activator)
	local knife = this.knifeSpawner.spawn(lock)
	local eligiblePicks = this.computeEligiblePicks(picks, activator)
	local item = this.pickSelector.select({
		picks = picks,
		eligiblePicks = eligiblePicks
	})
	local pick = this.pickSpawner.spawn(lock, item)

	return {
		activator = activator,
		picks = picks,
		eligiblePicks = eligiblePicks,
		lock = lock,
		knife = knife,
		pick = pick,
		sweetSpotCenter = math.random() * math.pi - (math.pi / 2),
	}
end

---@private
---@param picks tes3itemStack[]
---@param activator tes3reference
---@return { [string]: boolean }
function this.computeEligiblePicks(picks, activator)
	local eligiblePicks = {}
	local lockNode = activator.lockNode
	for _, pick in ipairs(picks) do
		if not this.settings.useLockComplexity or not lockNode then
			eligiblePicks[pick.object.id] = true
		else
			eligiblePicks[pick.object.id] = this.skillController.getSuccessChance(pick, lockNode) > 0
		end
	end
	return eligiblePicks
end

---@private
---@return number
function this.computeSweetSpotRadius()
	local difficulty = this.settings.difficulty
	local statsModifier = this.skillController.getStatsModifier()
	local lockLevel = this.session.activator.lockNode and this.session.activator.lockNode.level or 1
	local quality = this.session.pick.item.object.quality
	local radius = math.pi * quality ^ difficulty.qualityFactor * statsModifier * difficulty.securityFactor /
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
		gradientWidth = radius * this.settings.difficulty.gradientFactor,
	}
	event.trigger(this.enums.events.sweetSpotUpdated, eventData)
end

---@private
function this.onStartTimerFinished()
	---@type lockpickingStartedEventData
	local eventData = {
		session = this.session,
	}
	event.trigger(this.enums.events.lockpickingStarted, eventData)
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
	event.trigger(this.enums.events.lockpickingEnd, data)
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
	if this.paused then
		return
	end

	local exitKeyCode = this.settings.keyBinds.exit.keyCode
	if e.keyCode ~= exitKeyCode then
		return
	end

	---@type lockpickingEndEventData
	local data = {
		session = this.session,
		success = false,
	}
	event.trigger(this.enums.events.lockpickingEnd, data)
end

---@private
---@param e lockpickingEndEventData
function this.onLockpickingEnd(e)
	this.disableInput()
	this.timerManager.start({
		durationInSeconds = 0.1,
		callback = this.onEndTimerFinished,
		data = e --[[@as timerData]],
	})
end

---@private
---@param data timerData
function this.onEndTimerFinished(data)
	---@cast data +lockpickingEndEventData, -timerData
	---@type lockpickingEndedEventData
	this.endLockpicking(data.success)
end

---@private
---@param success boolean
function this.endLockpicking(success)
	---@type lockpickingEndedEventData
	local eventData = {
		session = this.session,
		success = success,
	}
	event.trigger(this.enums.events.lockpickingEnded, eventData)
	this.session = nil
end

---@private
function this.enableInput()
	this.eventRegistrar.register(this.eventHandlers.session)
end

---@private
function this.disableInput()
	this.eventRegistrar.unregister(this.eventHandlers.session)
end

return this
