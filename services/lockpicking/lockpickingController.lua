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
---@type formulas
this.formulas = nil

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
	this.formulas = services.formulas
	this.enums = services.enums
	this.eventRegistrar = services.eventRegistrar

	local events = services.enums.events

	this.eventHandlers = {
		lifetime = {
			[events.lockpickingInterrupted] = this.onLockpickingInterrupted,
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

---@private
---@param _ loadEventData
function this.onLockpickingInterrupted(_)
	if not this.session then
		return
	end
	this.endLockpicking(false)
end

---@public
function this.uninitialize()
	this.eventRegistrar.unregister(this.eventHandlers.lifetime)
end

---@private
function this.onOptionsMenuOpened()
	if this.session then
		this.session.paused = true
	end
end

---@private
function this.onOptionsMenuClosed()
	if this.session then
		this.session.paused = false
	end
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
	if #picks == 0 then
		this.endLockpicking(false)
		tes3.messageBox(this.translations.get(this.enums.translationKeys.messageBoxOutOfLockpicks))
		return
	end

	this.session.picks = picks

	local eligiblePicks, anyEligible = this.computeEligiblePicks(picks, this.session.activator)

	if not anyEligible then
		this.endLockpicking(false)
		tes3.messageBox(this.translations.get(this.enums.translationKeys.messageBoxPicksTooWeak))
		return
	end

	this.session.eligiblePicks = eligiblePicks
end

---@private
---@param e lockpickingActivatedEventData
function this.onLockPickingActivated(e)
	if this.session then
		return
	end

	this.session = this.createSession(e.activator)
	if not this.session then
		return
	end

	local events = this.enums.events

	---@type lockpickingStartEventData
	local eventData = {
		session = this.session,
	}
	event.trigger(events.lockpickingStart, eventData)

	this.timerManager.start({
		durationInSeconds = this.enums.constants.lockpicking.entryDelay,
		callback = this.onStartTimerFinished,
		cancelOn = { events.lockpickingEnded },
		pauseOn = { events.optionsMenuOpened },
		resumeOn = { events.optionsMenuClosed },
	})
end

---@private
---@param activator tes3reference
---@return lockpickingSession|nil
function this.createSession(activator)
	local picks = this.inventoryController.getLockpicks()
	if #picks == 0 then
		tes3.messageBox(this.translations.get(this.enums.translationKeys.messageBoxNoLockpicks))
		return nil
	end

	local lock = this.lockSpawner.spawn(activator)
	local knife = this.knifeSpawner.spawn(lock)
	local eligiblePicks, _ = this.computeEligiblePicks(picks, activator)
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
		paused = false,
	}
end

---@private
---@param picks tes3itemStack[]
---@param activator tes3reference
---@return { [string]: boolean }, boolean
function this.computeEligiblePicks(picks, activator)
	local eligiblePicks = {}
	local anyEligible = false
	local lockNode = activator.lockNode
	for _, pick in ipairs(picks) do
		local eligible = not this.settings.useLockComplexity
			or not lockNode
			or this.skillController.getSuccessChance(pick, lockNode) > 0

		eligiblePicks[pick.object.id] = eligible

		if eligible then
			anyEligible = true
		end
	end
	return eligiblePicks, anyEligible
end

---@private
---@return number
function this.computeSweetSpotRadius()
	local lockNode = this.session.activator.lockNode
	return this.formulas.computeSweetSpotRadius({
		quality = this.session.pick.item.object.quality,
		statsModifier = this.skillController.getStatsModifier(),
		lockLevel = lockNode and lockNode.level or 1,
		difficulty = this.settings.difficulty,
	})
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
	this.session.sweetSpot = eventData
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
	if this.session.paused then
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

	local events = this.enums.events

	this.timerManager.start({
		durationInSeconds = this.enums.constants.lockpicking.exitDelay,
		callback = this.onEndTimerFinished,
		data = e --[[@as timerData]],
		cancelOn = { events.lockpickingEnded },
		pauseOn = { events.optionsMenuOpened },
		resumeOn = { events.optionsMenuClosed },
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
