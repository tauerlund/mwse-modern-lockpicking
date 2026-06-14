---@class pickController : initializedService
local this = {}

---@private
---@type lockpickingSession
this.session = nil

---@private
---@type pick
this.currentPick = nil

---@private
---@type boolean
this.breaking = false

---@private
---@type number
this.damageAccumulator = 0

---@private
---@type { [tes3.scanCode]: cycleDirections }
this.pickCycleDirections = nil

---@type tes3itemData|nil
this.currentPickItemData = nil

---@private
---@type settings
this.settings = nil

---@private
---@type pickSelector
this.pickSelector = nil

---@private
---@type pickSpawner
this.pickSpawner = nil

---@private
---@type enums
this.enums = nil

---@private
---@type formulas
this.formulas = nil

---@private
---@type eventRegistrar
this.eventRegistrar = nil

---@private
---@type timerManager
this.timerManager = nil

---@private
---@type inventoryController
this.inventoryController = nil

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
	this.pickSelector = services.pickSelector
	this.pickSpawner = services.pickSpawner
	this.enums = services.enums
	this.formulas = services.formulas
	this.eventRegistrar = services.eventRegistrar
	this.timerManager = services.timerManager
	this.inventoryController = services.inventoryController

	local events = services.enums.events

	this.eventHandlers = {
		lifetime = {
			[events.settingsUpdated] = this.onKeyBindsUpdated,
			[events.lockpickingStarted] = this.onLockpickingStarted,
			[events.lockpickingEnd] = this.onLockpickingEnd,
			[events.lockpickingEnded] = this.onLockpickingEnded,
			[events.cylinderBlocked] = this.onCylinderBlocked,
			[events.rotationEnded] = this.onRotationEnded,
		},
		session = {
			[tes3.event.keyDown] = this.onKeyDown,
			[tes3.event.enterFrame] = this.onEnterFrame,
		}
	}

	this.applyKeybinds()
	this.eventRegistrar.register(this.eventHandlers.lifetime)
	return true, nil
end

---@public
function this.uninitialize()
	this.eventRegistrar.unregister(this.eventHandlers.lifetime)
end

---@private
function this.onKeyBindsUpdated()
	this.applyKeybinds()
end

---@private
---@param e lockpickingStartedEventData
function this.onLockpickingStarted(e)
	this.session = e.session
	this.currentPick = e.session.pick
	this.currentPickItemData = this.tryResolvePickItemData()
	this.enable()
end

---@private
---@param _ lockpickingEndEventData
function this.onLockpickingEnd(_)
	this.disable()
end

---@private
---@param _ lockpickingEndedEventData
function this.onLockpickingEnded(_)
	this.disable()
	this.session = nil
	this.currentPick = nil
	this.breaking = false
	this.damageAccumulator = 0
end

---@private
function this.enable()
	this.eventRegistrar.register(this.eventHandlers.session)
end

---@private
function this.disable()
	this.eventRegistrar.unregister(this.eventHandlers.session)
end

---@private
---@param e keyDownEventData
function this.onKeyDown(e)
	if this.session.paused then
		return
	end

	if this.breaking or this.currentPick.animating then
		return
	end

	if this.pickCycleDirections[e.keyCode] then
		this.cyclePick(this.pickCycleDirections[e.keyCode])
	end
end

---@private
function this.onCylinderBlocked()
	this.session.pick.damaging = true
end

---@private
function this.onRotationEnded()
	this.session.pick.damaging = false
end

---@private
---@return boolean
function this.isSkeletonKey()
	local id = this.currentPick.item.object.id
	return id and id:lower() == "skeleton_key"
end

---@private
---@param e enterFrameEventData
function this.onEnterFrame(e)
	local session = this.session

	if not session or session.paused then
		return
	end

	if session.pick.damaging then
		if this.isSkeletonKey() and not this.settings.difficulty.damageSkeletonKey then
			return
		end
		this.damagePick(e.delta)
	end
end

---@private
---@param delta number
function this.damagePick(delta)
	local itemData = this.ensurePickItemData()
	local maxCondition = this.currentPick.item.object.maxCondition
	local fractionPerSecond = this.computeDamageRate()
	this.damageAccumulator = this.damageAccumulator + fractionPerSecond * maxCondition * delta

	local intDamage = math.floor(this.damageAccumulator)
	if intDamage >= 1 then
		this.damageAccumulator = this.damageAccumulator - intDamage
		itemData.condition = itemData.condition - intDamage
		if itemData.condition <= 0 then
			this.breakPick()
		end
	end
end

---@private
---@return tes3itemData
function this.ensurePickItemData()
	if not this.currentPickItemData then
		this.currentPickItemData = tes3.addItemData({
			to = tes3.player,
			item = this.currentPick.item.object --[[@as tes3lockpick]],
			updateGUI = true
		})
		this.currentPick.itemData = this.currentPickItemData
	end
	return this.currentPickItemData
end

---@private
---@return number
function this.computeDamageRate()
	local sweetSpot = this.session.sweetSpot
	return this.formulas.damageRate(sweetSpot and sweetSpot.radius, this.settings.difficulty)
end

---@private
function this.breakPick()
	if this.breaking then
		return
	end
	this.breaking = true
	this.session.pick.damaging = false
	this.session.pick.animating = true

	local events = this.enums.events

	local item = this.currentPick.item.object --[[@as tes3lockpick]]
	local remainingCount = this.currentPick.item.count - 1
	local isLastOfStack = remainingCount <= 0
	this.inventoryController.removePick(this.currentPick, this.currentPickItemData)

	---@type pickBrokenEventData
	local eventData = {
		pick = this.currentPick,
		itemData = this.currentPickItemData,
		item = item,
		remainingCount = remainingCount,
	}
	event.trigger(events.pickBroken, eventData)

	local direction = isLastOfStack and this.enums.cycleDirections.next or nil
	local duration = this.enums.constants.picks.breakAnimation.duration +
		this.enums.constants.picks.breakAnimation.cycleDelay

	this.timerManager.start({
		durationInSeconds = duration,
		cancelOn = { events.lockpickingEnded },
		pauseOn = { events.optionsMenuOpened },
		resumeOn = { events.optionsMenuClosed },
		callback = function ()
			if not this.session then
				return
			end
			this.breaking = false
			this.cyclePick(direction)
		end,
	})
end

---@private
---@param direction? cycleDirections
function this.cyclePick(direction)
	local session = this.session
	local previousPick = this.currentPick

	local item = direction
		and this.pickSelector.select({
			picks = session.picks,
			direction = direction
		})
		or previousPick.item

	if direction and item == previousPick.item then
		return
	end

	local pick = this.pickSpawner.spawn(session.lock, item)

	this.damageAccumulator = 0
	this.session.pick.damaging = false
	this.currentPick = pick
	this.currentPickItemData = this.tryResolvePickItemData()

	---@type pickCycledEventData
	local eventData = {
		previousPick = previousPick,
		pick = pick,
	}
	event.trigger(this.enums.events.pickCycled, eventData)
end

---@private
function this.tryResolvePickItemData()
	local item = this.currentPick.item

	if item.variables then
		local data = item.variables[1]
		for _, variable in ipairs(item.variables) do
			if variable.condition < data.condition then
				data = variable
			end
		end
		this.currentPick.itemData = data
		return data
	end

	this.currentPick.itemData = nil
	return nil
end

---@private
function this.applyKeybinds()
	this.pickCycleDirections = {
		[this.settings.keyBinds.cycleNextPick.keyCode] = this.enums.cycleDirections.next,
		[this.settings.keyBinds.cyclePreviousPick.keyCode] = this.enums.cycleDirections.previous,
	}
end

return this
